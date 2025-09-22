"""
Authentication views for Electra Server.
"""

import logging
from django.contrib.auth import login, logout
from django.utils import timezone
from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError, InvalidToken

from .models import User
from .serializers import (
    UserRegistrationSerializer,
    UserLoginSerializer,
    UserSerializer,
    TokenSerializer
)

logger = logging.getLogger(__name__)


class LoginView(TokenObtainPairView):
    """
    User login endpoint with custom response format.
    """
    
    def post(self, request, *args, **kwargs):
        serializer = UserLoginSerializer(
            data=request.data,
            context={'request': request}
        )
        
        if serializer.is_valid():
            user = serializer.validated_data['user']
            
            # Update last login info
            user.last_login = timezone.now()
            user.last_login_ip = self.get_client_ip(request)
            user.save(update_fields=['last_login', 'last_login_ip'])
            
            # Generate tokens
            token_data = TokenSerializer.get_token_for_user(user)
            
            # Log successful login
            logger.info(
                f'User logged in: {user.matric_number}',
                extra={
                    'user_id': str(user.id),
                    'matric_number': user.matric_number,
                    'ip_address': self.get_client_ip(request),
                    'request_id': getattr(request, 'request_id', 'unknown')
                }
            )
            
            return Response({
                'status': 'success',
                'message': 'Login successful',
                'data': token_data
            }, status=status.HTTP_200_OK)
        
        # Log failed login attempt
        logger.warning(
            f'Failed login attempt',
            extra={
                'matric_number': request.data.get('matric_number', 'unknown'),
                'ip_address': self.get_client_ip(request),
                'errors': serializer.errors,
                'request_id': getattr(request, 'request_id', 'unknown')
            }
        )
        
        return Response({
            'status': 'error',
            'message': 'Invalid credentials',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
    
    def get_client_ip(self, request):
        """Get client IP address."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def register_view(request):
    """
    User registration endpoint.
    """
    
    serializer = UserRegistrationSerializer(data=request.data)
    
    if serializer.is_valid():
        user = serializer.save()
        
        # Generate tokens for immediate login
        token_data = TokenSerializer.get_token_for_user(user)
        
        # Log successful registration
        logger.info(
            f'New user registered: {user.matric_number}',
            extra={
                'user_id': str(user.id),
                'matric_number': user.matric_number,
                'email': user.email,
                'ip_address': request.META.get('REMOTE_ADDR', 'unknown'),
                'request_id': getattr(request, 'request_id', 'unknown')
            }
        )
        
        return Response({
            'status': 'success',
            'message': 'Registration successful',
            'data': token_data
        }, status=status.HTTP_201_CREATED)
    
    # Log failed registration
    logger.warning(
        f'Failed registration attempt',
        extra={
            'matric_number': request.data.get('matric_number', 'unknown'),
            'email': request.data.get('email', 'unknown'),
            'errors': serializer.errors,
            'request_id': getattr(request, 'request_id', 'unknown')
        }
    )
    
    return Response({
        'status': 'error',
        'message': 'Registration failed',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def logout_view(request):
    """
    User logout endpoint.
    Blacklists the refresh token.
    """
    
    try:
        refresh_token = request.data.get('refresh')
        if refresh_token:
            token = RefreshToken(refresh_token)
            token.blacklist()
        
        # Log logout
        logger.info(
            f'User logged out: {request.user.matric_number}',
            extra={
                'user_id': str(request.user.id),
                'matric_number': request.user.matric_number,
                'request_id': getattr(request, 'request_id', 'unknown')
            }
        )
        
        return Response({
            'status': 'success',
            'message': 'Logout successful'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(
            f'Logout error: {str(e)}',
            extra={
                'user_id': str(request.user.id) if request.user.is_authenticated else 'anonymous',
                'error': str(e),
                'request_id': getattr(request, 'request_id', 'unknown')
            }
        )
        
        return Response({
            'status': 'error',
            'message': 'Logout failed'
        }, status=status.HTTP_400_BAD_REQUEST)


class CustomTokenRefreshView(TokenRefreshView):
    """
    Custom token refresh endpoint with logging.
    """
    
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        
        try:
            serializer.is_valid(raise_exception=True)
        except TokenError as e:
            logger.warning(
                f'Token refresh failed: {str(e)}',
                extra={
                    'ip_address': request.META.get('REMOTE_ADDR', 'unknown'),
                    'request_id': getattr(request, 'request_id', 'unknown')
                }
            )
            raise InvalidToken(e)
        
        return Response(serializer.validated_data, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def profile_view(request):
    """
    Get current user profile.
    """
    
    serializer = UserSerializer(request.user)
    
    return Response({
        'status': 'success',
        'data': serializer.data
    }, status=status.HTTP_200_OK)


@api_view(['PUT', 'PATCH'])
@permission_classes([permissions.IsAuthenticated])
def update_profile_view(request):
    """
    Update current user profile.
    """
    
    serializer = UserSerializer(
        request.user,
        data=request.data,
        partial=request.method == 'PATCH'
    )
    
    if serializer.is_valid():
        serializer.save()
        
        logger.info(
            f'User profile updated: {request.user.matric_number}',
            extra={
                'user_id': str(request.user.id),
                'matric_number': request.user.matric_number,
                'request_id': getattr(request, 'request_id', 'unknown')
            }
        )
        
        return Response({
            'status': 'success',
            'message': 'Profile updated successfully',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    
    return Response({
        'status': 'error',
        'message': 'Profile update failed',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)