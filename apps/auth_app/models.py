"""
Authentication models for electra_server.
"""
import re
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.core.exceptions import ValidationError


def validate_matric_staff_id(value):
    """
    Validate matric/staff ID format.
    Flexible format - can be alphanumeric with specific patterns.
    """
    # Allow common formats: numeric, alphanumeric with prefixes, etc.
    patterns = [
        r'^[A-Z]{1,3}\d{6,10}$',  # e.g., U1234567, ST123456789
        r'^\d{8,12}$',            # e.g., 123456789
        r'^[A-Z]\d{7,10}$',       # e.g., A1234567
    ]
    
    if not any(re.match(pattern, value.upper()) for pattern in patterns):
        raise ValidationError(
            'Invalid matric/staff ID format. Must be alphanumeric (e.g., U1234567, 123456789, A1234567)'
        )


class User(AbstractUser):
    """
    Custom user model extending Django's AbstractUser.
    """
    email = models.EmailField(unique=True, help_text='Required. Must be a valid email address.')
    matric_staff_id = models.CharField(
        max_length=20,
        unique=True,
        validators=[validate_matric_staff_id],
        help_text='Matric or Staff ID (e.g., U1234567, 123456789)'
    )
    first_name = models.CharField(max_length=150, help_text='Required.')
    last_name = models.CharField(max_length=150, help_text='Required.')
    is_staff_member = models.BooleanField(
        default=False,
        help_text='Designates whether this user is a staff member (not Django admin staff)'
    )
    phone_number = models.CharField(
        max_length=20,
        blank=True,
        help_text='Optional phone number'
    )
    date_of_birth = models.DateField(
        null=True,
        blank=True,
        help_text='Optional date of birth'
    )
    
    # Email verification
    email_verified = models.BooleanField(
        default=False,
        help_text='Designates whether this user has verified their email'
    )
    email_verification_token = models.CharField(
        max_length=100,
        blank=True,
        help_text='Token for email verification'
    )
    
    # Account status
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_login_ip = models.GenericIPAddressField(null=True, blank=True)
    
    # Override username requirement - use email as the primary identifier
    REQUIRED_FIELDS = ['email', 'first_name', 'last_name', 'matric_staff_id']
    
    class Meta:
        db_table = 'auth_user'
        verbose_name = 'User'
        verbose_name_plural = 'Users'
    
    def __str__(self):
        return f"{self.email} ({self.matric_staff_id})"
    
    def get_full_name(self):
        """Return the user's full name."""
        return f"{self.first_name} {self.last_name}".strip()
    
    def get_short_name(self):
        """Return the user's first name."""
        return self.first_name
    
    def clean(self):
        """Validate the model."""
        super().clean()
        
        # Ensure email and matric_staff_id are not empty
        if not self.email:
            raise ValidationError({'email': 'Email is required.'})
        if not self.matric_staff_id:
            raise ValidationError({'matric_staff_id': 'Matric/Staff ID is required.'})
        
        # Normalize matric_staff_id to uppercase
        if self.matric_staff_id:
            self.matric_staff_id = self.matric_staff_id.upper()


class LoginAttempt(models.Model):
    """
    Track login attempts for security monitoring.
    """
    email = models.EmailField()
    ip_address = models.GenericIPAddressField()
    user_agent = models.TextField(blank=True)
    success = models.BooleanField(default=False)
    timestamp = models.DateTimeField(auto_now_add=True)
    failure_reason = models.CharField(max_length=100, blank=True)
    
    class Meta:
        db_table = 'auth_login_attempt'
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['email', 'timestamp']),
            models.Index(fields=['ip_address', 'timestamp']),
        ]
    
    def __str__(self):
        status = "Success" if self.success else "Failed"
        return f"{self.email} - {status} at {self.timestamp}"
