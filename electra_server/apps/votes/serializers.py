"""
Votes serializers for electra_server.

This module contains serializers for vote casting, validation, and management
in the electra voting system.
"""
import json
import uuid
from base64 import b64decode, b64encode
from typing import Dict, Any

from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.utils import timezone
from rest_framework import serializers

from electra_server.apps.ballots.models import BallotToken
from electra_server.apps.elections.models import Election
from .models import Vote, VoteToken, OfflineVoteQueue, VoteAuditLog

User = get_user_model()


class VoteCastSerializer(serializers.Serializer):
    """
    Serializer for vote casting.

    Handles encrypted vote submission with ballot token validation,
    ensuring vote integrity and preventing double voting.
    """

    # Ballot token for authentication
    token_uuid = serializers.UUIDField(help_text="UUID of the ballot token")

    # Token signature for verification
    token_signature = serializers.CharField(
        help_text="RSA signature of the ballot token"
    )

    # Election ID
    election_id = serializers.UUIDField(help_text="UUID of the election")

    # Encrypted vote data (base64 encoded)
    encrypted_vote_data = serializers.CharField(
        help_text="Base64 encoded AES-256-GCM encrypted vote data"
    )

    # Encryption nonce (base64 encoded)
    encryption_nonce = serializers.CharField(
        help_text="Base64 encoded AES-256-GCM nonce"
    )

    # Vote signature
    vote_signature = serializers.CharField(help_text="RSA signature of the vote data")

    # Client encryption key hash
    encryption_key_hash = serializers.CharField(
        help_text="SHA-256 hash of client encryption key"
    )

    def validate_token_uuid(self, value: uuid.UUID) -> uuid.UUID:
        """
        Validate ballot token exists and is valid.

        Args:
            value: Token UUID to validate

        Returns:
            uuid.UUID: Validated token UUID

        Raises:
            ValidationError: If token is invalid
        """
        try:
            token = BallotToken.objects.select_related("user", "election").get(
                token_uuid=value
            )
        except BallotToken.DoesNotExist:
            raise serializers.ValidationError("Invalid ballot token.")

        # Store for later use
        self.ballot_token = token
        return value

    def validate_election_id(self, value: uuid.UUID) -> uuid.UUID:
        """
        Validate election exists and is accepting votes.

        Args:
            value: Election UUID to validate

        Returns:
            uuid.UUID: Validated election ID

        Raises:
            ValidationError: If election is invalid
        """
        try:
            election = Election.objects.get(id=value)
        except Election.DoesNotExist:
            raise serializers.ValidationError("Election not found.")

        # Check if election allows voting
        if not election.can_vote:
            raise serializers.ValidationError(
                "Voting is not currently allowed for this election."
            )

        # Store for later use
        self.election = election
        return value

    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate the complete vote submission.

        Args:
            attrs: Validation data

        Returns:
            Dict[str, Any]: Validated data

        Raises:
            ValidationError: If validation fails
        """
        # Verify token matches election
        if self.ballot_token.election.id != self.election.id:
            raise serializers.ValidationError(
                "Ballot token is not valid for this election."
            )

        # Verify token signature
        if not self.ballot_token.verify_signature(attrs["token_signature"]):
            raise serializers.ValidationError("Invalid ballot token signature.")

        # Check if token is still valid
        if self.ballot_token.status != "issued":
            raise serializers.ValidationError(
                "Ballot token has already been used or is invalid."
            )

        # Check if user has already voted (via vote token)
        vote_token = Vote.create_anonymous_vote_token(self.ballot_token)
        if Vote.objects.filter(vote_token=vote_token, election=self.election).exists():
            raise serializers.ValidationError(
                "Vote has already been cast for this election."
            )

        # Validate base64 encoding
        try:
            b64decode(attrs["encrypted_vote_data"])
            b64decode(attrs["encryption_nonce"])
        except Exception:
            raise serializers.ValidationError(
                "Invalid base64 encoding in vote data or nonce."
            )

        # Add validated objects to attrs
        attrs["ballot_token"] = self.ballot_token
        attrs["election"] = self.election
        attrs["vote_token"] = vote_token

        return attrs


class VoteVerificationSerializer(serializers.Serializer):
    """
    Serializer for vote verification.

    Validates vote signature and integrity without exposing voter identity.
    """

    # Anonymous vote token
    vote_token = serializers.UUIDField(help_text="Anonymous vote token")

    # Election ID
    election_id = serializers.UUIDField(help_text="UUID of the election")

    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate vote exists and can be verified.

        Args:
            attrs: Validation data

        Returns:
            Dict[str, Any]: Validated data with vote object

        Raises:
            ValidationError: If vote is not found or invalid
        """
        try:
            vote = Vote.objects.select_related("election").get(
                vote_token=attrs["vote_token"], election__id=attrs["election_id"]
            )
        except Vote.DoesNotExist:
            raise serializers.ValidationError("Vote not found.")

        attrs["vote"] = vote
        return attrs


