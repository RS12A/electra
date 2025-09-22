"""
Custom managers for authentication models.

This module contains specialized managers for User and related models
that provide additional query methods and business logic.
"""
import random
import string
from datetime import timedelta
from typing import Optional, Dict, Any

from django.contrib.auth.models import BaseUserManager
from django.db import models
from django.utils import timezone


class UserManager(BaseUserManager):
    """
    Custom user manager that handles user creation with role-based validation.
    
    This manager extends BaseUserManager to provide methods for creating
    users with proper validation based on their roles in the electra system.
    """
    
    def create_user(
        self,
        email: str,
        password: str,
        matric_number: Optional[str] = None,
        staff_id: Optional[str] = None,
        full_name: str = '',
        role: str = 'student',
        **extra_fields
    ):
        """
        Create and save a User with the given email and password.
        
        Args:
            email: User's email address
            password: User's password
            matric_number: Student matriculation number
            staff_id: Staff identification number
            full_name: User's full name
            role: User's role in the system
            **extra_fields: Additional fields
            
        Returns:
            User: Created user instance
            
        Raises:
            ValueError: If required fields are missing
        """
        if not email:
            raise ValueError('The Email field must be set')
        
        from .models import UserRole
        
        # Validate role-specific requirements
        if role == UserRole.STUDENT and not matric_number:
            raise ValueError('Students must have a matric_number')
        elif role in [UserRole.STAFF, UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE] and not staff_id:
            raise ValueError('Staff/Admin users must have a staff_id')
        
        email = self.normalize_email(email)
        extra_fields.setdefault('is_active', True)
        
        user = self.model(
            email=email,
            matric_number=matric_number,
            staff_id=staff_id,
            full_name=full_name,
            role=role,
            **extra_fields
        )
        user.set_password(password)
        user.save(using=self._db)
        return user
    
    def create_superuser(
        self,
        email: str,
        password: str,
        staff_id: str,
        full_name: str = 'Super Admin',
        **extra_fields
    ):
        """
        Create and save a SuperUser with the given email and password.
        
        Args:
            email: Admin's email address
            password: Admin's password  
            staff_id: Admin's staff ID
            full_name: Admin's full name
            **extra_fields: Additional fields
            
        Returns:
            User: Created superuser instance
        """
        from .models import UserRole
        
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', UserRole.ADMIN)
        
        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')
        
        return self.create_user(
            email=email,
            password=password,
            staff_id=staff_id,
            full_name=full_name,
            **extra_fields
        )
    
    def get_by_login_credential(self, identifier: str):
        """
        Get user by either email, matric_number, or staff_id.
        
        Args:
            identifier: Email, matric number, or staff ID
            
        Returns:
            User: Found user instance
            
        Raises:
            User.DoesNotExist: If no user found
        """
        from django.db.models import Q
        
        return self.get(
            Q(email=identifier) |
            Q(matric_number=identifier) |
            Q(staff_id=identifier)
        )
    
    def active_users(self):
        """Get queryset of active users only."""
        return self.filter(is_active=True)
    
    def by_role(self, role: str):
        """Get users by specific role."""
        return self.filter(role=role)
    
    def students(self):
        """Get all student users."""
        from .models import UserRole
        return self.by_role(UserRole.STUDENT)
    
    def staff_users(self):
        """Get all staff users."""
        from .models import UserRole
        return self.by_role(UserRole.STAFF)
    
    def admins(self):
        """Get all admin users."""
        from .models import UserRole
        return self.by_role(UserRole.ADMIN)
    
    def electoral_committee(self):
        """Get all electoral committee users."""
        from .models import UserRole
        return self.by_role(UserRole.ELECTORAL_COMMITTEE)
    
    def candidates(self):
        """Get all candidate users."""
        from .models import UserRole
        return self.by_role(UserRole.CANDIDATE)
    
    def election_managers(self):
        """Get users who can manage elections."""
        from .models import UserRole
        return self.filter(
            role__in=[UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]
        )


