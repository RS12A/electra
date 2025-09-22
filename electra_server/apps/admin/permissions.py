"""
Admin API permissions for the electra voting system.

This module contains permission classes that enforce role-based access control
for admin API endpoints, ensuring only authorized users can access sensitive
administrative functions.
"""
import logging
from typing import Any
from rest_framework import permissions
from rest_framework.request import Request
from rest_framework.views import View

from electra_server.apps.auth.models import UserRole
from electra_server.apps.audit.utils import log_user_action
from electra_server.apps.audit.models import AuditActionType

logger = logging.getLogger('electra_server.admin')


class AdminPermission(permissions.BasePermission):
    """
    Permission class for admin API access.
    
    Only allows users with admin or electoral_committee roles to access
    admin API endpoints. Includes comprehensive security checks and logging.
    """
    
    # Roles allowed to access admin APIs
    ALLOWED_ROLES = [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if user has permission to access admin APIs.
        
        Args:
            request: HTTP request object
            view: View being accessed
            
        Returns:
            bool: True if user is authorized, False otherwise
        """
        # Require authentication
        if not request.user or not request.user.is_authenticated:
            self._log_access_denied(request, 'unauthenticated')
            return False
        
        # Check if user account is active
        if not request.user.is_active:
            self._log_access_denied(request, 'inactive_user')
            return False
        
        # Check user role
        if not hasattr(request.user, 'role'):
            self._log_access_denied(request, 'no_role')
            return False
        
        if request.user.role not in self.ALLOWED_ROLES:
            self._log_access_denied(request, 'insufficient_role')
            return False
        
        # Additional security checks for production
        if hasattr(request, 'is_secure') and not request.is_secure():
            # This should be handled by middleware, but we'll log it
            logger.warning(
                'Admin API accessed over insecure connection',
                extra={
                    'user_id': request.user.id,
                    'user_email': request.user.email,
                    'path': request.path,
                    'ip_address': self._get_client_ip(request)
                }
            )
        
        # Log successful access for audit trail
        self._log_access_granted(request)
        return True
    
    def has_object_permission(self, request: Request, view: View, obj: Any) -> bool:
        """
        Check object-level permissions for admin API access.
        
        Args:
            request: HTTP request object
            view: View being accessed
            obj: Object being accessed
            
        Returns:
            bool: True if user has object-level permission, False otherwise
        """
        # First check general permission
        if not self.has_permission(request, view):
            return False
        
        # For admin APIs, if user has general access, they have object access
        # This can be customized per view if needed
        return True
    
    def _log_access_denied(self, request: Request, reason: str) -> None:
        """
        Log admin API access denial for security monitoring.
        
        Args:
            request: HTTP request object
            reason: Reason for access denial
        """
        user_identifier = 'Anonymous'
        user_id = None
        
        if hasattr(request, 'user') and request.user.is_authenticated:
            user_identifier = request.user.email
            user_id = request.user.id
        
        log_user_action(
            action_type=AuditActionType.USER_LOGIN_FAILED,
            description=f'Admin API access denied: {reason}',
            user=request.user if request.user and request.user.is_authenticated else None,
            outcome='error',
            target_resource_type='AdminAPI',
            target_resource_id=request.path,
            metadata={
                'endpoint': request.path,
                'method': request.method,
                'user_identifier': user_identifier,
                'user_id': str(user_id) if user_id else None,
                'ip_address': self._get_client_ip(request),
                'user_agent': request.META.get('HTTP_USER_AGENT', ''),
                'denial_reason': reason,
                'security_event': 'admin_api_access_denied'
            },
            error_details=f'Admin API access denied for reason: {reason}'
        )
        
        logger.warning(
            f'Admin API access denied: {reason}',
            extra={
                'user_identifier': user_identifier,
                'path': request.path,
                'method': request.method,
                'ip_address': self._get_client_ip(request),
                'reason': reason
            }
        )
    
    def _log_access_granted(self, request: Request) -> None:
        """
        Log successful admin API access for audit trail.
        
        Args:
            request: HTTP request object
        """
        log_user_action(
            action_type=AuditActionType.USER_LOGIN,
            description='Admin API access granted',
            user=request.user,
            outcome='success',
            target_resource_type='AdminAPI',
            target_resource_id=request.path,
            metadata={
                'endpoint': request.path,
                'method': request.method,
                'user_id': str(request.user.id),
                'user_email': request.user.email,
                'user_role': request.user.role,
                'ip_address': self._get_client_ip(request),
                'user_agent': request.META.get('HTTP_USER_AGENT', ''),
                'security_event': 'admin_api_access_granted'
            }
        )
    
    def _get_client_ip(self, request: Request) -> str:
        """
        Extract client IP address from request.
        
        Args:
            request: HTTP request object
            
        Returns:
            str: Client IP address
        """
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0].strip()
        else:
            ip = request.META.get('REMOTE_ADDR', '')
        return ip


class UserManagementPermission(AdminPermission):
    """
    Specialized permission for user management operations.
    
    Inherits from AdminPermission but adds additional checks for user
    management operations like creating/modifying admin users.
    """
    
    def has_object_permission(self, request: Request, view: View, obj: Any) -> bool:
        """
        Check object-level permissions for user management.
        
        Args:
            request: HTTP request object
            view: View being accessed
            obj: User object being accessed
            
        Returns:
            bool: True if user has permission, False otherwise
        """
        # First check general admin permission
        if not super().has_object_permission(request, view, obj):
            return False
        
        # Additional restrictions for user management
        # Only full admins can modify other admin users
        if hasattr(obj, 'role') and obj.role == UserRole.ADMIN:
            if request.user.role != UserRole.ADMIN:
                self._log_access_denied(request, 'insufficient_role_for_admin_user')
                return False
        
        return True


class ElectionManagementPermission(AdminPermission):
    """
    Specialized permission for election management operations.
    
    Inherits from AdminPermission with additional checks for election
    lifecycle operations.
    """
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check permissions for election management operations.
        
        Args:
            request: HTTP request object
            view: View being accessed
            
        Returns:
            bool: True if user has permission, False otherwise
        """
        # Use parent permission check
        if not super().has_permission(request, view):
            return False
        
        # Additional logging for election management
        if request.method in ['POST', 'PUT', 'PATCH', 'DELETE']:
            log_user_action(
                action_type=AuditActionType.ADMIN_ACTION,
                description=f'Election management action attempted: {request.method}',
                user=request.user,
                outcome='in_progress',
                target_resource_type='Election',
                target_resource_id=request.path,
                metadata={
                    'endpoint': request.path,
                    'method': request.method,
                    'user_role': request.user.role,
                    'ip_address': self._get_client_ip(request)
                }
            )
        
        return True


class BallotTokenManagementPermission(AdminPermission):
    """
    Specialized permission for ballot token management operations.
    
    Inherits from AdminPermission with additional security for ballot
    token operations which are highly sensitive.
    """
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check permissions for ballot token management operations.
        
        Args:
            request: HTTP request object
            view: View being accessed
            
        Returns:
            bool: True if user has permission, False otherwise
        """
        # Use parent permission check
        if not super().has_permission(request, view):
            return False
        
        # Log all ballot token operations for security
        log_user_action(
            action_type=AuditActionType.ADMIN_ACTION,
            description=f'Ballot token management action: {request.method}',
            user=request.user,
            outcome='in_progress',
            target_resource_type='BallotToken',
            target_resource_id=request.path,
            metadata={
                'endpoint': request.path,
                'method': request.method,
                'user_role': request.user.role,
                'ip_address': self._get_client_ip(request),
                'security_event': 'ballot_token_admin_access'
            }
        )
        
        return True