class OfflineVoteQueueSerializer(serializers.ModelSerializer):
    """
    Serializer for offline vote queue management.

    Handles queuing votes for offline submission and later synchronization.
    """

    # Ballot token UUID (for easier access)
    ballot_token_uuid = serializers.UUIDField(
        source="ballot_token.token_uuid",
        read_only=True,
        help_text="UUID of the associated ballot token",
    )

    # Election title (for display)
    election_title = serializers.CharField(
        source="ballot_token.election.title",
        read_only=True,
        help_text="Title of the associated election",
    )

    class Meta:
        model = OfflineVoteQueue
        fields = [
            "id",
            "ballot_token_uuid",
            "election_title",
            "encrypted_vote_data",
            "client_timestamp",
            "queued_at",
            "is_synced",
            "synced_at",
            "sync_result",
            "client_ip",
        ]
        read_only_fields = [
            "id",
            "ballot_token_uuid",
            "election_title",
            "queued_at",
            "is_synced",
            "synced_at",
            "sync_result",
        ]


class OfflineVoteSubmissionSerializer(serializers.Serializer):
    """
    Serializer for offline vote submission synchronization.

    Handles batch submission of offline votes when connectivity is restored.
    """

    # Ballot token for authentication
    token_uuid = serializers.UUIDField(help_text="UUID of the ballot token")

    # Token signature for verification
    token_signature = serializers.CharField(
        help_text="RSA signature of the ballot token"
    )

    # Complete encrypted vote data
    encrypted_vote_data = serializers.JSONField(
        help_text="Complete encrypted vote data structure"
    )

    # Client-side timestamp
    client_timestamp = serializers.DateTimeField(
        help_text="When the vote was cast on the client side"
    )

    def validate_token_uuid(self, value: uuid.UUID) -> uuid.UUID:
        """
        Validate ballot token exists.

        Args:
            value: Token UUID to validate

        Returns:
            uuid.UUID: Validated token UUID

        Raises:
            ValidationError: If token is invalid
        """
        try:
            token = BallotToken.objects.select_related("user", "election").get(
                token_uuid=value
            )
        except BallotToken.DoesNotExist:
            raise serializers.ValidationError("Invalid ballot token.")

        # Store for later use
        self.ballot_token = token
        return value

    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate the offline vote submission.

        Args:
            attrs: Validation data

        Returns:
            Dict[str, Any]: Validated data

        Raises:
            ValidationError: If validation fails
        """
        # Verify token signature
        if not self.ballot_token.verify_signature(attrs["token_signature"]):
            raise serializers.ValidationError("Invalid ballot token signature.")

        # Validate encrypted vote data structure
        vote_data = attrs["encrypted_vote_data"]
        required_fields = [
            "election_id",
            "encrypted_vote_data",
            "encryption_nonce",
            "vote_signature",
            "encryption_key_hash",
        ]

        for field in required_fields:
            if field not in vote_data:
                raise serializers.ValidationError(
                    f"Missing required field in encrypted vote data: {field}"
                )

        # Verify election matches token
        try:
            election = Election.objects.get(id=vote_data["election_id"])
        except Election.DoesNotExist:
            raise serializers.ValidationError("Election not found.")

        if self.ballot_token.election.id != election.id:
            raise serializers.ValidationError(
                "Ballot token election does not match vote election."
            )

        # Add validated objects to attrs
        attrs["ballot_token"] = self.ballot_token
        attrs["election"] = election

        return attrs


class VoteStatusSerializer(serializers.ModelSerializer):
    """
    Serializer for vote status information.

    Provides basic vote information without exposing sensitive data.
    """

    # Election information
    election_id = serializers.UUIDField(
        source="election.id", read_only=True, help_text="ID of the election"
    )

    election_title = serializers.CharField(
        source="election.title", read_only=True, help_text="Title of the election"
    )

    # Signature verification status
    signature_valid = serializers.SerializerMethodField(
        help_text="Whether the vote signature is valid"
    )

    class Meta:
        model = Vote
        fields = [
            "id",
            "vote_token",
            "election_id",
            "election_title",
            "status",
            "submitted_at",
            "signature_valid",
        ]
        read_only_fields = [
            "id",
            "vote_token",
            "election_id",
            "election_title",
            "status",
            "submitted_at",
            "signature_valid",
        ]

    def get_signature_valid(self, obj: Vote) -> bool:
        """
        Get signature validation status.

        Args:
            obj: Vote instance

        Returns:
            bool: Whether signature is valid
        """
        return obj.verify_signature()


class VoteAuditLogSerializer(serializers.ModelSerializer):
    """
    Serializer for vote audit log entries.

    Provides audit information while maintaining anonymity.
    """

    # Vote information (limited)
    vote_id = serializers.UUIDField(
        source="vote.id", read_only=True, help_text="Vote ID if applicable"
    )

    # Election information
    election_title = serializers.CharField(
        source="election.title", read_only=True, help_text="Election title"
    )

    class Meta:
        model = VoteAuditLog
        fields = [
            "id",
            "vote_id",
            "action",
            "election_title",
            "vote_token",
            "ip_address",
            "metadata",
            "timestamp",
            "result",
            "error_details",
        ]
        read_only_fields = [
            "id",
            "vote_id",
            "action",
            "election_title",
            "vote_token",
            "ip_address",
            "metadata",
            "timestamp",
            "result",
            "error_details",
        ]
