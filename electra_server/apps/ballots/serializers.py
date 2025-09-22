"""
Serializers for ballot token endpoints.

This module contains all DRF serializers used for ballot token issuance,
validation, and offline queue management.
"""
import uuid
from typing import Dict, Any, Optional

from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework import serializers

from electra_server.apps.elections.models import Election
from .models import BallotToken, BallotTokenStatus, OfflineBallotQueue, BallotTokenUsageLog

User = get_user_model()


class BallotTokenRequestSerializer(serializers.Serializer):
    """
    Serializer for ballot token request.
    
    Handles token requests for specific elections, ensuring users
    can only request tokens for elections they're eligible to vote in.
    """
    
    election_id = serializers.UUIDField(
        help_text='UUID of the election to request a token for'
    )
    
    def validate_election_id(self, value: uuid.UUID) -> uuid.UUID:
        """
        Validate the election ID.
        
        Args:
            value: Election UUID to validate
            
        Returns:
            uuid.UUID: Validated election ID
            
        Raises:
            ValidationError: If election is invalid or voting not allowed
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
        
        # Store election for later use
        self.election = election
        return value
    
    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate the request data.
        
        Args:
            attrs: Request data
            
        Returns:
            Dict[str, Any]: Validated data
            
        Raises:
            ValidationError: If user already has a token for this election
        """
        request = self.context['request']
        user = request.user
        election_id = attrs['election_id']
        
        # Check if user already has a token for this election
        existing_token = BallotToken.objects.filter(
            user=user,
            election_id=election_id,
            status__in=[BallotTokenStatus.ISSUED]
        ).first()
        
        if existing_token:
            if existing_token.is_valid:
                raise serializers.ValidationError(
                    "You already have a valid ballot token for this election."
                )
            elif existing_token.is_expired:
                # Mark expired token as expired
                existing_token.status = BallotTokenStatus.EXPIRED
                existing_token.save(update_fields=['status'])
        
        return attrs


class BallotTokenResponseSerializer(serializers.ModelSerializer):
    """
    Serializer for ballot token response.
    
    Returns complete token information including signature and metadata
    needed for offline voting support.
    """
    
    election_title = serializers.CharField(
        source='election.title',
        read_only=True,
        help_text='Title of the election'
    )
    
    election_id = serializers.UUIDField(
        source='election.id',
        read_only=True,
        help_text='UUID of the election'
    )
    
    user_id = serializers.UUIDField(
        source='user.id',
        read_only=True,
        help_text='UUID of the user'
    )
    
    is_valid = serializers.BooleanField(
        read_only=True,
        help_text='Whether the token is currently valid for voting'
    )
    
    is_expired = serializers.BooleanField(
        read_only=True,
        help_text='Whether the token has expired'
    )
    
    token_data = serializers.SerializerMethodField(
        help_text='Token data for verification'
    )
    
    class Meta:
        model = BallotToken
        fields = [
            'id', 'token_uuid', 'signature', 'status', 'issued_at', 
            'expires_at', 'election_id', 'election_title', 'user_id',
            'is_valid', 'is_expired', 'token_data', 'offline_data'
        ]
        read_only_fields = [
            'id', 'token_uuid', 'signature', 'status', 'issued_at',
            'expires_at', 'is_valid', 'is_expired', 'token_data'
        ]
    
    def get_token_data(self, obj: BallotToken) -> Dict[str, Any]:
        """Get token data for verification."""
        return obj.get_token_data()


