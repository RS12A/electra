"""
Serializers for the authentication app.
"""

import re
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User


class UserRegistrationSerializer(serializers.ModelSerializer):
    """
    Serializer for user registration.
    """
    
    password = serializers.CharField(
        write_only=True,
        min_length=8,
        validators=[validate_password]
    )
    password_confirm = serializers.CharField(write_only=True)
    
    class Meta:
        model = User
        fields = [
            'matric_number', 'email', 'first_name', 'last_name',
            'phone_number', 'faculty', 'department', 'level',
            'password', 'password_confirm'
        ]
        extra_kwargs = {
            'email': {'required': True},
            'first_name': {'required': True},
            'last_name': {'required': True},
        }
    
    def validate_matric_number(self, value):
        """
        Validate matric number format.
        """
        # Pattern for student matric numbers (e.g., KWU/SCI/001)
        student_pattern = r'^[A-Z]{2,4}\/[A-Z]{3,5}\/\d{3,4}$'
        # Pattern for simple student IDs (e.g., KWU2021001)
        simple_pattern = r'^[A-Z]{2,5}\d{3,4}$'
        # Pattern for admin users (e.g., ADMIN001)
        admin_pattern = r'^ADMIN\d{3}$'
        # Pattern for electoral committee (e.g., EC001)
        ec_pattern = r'^EC\d{3}$'
        
        if not (re.match(student_pattern, value) or 
                re.match(simple_pattern, value) or
                re.match(admin_pattern, value) or
                re.match(ec_pattern, value)):
            raise serializers.ValidationError(
                "Invalid matric/staff ID format. Examples: KWU/SCI/001, ADMIN001, EC001"
            )
        
        # Check if matric number already exists
        if User.objects.filter(matric_number=value).exists():
            raise serializers.ValidationError("This matric/staff ID is already registered.")
        
        return value
    
    def validate_email(self, value):
        """
        Validate email uniqueness.
        """
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("This email address is already registered.")
        return value
    
    def validate(self, attrs):
        """
        Validate password confirmation.
        """
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({
                'password_confirm': 'Passwords do not match.'
            })
        return attrs
    
    def create(self, validated_data):
        """
        Create new user with hashed password.
        """
        validated_data.pop('password_confirm')
        password = validated_data.pop('password')
        
        user = User.objects.create_user(
            username=validated_data['matric_number'],
            password=password,
            **validated_data
        )
        
        return user


class UserLoginSerializer(serializers.Serializer):
    """
    Serializer for user login.
    """
    
    matric_number = serializers.CharField()
    password = serializers.CharField(write_only=True)
    
    def validate(self, attrs):
        """
        Validate login credentials.
        """
        matric_number = attrs.get('matric_number')
        password = attrs.get('password')
        
        if matric_number and password:
            # Try to authenticate with matric_number as username
            user = authenticate(
                request=self.context.get('request'),
                username=matric_number,
                password=password
            )
            
            if not user:
                # Try to find user by matric_number and authenticate
                try:
                    user_obj = User.objects.get(matric_number=matric_number)
                    user = authenticate(
                        request=self.context.get('request'),
                        username=user_obj.username,
                        password=password
                    )
                except User.DoesNotExist:
                    pass
            
            if not user:
                raise serializers.ValidationError('Invalid matric number or password.')
            
            if not user.is_active:
                raise serializers.ValidationError('Account is disabled.')
            
            attrs['user'] = user
            return attrs
        
        raise serializers.ValidationError('Must include matric number and password.')


class UserSerializer(serializers.ModelSerializer):
    """
    Serializer for user profile data.
    """
    
    class Meta:
        model = User
        fields = [
            'id', 'matric_number', 'email', 'first_name', 'last_name',
            'phone_number', 'faculty', 'department', 'level',
            'is_verified', 'is_active', 'can_vote', 'created_at', 'last_login'
        ]
        read_only_fields = [
            'id', 'matric_number', 'is_verified', 'is_active', 'can_vote',
            'created_at', 'last_login'
        ]


class TokenSerializer(serializers.Serializer):
    """
    Serializer for JWT token response.
    """
    
    access = serializers.CharField()
    refresh = serializers.CharField()
    user = UserSerializer()
    
    @classmethod
    def get_token_for_user(cls, user):
        """
        Generate JWT tokens for user.
        """
        refresh = RefreshToken.for_user(user)
        return {
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': UserSerializer(user).data
        }