class PasswordResetOTPManager(models.Manager):
    """
    Custom manager for PasswordResetOTP model.
    
    Provides methods for creating, validating, and managing OTP codes
    for password recovery functionality.
    """
    
    def create_otp(
        self,
        user,
        ip_address: Optional[str] = None,
        expiry_minutes: int = 15
    ):
        """
        Create a new OTP for password reset.
        
        Args:
            user: User requesting password reset
            ip_address: IP address of the request
            expiry_minutes: Minutes until OTP expires (default: 15)
            
        Returns:
            PasswordResetOTP: Created OTP instance
        """
        # Generate 6-digit OTP
        otp_code = ''.join(random.choices(string.digits, k=6))
        
        # Calculate expiry time
        expires_at = timezone.now() + timedelta(minutes=expiry_minutes)
        
        # Invalidate any existing active OTPs for this user
        self.filter(
            user=user,
            is_used=False
        ).update(is_used=True)
        
        # Create new OTP
        otp = self.create(
            user=user,
            otp_code=otp_code,
            expires_at=expires_at,
            ip_address=ip_address
        )
        
        return otp
    
    def validate_otp(self, user, otp_code: str):
        """
        Validate an OTP code for a user.
        
        Args:
            user: User attempting to use OTP
            otp_code: OTP code to validate
            
        Returns:
            PasswordResetOTP: Valid OTP instance
            
        Raises:
            PasswordResetOTP.DoesNotExist: If OTP is invalid
        """
        otp = self.get(
            user=user,
            otp_code=otp_code,
            is_used=False,
            expires_at__gt=timezone.now()
        )
        return otp
    
    def cleanup_expired(self) -> int:
        """
        Clean up expired and used OTPs.
        
        Returns:
            int: Number of OTPs deleted
        """
        expired_otps = self.filter(
            models.Q(expires_at__lt=timezone.now()) |
            models.Q(is_used=True)
        )
        count = expired_otps.count()
        expired_otps.delete()
        return count
    
    def get_active_otp_for_user(self, user):
        """
        Get active (valid and unused) OTP for a user.
        
        Args:
            user: User to get OTP for
            
        Returns:
            PasswordResetOTP or None: Active OTP if exists
        """
        try:
            return self.get(
                user=user,
                is_used=False,
                expires_at__gt=timezone.now()
            )
        except self.model.DoesNotExist:
            return None
    
    def get_recent_attempts(self, user, minutes: int = 60):
        """
        Get recent OTP creation attempts for a user.
        
        Args:
            user: User to check
            minutes: Time window in minutes
            
        Returns:
            QuerySet: Recent OTP attempts
        """
        since = timezone.now() - timedelta(minutes=minutes)
        return self.filter(
            user=user,
            created_at__gte=since
        )


class LoginAttemptManager(models.Manager):
    """
    Custom manager for LoginAttempt model.
    
    Provides methods for tracking and analyzing login attempts
    for security monitoring purposes.
    """
    
    def create_attempt(
        self,
        email: str,
        ip_address: str,
        user_agent: str = '',
        success: bool = False,
        failure_reason: str = '',
        user=None
    ):
        """
        Create a new login attempt record.
        
        Args:
            email: Email used in login attempt
            ip_address: IP address of attempt
            user_agent: User agent string
            success: Whether login was successful
            failure_reason: Reason for failure if applicable
            user: User instance if found
            
        Returns:
            LoginAttempt: Created login attempt instance
        """
        return self.create(
            email=email,
            ip_address=ip_address,
            user_agent=user_agent,
            success=success,
            failure_reason=failure_reason,
            user=user
        )
    
    def successful_attempts(self):
        """Get successful login attempts."""
        return self.filter(success=True)
    
    def failed_attempts(self):
        """Get failed login attempts."""
        return self.filter(success=False)
    
    def recent_attempts(self, hours: int = 24):
        """
        Get recent login attempts within specified hours.
        
        Args:
            hours: Number of hours to look back
            
        Returns:
            QuerySet: Recent login attempts
        """
        since = timezone.now() - timedelta(hours=hours)
        return self.filter(timestamp__gte=since)
    
    def attempts_by_ip(self, ip_address: str, hours: int = 24):
        """
        Get login attempts from specific IP address.
        
        Args:
            ip_address: IP address to filter by
            hours: Number of hours to look back
            
        Returns:
            QuerySet: Login attempts from IP
        """
        since = timezone.now() - timedelta(hours=hours)
        return self.filter(
            ip_address=ip_address,
            timestamp__gte=since
        )
    
    def attempts_by_email(self, email: str, hours: int = 24):
        """
        Get login attempts for specific email.
        
        Args:
            email: Email address to filter by
            hours: Number of hours to look back
            
        Returns:
            QuerySet: Login attempts for email
        """
        since = timezone.now() - timedelta(hours=hours)
        return self.filter(
            email=email,
            timestamp__gte=since
        )
    
    def failed_attempts_count(self, email: str, hours: int = 1) -> int:
        """
        Count failed login attempts for email within time window.
        
        Args:
            email: Email to check
            hours: Time window in hours
            
        Returns:
            int: Number of failed attempts
        """
        return self.attempts_by_email(email, hours).filter(success=False).count()
    
    def is_rate_limited(self, email: str, max_attempts: int = 5, hours: int = 1) -> bool:
        """
        Check if an email is rate limited based on failed attempts.
        
        Args:
            email: Email to check
            max_attempts: Maximum allowed failed attempts
            hours: Time window in hours
            
        Returns:
            bool: Whether the email is rate limited
        """
        return self.failed_attempts_count(email, hours) >= max_attempts
    
    def cleanup_old_attempts(self, days: int = 30) -> int:
        """
        Clean up login attempts older than specified days.
        
        Args:
            days: Number of days to retain
            
        Returns:
            int: Number of attempts deleted
        """
        cutoff = timezone.now() - timedelta(days=days)
        old_attempts = self.filter(timestamp__lt=cutoff)
        count = old_attempts.count()
        old_attempts.delete()
        return count