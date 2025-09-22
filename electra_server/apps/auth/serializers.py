"""
Serializers for authentication endpoints.

This module contains all DRF serializers used for user registration,
authentication, password recovery, and user profile management.
"""
import logging
from typing import Dict, Any, Optional

from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.core.mail import send_mail
from django.conf import settings
from django.template.loader import render_to_string
from django.utils import timezone
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User, UserRole, PasswordResetOTP, LoginAttempt

logger = logging.getLogger(__name__)


class UserRegistrationSerializer(serializers.ModelSerializer):
    """
    Serializer for user registration.
    
    Handles validation and creation of new users with role-based
    field requirements and password confirmation.
    """
    
    password = serializers.CharField(
        write_only=True,
        min_length=8,
        validators=[validate_password],
        help_text='Password must be at least 8 characters'
    )
    password_confirm = serializers.CharField(
        write_only=True,
        help_text='Must match the password field'
    )
    
    class Meta:
        model = User
        fields = [
            'email', 'password', 'password_confirm', 'full_name',
            'matric_number', 'staff_id', 'role'
        ]
        extra_kwargs = {
            'email': {'required': True},
            'full_name': {'required': True},
            'role': {'required': False, 'default': UserRole.STUDENT},
        }
    
    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate the registration data.
        
        Args:
            attrs: Serializer data
            
        Returns:
            Dict: Validated data
            
        Raises:
            serializers.ValidationError: If validation fails
        """
        # Password confirmation
        if attrs.get('password') != attrs.get('password_confirm'):
            raise serializers.ValidationError({
                'password_confirm': 'Password confirmation does not match.'
            })
        
        role = attrs.get('role', UserRole.STUDENT)
        matric_number = attrs.get('matric_number')
        staff_id = attrs.get('staff_id')
        
        # Role-based field validation
        if role == UserRole.STUDENT:
            if not matric_number:
                raise serializers.ValidationError({
                    'matric_number': 'Students must provide a matriculation number.'
                })
            if staff_id:
                raise serializers.ValidationError({
                    'staff_id': 'Students should not have a staff ID.'
                })
        elif role in [UserRole.STAFF, UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]:
            if not staff_id:
                raise serializers.ValidationError({
                    'staff_id': f'{role.title()} must provide a staff ID.'
                })
            if matric_number:
                raise serializers.ValidationError({
                    'matric_number': f'{role.title()} should not have a matriculation number.'
                })
        # Candidates can have either
        
        return attrs
    
    def create(self, validated_data: Dict[str, Any]) -> User:
        """
        Create a new user instance.
        
        Args:
            validated_data: Validated serializer data
            
        Returns:
            User: Created user instance
        """
        # Remove password_confirm
        validated_data.pop('password_confirm', None)
        
        # Extract password
        password = validated_data.pop('password')
        
        # Create user
        user = User.objects.create_user(
            password=password,
            **validated_data
        )
        
        logger.info(f"New user registered: {user.email} ({user.role})")
        return user


class UserLoginSerializer(serializers.Serializer):
    """
    Serializer for user login.
    
    Handles authentication using email/matric_number/staff_id and password.
    """
    
    identifier = serializers.CharField(
        help_text='Email, matriculation number, or staff ID'
    )
    password = serializers.CharField(
        write_only=True,
        help_text='User password'
    )
    
    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate login credentials.
        
        Args:
            attrs: Serializer data
            
        Returns:
            Dict: Validated data with user instance
            
        Raises:
            serializers.ValidationError: If authentication fails
        """
        identifier = attrs.get('identifier')
        password = attrs.get('password')
        
        if not identifier or not password:
            raise serializers.ValidationError(
                'Both identifier and password are required.'
            )
        
        # Try to find user by identifier
        try:
            user = User.objects.get_by_login_credential(identifier)
        except User.DoesNotExist:
            raise serializers.ValidationError(
                'Invalid credentials provided.'
            )
        
        # Check if user is active
        if not user.is_active:
            raise serializers.ValidationError(
                'User account is disabled.'
            )
        
        # Authenticate with email (USERNAME_FIELD)
        authenticated_user = authenticate(
            username=user.email,
            password=password
        )
        
        if not authenticated_user:
            raise serializers.ValidationError(
                'Invalid credentials provided.'
            )
        
        attrs['user'] = authenticated_user
        return attrs


