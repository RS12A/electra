"""
Analytics models for electra_server.

This module contains models for caching analytics data and managing
export verification for the electra voting system.
"""
import hashlib
import json
import uuid
from datetime import datetime, timedelta
from typing import Dict, Any, Optional

from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone

from electra_server.apps.elections.models import Election

User = get_user_model()


class AnalyticsCache(models.Model):
    """
    Cache model for storing pre-calculated analytics data.
    
    This model optimizes performance by caching expensive analytics
    calculations and providing version control for data integrity.
    """
    
    # Primary key as UUID
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text='Unique identifier for the analytics cache entry'
    )
    
    # Cache key for identification
    cache_key = models.CharField(
        max_length=255,
        unique=True,
        help_text='Unique cache key identifying the analytics data'
    )
    
    # Election context (optional - for election-specific analytics)
    election = models.ForeignKey(
        Election,
        on_delete=models.CASCADE,
        related_name='analytics_cache',
        null=True,
        blank=True,
        help_text='Election this analytics data relates to (optional)'
    )
    
    # Cached analytics data
    data = models.JSONField(
        help_text='Pre-calculated analytics data in JSON format'
    )
    
    # Data hash for integrity verification
    data_hash = models.CharField(
        max_length=64,
        help_text='SHA-256 hash of the analytics data for integrity verification'
    )
    
    # Cache metadata
    calculation_duration = models.FloatField(
        help_text='Time taken to calculate this data (in seconds)'
    )
    
    # Timestamps
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When this cache entry was created'
    )
    
    expires_at = models.DateTimeField(
        help_text='When this cache entry expires'
    )
    
    last_accessed = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When this cache entry was last accessed'
    )
    
    # Usage tracking
    access_count = models.PositiveIntegerField(
        default=0,
        help_text='Number of times this cache entry has been accessed'
    )
    
    class Meta:
        """Meta options for AnalyticsCache model."""
        
        db_table = 'analytics_cache'
        verbose_name = 'Analytics Cache'
        verbose_name_plural = 'Analytics Cache'
        ordering = ['-created_at']
        
        # Indexes for performance
        indexes = [
            models.Index(fields=['cache_key']),
            models.Index(fields=['election']),
            models.Index(fields=['created_at']),
            models.Index(fields=['expires_at']),
            models.Index(fields=['last_accessed']),
        ]
    
    def __str__(self) -> str:
        """Return string representation of the cache entry."""
        return f"AnalyticsCache({self.cache_key}) - {self.created_at}"
    
    def clean(self) -> None:
        """Validate the cache entry."""
        super().clean()
        
        # Ensure expires_at is in the future
        if self.expires_at and self.expires_at <= timezone.now():
            raise ValidationError({'expires_at': 'Expiration time must be in the future.'})
    
    def save(self, *args, **kwargs) -> None:
        """Override save to generate data hash."""
        # Generate data hash for integrity
        data_string = json.dumps(self.data, sort_keys=True)
        self.data_hash = hashlib.sha256(data_string.encode()).hexdigest()
        
        super().save(*args, **kwargs)
    
    def is_expired(self) -> bool:
        """Check if the cache entry is expired."""
        return timezone.now() > self.expires_at
    
    def mark_accessed(self) -> None:
        """Mark the cache entry as accessed."""
        self.last_accessed = timezone.now()
        self.access_count += 1
        self.save(update_fields=['last_accessed', 'access_count'])
    
    def verify_integrity(self) -> bool:
        """Verify the integrity of the cached data."""
        data_string = json.dumps(self.data, sort_keys=True)
        calculated_hash = hashlib.sha256(data_string.encode()).hexdigest()
        return calculated_hash == self.data_hash


class ExportVerification(models.Model):
    """
    Model for tracking and verifying analytics data exports.
    
    This model provides hash-stamped verification for all exported
    analytics data, ensuring data integrity and non-repudiation.
    """
    
    # Primary key as UUID
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text='Unique identifier for the export verification'
    )
    
    # Export metadata
    export_type = models.CharField(
        max_length=20,
        choices=[
            ('csv', 'CSV'),
            ('xlsx', 'Excel'),
            ('pdf', 'PDF'),
        ],
        help_text='Type of export format'
    )
    
    # Export content identification
    content_hash = models.CharField(
        max_length=64,
        help_text='SHA-256 hash of the exported content'
    )
    
    # Verification stamp
    verification_hash = models.CharField(
        max_length=64,
        unique=True,
        help_text='Unique verification hash for this export'
    )
    
    # Export parameters and metadata
    export_params = models.JSONField(
        default=dict,
        help_text='Parameters used for this export'
    )
    
    # File information
    filename = models.CharField(
        max_length=255,
        help_text='Original filename of the export'
    )
    
    file_size = models.PositiveIntegerField(
        help_text='Size of the exported file in bytes'
    )
    
    # User who requested the export
    requested_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name='export_requests',
        help_text='User who requested this export'
    )
    
    # Timestamps
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When this export was created'
    )
    
    # IP address for audit
    request_ip = models.GenericIPAddressField(
        help_text='IP address from which export was requested'
    )
    
    class Meta:
        """Meta options for ExportVerification model."""
        
        db_table = 'analytics_export_verification'
        verbose_name = 'Export Verification'
        verbose_name_plural = 'Export Verifications'
        ordering = ['-created_at']
        
        # Indexes for performance
        indexes = [
            models.Index(fields=['content_hash']),
            models.Index(fields=['verification_hash']),
            models.Index(fields=['export_type']),
            models.Index(fields=['requested_by']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self) -> str:
        """Return string representation of the export verification."""
        return f"Export({self.export_type}) - {self.filename} - {self.created_at}"
    
    def save(self, *args, **kwargs) -> None:
        """Override save to generate verification hash."""
        if not self.verification_hash:
            # Generate unique verification hash
            verification_data = f"{self.content_hash}:{self.created_at}:{self.requested_by.id}:{self.request_ip}"
            self.verification_hash = hashlib.sha256(verification_data.encode()).hexdigest()
        
        super().save(*args, **kwargs)
    
    @classmethod
    def create_for_export(
        cls,
        export_type: str,
        content: bytes,
        filename: str,
        export_params: Dict[str, Any],
        requested_by: User,
        request_ip: str
    ) -> 'ExportVerification':
        """
        Create a verification record for an export.
        
        Args:
            export_type: Type of export (csv, xlsx, pdf)
            content: Binary content of the export
            filename: Name of the exported file
            export_params: Parameters used for the export
            requested_by: User who requested the export
            request_ip: IP address of the request
            
        Returns:
            ExportVerification: Created verification record
        """
        content_hash = hashlib.sha256(content).hexdigest()
        
        return cls.objects.create(
            export_type=export_type,
            content_hash=content_hash,
            filename=filename,
            file_size=len(content),
            export_params=export_params,
            requested_by=requested_by,
            request_ip=request_ip
        )
    
    def verify_content(self, content: bytes) -> bool:
        """
        Verify that the provided content matches this export.
        
        Args:
            content: Binary content to verify
            
        Returns:
            bool: True if content matches, False otherwise
        """
        content_hash = hashlib.sha256(content).hexdigest()
        return content_hash == self.content_hash