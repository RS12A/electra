"""
Authentication views for the electra voting system.

This module contains all the views for user registration, authentication,
password recovery, and profile management with proper JWT integration.
"""
import logging
from typing import Dict, Any, Optional

from django.contrib.auth import login, logout
from django.utils import timezone
from rest_framework import status, permissions, generics
from rest_framework.decorators import api_view, permission_classes
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from .models import User, LoginAttempt, PasswordResetOTP, UserRole
from .serializers import (
    UserRegistrationSerializer,
    UserLoginSerializer,
    UserProfileSerializer,
    TokenResponseSerializer,
    PasswordResetRequestSerializer,
    PasswordResetConfirmSerializer,
    ChangePasswordSerializer,
    LogoutSerializer,
    UserUpdateSerializer,
    LoginAttemptSerializer
)
from .permissions import IsAuthenticated, IsOwner, IsElectionManager

# Import audit logging utilities
from electra_server.apps.audit.utils import log_authentication_event
from electra_server.apps.audit.models import AuditActionType

logger = logging.getLogger(__name__)


def get_client_ip(request: Request) -> str:
    """
    Get client IP address from request.
    
    Args:
        request: HTTP request
        
    Returns:
        str: Client IP address
    """
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0].strip()
    else:
        ip = request.META.get('REMOTE_ADDR', 'unknown')
    return ip


def get_user_agent(request: Request) -> str:
    """
    Get user agent from request.
    
    Args:
        request: HTTP request
        
    Returns:
        str: User agent string
    """
    return request.META.get('HTTP_USER_AGENT', '')