class UserProfileSerializer(serializers.ModelSerializer):
    """
    Serializer for user profile data.
    
    Used for displaying user information in responses.
    """
    
    login_identifier = serializers.CharField(
        source='get_login_identifier',
        read_only=True,
        help_text='Login identifier based on role'
    )
    can_manage_elections = serializers.BooleanField(
        read_only=True,
        help_text='Whether user can manage elections'
    )
    
    class Meta:
        model = User
        fields = [
            'id', 'email', 'full_name', 'matric_number', 'staff_id',
            'role', 'login_identifier', 'can_manage_elections',
            'is_active', 'date_joined', 'last_login'
        ]
        read_only_fields = [
            'id', 'email', 'matric_number', 'staff_id', 'role',
            'date_joined', 'last_login'
        ]


class TokenResponseSerializer(serializers.Serializer):
    """
    Serializer for JWT token response.
    """
    
    access = serializers.CharField(
        help_text='JWT access token'
    )
    refresh = serializers.CharField(
        help_text='JWT refresh token'
    )
    user = UserProfileSerializer(
        help_text='User profile data'
    )


class PasswordResetRequestSerializer(serializers.Serializer):
    """
    Serializer for password reset request.
    
    Handles OTP generation and email sending for password recovery.
    """
    
    email = serializers.EmailField(
        help_text='Email address for password reset'
    )
    
    def validate_email(self, value: str) -> str:
        """
        Validate that the email exists.
        
        Args:
            value: Email address
            
        Returns:
            str: Validated email
            
        Raises:
            serializers.ValidationError: If email not found
        """
        try:
            self.user = User.objects.get(email=value, is_active=True)
        except User.DoesNotExist:
            # Don't reveal if email exists for security
            pass
        return value
    
    def create_otp(self, ip_address: Optional[str] = None) -> Optional[PasswordResetOTP]:
        """
        Create OTP for password reset.
        
        Args:
            ip_address: IP address of request
            
        Returns:
            PasswordResetOTP or None: Created OTP if user exists
        """
        if not hasattr(self, 'user'):
            return None
        
        # Create OTP
        otp = PasswordResetOTP.objects.create_otp(
            user=self.user,
            ip_address=ip_address
        )
        
        # Send email
        self._send_reset_email(otp)
        
        logger.info(f"Password reset OTP created for {self.user.email}")
        return otp
    
    def _send_reset_email(self, otp: PasswordResetOTP) -> None:
        """
        Send password reset email with OTP.
        
        Args:
            otp: OTP instance to send
        """
        try:
            subject = 'Electra Password Reset'
            message = f"""
Hello {otp.user.full_name},

You requested a password reset for your Electra account. 
Use the following OTP code to reset your password:

{otp.otp_code}

This code will expire in 15 minutes.

If you did not request this reset, please ignore this email.

Best regards,
Electra Team
"""
            
            send_mail(
                subject=subject,
                message=message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[otp.user.email],
                fail_silently=False,
            )
            
        except Exception as e:
            logger.error(f"Failed to send password reset email: {e}")
            # Don't raise exception to avoid revealing email existence


