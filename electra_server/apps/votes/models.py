"""
Votes models for electra_server.

This module contains models for managing vote casting, including encrypted
vote storage, anonymization, and offline support for the electra voting system.
"""
import hashlib
import json
import uuid
from base64 import b64decode
from typing import Dict, Any

from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone

from electra_server.apps.elections.models import Election
from electra_server.apps.ballots.models import BallotToken

User = get_user_model()


class VoteStatus(models.TextChoices):
    """Vote status choices."""

    CAST = "cast", "Cast"
    VERIFIED = "verified", "Verified"
    INVALIDATED = "invalidated", "Invalidated"


class Vote(models.Model):
    """
    Vote model for storing encrypted votes with anonymization.

    This model stores votes in encrypted form using AES-256-GCM encryption.
    The voter identity is separated from the vote content to ensure anonymity
    while maintaining audit capabilities through cryptographic signatures.
    """

    # Primary key as UUID
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text="Unique identifier for the vote",
    )

    # Anonymous vote token (separates vote from voter identity)
    vote_token = models.UUIDField(
        unique=True,
        help_text="Anonymous token linking to ballot token without revealing voter identity",
    )

    # Encrypted vote data (AES-256-GCM)
    encrypted_data = models.TextField(
        help_text="AES-256-GCM encrypted vote data in base64 format"
    )

    # Encryption nonce/IV for AES-GCM
    encryption_nonce = models.TextField(
        help_text="Base64 encoded nonce/IV for AES-256-GCM decryption"
    )

    # RSA signature of the vote (for integrity verification)
    signature = models.TextField(
        help_text="RSA signature of the vote data for verification"
    )

    # Election reference
    election = models.ForeignKey(
        Election,
        on_delete=models.CASCADE,
        related_name="votes",
        help_text="Election this vote belongs to",
    )

    # Vote status
    status = models.CharField(
        max_length=20,
        choices=VoteStatus.choices,
        default=VoteStatus.CAST,
        help_text="Current status of the vote",
    )

    # Hash of original ballot token (for audit without identity exposure)
    ballot_token_hash = models.CharField(
        max_length=64, help_text="SHA-256 hash of ballot token UUID for audit trail"
    )

    # Submission metadata (for audit)
    submitted_at = models.DateTimeField(
        auto_now_add=True, help_text="When the vote was submitted"
    )

    submitted_ip = models.GenericIPAddressField(
        help_text="IP address from which vote was submitted"
    )

    # Client-side encryption key hash (for verification)
    encryption_key_hash = models.CharField(
        max_length=64,
        help_text="SHA-256 hash of client encryption key for verification",
    )

    class Meta:
        """Meta options for Vote model."""

        db_table = "votes_vote"
        verbose_name = "Vote"
        verbose_name_plural = "Votes"
        ordering = ["-submitted_at"]

        # Constraints
        constraints = [
            models.UniqueConstraint(
                fields=["vote_token", "election"], name="unique_vote_token_per_election"
            ),
        ]

        # Indexes for performance
        indexes = [
            models.Index(fields=["election"]),
            models.Index(fields=["status"]),
            models.Index(fields=["submitted_at"]),
            models.Index(fields=["vote_token"]),
            models.Index(fields=["ballot_token_hash"]),
        ]

    def __str__(self) -> str:
        """Return string representation of the vote."""
        return f"Vote({self.vote_token}) - {self.election.title}"

    def clean(self) -> None:
        """Validate the vote instance."""
        super().clean()

        # Validate vote token format
        if self.vote_token and len(str(self.vote_token)) != 36:
            raise ValidationError({"vote_token": "Invalid vote token format."})

    @classmethod
    def create_anonymous_vote_token(cls, ballot_token: BallotToken) -> uuid.UUID:
        """
        Create anonymous vote token from ballot token.

        Args:
            ballot_token: The ballot token to anonymize

        Returns:
            uuid.UUID: Anonymous vote token
        """
        # Create deterministic but anonymous token from ballot token
        token_data = f"{ballot_token.token_uuid}:{ballot_token.election.id}:{ballot_token.user.id}"
        token_hash = hashlib.sha256(token_data.encode()).hexdigest()

        # Create UUID5 from namespace and hash (deterministic)
        namespace = uuid.UUID(
            "12345678-1234-5678-1234-567812345678"
        )  # Static namespace
        return uuid.uuid5(namespace, token_hash)

    @classmethod
    def create_ballot_token_hash(cls, ballot_token: BallotToken) -> str:
        """
        Create hash of ballot token for audit trail.

        Args:
            ballot_token: The ballot token to hash

        Returns:
            str: SHA-256 hash of ballot token UUID
        """
        return hashlib.sha256(str(ballot_token.token_uuid).encode()).hexdigest()

    def verify_signature(self) -> bool:
        """
        Verify RSA signature of the vote.

        Returns:
            bool: True if signature is valid
        """
        try:
            # Load public key
            public_key_path = settings.BASE_DIR / settings.RSA_PUBLIC_KEY_PATH
            with open(public_key_path, "rb") as key_file:
                public_key = serialization.load_pem_public_key(key_file.read())

            # Prepare data for verification
            vote_data = {
                "vote_token": str(self.vote_token),
                "encrypted_data": self.encrypted_data,
                "election_id": str(self.election.id),
                "encryption_nonce": self.encryption_nonce,
            }
            data_string = json.dumps(vote_data, sort_keys=True)

            # Verify signature
            signature_bytes = b64decode(self.signature)
            public_key.verify(
                signature_bytes,
                data_string.encode("utf-8"),
                padding.PSS(
                    mgf=padding.MGF1(hashes.SHA256()),
                    salt_length=padding.PSS.MAX_LENGTH,
                ),
                hashes.SHA256(),
            )
            return True
        except Exception:
            return False

    def decrypt_vote_data(self, decryption_key: bytes) -> Dict[str, Any]:
        """
        Decrypt vote data using AES-256-GCM.

        Args:
            decryption_key: 32-byte AES-256 key

        Returns:
            Dict[str, Any]: Decrypted vote data

        Raises:
            ValueError: If decryption fails
        """
        try:
            aesgcm = AESGCM(decryption_key)
            nonce = b64decode(self.encryption_nonce)
            encrypted_data = b64decode(self.encrypted_data)

            # Decrypt data
            decrypted_bytes = aesgcm.decrypt(nonce, encrypted_data, None)

            # Parse JSON
            return json.loads(decrypted_bytes.decode("utf-8"))
        except Exception as e:
            raise ValueError(f"Failed to decrypt vote data: {str(e)}")