class UserRegistrationView(APIView):
    """
    Handle user registration.
    
    POST /api/auth/register/
    """
    
    permission_classes = [permissions.AllowAny]
    
    def post(self, request: Request) -> Response:
        """
        Register a new user.
        
        Args:
            request: HTTP request with user data
            
        Returns:
            Response: Registration result with JWT tokens
        """
        serializer = UserRegistrationSerializer(data=request.data)
        
        if serializer.is_valid():
            try:
                user = serializer.save()
                
                # Generate JWT tokens
                refresh = RefreshToken.for_user(user)
                
                # Prepare response data
                response_data = {
                    'message': 'User registered successfully.',
                    'tokens': {
                        'access': str(refresh.access_token),
                        'refresh': str(refresh),
                    },
                    'user': UserProfileSerializer(user).data
                }
                
                # Log successful registration
                logger.info(
                    f"User registered successfully",
                    extra={
                        'user_id': str(user.id),
                        'email': user.email,
                        'role': user.role,
                        'ip_address': get_client_ip(request)
                    }
                )
                
                return Response(response_data, status=status.HTTP_201_CREATED)
                
            except Exception as e:
                logger.error(f"Registration failed: {e}")
                return Response(
                    {
                        'error': 'Registration failed due to internal error.',
                        'details': str(e)
                    },
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        return Response(
            {
                'error': 'Registration failed. Please check your input.',
                'details': serializer.errors
            },
            status=status.HTTP_400_BAD_REQUEST
        )


class UserLoginView(APIView):
    """
    Handle user login.
    
    POST /api/auth/login/
    """
    
    permission_classes = [permissions.AllowAny]
    
    def post(self, request: Request) -> Response:
        """
        Authenticate user and return JWT tokens.
        
        Args:
            request: HTTP request with login credentials
            
        Returns:
            Response: Authentication result with JWT tokens
        """
        serializer = UserLoginSerializer(data=request.data)
        
        # Track login attempt info
        ip_address = get_client_ip(request)
        user_agent = get_user_agent(request)
        identifier = request.data.get('identifier', '')
        
        if serializer.is_valid():
            user = serializer.validated_data['user']
            
            try:
                # Update user login info
                user.last_login = timezone.now()
                user.save(update_fields=['last_login'])
                
                # Generate JWT tokens
                refresh = RefreshToken.for_user(user)
                
                # Create successful login attempt record
                LoginAttempt.objects.create_attempt(
                    email=user.email,
                    ip_address=ip_address,
                    user_agent=user_agent,
                    success=True,
                    user=user
                )
                
                # Prepare response data
                response_data = {
                    'message': 'Login successful.',
                    'tokens': {
                        'access': str(refresh.access_token),
                        'refresh': str(refresh),
                    },
                    'user': UserProfileSerializer(user).data
                }
                
                # Log successful login
                logger.info(
                    f"User login successful",
                    extra={
                        'user_id': str(user.id),
                        'email': user.email,
                        'ip_address': ip_address
                    }
                )
                
                # Add audit log entry for successful login
                log_authentication_event(
                    action_type=AuditActionType.USER_LOGIN,
                    user=user,
                    request=request,
                    outcome='success',
                    metadata={
                        'login_method': 'password',
                        'user_role': user.role,
                        'login_identifier': identifier,
                    }
                )
                
                return Response(response_data, status=status.HTTP_200_OK)
                
            except Exception as e:
                logger.error(f"Login processing failed: {e}")
                
                # Create failed login attempt record
                LoginAttempt.objects.create_attempt(
                    email=identifier,
                    ip_address=ip_address,
                    user_agent=user_agent,
                    success=False,
                    failure_reason='Internal error'
                )
                
                # Add audit log entry for internal error during login
                log_authentication_event(
                    action_type=AuditActionType.SYSTEM_ERROR,
                    user=user,
                    request=request,
                    outcome='error',
                    error_details=str(e),
                    metadata={
                        'error_type': 'login_processing_error',
                        'attempted_identifier': identifier,
                    }
                )
                
                return Response(
                    {
                        'error': 'Login failed due to internal error.',
                        'details': str(e)
                    },
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        # Create failed login attempt record
        LoginAttempt.objects.create_attempt(
            email=identifier,
            ip_address=ip_address,
            user_agent=user_agent,
            success=False,
            failure_reason='Invalid credentials'
        )
        
        # Log failed login attempt
        logger.warning(
            f"Failed login attempt for: {identifier}",
            extra={
                'identifier': identifier,
                'ip_address': ip_address,
                'errors': serializer.errors
            }
        )
        
        # Add audit log entry for failed login
        log_authentication_event(
            action_type=AuditActionType.USER_LOGIN_FAILED,
            user=None,  # No user object for failed login
            request=request,
            outcome='failure',
            error_details='Invalid credentials provided',
            metadata={
                'attempted_identifier': identifier,
                'validation_errors': serializer.errors,
            }
        )
        
        return Response(
            {
                'error': 'Authentication failed.',
                'details': serializer.errors
            },
            status=status.HTTP_401_UNAUTHORIZED
        )


class UserLogoutView(APIView):
    """
    Handle user logout.
    
    POST /api/auth/logout/
    """
    
    permission_classes = [IsAuthenticated]
    
    def post(self, request: Request) -> Response:
        """
        Logout user by blacklisting refresh token.
        
        Args:
            request: HTTP request with refresh token
            
        Returns:
            Response: Logout result
        """
        serializer = LogoutSerializer(data=request.data)
        
        if serializer.is_valid():
            try:
                serializer.save()
                
                # Log successful logout
                logger.info(
                    f"User logout successful",
                    extra={
                        'user_id': str(request.user.id),
                        'email': request.user.email,
                        'ip_address': get_client_ip(request)
                    }
                )
                
                # Add audit log entry for successful logout
                log_authentication_event(
                    action_type=AuditActionType.USER_LOGOUT,
                    user=request.user,
                    request=request,
                    outcome='success',
                    metadata={
                        'logout_method': 'token_blacklist',
                        'user_role': request.user.role,
                    }
                )
                
                return Response(
                    {'message': 'Logout successful.'},
                    status=status.HTTP_200_OK
                )
                
            except Exception as e:
                logger.error(f"Logout failed: {e}")
                return Response(
                    {
                        'error': 'Logout failed.',
                        'details': str(e)
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        return Response(
            {
                'error': 'Invalid logout request.',
                'details': serializer.errors
            },
            status=status.HTTP_400_BAD_REQUEST
        )


class UserProfileView(generics.RetrieveUpdateAPIView):
    """
    Handle user profile retrieval and updates.
    
    GET /api/auth/profile/
    PUT/PATCH /api/auth/profile/
    """
    
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        """Get appropriate serializer based on request method."""
        if self.request.method in ['PUT', 'PATCH']:
            return UserUpdateSerializer
        return UserProfileSerializer
    
    def get_object(self):
        """Get the current user."""
        return self.request.user
    
    def retrieve(self, request: Request, *args, **kwargs) -> Response:
        """
        Retrieve user profile.
        
        Args:
            request: HTTP request
            
        Returns:
            Response: User profile data
        """
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
    
    def update(self, request: Request, *args, **kwargs) -> Response:
        """
        Update user profile.
        
        Args:
            request: HTTP request with updated data
            
        Returns:
            Response: Updated user profile
        """
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        
        if serializer.is_valid():
            try:
                serializer.save()
                
                # Return updated profile
                profile_serializer = UserProfileSerializer(instance)
                
                logger.info(
                    f"User profile updated",
                    extra={
                        'user_id': str(instance.id),
                        'email': instance.email
                    }
                )
                
                return Response(
                    {
                        'message': 'Profile updated successfully.',
                        'user': profile_serializer.data
                    },
                    status=status.HTTP_200_OK
                )
                
            except Exception as e:
                logger.error(f"Profile update failed: {e}")
                return Response(
                    {
                        'error': 'Profile update failed.',
                        'details': str(e)
                    },
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        return Response(
            {
                'error': 'Invalid profile data.',
                'details': serializer.errors
            },
            status=status.HTTP_400_BAD_REQUEST
        )


class PasswordResetRequestView(APIView):
    """
    Handle password reset requests.
    
    POST /api/auth/password-reset/request/
    """
    
    permission_classes = [permissions.AllowAny]
    
    def post(self, request: Request) -> Response:
        """
        Request password reset OTP.
        
        Args:
            request: HTTP request with email
            
        Returns:
            Response: Reset request result
        """
        serializer = PasswordResetRequestSerializer(data=request.data)
        
        if serializer.is_valid():
            try:
                # Create OTP (returns None if email doesn't exist)
                otp = serializer.create_otp(ip_address=get_client_ip(request))
                
                # Always return success to avoid email enumeration
                return Response(
                    {
                        'message': 'If the email exists, a password reset code has been sent.'
                    },
                    status=status.HTTP_200_OK
                )
                
            except Exception as e:
                logger.error(f"Password reset request failed: {e}")
                return Response(
                    {
                        'message': 'If the email exists, a password reset code has been sent.'
                    },
                    status=status.HTTP_200_OK
                )
        
        return Response(
            {
                'error': 'Invalid request.',
                'details': serializer.errors
            },
            status=status.HTTP_400_BAD_REQUEST
        )


class PasswordResetConfirmView(APIView):
    """
    Handle password reset confirmation.
    
    POST /api/auth/password-reset/confirm/
    """
    
    permission_classes = [permissions.AllowAny]
    
    def post(self, request: Request) -> Response:
        """
        Confirm password reset with OTP.
        
        Args:
            request: HTTP request with OTP and new password
            
        Returns:
            Response: Reset confirmation result
        """
        serializer = PasswordResetConfirmSerializer(data=request.data)
        
        if serializer.is_valid():
            try:
                user = serializer.save()
                
                logger.info(
                    f"Password reset completed",
                    extra={
                        'user_id': str(user.id),
                        'email': user.email,
                        'ip_address': get_client_ip(request)
                    }
                )
                
                return Response(
                    {'message': 'Password reset successful.'},
                    status=status.HTTP_200_OK
                )
                
            except Exception as e:
                logger.error(f"Password reset confirmation failed: {e}")
                return Response(
                    {
                        'error': 'Password reset failed.',
                        'details': str(e)
                    },
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        return Response(
            {
                'error': 'Invalid reset data.',
                'details': serializer.errors
            },
            status=status.HTTP_400_BAD_REQUEST
        )


class ChangePasswordView(APIView):
    """
    Handle password changes for authenticated users.
    
    POST /api/auth/change-password/
    """
    
    permission_classes = [IsAuthenticated]
    
    def post(self, request: Request) -> Response:
        """
        Change user password.
        
        Args:
            request: HTTP request with current and new passwords
            
        Returns:
            Response: Password change result
        """
        serializer = ChangePasswordSerializer(
            data=request.data,
            user=request.user
        )
        
        if serializer.is_valid():
            try:
                user = serializer.save()
                
                logger.info(
                    f"Password changed",
                    extra={
                        'user_id': str(user.id),
                        'email': user.email,
                        'ip_address': get_client_ip(request)
                    }
                )
                
                return Response(
                    {'message': 'Password changed successfully.'},
                    status=status.HTTP_200_OK
                )
                
            except Exception as e:
                logger.error(f"Password change failed: {e}")
                return Response(
                    {
                        'error': 'Password change failed.',
                        'details': str(e)
                    },
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        return Response(
            {
                'error': 'Invalid password data.',
                'details': serializer.errors
            },
            status=status.HTTP_400_BAD_REQUEST
        )


class UserListView(generics.ListAPIView):
    """
    List users (for admin/electoral committee).
    
    GET /api/auth/users/
    """
    
    permission_classes = [IsElectionManager]
    serializer_class = UserProfileSerializer
    
    def get_queryset(self):
        """Get filtered user queryset."""
        queryset = User.objects.active_users()
        
        # Filter by role if specified
        role = self.request.query_params.get('role')
        if role and role in [choice[0] for choice in UserRole.choices]:
            queryset = queryset.filter(role=role)
        
        # Search by name or email
        search = self.request.query_params.get('search')
        if search:
            from django.db.models import Q
            queryset = queryset.filter(
                Q(full_name__icontains=search) |
                Q(email__icontains=search) |
                Q(matric_number__icontains=search) |
                Q(staff_id__icontains=search)
            )
        
        return queryset.order_by('-date_joined')


class UserDetailView(generics.RetrieveAPIView):
    """
    Retrieve user details (for admin/electoral committee).
    
    GET /api/auth/users/<user_id>/
    """
    
    permission_classes = [IsElectionManager]
    serializer_class = UserProfileSerializer
    queryset = User.objects.all()
    lookup_field = 'id'


class LoginHistoryView(generics.ListAPIView):
    """
    View login history for current user.
    
    GET /api/auth/login-history/
    """
    
    permission_classes = [IsAuthenticated]
    serializer_class = LoginAttemptSerializer
    
    def get_queryset(self):
        """Get login attempts for current user."""
        return LoginAttempt.objects.filter(
            user=self.request.user
        ).order_by('-timestamp')[:20]  # Last 20 attempts


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def auth_status(request: Request) -> Response:
    """
    Check authentication status.
    
    GET /api/auth/status/
    
    Args:
        request: HTTP request
        
    Returns:
        Response: Authentication status
    """
    if request.user.is_authenticated:
        return Response({
            'authenticated': True,
            'user': UserProfileSerializer(request.user).data
        })
    else:
        return Response({
            'authenticated': False,
            'user': None
        })


@api_view(['GET'])
@permission_classes([IsElectionManager])
def user_stats(request: Request) -> Response:
    """
    Get user statistics (for admin/electoral committee).
    
    GET /api/auth/stats/
    
    Args:
        request: HTTP request
        
    Returns:
        Response: User statistics
    """
    from django.db.models import Count
    
    try:
        stats = {
            'total_users': User.objects.count(),
            'active_users': User.objects.filter(is_active=True).count(),
            'users_by_role': dict(
                User.objects.values('role').annotate(count=Count('role')).values_list('role', 'count')
            ),
            'recent_registrations': User.objects.filter(
                date_joined__gte=timezone.now().date()
            ).count(),
            'recent_logins': LoginAttempt.objects.filter(
                success=True,
                timestamp__gte=timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
            ).count()
        }
        
        return Response(stats)
        
    except Exception as e:
        logger.error(f"User stats retrieval failed: {e}")
        return Response(
            {
                'error': 'Failed to retrieve statistics.',
                'details': str(e)
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )