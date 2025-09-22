"""
Serializers for authentication endpoints.
"""
import uuid
from django.contrib.auth import authenticate
from django.contrib.auth.hashers import make_password
from django.core.mail import send_mail
from django.conf import settings
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User, LoginAttempt


class UserRegistrationSerializer(serializers.ModelSerializer):
    """
    Serializer for user registration.
    """
    password = serializers.CharField(write_only=True, min_length=8)
    password_confirm = serializers.CharField(write_only=True)
    
    class Meta:
        model = User
        fields = [
            'username', 'email', 'password', 'password_confirm',
            'first_name', 'last_name', 'matric_staff_id',
            'phone_number', 'date_of_birth', 'is_staff_member'
        ]
        extra_kwargs = {
            'first_name': {'required': True},
            'last_name': {'required': True},
            'email': {'required': True},
            'matric_staff_id': {'required': True},
        }
    
    def validate(self, attrs):
        """Validate registration data."""
        # Check password confirmation
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({'password_confirm': 'Password confirmation does not match.'})
        
        # Check if email already exists
        if User.objects.filter(email=attrs['email']).exists():
            raise serializers.ValidationError({'email': 'A user with this email already exists.'})
        
        # Check if matric_staff_id already exists
        if User.objects.filter(matric_staff_id=attrs['matric_staff_id'].upper()).exists():
            raise serializers.ValidationError({'matric_staff_id': 'A user with this matric/staff ID already exists.'})
        
        return attrs
    
    def create(self, validated_data):
        """Create new user."""
        # Remove password_confirm from validated_data
        validated_data.pop('password_confirm', None)
        
        # Generate username if not provided
        if not validated_data.get('username'):
            validated_data['username'] = validated_data['email']
        
        # Generate email verification token
        validated_data['email_verification_token'] = str(uuid.uuid4())
        
        # Hash password
        validated_data['password'] = make_password(validated_data['password'])
        
        # Normalize matric_staff_id
        validated_data['matric_staff_id'] = validated_data['matric_staff_id'].upper()
        
        user = User.objects.create(**validated_data)
        
        # Send verification email (in real app, this would be async)
        self._send_verification_email(user)
        
        return user
    
    def _send_verification_email(self, user):
        """Send email verification email."""
        try:
            subject = 'Verify your Electra account'
            message = f"""
            Hello {user.get_full_name()},
            
            Please verify your email address by clicking the link below:
            
            [Verification Link - Token: {user.email_verification_token}]
            
            If you did not create this account, please ignore this email.
            
            Best regards,
            Electra Team
            """
            
            send_mail(
                subject=subject,
                message=message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                fail_silently=True,  # Don't break registration if email fails
            )
        except Exception:
            pass  # Log this in real implementation


class UserLoginSerializer(serializers.Serializer):
    """
    Serializer for user login.
    """
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    
    def validate(self, attrs):
        """Validate login credentials."""
        email = attrs.get('email')
        password = attrs.get('password')
        
        if email and password:
            # Get user by email
            try:
                user = User.objects.get(email=email)
            except User.DoesNotExist:
                user = None
            
            if user:
                # Authenticate user
                user = authenticate(username=user.username, password=password)
            
            if user:
                if not user.is_active:
                    raise serializers.ValidationError('User account is disabled.')
                attrs['user'] = user
            else:
                raise serializers.ValidationError('Invalid email or password.')
        else:
            raise serializers.ValidationError('Must include email and password.')
        
        return attrs


class UserProfileSerializer(serializers.ModelSerializer):
    """
    Serializer for user profile data.
    """
    full_name = serializers.ReadOnlyField(source='get_full_name')
    
    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'full_name', 'matric_staff_id', 'phone_number', 'date_of_birth',
            'is_staff_member', 'email_verified', 'date_joined', 'last_login'
        ]
        read_only_fields = [
            'id', 'username', 'email', 'matric_staff_id', 
            'email_verified', 'date_joined', 'last_login'
        ]


class TokenResponseSerializer(serializers.Serializer):
    """
    Serializer for token response.
    """
    access = serializers.CharField()
    refresh = serializers.CharField()
    user = UserProfileSerializer()


class LogoutSerializer(serializers.Serializer):
    """
    Serializer for logout request.
    """
    refresh = serializers.CharField()
    
    def validate(self, attrs):
        """Validate refresh token."""
        refresh_token = attrs.get('refresh')
        try:
            token = RefreshToken(refresh_token)
            attrs['token'] = token
        except Exception:
            raise serializers.ValidationError('Invalid or expired refresh token.')
        return attrs