class VoteToken(models.Model):
    """
    Vote token model for tracking anonymous vote submissions.

    This model maintains the link between ballot tokens and votes while
    preserving anonymity by storing only hashed references.
    """

    # Primary key as UUID
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text="Unique identifier for the vote token",
    )

    # Anonymous vote token (matches Vote.vote_token)
    vote_token = models.UUIDField(unique=True, help_text="Anonymous vote token")

    # Hash of ballot token (for audit without exposing voter)
    ballot_token_hash = models.CharField(
        max_length=64, help_text="SHA-256 hash of original ballot token UUID"
    )

    # Election reference
    election = models.ForeignKey(
        Election,
        on_delete=models.CASCADE,
        related_name="vote_tokens",
        help_text="Election this vote token belongs to",
    )

    # Status tracking
    is_used = models.BooleanField(
        default=False, help_text="Whether this vote token has been used to cast a vote"
    )

    # Creation timestamp
    created_at = models.DateTimeField(
        auto_now_add=True, help_text="When the vote token was created"
    )

    # Usage timestamp
    used_at = models.DateTimeField(
        null=True, blank=True, help_text="When the vote token was used to cast a vote"
    )

    class Meta:
        """Meta options for VoteToken model."""

        db_table = "votes_vote_token"
        verbose_name = "Vote Token"
        verbose_name_plural = "Vote Tokens"
        ordering = ["-created_at"]

        # Constraints
        constraints = [
            models.UniqueConstraint(
                fields=["ballot_token_hash", "election"],
                name="unique_vote_token_per_ballot_election",
            ),
        ]

        # Indexes
        indexes = [
            models.Index(fields=["vote_token"]),
            models.Index(fields=["ballot_token_hash"]),
            models.Index(fields=["election"]),
            models.Index(fields=["is_used"]),
            models.Index(fields=["created_at"]),
        ]

    def __str__(self) -> str:
        """Return string representation of the vote token."""
        status = "Used" if self.is_used else "Available"
        return f"VoteToken({self.vote_token}) - {self.election.title} - {status}"

    def mark_as_used(self) -> None:
        """Mark the vote token as used."""
        self.is_used = True
        self.used_at = timezone.now()
        self.save(update_fields=["is_used", "used_at"])


