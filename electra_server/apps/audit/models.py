"""
Audit logging models for electra_server.

This module contains models for comprehensive audit logging with tamper-proof
blockchain-style hash chaining and RSA digital signatures for the electra
voting system.
"""
import hashlib
import json
import uuid
from datetime import datetime
from typing import Dict, Any, Optional

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.db import models, transaction
from django.utils import timezone
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding

from electra_server.apps.elections.models import Election

User = get_user_model()


class AuditActionType(models.TextChoices):
    """Audit action type choices for comprehensive logging."""
    
    # User authentication actions
    USER_LOGIN = 'user_login', 'User Login'
    USER_LOGOUT = 'user_logout', 'User Logout'
    USER_LOGIN_FAILED = 'user_login_failed', 'User Login Failed'
    USER_PASSWORD_RESET = 'user_password_reset', 'User Password Reset'
    
    # Election management actions
    ELECTION_CREATED = 'election_created', 'Election Created'
    ELECTION_UPDATED = 'election_updated', 'Election Updated'
    ELECTION_ACTIVATED = 'election_activated', 'Election Activated'
    ELECTION_COMPLETED = 'election_completed', 'Election Completed'
    ELECTION_CANCELLED = 'election_cancelled', 'Election Cancelled'
    
    # Ballot token actions
    TOKEN_ISSUED = 'token_issued', 'Ballot Token Issued'
    TOKEN_VALIDATED = 'token_validated', 'Ballot Token Validated'
    TOKEN_INVALIDATED = 'token_invalidated', 'Ballot Token Invalidated'
    
    # Vote casting actions
    VOTE_CAST = 'vote_cast', 'Vote Cast'
    VOTE_VERIFIED = 'vote_verified', 'Vote Verified'
    VOTE_FAILED = 'vote_failed', 'Vote Failed'
    
    # System actions
    ADMIN_ACTION = 'admin_action', 'Administrative Action'
    SYSTEM_ERROR = 'system_error', 'System Error'