class BallotTokenValidationSerializer(serializers.Serializer):
    """
    Serializer for ballot token validation.
    
    Validates token signatures and ensures tokens are valid for voting.
    """
    
    token_uuid = serializers.UUIDField(
        help_text='UUID of the token to validate'
    )
    
    signature = serializers.CharField(
        help_text='RSA signature to validate'
    )
    
    election_id = serializers.UUIDField(
        required=False,
        help_text='Optional election ID for additional validation'
    )
    
    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate the token and signature.
        
        Args:
            attrs: Validation data
            
        Returns:
            Dict[str, Any]: Validated data with token object
            
        Raises:
            ValidationError: If token is invalid or signature doesn't match
        """
        token_uuid = attrs['token_uuid']
        signature = attrs['signature']
        election_id = attrs.get('election_id')
        
        try:
            token = BallotToken.objects.select_related('user', 'election').get(
                token_uuid=token_uuid
            )
        except BallotToken.DoesNotExist:
            raise serializers.ValidationError("Invalid token.")
        
        # Verify signature
        if not token.verify_signature(signature):
            raise serializers.ValidationError("Invalid token signature.")
        
        # Additional election validation if provided
        if election_id and token.election.id != election_id:
            raise serializers.ValidationError(
                "Token is not valid for the specified election."
            )
        
        # Check token validity
        if not token.is_valid:
            if token.is_expired:
                raise serializers.ValidationError("Token has expired.")
            elif token.status == BallotTokenStatus.USED:
                raise serializers.ValidationError("Token has already been used.")
            elif token.status == BallotTokenStatus.INVALIDATED:
                raise serializers.ValidationError("Token has been invalidated.")
            else:
                raise serializers.ValidationError("Token is not valid.")
        
        attrs['token'] = token
        return attrs


class BallotTokenValidationResponseSerializer(serializers.Serializer):
    """
    Serializer for ballot token validation response.
    """
    
    valid = serializers.BooleanField(
        help_text='Whether the token is valid'
    )
    
    token = BallotTokenResponseSerializer(
        required=False,
        help_text='Token details if valid'
    )
    
    message = serializers.CharField(
        required=False,
        help_text='Validation message'
    )


class OfflineBallotQueueSerializer(serializers.ModelSerializer):
    """
    Serializer for offline ballot queue entries.
    
    Manages offline voting data encryption and synchronization.
    """
    
    ballot_token_uuid = serializers.UUIDField(
        source='ballot_token.token_uuid',
        read_only=True,
        help_text='UUID of the associated ballot token'
    )
    
    election_title = serializers.CharField(
        source='ballot_token.election.title',
        read_only=True,
        help_text='Title of the election'
    )
    
    user_email = serializers.EmailField(
        source='ballot_token.user.email',
        read_only=True,
        help_text='Email of the user'
    )
    
    class Meta:
        model = OfflineBallotQueue
        fields = [
            'id', 'ballot_token_uuid', 'election_title', 'user_email',
            'encrypted_data', 'is_synced', 'created_at', 'synced_at',
            'sync_attempts', 'last_sync_error'
        ]
        read_only_fields = [
            'id', 'ballot_token_uuid', 'election_title', 'user_email',
            'is_synced', 'created_at', 'synced_at', 'sync_attempts',
            'last_sync_error'
        ]


class OfflineBallotSubmissionSerializer(serializers.Serializer):
    """
    Serializer for offline ballot submission.
    
    Handles submission of votes that were cast offline and need to be
    synchronized back to the server.
    """
    
    ballot_token_uuid = serializers.UUIDField(
        help_text='UUID of the ballot token'
    )
    
    encrypted_vote_data = serializers.CharField(
        help_text='Encrypted vote data from offline voting'
    )
    
    signature = serializers.CharField(
        help_text='Signature of the offline ballot data'
    )
    
    submission_timestamp = serializers.DateTimeField(
        help_text='When the vote was originally cast offline'
    )
    
    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate the offline ballot submission.
        
        Args:
            attrs: Submission data
            
        Returns:
            Dict[str, Any]: Validated data
            
        Raises:
            ValidationError: If submission is invalid
        """
        token_uuid = attrs['ballot_token_uuid']
        
        try:
            token = BallotToken.objects.select_related('election', 'user').get(
                token_uuid=token_uuid
            )
        except BallotToken.DoesNotExist:
            raise serializers.ValidationError("Invalid ballot token.")
        
        # Check if token was valid at submission time
        submission_time = attrs['submission_timestamp']
        if submission_time > token.expires_at:
            raise serializers.ValidationError(
                "Ballot was submitted after token expiry."
            )
        
        if submission_time < token.issued_at:
            raise serializers.ValidationError(
                "Invalid submission timestamp."
            )
        
        # Check if election was active at submission time
        if not (token.election.start_time <= submission_time <= token.election.end_time):
            raise serializers.ValidationError(
                "Ballot was submitted outside election voting period."
            )
        
        attrs['token'] = token
        return attrs


class BallotTokenUsageLogSerializer(serializers.ModelSerializer):
    """
    Serializer for ballot token usage logs.
    
    Provides audit trail information for token operations.
    """
    
    ballot_token_uuid = serializers.UUIDField(
        source='ballot_token.token_uuid',
        read_only=True,
        help_text='UUID of the ballot token'
    )
    
    user_email = serializers.EmailField(
        source='ballot_token.user.email',
        read_only=True,
        help_text='Email of the user who owns the token'
    )
    
    election_title = serializers.CharField(
        source='ballot_token.election.title',
        read_only=True,
        help_text='Title of the election'
    )
    
    class Meta:
        model = BallotTokenUsageLog
        fields = [
            'id', 'ballot_token_uuid', 'user_email', 'election_title',
            'action', 'ip_address', 'user_agent', 'metadata', 'timestamp'
        ]
        read_only_fields = [
            'id', 'ballot_token_uuid', 'user_email', 'election_title',
            'timestamp'
        ]


class BallotTokenStatsSerializer(serializers.Serializer):
    """
    Serializer for ballot token statistics.
    
    Provides aggregated statistics about token issuance and usage.
    """
    
    total_tokens_issued = serializers.IntegerField(
        help_text='Total number of tokens issued'
    )
    
    active_tokens = serializers.IntegerField(
        help_text='Number of currently active tokens'
    )
    
    used_tokens = serializers.IntegerField(
        help_text='Number of tokens that have been used'
    )
    
    expired_tokens = serializers.IntegerField(
        help_text='Number of expired tokens'
    )
    
    invalidated_tokens = serializers.IntegerField(
        help_text='Number of invalidated tokens'
    )
    
    offline_queue_entries = serializers.IntegerField(
        help_text='Number of offline queue entries'
    )
    
    pending_sync_entries = serializers.IntegerField(
        help_text='Number of offline entries pending sync'
    )
    
    by_election = serializers.DictField(
        help_text='Token statistics by election'
    )
    
    by_status = serializers.DictField(
        help_text='Token statistics by status'
    )