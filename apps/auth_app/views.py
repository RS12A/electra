"""
Authentication views.
"""
import logging
from django.contrib.auth import login
from django.utils import timezone
from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from .models import User, LoginAttempt
from .serializers import (
    UserRegistrationSerializer,
    UserLoginSerializer,
    UserProfileSerializer,
    TokenResponseSerializer,
    LogoutSerializer
)

logger = logging.getLogger('electra_server')


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def register(request):
    """
    Register a new user.
    """
    serializer = UserRegistrationSerializer(data=request.data)
    
    if serializer.is_valid():
        user = serializer.save()
        
        # Generate tokens
        refresh = RefreshToken.for_user(user)
        
        # Log successful registration
        log_data = {
            'event': 'user_registration',
            'user_id': user.id,
            'email': user.email,
            'matric_staff_id': user.matric_staff_id,
            'ip_address': _get_client_ip(request),
        }
        logger.info('User registered successfully', extra={'log_data': log_data})
        
        response_data = {
            'message': 'User registered successfully. Please check your email for verification.',
            'tokens': {
                'access': str(refresh.access_token),
                'refresh': str(refresh),
            },
            'user': UserProfileSerializer(user).data
        }
        
        return Response(response_data, status=status.HTTP_201_CREATED)
    
    return Response({
        'error': True,
        'message': 'Registration failed. Please check your input.',
        'details': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def login_view(request):
    """
    Authenticate user and return JWT tokens.
    """
    serializer = UserLoginSerializer(data=request.data)
    
    # Track login attempt
    ip_address = _get_client_ip(request)
    user_agent = request.META.get('HTTP_USER_AGENT', '')
    email = request.data.get('email', '')
    
    if serializer.is_valid():
        user = serializer.validated_data['user']
        
        # Update user login info
        user.last_login = timezone.now()
        user.last_login_ip = ip_address
        user.save(update_fields=['last_login', 'last_login_ip'])
        
        # Generate tokens
        refresh = RefreshToken.for_user(user)
        
        # Log successful login
        LoginAttempt.objects.create(
            email=email,
            ip_address=ip_address,
            user_agent=user_agent,
            success=True
        )
        
        log_data = {
            'event': 'user_login_success',
            'user_id': user.id,
            'email': user.email,
            'ip_address': ip_address,
        }
        logger.info('User logged in successfully', extra={'log_data': log_data})
        
        response_data = {
            'message': 'Login successful',
            'tokens': {
                'access': str(refresh.access_token),
                'refresh': str(refresh),
            },
            'user': UserProfileSerializer(user).data
        }
        
        return Response(response_data, status=status.HTTP_200_OK)
    
    # Log failed login attempt
    LoginAttempt.objects.create(
        email=email,
        ip_address=ip_address,
        user_agent=user_agent,
        success=False,
        failure_reason='Invalid credentials'
    )
    
    log_data = {
        'event': 'user_login_failed',
        'email': email,
        'ip_address': ip_address,
        'reason': 'Invalid credentials'
    }
    logger.warning('Login attempt failed', extra={'log_data': log_data})
    
    return Response({
        'error': True,
        'message': 'Invalid email or password.',
        'details': serializer.errors
    }, status=status.HTTP_401_UNAUTHORIZED)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def logout_view(request):
    """
    Logout user by blacklisting refresh token.
    """
    serializer = LogoutSerializer(data=request.data)
    
    if serializer.is_valid():
        try:
            token = serializer.validated_data['token']
            
            # Add the token to blacklist (requires django-rest-framework-simplejwt with blacklist app)
            try:
                from rest_framework_simplejwt.token_blacklist.models import BlacklistedToken, OutstandingToken
                
                # Try to get the outstanding token
                outstanding_token = OutstandingToken.objects.filter(
                    token=token.token
                ).first()
                
                if outstanding_token:
                    # Create blacklisted token entry
                    BlacklistedToken.objects.get_or_create(token=outstanding_token)
                
            except ImportError:
                # If blacklist app is not available, we can't blacklist the token
                # This is acceptable for basic functionality
                pass
            
            # Log successful logout
            log_data = {
                'event': 'user_logout',
                'user_id': request.user.id,
                'email': request.user.email,
                'ip_address': _get_client_ip(request),
            }
            logger.info('User logged out successfully', extra={'log_data': log_data})
            
            return Response({
                'message': 'Logout successful'
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f'Logout error: {str(e)}')
            return Response({
                'error': True,
                'message': 'An error occurred during logout.'
            }, status=status.HTTP_400_BAD_REQUEST)
    
    return Response({
        'error': True,
        'message': 'Invalid refresh token provided.',
        'details': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def profile_view(request):
    """
    Get current user's profile.
    """
    serializer = UserProfileSerializer(request.user)
    return Response({
        'user': serializer.data
    }, status=status.HTTP_200_OK)


@api_view(['PUT', 'PATCH'])
@permission_classes([permissions.IsAuthenticated])
def update_profile_view(request):
    """
    Update current user's profile.
    """
    serializer = UserProfileSerializer(
        request.user, 
        data=request.data, 
        partial=request.method == 'PATCH'
    )
    
    if serializer.is_valid():
        user = serializer.save()
        
        # Log profile update
        log_data = {
            'event': 'user_profile_updated',
            'user_id': user.id,
            'email': user.email,
            'ip_address': _get_client_ip(request),
        }
        logger.info('User profile updated', extra={'log_data': log_data})
        
        return Response({
            'message': 'Profile updated successfully',
            'user': UserProfileSerializer(user).data
        }, status=status.HTTP_200_OK)
    
    return Response({
        'error': True,
        'message': 'Profile update failed. Please check your input.',
        'details': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


def _get_client_ip(request):
    """Get client IP address from request."""
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0]
    else:
        ip = request.META.get('REMOTE_ADDR', 'unknown')
    return ip