class AuditLog(models.Model):
    """
    Comprehensive audit log model with tamper-proof blockchain-style chaining.
    
    This model maintains an immutable audit trail of all critical system actions
    with cryptographic integrity verification through hash chaining and RSA 
    digital signatures.
    """
    
    # Primary key as UUID
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text='Unique identifier for the audit log entry'
    )
    
    # Action and context
    action_type = models.CharField(
        max_length=50,
        choices=AuditActionType.choices,
        help_text='Type of action being audited'
    )
    
    action_description = models.TextField(
        help_text='Detailed description of the action performed'
    )
    
    # User and session context
    user = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='audit_logs',
        help_text='User who performed the action (null for system actions)'
    )
    
    user_identifier = models.CharField(
        max_length=255,
        blank=True,
        help_text='User identifier at time of action (for audit trail consistency)'
    )
    
    session_key = models.CharField(
        max_length=40,
        blank=True,
        help_text='Django session key for correlation'
    )
    
    # Request context
    ip_address = models.GenericIPAddressField(
        null=True,
        blank=True,
        help_text='IP address from which action was performed'
    )
    
    user_agent = models.TextField(
        blank=True,
        help_text='User agent string from request'
    )
    
    # Target resource context
    election = models.ForeignKey(
        Election,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='audit_logs',
        help_text='Election context for the action'
    )
    
    target_resource_type = models.CharField(
        max_length=50,
        blank=True,
        help_text='Type of resource being acted upon (User, Election, Token, etc.)'
    )
    
    target_resource_id = models.CharField(
        max_length=255,
        blank=True,
        help_text='ID of the target resource'
    )
    
    # Outcome and metadata
    outcome = models.CharField(
        max_length=20,
        choices=[
            ('success', 'Success'),
            ('failure', 'Failure'),
            ('error', 'Error'),
            ('warning', 'Warning'),
        ],
        help_text='Outcome of the action'
    )
    
    metadata = models.JSONField(
        default=dict,
        blank=True,
        help_text='Additional contextual data for the action'
    )
    
    error_details = models.TextField(
        blank=True,
        help_text='Error details if action failed'
    )
    
    # Timing
    timestamp = models.DateTimeField(
        default=timezone.now,
        help_text='When the action occurred'
    )
    
    # Blockchain-style tamper-proof chaining
    previous_hash = models.CharField(
        max_length=128,
        blank=True,
        help_text='SHA-512 hash of the previous audit log entry'
    )
    
    content_hash = models.CharField(
        max_length=128,
        blank=True,
        help_text='SHA-512 hash of this entry\'s content'
    )
    
    chain_position = models.PositiveIntegerField(
        default=0,
        help_text='Position in the audit chain (auto-incremented)'
    )
    
    # RSA digital signature for authenticity
    signature = models.TextField(
        blank=True,
        help_text='RSA digital signature of the audit entry'
    )
    
    # Immutability enforcement
    is_sealed = models.BooleanField(
        default=False,
        help_text='Whether this entry is sealed and immutable'
    )
    
    class Meta:
        """Meta options for AuditLog model."""
        
        db_table = 'audit_log'
        verbose_name = 'Audit Log Entry'
        verbose_name_plural = 'Audit Log Entries'
        ordering = ['chain_position', 'timestamp']
        
        indexes = [
            models.Index(fields=['action_type', 'timestamp']),
            models.Index(fields=['user', 'timestamp']),
            models.Index(fields=['election', 'timestamp']),
            models.Index(fields=['target_resource_type', 'target_resource_id']),
            models.Index(fields=['outcome', 'timestamp']),
            models.Index(fields=['ip_address', 'timestamp']),
            models.Index(fields=['chain_position']),
            models.Index(fields=['is_sealed']),
        ]
        
        constraints = [
            models.UniqueConstraint(
                fields=['chain_position'],
                name='unique_chain_position'
            )
        ]
    
    def __str__(self) -> str:
        """Return string representation of the audit log entry."""
        user_str = self.user_identifier or 'System'
        return f"#{self.chain_position}: {user_str} - {self.get_action_type_display()} - {self.outcome}"
    
    def clean(self) -> None:
        """Validate the audit log entry."""
        super().clean()
        
        # Validate user identifier consistency
        if self.user and not self.user_identifier:
            self.user_identifier = self.user.email
        
        # Validate target resource consistency
        if self.election:
            if not self.target_resource_type:
                self.target_resource_type = 'Election'
            if not self.target_resource_id:
                self.target_resource_id = str(self.election.id)
    
    def save(self, *args, **kwargs) -> None:
        """Override save to implement blockchain-style chaining and signing."""
        if self.is_sealed:
            raise ValidationError("Cannot modify a sealed audit log entry")
        
        # Ensure validation
        self.full_clean()
        
        # Use transaction to ensure atomicity
        with transaction.atomic():
            # Get the last entry in the chain
            last_entry = AuditLog.objects.select_for_update().order_by('-chain_position').first()
            
            # Set chain position
            self.chain_position = (last_entry.chain_position + 1) if last_entry else 1
            
            # Set previous hash
            self.previous_hash = last_entry.content_hash if last_entry else ''
            
            # Calculate content hash
            self.content_hash = self._calculate_content_hash()
            
            # Generate RSA signature
            self.signature = self._create_signature()
            
            # Save the entry
            super().save(*args, **kwargs)
            
            # Seal the entry after successful save
            self.is_sealed = True
            super().save(update_fields=['is_sealed'])
    
    def _calculate_content_hash(self) -> str:
        """Calculate SHA-512 hash of the audit entry content."""
        content_data = {
            'id': str(self.id),
            'action_type': self.action_type,
            'action_description': self.action_description,
            'user_identifier': self.user_identifier,
            'session_key': self.session_key,
            'ip_address': str(self.ip_address) if self.ip_address else '',
            'user_agent': self.user_agent,
            'target_resource_type': self.target_resource_type,
            'target_resource_id': self.target_resource_id,
            'outcome': self.outcome,
            'metadata': self.metadata,
            'error_details': self.error_details,
            'timestamp': self.timestamp.isoformat() if self.timestamp else '',
            'previous_hash': self.previous_hash,
            'chain_position': self.chain_position,
            'election_id': str(self.election.id) if self.election else '',
        }
        
        # Create deterministic JSON string
        content_json = json.dumps(content_data, sort_keys=True, separators=(',', ':'))
        
        # Generate SHA-512 hash
        return hashlib.sha512(content_json.encode('utf-8')).hexdigest()
    
    def _create_signature(self) -> str:
        """Create RSA signature for the audit entry."""
        try:
            private_key = self._load_private_key()
            
            # Create signature data
            signature_data = {
                'content_hash': self.content_hash,
                'chain_position': self.chain_position,
                'timestamp': self.timestamp.isoformat() if self.timestamp else '',
            }
            
            signature_json = json.dumps(signature_data, sort_keys=True)
            
            # Sign the data
            signature = private_key.sign(
                signature_json.encode('utf-8'),
                padding.PSS(
                    mgf=padding.MGF1(hashes.SHA512()),
                    salt_length=padding.PSS.MAX_LENGTH
                ),
                hashes.SHA512()
            )
            
            return signature.hex()
        except Exception as e:
            # Log the error but don't fail the audit entry creation
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Failed to create audit signature: {e}")
            return ''
    
    def verify_signature(self) -> bool:
        """Verify the RSA signature of the audit entry."""
        if not self.signature:
            return False
        
        try:
            public_key = self._load_public_key()
            
            # Recreate signature data
            signature_data = {
                'content_hash': self.content_hash,
                'chain_position': self.chain_position,
                'timestamp': self.timestamp.isoformat() if self.timestamp else '',
            }
            
            signature_json = json.dumps(signature_data, sort_keys=True)
            signature_bytes = bytes.fromhex(self.signature)
            
            # Verify signature
            public_key.verify(
                signature_bytes,
                signature_json.encode('utf-8'),
                padding.PSS(
                    mgf=padding.MGF1(hashes.SHA512()),
                    salt_length=padding.PSS.MAX_LENGTH
                ),
                hashes.SHA512()
            )
            return True
        except Exception:
            return False
    
    def verify_chain_integrity(self) -> bool:
        """Verify the integrity of this entry in the blockchain chain."""
        # Check content hash
        expected_hash = self._calculate_content_hash()
        if self.content_hash != expected_hash:
            return False
        
        # Check previous hash chain
        if self.chain_position > 1:
            try:
                previous_entry = AuditLog.objects.get(chain_position=self.chain_position - 1)
                if self.previous_hash != previous_entry.content_hash:
                    return False
            except AuditLog.DoesNotExist:
                return False
        elif self.chain_position == 1:
            # First entry should have empty previous hash
            if self.previous_hash != '':
                return False
        
        # Verify RSA signature
        return self.verify_signature()
    
    def _load_private_key(self):
        """Load RSA private key from settings."""
        private_key_path = settings.BASE_DIR / settings.RSA_PRIVATE_KEY_PATH
        with open(private_key_path, 'rb') as key_file:
            private_key = serialization.load_pem_private_key(
                key_file.read(),
                password=None,
            )
        return private_key
    
    def _load_public_key(self):
        """Load RSA public key from settings."""
        public_key_path = settings.BASE_DIR / settings.RSA_PUBLIC_KEY_PATH
        with open(public_key_path, 'rb') as key_file:
            public_key = serialization.load_pem_public_key(key_file.read())
        return public_key
    
    @classmethod
    def create_audit_entry(
        cls,
        action_type: str,
        action_description: str,
        user: Optional[User] = None,
        ip_address: Optional[str] = None,
        user_agent: str = '',
        session_key: str = '',
        election: Optional[Election] = None,
        target_resource_type: str = '',
        target_resource_id: str = '',
        outcome: str = 'success',
        metadata: Optional[Dict[str, Any]] = None,
        error_details: str = '',
    ) -> 'AuditLog':
        """
        Create a new audit log entry with proper validation and chaining.
        
        Args:
            action_type: Type of action being audited
            action_description: Detailed description of the action
            user: User who performed the action
            ip_address: IP address from request (optional)
            user_agent: User agent from request
            session_key: Django session key
            election: Election context
            target_resource_type: Type of target resource
            target_resource_id: ID of target resource
            outcome: Outcome of the action
            metadata: Additional contextual data
            error_details: Error details if action failed
        
        Returns:
            Created AuditLog instance
        """
        entry = cls(
            action_type=action_type,
            action_description=action_description,
            user=user,
            ip_address=ip_address,
            user_agent=user_agent,
            session_key=session_key,
            election=election,
            target_resource_type=target_resource_type,
            target_resource_id=target_resource_id,
            outcome=outcome,
            metadata=metadata or {},
            error_details=error_details,
        )
        entry.save()
        return entry
    
    @classmethod
    def verify_chain_integrity_full(cls) -> Dict[str, Any]:
        """
        Verify the integrity of the entire audit log chain.
        
        Returns:
            Dictionary with verification results
        """
        results = {
            'is_valid': True,
            'total_entries': 0,
            'verified_entries': 0,
            'failed_entries': [],
            'chain_breaks': [],
            'signature_failures': [],
        }
        
        entries = cls.objects.order_by('chain_position')
        results['total_entries'] = entries.count()
        
        for entry in entries:
            if entry.verify_chain_integrity():
                results['verified_entries'] += 1
            else:
                results['is_valid'] = False
                results['failed_entries'].append({
                    'id': str(entry.id),
                    'chain_position': entry.chain_position,
                    'action_type': entry.action_type,
                    'timestamp': entry.timestamp.isoformat(),
                })
                
                # Check specific failure types
                if not entry.verify_signature():
                    results['signature_failures'].append(entry.chain_position)
                
                # Check for chain breaks
                expected_hash = entry._calculate_content_hash()
                if entry.content_hash != expected_hash:
                    results['chain_breaks'].append(entry.chain_position)
        
        return results