class OfflineVoteQueue(models.Model):
    """
    Offline vote queue model for handling offline vote submissions.

    This model queues encrypted votes for later synchronization when
    connectivity is restored, supporting offline voting scenarios.
    """

    # Primary key as UUID
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text="Unique identifier for the offline vote queue entry",
    )

    # Ballot token reference (for authentication when syncing)
    ballot_token = models.ForeignKey(
        BallotToken,
        on_delete=models.CASCADE,
        related_name="offline_votes",
        help_text="Ballot token used for this offline vote",
    )

    # Encrypted vote data (same format as Vote model)
    encrypted_vote_data = models.JSONField(
        help_text="Complete encrypted vote data for offline submission"
    )

    # Client-side timestamp of vote casting
    client_timestamp = models.DateTimeField(
        help_text="When the vote was cast on the client side"
    )

    # Queue entry timestamp
    queued_at = models.DateTimeField(
        auto_now_add=True, help_text="When the vote was queued for offline processing"
    )

    # Sync status
    is_synced = models.BooleanField(
        default=False,
        help_text="Whether this offline vote has been synced to the server",
    )

    # Sync timestamp
    synced_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When the offline vote was synced to the server",
    )

    # Sync result
    sync_result = models.TextField(
        blank=True, help_text="Result/error message from sync attempt"
    )

    # Network info when queued
    client_ip = models.GenericIPAddressField(
        null=True, blank=True, help_text="Client IP when queued (if available)"
    )

    class Meta:
        """Meta options for OfflineVoteQueue model."""

        db_table = "votes_offline_queue"
        verbose_name = "Offline Vote Queue Entry"
        verbose_name_plural = "Offline Vote Queue"
        ordering = ["-queued_at"]

        # Constraints
        constraints = [
            models.UniqueConstraint(
                fields=["ballot_token"],
                condition=models.Q(is_synced=False),
                name="unique_pending_offline_vote_per_token",
            ),
        ]

        # Indexes
        indexes = [
            models.Index(fields=["ballot_token"]),
            models.Index(fields=["is_synced"]),
            models.Index(fields=["queued_at"]),
            models.Index(fields=["synced_at"]),
            models.Index(fields=["client_timestamp"]),
        ]

    def __str__(self) -> str:
        """Return string representation of the offline vote queue entry."""
        status = "Synced" if self.is_synced else "Pending"
        return f"OfflineVote({self.ballot_token.token_uuid}) - {status}"

    def mark_as_synced(self, result: str = "Success") -> None:
        """
        Mark the offline vote as synced.

        Args:
            result: Sync result message
        """
        self.is_synced = True
        self.synced_at = timezone.now()
        self.sync_result = result
        self.save(update_fields=["is_synced", "synced_at", "sync_result"])


class VoteAuditLog(models.Model):
    """
    Vote audit log model for tracking vote-related operations.

    This model maintains an audit trail of all vote operations while
    preserving anonymity by not directly linking to voter identities.
    """

    # Primary key as UUID
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text="Unique identifier for the audit log entry",
    )

    # Vote reference (optional, for specific vote operations)
    vote = models.ForeignKey(
        Vote,
        on_delete=models.CASCADE,
        related_name="audit_logs",
        null=True,
        blank=True,
        help_text="Vote associated with this audit log entry",
    )

    # Action performed
    action = models.CharField(
        max_length=50, help_text="Action performed (cast_vote, verify_vote, etc.)"
    )

    # Election context
    election = models.ForeignKey(
        Election,
        on_delete=models.CASCADE,
        related_name="vote_audit_logs",
        help_text="Election context for this audit entry",
    )

    # Anonymous vote token (for linking without exposing voter)
    vote_token = models.UUIDField(
        null=True, blank=True, help_text="Anonymous vote token for audit trail"
    )

    # Ballot token hash (for audit without exposing voter identity)
    ballot_token_hash = models.CharField(
        max_length=64,
        null=True,
        blank=True,
        help_text="SHA-256 hash of ballot token UUID",
    )

    # Network and context information
    ip_address = models.GenericIPAddressField(
        help_text="IP address where action was performed"
    )

    user_agent = models.TextField(
        blank=True, help_text="User agent when action was performed"
    )

    # Additional metadata
    metadata = models.JSONField(
        default=dict, blank=True, help_text="Additional metadata about the action"
    )

    # Timestamp
    timestamp = models.DateTimeField(
        auto_now_add=True, help_text="When the action was performed"
    )

    # Result/status
    result = models.CharField(
        max_length=20,
        choices=[
            ("success", "Success"),
            ("failure", "Failure"),
            ("error", "Error"),
        ],
        help_text="Result of the action",
    )

    # Error details (if any)
    error_details = models.TextField(
        blank=True, help_text="Error details if result was failure/error"
    )

    class Meta:
        """Meta options for VoteAuditLog model."""

        db_table = "votes_audit_log"
        verbose_name = "Vote Audit Log"
        verbose_name_plural = "Vote Audit Logs"
        ordering = ["-timestamp"]

        # Indexes
        indexes = [
            models.Index(fields=["vote"]),
            models.Index(fields=["action"]),
            models.Index(fields=["election"]),
            models.Index(fields=["vote_token"]),
            models.Index(fields=["ballot_token_hash"]),
            models.Index(fields=["timestamp"]),
            models.Index(fields=["result"]),
            models.Index(fields=["ip_address"]),
        ]

    def __str__(self) -> str:
        """Return string representation of the audit log entry."""
        return f"VoteAuditLog({self.action}) - {self.election.title} - {self.result}"
