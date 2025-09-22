"""
Analytics permissions for the electra voting system.

This module contains permission classes that enforce admin-only access
to analytics endpoints, ensuring proper role-based access control.
"""
import logging
from typing import Any
from rest_framework import permissions
from rest_framework.request import Request
from rest_framework.views import View

from electra_server.apps.auth.models import UserRole
from electra_server.apps.audit.utils import log_user_action
from electra_server.apps.audit.models import AuditActionType

logger = logging.getLogger('electra_server.analytics')


class AnalyticsPermission(permissions.BasePermission):
    """
    Permission class for analytics API access.
    
    Only allows users with admin or electoral_committee roles to access
    analytics endpoints. Includes comprehensive security checks and logging.
    """
    
    # Roles allowed to access analytics
    ALLOWED_ROLES = [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if the user has permission to access analytics.
        
        Args:
            request: The incoming request
            view: The view being accessed
            
        Returns:
            bool: True if user has permission, False otherwise
        """
        # Check if user is authenticated
        if not request.user or not request.user.is_authenticated:
            self._log_access_denied(request, 'user_not_authenticated')
            return False
        
        # Check if user is active
        if not request.user.is_active:
            self._log_access_denied(request, 'user_not_active')
            return False
        
        # Check if user has required role
        if request.user.role not in self.ALLOWED_ROLES:
            self._log_access_denied(request, f'insufficient_role:{request.user.role}')
            return False
        
        # Log successful access
        self._log_access_granted(request)
        
        return True
    
    def has_object_permission(self, request: Request, view: View, obj: Any) -> bool:
        """
        Check object-level permissions for analytics data.
        
        Args:
            request: The incoming request
            view: The view being accessed
            obj: The object being accessed
            
        Returns:
            bool: True if user has permission, False otherwise
        """
        # First check general permission
        if not self.has_permission(request, view):
            return False
        
        # Additional object-level checks can be added here
        # For now, general analytics permission is sufficient
        
        return True
    
    def _log_access_denied(self, request: Request, reason: str) -> None:
        """
        Log access denial for security monitoring.
        
        Args:
            request: The request that was denied
            reason: Reason for denial
        """
        user_info = 'anonymous'
        if request.user and hasattr(request.user, 'id'):
            user_info = f'user:{request.user.id}'
        
        logger.warning(
            'Analytics access denied',
            extra={
                'user': user_info,
                'path': request.path,
                'method': request.method,
                'reason': reason,
                'ip_address': self._get_client_ip(request),
                'user_agent': request.META.get('HTTP_USER_AGENT', ''),
            }
        )
        
        # Log to audit system if user is authenticated
        if request.user and hasattr(request.user, 'id'):
            log_user_action(
                user=request.user,
                action_type=AuditActionType.ADMIN_ACCESS,
                description=f'Analytics access denied: {reason}',
                outcome='denied',
                metadata={
                    'path': request.path,
                    'method': request.method,
                    'reason': reason,
                    'ip_address': self._get_client_ip(request),
                }
            )
    
    def _log_access_granted(self, request: Request) -> None:
        """
        Log successful access for audit purposes.
        
        Args:
            request: The successful request
        """
        logger.info(
            'Analytics access granted',
            extra={
                'user': f'user:{request.user.id}',
                'path': request.path,
                'method': request.method,
                'user_role': request.user.role,
                'ip_address': self._get_client_ip(request),
            }
        )
        
        # Log to audit system
        log_user_action(
            user=request.user,
            action_type=AuditActionType.ADMIN_ACCESS,
            description=f'Analytics access granted for {request.path}',
            outcome='success',
            metadata={
                'path': request.path,
                'method': request.method,
                'ip_address': self._get_client_ip(request),
            }
        )
    
    def _get_client_ip(self, request: Request) -> str:
        """
        Extract client IP address from request.
        
        Args:
            request: The HTTP request
            
        Returns:
            str: Client IP address
        """
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR', 'unknown')
        return ip


class AnalyticsExportPermission(AnalyticsPermission):
    """
    Enhanced permission class for analytics export functionality.
    
    Provides additional security checks for export operations,
    including rate limiting considerations and export-specific logging.
    """
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check permission for analytics export operations.
        
        Args:
            request: The incoming request
            view: The view being accessed
            
        Returns:
            bool: True if user has permission, False otherwise
        """
        # First check base analytics permission
        if not super().has_permission(request, view):
            return False
        
        # Additional checks for export operations
        if request.method in ['POST', 'PUT', 'PATCH']:
            # Log export request attempt
            logger.info(
                'Analytics export requested',
                extra={
                    'user': f'user:{request.user.id}',
                    'path': request.path,
                    'method': request.method,
                    'ip_address': self._get_client_ip(request),
                }
            )
            
            # Log to audit system
            log_user_action(
                user=request.user,
                action_type=AuditActionType.ADMIN_ACCESS,
                description=f'Analytics export requested: {request.path}',
                outcome='initiated',
                metadata={
                    'path': request.path,
                    'method': request.method,
                    'ip_address': self._get_client_ip(request),
                    'export_request': True,
                }
            )
        
        return True


class ReadOnlyAnalyticsPermission(AnalyticsPermission):
    """
    Read-only permission for analytics data.
    
    Allows viewing analytics but prevents any modifications.
    Useful for dashboard views or reporting interfaces.
    """
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check permission for read-only analytics access.
        
        Args:
            request: The incoming request
            view: The view being accessed
            
        Returns:
            bool: True if user has permission and method is safe, False otherwise
        """
        # First check base analytics permission
        if not super().has_permission(request, view):
            return False
        
        # Only allow safe methods (GET, HEAD, OPTIONS)
        if request.method not in permissions.SAFE_METHODS:
            self._log_access_denied(request, f'unsafe_method:{request.method}')
            return False
        
        return True