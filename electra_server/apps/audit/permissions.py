"""
Audit permissions for electra_server.

This module contains permission classes for the audit logging system,
ensuring only authorized users can access audit logs and verification
endpoints.
"""
from rest_framework import permissions
from rest_framework.request import Request
from django.contrib.auth import get_user_model

User = get_user_model()


class AuditLogPermission(permissions.BasePermission):
    """
    Permission class for audit log access.
    
    Allows access only to administrators and electoral committee members
    with additional security checks for production environments.
    """
    
    def has_permission(self, request: Request, view) -> bool:
        """
        Check if user has permission to access audit logs.
        
        Args:
            request: HTTP request object
            view: View being accessed
            
        Returns:
            True if user is authorized, False otherwise
        """
        # Require authentication
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Check user role - only admin and electoral committee
        if not hasattr(request.user, 'role'):
            return False
        
        allowed_roles = ['admin', 'electoral_committee']
        if request.user.role not in allowed_roles:
            return False
        
        # Additional security checks for production
        if hasattr(request, 'is_secure') and not request.is_secure():
            # Require HTTPS in production (handled by middleware)
            pass
        
        # Check if user account is active and not compromised
        if not request.user.is_active:
            return False
        
        # Log the access attempt for security monitoring
        from .models import AuditLog, AuditActionType
        
        # Get client IP
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip_address = x_forwarded_for.split(',')[0].strip()
        else:
            ip_address = request.META.get('REMOTE_ADDR', '')
        
        # Create audit entry for access attempt
        try:
            AuditLog.create_audit_entry(
                action_type=AuditActionType.ADMIN_ACTION,
                action_description=f"Audit log access attempted via {view.__class__.__name__}",
                user=request.user,
                ip_address=ip_address,
                user_agent=request.META.get('HTTP_USER_AGENT', ''),
                session_key=request.session.session_key or '',
                target_resource_type='AuditLog',
                outcome='success',
                metadata={
                    'view_name': view.__class__.__name__,
                    'method': request.method,
                    'path': request.path,
                }
            )
        except Exception:
            # Don't fail permission check due to audit logging issues
            pass
        
        return True
    
    def has_object_permission(self, request: Request, view, obj) -> bool:
        """
        Check if user has permission to access specific audit log object.
        
        Args:
            request: HTTP request object
            view: View being accessed
            obj: Audit log object being accessed
            
        Returns:
            True if user is authorized, False otherwise
        """
        # Use same permission logic as has_permission
        return self.has_permission(request, view)


class AuditVerificationPermission(permissions.BasePermission):
    """
    Permission class for audit chain verification endpoints.
    
    Provides additional security for verification operations that
    could be computationally expensive.
    """
    
    def has_permission(self, request: Request, view) -> bool:
        """
        Check if user has permission to perform audit verification.
        
        Args:
            request: HTTP request object
            view: View being accessed
            
        Returns:
            True if user is authorized, False otherwise
        """
        # Use base audit log permission first
        base_permission = AuditLogPermission()
        if not base_permission.has_permission(request, view):
            return False
        
        # Additional checks for verification operations
        if request.method in ['POST', 'PUT', 'PATCH']:
            # Require admin role for verification operations
            if request.user.role != 'admin':
                return False
        
        # Rate limiting could be implemented here
        # For now, we'll rely on the base permission
        
        return True


class AuditStatsPermission(permissions.BasePermission):
    """
    Permission class for audit statistics endpoints.
    
    Allows access to audit statistics for monitoring and reporting.
    """
    
    def has_permission(self, request: Request, view) -> bool:
        """
        Check if user has permission to access audit statistics.
        
        Args:
            request: HTTP request object
            view: View being accessed
            
        Returns:
            True if user is authorized, False otherwise
        """
        # Use base audit log permission
        base_permission = AuditLogPermission()
        return base_permission.has_permission(request, view)