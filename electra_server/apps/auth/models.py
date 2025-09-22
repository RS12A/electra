"""
Authentication models for electra_server.

This module contains the custom User model and related authentication models
following the requirements for the electra voting system.
"""
import uuid
from typing import Optional
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.core.exceptions import ValidationError
from django.core.validators import EmailValidator
from django.db import models
from django.utils import timezone

from .managers import UserManager, PasswordResetOTPManager, LoginAttemptManager


class UserRole(models.TextChoices):
    """User role choices for the electra system."""
    
    STUDENT = 'student', 'Student'
    STAFF = 'staff', 'Staff'
    CANDIDATE = 'candidate', 'Candidate'
    ADMIN = 'admin', 'Administrator'
    ELECTORAL_COMMITTEE = 'electoral_committee', 'Electoral Committee'





class User(AbstractBaseUser, PermissionsMixin):
    """
    Custom User model extending AbstractBaseUser with electra-specific fields.
    
    This model represents users in the electra voting system with different roles
    and authentication methods based on whether they are students or staff.
    """
    
    # Primary key as UUID
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text='Unique identifier for the user'
    )
    
    # Authentication fields
    email = models.EmailField(
        unique=True,
        validators=[EmailValidator()],
        help_text='User email address - used for authentication'
    )
    
    matric_number = models.CharField(
        max_length=20,
        unique=True,
        null=True,
        blank=True,
        help_text='Student matriculation number (required for students)'
    )
    
    staff_id = models.CharField(
        max_length=20,
        unique=True,
        null=True,
        blank=True,
        help_text='Staff identification number (required for staff/admin)'
    )
    
    # User information
    full_name = models.CharField(
        max_length=255,
        help_text='User full name'
    )
    
    # Role-based access
    role = models.CharField(
        max_length=20,
        choices=UserRole.choices,
        default=UserRole.STUDENT,
        help_text='User role in the system'
    )
    
    # Django auth fields
    is_active = models.BooleanField(
        default=True,
        help_text='Designates whether this user should be treated as active'
    )
    
    is_staff = models.BooleanField(
        default=False,
        help_text='Designates whether the user can log into this admin site'
    )
    
    is_superuser = models.BooleanField(
        default=False,
        help_text='Designates that this user has all permissions without explicitly assigning them'
    )
    
    # Timestamps
    date_joined = models.DateTimeField(
        default=timezone.now,
        help_text='Date when the user joined'
    )
    
    last_login = models.DateTimeField(
        blank=True,
        null=True,
        help_text='Last login timestamp'
    )
    
    # Additional tracking
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Manager
    objects = UserManager()
    
    # Authentication settings
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['full_name']
    
    class Meta:
        db_table = 'auth_user'
        verbose_name = 'User'
        verbose_name_plural = 'Users'
        indexes = [
            models.Index(fields=['email']),
            models.Index(fields=['matric_number']),
            models.Index(fields=['staff_id']),
            models.Index(fields=['role']),
        ]
        constraints = [
            models.CheckConstraint(
                check=models.Q(
                    models.Q(role='student', matric_number__isnull=False) |
                    models.Q(role__in=['staff', 'admin', 'electoral_committee'], staff_id__isnull=False) |
                    models.Q(role='candidate')  # Candidates can have either
                ),
                name='user_identification_constraint'
            )
        ]
    
    def __str__(self) -> str:
        """Return string representation of the user."""
        identifier = self.matric_number or self.staff_id or 'No ID'
        return f"{self.full_name} ({identifier}) - {self.get_role_display()}"
    
    def clean(self) -> None:
        """Validate the model instance."""
        super().clean()
        
        # Email validation
        if not self.email:
            raise ValidationError({'email': 'Email is required.'})
        
        # Role-based validation
        if self.role == UserRole.STUDENT:
            if not self.matric_number:
                raise ValidationError({
                    'matric_number': 'Students must have a matriculation number.'
                })
            if self.staff_id:
                raise ValidationError({
                    'staff_id': 'Students should not have a staff ID.'
                })
        elif self.role in [UserRole.STAFF, UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]:
            if not self.staff_id:
                raise ValidationError({
                    'staff_id': f'{self.get_role_display()} must have a staff ID.'
                })
            if self.matric_number:
                raise ValidationError({
                    'matric_number': f'{self.get_role_display()} should not have a matriculation number.'
                })
        # Candidates can have either matric_number or staff_id
        
        # Normalize identifiers
        if self.matric_number:
            self.matric_number = self.matric_number.upper().strip()
        if self.staff_id:
            self.staff_id = self.staff_id.upper().strip()
    
    def get_login_identifier(self) -> str:
        """Get the appropriate login identifier based on user role."""
        if self.role == UserRole.STUDENT:
            return self.matric_number or ''
        else:
            return self.staff_id or ''
    
    def can_manage_elections(self) -> bool:
        """Check if user can manage elections."""
        return self.role in [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]
    
    def save(self, *args, **kwargs) -> None:
        """Override save to ensure proper validation.""" 
        # Skip validation during factory creation to allow post_generation to work
        if not kwargs.pop('skip_validation', False):
            self.full_clean()
        super().save(*args, **kwargs)


