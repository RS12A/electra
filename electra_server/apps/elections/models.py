"""
Elections models for electra_server.

This module contains the Election model and related models for managing
elections in the electra voting system.
"""
import uuid
from typing import Optional
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone

User = get_user_model()


class ElectionStatus(models.TextChoices):
    """Election status choices."""
    
    DRAFT = 'draft', 'Draft'
    ACTIVE = 'active', 'Active'
    COMPLETED = 'completed', 'Completed'
    CANCELLED = 'cancelled', 'Cancelled'


class Election(models.Model):
    """
    Election model for managing elections in the electra voting system.
    
    This model represents an election with all necessary fields for lifecycle
    management, security, and audit trail.
    """
    
    # Primary key as UUID
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text='Unique identifier for the election'
    )
    
    # Basic election information
    title = models.CharField(
        max_length=255,
        help_text='Election title'
    )
    
    description = models.TextField(
        help_text='Detailed description of the election'
    )
    
    # Time management
    start_time = models.DateTimeField(
        help_text='When the election begins and voting is allowed'
    )
    
    end_time = models.DateTimeField(
        help_text='When the election ends and voting stops'
    )
    
    # Status management
    status = models.CharField(
        max_length=20,
        choices=ElectionStatus.choices,
        default=ElectionStatus.DRAFT,
        help_text='Current status of the election'
    )
    
    # Election creator (foreign key to User)
    created_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name='created_elections',
        help_text='User who created this election'
    )
    
    # Results management
    delayed_reveal = models.BooleanField(
        default=False,
        help_text='Whether election results should be revealed after completion'
    )
    
    # Audit trail
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When the election was created'
    )
    
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text='When the election was last updated'
    )
    
    class Meta:
        """Meta options for Election model."""
        
        db_table = 'elections_election'
        verbose_name = 'Election'
        verbose_name_plural = 'Elections'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['start_time']),
            models.Index(fields=['end_time']),
            models.Index(fields=['created_by']),
            models.Index(fields=['-created_at']),
        ]
    
    def __str__(self) -> str:
        """Return string representation of the election."""
        return f"{self.title} ({self.get_status_display()})"
    
    def clean(self) -> None:
        """Validate the election instance."""
        super().clean()
        
        if self.start_time and self.end_time:
            if self.start_time >= self.end_time:
                raise ValidationError({
                    'end_time': 'End time must be after start time.'
                })
            
            # Don't allow past start times for new elections
            if self.pk is None and self.start_time <= timezone.now():
                raise ValidationError({
                    'start_time': 'Start time must be in the future for new elections.'
                })
    
    def save(self, *args, **kwargs) -> None:
        """Override save to ensure proper validation."""
        self.full_clean()
        super().save(*args, **kwargs)
    
    @property
    def is_active(self) -> bool:
        """Check if the election is currently active for voting."""
        if self.status != ElectionStatus.ACTIVE:
            return False
        
        now = timezone.now()
        return self.start_time <= now <= self.end_time
    
    @property
    def is_voting_period(self) -> bool:
        """Check if we're currently in the voting period."""
        now = timezone.now()
        return self.start_time <= now <= self.end_time
    
    @property
    def can_vote(self) -> bool:
        """Check if voting is allowed for this election."""
        return self.status == ElectionStatus.ACTIVE and self.is_voting_period
    
    @property
    def has_started(self) -> bool:
        """Check if the election has started."""
        return timezone.now() >= self.start_time
    
    @property
    def has_ended(self) -> bool:
        """Check if the election has ended."""
        return timezone.now() > self.end_time
    
    def can_be_activated(self) -> bool:
        """Check if the election can be activated."""
        return (
            self.status == ElectionStatus.DRAFT and
            self.start_time > timezone.now()
        )
    
    def can_be_cancelled(self) -> bool:
        """Check if the election can be cancelled."""
        return self.status in [ElectionStatus.DRAFT, ElectionStatus.ACTIVE]
    
    def activate(self) -> None:
        """Activate the election."""
        if not self.can_be_activated():
            raise ValidationError("Election cannot be activated in its current state.")
        
        self.status = ElectionStatus.ACTIVE
        self.save(update_fields=['status', 'updated_at'])
    
    def cancel(self) -> None:
        """Cancel the election."""
        if not self.can_be_cancelled():
            raise ValidationError("Election cannot be cancelled in its current state.")
        
        self.status = ElectionStatus.CANCELLED
        self.save(update_fields=['status', 'updated_at'])
    
    def complete(self) -> None:
        """Mark the election as completed."""
        if self.status != ElectionStatus.ACTIVE:
            raise ValidationError("Only active elections can be marked as completed.")
        
        self.status = ElectionStatus.COMPLETED
        self.save(update_fields=['status', 'updated_at'])