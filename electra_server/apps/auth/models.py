"""
Authentication models for Electra Server.
"""

from django.contrib.auth.models import AbstractUser
from django.db import models
from django.core.validators import RegexValidator
import uuid


class User(AbstractUser):
    """
    Custom user model for Electra voting system.
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # University identification
    matric_number = models.CharField(
        max_length=20,
        unique=True,
        validators=[
            RegexValidator(
                regex=r'^[A-Z]{2,4}\/[A-Z]{3,5}\/\d{3,4}$|^[A-Z]{2,5}\d{3,4}$|^ADMIN\d{3}$|^EC\d{3}$',
                message='Invalid matric/staff ID format. Examples: KWU/SCI/001, ADMIN001, EC001'
            )
        ],
        help_text='Student matric number or staff ID (e.g., KWU/SCI/001, ADMIN001, EC001)'
    )
    
    # Extended profile fields
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=15, blank=True, null=True)
    
    # University structure
    faculty = models.CharField(max_length=100, blank=True, null=True)
    department = models.CharField(max_length=100, blank=True, null=True)
    level = models.CharField(
        max_length=20,
        choices=[
            ('100', '100 Level'),
            ('200', '200 Level'),
            ('300', '300 Level'),
            ('400', '400 Level'),
            ('500', '500 Level'),
            ('postgrad', 'Postgraduate'),
            ('staff', 'Staff'),
            ('admin', 'Admin'),
        ],
        blank=True,
        null=True
    )
    
    # Account status
    is_verified = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    can_vote = models.BooleanField(default=True)
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_login_ip = models.GenericIPAddressField(null=True, blank=True)
    
    # Use matric_number as the unique identifier
    USERNAME_FIELD = 'matric_number'
    REQUIRED_FIELDS = ['email', 'first_name', 'last_name']
    
    class Meta:
        db_table = 'auth_users'
        verbose_name = 'User'
        verbose_name_plural = 'Users'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.matric_number} - {self.get_full_name()}"
    
    def get_full_name(self):
        return f"{self.first_name} {self.last_name}".strip()
    
    def is_student(self):
        return self.level in ['100', '200', '300', '400', '500']
    
    def is_staff_member(self):
        return self.level in ['staff', 'admin']


class Election(models.Model):
    """
    Election model for voting events.
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=200)
    description = models.TextField()
    
    # Election schedule
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    
    # Election settings
    is_active = models.BooleanField(default=False)
    requires_verification = models.BooleanField(default=True)
    allow_multiple_votes = models.BooleanField(default=False)
    
    # Eligibility
    eligible_levels = models.JSONField(
        default=list,
        help_text='List of eligible levels (e.g., ["100", "200", "300"])'
    )
    eligible_faculties = models.JSONField(
        default=list,
        help_text='List of eligible faculties (empty = all faculties)'
    )
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_elections')
    
    class Meta:
        db_table = 'elections'
        verbose_name = 'Election'
        verbose_name_plural = 'Elections'
        ordering = ['-created_at']
    
    def __str__(self):
        return self.title