"""
Ballot models for electra_server.

This module contains models for managing ballot tokens, including issuance,
validation, and offline queue support for the electra voting system.
"""
import json
import uuid
from datetime import datetime, timedelta
from typing import Dict, Any, Optional

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, padding

from electra_server.apps.elections.models import Election

User = get_user_model()


class BallotTokenStatus(models.TextChoices):
    """Ballot token status choices."""
    ISSUED = 'issued', 'Issued'
    USED = 'used', 'Used' 
    EXPIRED = 'expired', 'Expired'
    INVALIDATED = 'invalidated', 'Invalidated'


class BallotToken(models.Model):
    """
    Ballot token model for managing secure voting tokens.
    
    Each token represents a single-use, cryptographically signed authorization
    to cast a ballot in a specific election. Tokens include RSA signatures
    for security and offline validation capabilities.
    """
    
    # Primary key as UUID
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text='Unique identifier for the ballot token'
    )
    
    # Token content - cryptographically signed UUID
    token_uuid = models.UUIDField(
        default=uuid.uuid4,
        unique=True,
        help_text='Unique token UUID for the ballot'
    )
    
    # RSA signature of the token (hex encoded)
    signature = models.TextField(
        help_text='RSA signature of the token for verification'
    )
    
    # Foreign key relationships
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='ballot_tokens',
        help_text='User who owns this ballot token'
    )
    
    election = models.ForeignKey(
        Election,
        on_delete=models.CASCADE,
        related_name='ballot_tokens',
        help_text='Election this token is valid for'
    )
    
    # Token status and lifecycle
    status = models.CharField(
        max_length=20,
        choices=BallotTokenStatus.choices,
        default=BallotTokenStatus.ISSUED,
        help_text='Current status of the ballot token'
    )
    
    # Timestamps
    issued_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When the token was issued'
    )
    
    expires_at = models.DateTimeField(
        help_text='When the token expires'
    )
    
    used_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the token was used to cast a vote'
    )
    
    invalidated_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the token was invalidated'
    )
    
    # Metadata for offline support
    offline_data = models.JSONField(
        default=dict,
        blank=True,
        help_text='Encrypted data for offline voting support'
    )
    
    # IP address and user agent for security logging
    issued_ip = models.GenericIPAddressField(
        help_text='IP address where token was issued'
    )
    
    issued_user_agent = models.TextField(
        blank=True,
        help_text='User agent when token was issued'
    )
    
    class Meta:
        """Meta options for BallotToken model."""
        
        db_table = 'ballots_ballot_token'
        verbose_name = 'Ballot Token'
        verbose_name_plural = 'Ballot Tokens'
        ordering = ['-issued_at']
        
        # Constraints
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'election'],
                name='unique_ballot_token_per_user_election'
            ),
            models.CheckConstraint(
                check=models.Q(expires_at__gt=models.F('issued_at')),
                name='ballot_token_expiry_after_issue'
            )
        ]
        
        # Indexes for performance
        indexes = [
            models.Index(fields=['user', 'election']),
            models.Index(fields=['status']),
            models.Index(fields=['issued_at']),
            models.Index(fields=['expires_at']),
            models.Index(fields=['token_uuid']),
        ]
    
    def __str__(self) -> str:
        """Return string representation of the ballot token."""
        return f"BallotToken({self.token_uuid}) - {self.user.email} - {self.election.title}"
    
    def clean(self) -> None:
        """Validate the ballot token instance."""
        super().clean()
        
        # Validate expiry time
        if self.expires_at and self.issued_at:
            if self.expires_at <= self.issued_at:
                raise ValidationError({
                    'expires_at': 'Expiry time must be after issue time.'
                })
        
        # Validate election voting period alignment
        if self.election and self.expires_at:
            if self.expires_at > self.election.end_time:
                raise ValidationError({
                    'expires_at': 'Token cannot expire after election ends.'
                })
    
    def save(self, *args, **kwargs) -> None:
        """Override save to ensure proper validation and defaults."""
        if not self.expires_at:
            # Default expiry: 24 hours or election end time, whichever is sooner
            default_expiry = timezone.now() + timedelta(hours=24)
            self.expires_at = min(default_expiry, self.election.end_time)
        
        self.full_clean()
        super().save(*args, **kwargs)
    
    @property
    def is_valid(self) -> bool:
        """Check if the token is valid for use."""
        now = timezone.now()
        return (
            self.status == BallotTokenStatus.ISSUED and
            self.expires_at > now and
            self.election.can_vote
        )
    
    @property
    def is_expired(self) -> bool:
        """Check if the token has expired."""
        return timezone.now() > self.expires_at
    
    def mark_as_used(self) -> None:
        """Mark the token as used."""
        self.status = BallotTokenStatus.USED
        self.used_at = timezone.now()
        self.save(update_fields=['status', 'used_at'])
    
    def invalidate(self, reason: str = '') -> None:
        """Invalidate the token."""
        self.status = BallotTokenStatus.INVALIDATED
        self.invalidated_at = timezone.now()
        if reason:
            self.offline_data['invalidation_reason'] = reason
        self.save(update_fields=['status', 'invalidated_at', 'offline_data'])
    
    def get_token_data(self) -> Dict[str, Any]:
        """Get token data for signing/verification."""
        return {
            'token_uuid': str(self.token_uuid),
            'user_id': str(self.user.id),
            'election_id': str(self.election.id),
            'issued_at': self.issued_at.isoformat() if self.issued_at else timezone.now().isoformat(),
            'expires_at': self.expires_at.isoformat() if self.expires_at else '',
        }
    
    def create_signature(self) -> str:
        """Create RSA signature for the token."""
        private_key = self._load_private_key()
        token_data = json.dumps(self.get_token_data(), sort_keys=True)
        
        signature = private_key.sign(
            token_data.encode('utf-8'),
            padding.PSS(
                mgf=padding.MGF1(hashes.SHA256()),
                salt_length=padding.PSS.MAX_LENGTH
            ),
            hashes.SHA256()
        )
        
        return signature.hex()
    
    def verify_signature(self, signature_hex: str) -> bool:
        """Verify RSA signature of the token."""
        try:
            public_key = self._load_public_key()
            signature = bytes.fromhex(signature_hex)
            token_data = json.dumps(self.get_token_data(), sort_keys=True)
            
            public_key.verify(
                signature,
                token_data.encode('utf-8'),
                padding.PSS(
                    mgf=padding.MGF1(hashes.SHA256()),
                    salt_length=padding.PSS.MAX_LENGTH
                ),
                hashes.SHA256()
            )
            return True
        except Exception:
            return False
    
    def _load_private_key(self):
        """Load RSA private key from file."""
        private_key_path = settings.BASE_DIR / settings.RSA_PRIVATE_KEY_PATH
        with open(private_key_path, 'rb') as key_file:
            private_key = serialization.load_pem_private_key(
                key_file.read(),
                password=None,
            )
        return private_key
    
    def _load_public_key(self):
        """Load RSA public key from file."""
        public_key_path = settings.BASE_DIR / settings.RSA_PUBLIC_KEY_PATH
        with open(public_key_path, 'rb') as key_file:
            public_key = serialization.load_pem_public_key(key_file.read())
        return public_key