class PasswordResetConfirmSerializer(serializers.Serializer):
    """
    Serializer for password reset confirmation.
    
    Handles OTP validation and password reset completion.
    """
    
    email = serializers.EmailField(
        help_text='Email address'
    )
    otp_code = serializers.CharField(
        max_length=6,
        min_length=6,
        help_text='6-digit OTP code'
    )
    new_password = serializers.CharField(
        write_only=True,
        min_length=8,
        validators=[validate_password],
        help_text='New password'
    )
    new_password_confirm = serializers.CharField(
        write_only=True,
        help_text='Confirm new password'
    )
    
    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate password reset data.
        
        Args:
            attrs: Serializer data
            
        Returns:
            Dict: Validated data
            
        Raises:
            serializers.ValidationError: If validation fails
        """
        email = attrs.get('email')
        otp_code = attrs.get('otp_code')
        new_password = attrs.get('new_password')
        new_password_confirm = attrs.get('new_password_confirm')
        
        # Password confirmation
        if new_password != new_password_confirm:
            raise serializers.ValidationError({
                'new_password_confirm': 'Password confirmation does not match.'
            })
        
        # Find user
        try:
            user = User.objects.get(email=email, is_active=True)
        except User.DoesNotExist:
            raise serializers.ValidationError('Invalid reset request.')
        
        # Validate OTP
        try:
            otp = PasswordResetOTP.objects.validate_otp(user, otp_code)
            attrs['otp'] = otp
            attrs['user'] = user
        except PasswordResetOTP.DoesNotExist:
            raise serializers.ValidationError({
                'otp_code': 'Invalid or expired OTP code.'
            })
        
        return attrs
    
    def save(self) -> User:
        """
        Reset the user's password.
        
        Returns:
            User: User with updated password
        """
        user = self.validated_data['user']
        otp = self.validated_data['otp']
        new_password = self.validated_data['new_password']
        
        # Update password
        user.set_password(new_password)
        user.save(update_fields=['password', 'updated_at'])
        
        # Mark OTP as used
        otp.mark_as_used()
        
        logger.info(f"Password reset completed for {user.email}")
        return user


class ChangePasswordSerializer(serializers.Serializer):
    """
    Serializer for changing password when authenticated.
    """
    
    current_password = serializers.CharField(
        write_only=True,
        help_text='Current password'
    )
    new_password = serializers.CharField(
        write_only=True,
        min_length=8,
        validators=[validate_password],
        help_text='New password'
    )
    new_password_confirm = serializers.CharField(
        write_only=True,
        help_text='Confirm new password'
    )
    
    def __init__(self, *args, **kwargs):
        self.user = kwargs.pop('user', None)
        super().__init__(*args, **kwargs)
    
    def validate_current_password(self, value: str) -> str:
        """
        Validate current password.
        
        Args:
            value: Current password
            
        Returns:
            str: Validated password
            
        Raises:
            serializers.ValidationError: If current password is wrong
        """
        if not self.user.check_password(value):
            raise serializers.ValidationError('Current password is incorrect.')
        return value
    
    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate password change data.
        
        Args:
            attrs: Serializer data
            
        Returns:
            Dict: Validated data
            
        Raises:
            serializers.ValidationError: If validation fails
        """
        new_password = attrs.get('new_password')
        new_password_confirm = attrs.get('new_password_confirm')
        
        if new_password != new_password_confirm:
            raise serializers.ValidationError({
                'new_password_confirm': 'Password confirmation does not match.'
            })
        
        return attrs
    
    def save(self) -> User:
        """
        Change the user's password.
        
        Returns:
            User: User with updated password
        """
        new_password = self.validated_data['new_password']
        
        self.user.set_password(new_password)
        self.user.save(update_fields=['password', 'updated_at'])
        
        logger.info(f"Password changed for {self.user.email}")
        return self.user


class LogoutSerializer(serializers.Serializer):
    """
    Serializer for logout request.
    
    Handles refresh token blacklisting.
    """
    
    refresh = serializers.CharField(
        help_text='Refresh token to blacklist'
    )
    
    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate refresh token.
        
        Args:
            attrs: Serializer data
            
        Returns:
            Dict: Validated data
            
        Raises:
            serializers.ValidationError: If token is invalid
        """
        try:
            refresh_token = RefreshToken(attrs['refresh'])
            attrs['refresh_token'] = refresh_token
        except Exception:
            raise serializers.ValidationError({
                'refresh': 'Invalid refresh token.'
            })
        
        return attrs
    
    def save(self) -> None:
        """Blacklist the refresh token."""
        refresh_token = self.validated_data['refresh_token']
        refresh_token.blacklist()


class LoginAttemptSerializer(serializers.ModelSerializer):
    """
    Serializer for login attempt records.
    
    Used for displaying login history and security monitoring.
    """
    
    class Meta:
        model = LoginAttempt
        fields = [
            'id', 'email', 'ip_address', 'user_agent', 'success',
            'failure_reason', 'timestamp', 'user'
        ]
        read_only_fields = ['id', 'timestamp']


class UserUpdateSerializer(serializers.ModelSerializer):
    """
    Serializer for updating user profile information.
    
    Allows users to update their profile data except for
    authentication-critical fields.
    """
    
    class Meta:
        model = User
        fields = ['full_name']
        
    def update(self, instance: User, validated_data: Dict[str, Any]) -> User:
        """
        Update user profile.
        
        Args:
            instance: User instance to update
            validated_data: Validated data
            
        Returns:
            User: Updated user instance
        """
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        
        instance.save(update_fields=list(validated_data.keys()) + ['updated_at'])
        return instance