class PasswordResetOTP(models.Model):
    """
    Model for storing OTP codes for password recovery.
    
    This model handles time-limited 6-digit OTP codes sent via email
    for secure password recovery.
    """
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='password_reset_otps',
        help_text='User requesting password reset'
    )
    
    otp_code = models.CharField(
        max_length=6,
        help_text='6-digit OTP code'
    )
    
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text='When the OTP was created'
    )
    
    expires_at = models.DateTimeField(
        help_text='When the OTP expires'
    )
    
    is_used = models.BooleanField(
        default=False,
        help_text='Whether the OTP has been used'
    )
    
    ip_address = models.GenericIPAddressField(
        null=True,
        blank=True,
        help_text='IP address that requested the OTP'
    )
    
    # Manager
    objects = PasswordResetOTPManager()
    
    class Meta:
        db_table = 'auth_password_reset_otp'
        verbose_name = 'Password Reset OTP'
        verbose_name_plural = 'Password Reset OTPs'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'created_at']),
            models.Index(fields=['otp_code']),
            models.Index(fields=['expires_at']),
        ]
    
    def __str__(self) -> str:
        """Return string representation."""
        status = "Used" if self.is_used else "Active" if not self.is_expired() else "Expired"
        return f"OTP for {self.user.email} - {status}"
    
    def is_expired(self) -> bool:
        """Check if the OTP has expired."""
        return timezone.now() > self.expires_at
    
    def is_valid(self) -> bool:
        """Check if the OTP is valid (not used and not expired)."""
        return not self.is_used and not self.is_expired()
    
    def mark_as_used(self) -> None:
        """Mark the OTP as used."""
        self.is_used = True
        self.save(update_fields=['is_used'])


class LoginAttempt(models.Model):
    """
    Model for tracking login attempts for security monitoring.
    """
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    
    email = models.EmailField(
        help_text='Email used in login attempt'
    )
    
    ip_address = models.GenericIPAddressField(
        help_text='IP address of login attempt'
    )
    
    user_agent = models.TextField(
        blank=True,
        help_text='User agent string'
    )
    
    success = models.BooleanField(
        default=False,
        help_text='Whether the login was successful'
    )
    
    failure_reason = models.CharField(
        max_length=100,
        blank=True,
        help_text='Reason for login failure'
    )
    
    timestamp = models.DateTimeField(
        auto_now_add=True,
        help_text='When the login attempt occurred'
    )
    
    user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='login_attempts',
        help_text='User who attempted login (if found)'
    )
    
    # Manager
    objects = LoginAttemptManager()
    
    class Meta:
        db_table = 'auth_login_attempt'
        verbose_name = 'Login Attempt'
        verbose_name_plural = 'Login Attempts'
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['email', 'timestamp']),
            models.Index(fields=['ip_address', 'timestamp']),
            models.Index(fields=['success', 'timestamp']),
        ]
    
    def __str__(self) -> str:
        """Return string representation."""
        status = "Success" if self.success else f"Failed ({self.failure_reason})"
        return f"{self.email} - {status} at {self.timestamp}"