class OfflineBallotQueue(models.Model):
    """
    Queue for offline ballot tokens and votes.
    
    This model stores ballot tokens and associated data for offline voting
    scenarios where users need to vote without internet connectivity.
    """
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text='Unique identifier for the offline queue entry'
    )
    
    # Associated ballot token
    ballot_token = models.ForeignKey(
        BallotToken,
        on_delete=models.CASCADE,
        related_name='offline_queue_entries',
        help_text='Associated ballot token'
    )
    
    # Encrypted offline voting data
    encrypted_data = models.TextField(
        help_text='Encrypted ballot and voting data for offline use'
    )
    
    # Status tracking
    is_synced = models.BooleanField(
        default=False,
        help_text='Whether this entry has been synced back online'
    )
    
    # Timestamps
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When the offline entry was created'
    )
    
    synced_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the entry was synced back online'
    )
    
    # Sync metadata
    sync_attempts = models.PositiveIntegerField(
        default=0,
        help_text='Number of sync attempts made'
    )
    
    last_sync_error = models.TextField(
        blank=True,
        help_text='Last sync error message if any'
    )
    
    class Meta:
        """Meta options for OfflineBallotQueue model."""
        
        db_table = 'ballots_offline_queue'
        verbose_name = 'Offline Ballot Queue Entry'
        verbose_name_plural = 'Offline Ballot Queue Entries'
        ordering = ['-created_at']
        
        indexes = [
            models.Index(fields=['ballot_token']),
            models.Index(fields=['is_synced']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self) -> str:
        """Return string representation of the offline queue entry."""
        status = "Synced" if self.is_synced else "Pending"
        return f"OfflineQueue({self.ballot_token.token_uuid}) - {status}"
    
    def mark_as_synced(self) -> None:
        """Mark the queue entry as successfully synced."""
        self.is_synced = True
        self.synced_at = timezone.now()
        self.save(update_fields=['is_synced', 'synced_at'])
    
    def record_sync_error(self, error_message: str) -> None:
        """Record a sync error."""
        self.sync_attempts += 1
        self.last_sync_error = error_message
        self.save(update_fields=['sync_attempts', 'last_sync_error'])


class BallotTokenUsageLog(models.Model):
    """
    Audit log for ballot token usage.
    
    This model maintains a comprehensive audit trail of all ballot token
    operations for security and compliance purposes.
    """
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text='Unique identifier for the log entry'
    )
    
    # Associated ballot token
    ballot_token = models.ForeignKey(
        BallotToken,
        on_delete=models.CASCADE,
        related_name='usage_logs',
        help_text='Associated ballot token'
    )
    
    # Action performed
    action = models.CharField(
        max_length=50,
        help_text='Action performed on the token'
    )
    
    # Context and metadata
    ip_address = models.GenericIPAddressField(
        help_text='IP address where action was performed'
    )
    
    user_agent = models.TextField(
        blank=True,
        help_text='User agent when action was performed'
    )
    
    # Additional metadata
    metadata = models.JSONField(
        default=dict,
        blank=True,
        help_text='Additional metadata about the action'
    )
    
    # Timestamp
    timestamp = models.DateTimeField(
        auto_now_add=True,
        help_text='When the action was performed'
    )
    
    class Meta:
        """Meta options for BallotTokenUsageLog model."""
        
        db_table = 'ballots_usage_log'
        verbose_name = 'Ballot Token Usage Log'
        verbose_name_plural = 'Ballot Token Usage Logs'
        ordering = ['-timestamp']
        
        indexes = [
            models.Index(fields=['ballot_token']),
            models.Index(fields=['action']),
            models.Index(fields=['timestamp']),
            models.Index(fields=['ip_address']),
        ]
    
    def __str__(self) -> str:
        """Return string representation of the usage log entry."""
        return f"UsageLog({self.ballot_token.token_uuid}) - {self.action} - {self.timestamp}"