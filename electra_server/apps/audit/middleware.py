"""
Security middleware for electra_server.

This module contains security middleware for enforcing production-grade
security requirements including TLS 1.3, audit logging, and tamper detection.
"""
import logging
from typing import Dict, Any

from django.conf import settings
from django.http import HttpResponse, HttpRequest
from django.utils.deprecation import MiddlewareMixin

from electra_server.apps.audit.utils import log_system_event
from electra_server.apps.audit.models import AuditActionType

logger = logging.getLogger(__name__)


class SecurityEnforcementMiddleware(MiddlewareMixin):
    """
    Middleware to enforce production-grade security requirements.
    
    Features:
    - TLS 1.3 enforcement for audit endpoints
    - Security header validation
    - Rate limiting preparation
    - Audit logging for security events
    """
    
    def process_request(self, request: HttpRequest) -> HttpResponse:
        """
        Process incoming requests for security compliance.
        
        Args:
            request: HTTP request object
            
        Returns:
            HttpResponse: Error response if security requirements not met, None otherwise
        """
        # Check if this is an audit endpoint
        if request.path.startswith('/api/audit/'):
            # Enforce HTTPS for audit endpoints in production
            if not settings.DEBUG and not request.is_secure():
                log_system_event(
                    action_type=AuditActionType.SYSTEM_ERROR,
                    description='Insecure audit endpoint access attempted',
                    outcome='error',
                    metadata={
                        'path': request.path,
                        'method': request.method,
                        'ip_address': self._get_client_ip(request),
                        'user_agent': request.META.get('HTTP_USER_AGENT', ''),
                        'security_violation': 'unencrypted_audit_access'
                    },
                    error_details='Audit endpoints require HTTPS in production'
                )
                
                return HttpResponse(
                    'Audit endpoints require encrypted connection (HTTPS)',
                    status=400,
                    content_type='text/plain'
                )
            
            # Check TLS version (if available in headers)
            # Note: This is typically handled at the load balancer/proxy level
            # but we can add logging for monitoring
            tls_version = request.META.get('HTTP_X_TLS_VERSION', '')
            if tls_version and not tls_version.startswith('TLS 1.3'):
                logger.warning(
                    'Audit endpoint accessed with non-TLS 1.3 connection',
                    extra={
                        'tls_version': tls_version,
                        'path': request.path,
                        'ip_address': self._get_client_ip(request)
                    }
                )
        
        return None
    
    def process_response(self, request: HttpRequest, response: HttpResponse) -> HttpResponse:
        """
        Process outgoing responses to add security headers.
        
        Args:
            request: HTTP request object
            response: HTTP response object
            
        Returns:
            HttpResponse: Response with security headers added
        """
        # Add security headers for audit endpoints
        if request.path.startswith('/api/audit/'):
            # Ensure no caching of audit data
            response['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
            response['Pragma'] = 'no-cache'
            response['Expires'] = '0'
            
            # Add audit-specific security headers
            response['X-Audit-Endpoint'] = 'true'
            response['X-Content-Type-Options'] = 'nosniff'
            response['X-Frame-Options'] = 'DENY'
            
            # Force HTTPS for future requests in production
            if not settings.DEBUG:
                response['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains; preload'
        
        return response
    
    def _get_client_ip(self, request: HttpRequest) -> str:
        """Extract client IP address from request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            return x_forwarded_for.split(',')[0].strip()
        return request.META.get('REMOTE_ADDR', '')


class AuditTrailMiddleware(MiddlewareMixin):
    """
    Middleware for automatic audit trail generation.
    
    Logs high-level request patterns and security events for
    comprehensive audit coverage.
    """
    
    SENSITIVE_ENDPOINTS = [
        '/api/auth/login/',
        '/api/auth/logout/',
        '/api/elections/create/',
        '/api/ballots/request-token/',
        '/api/votes/cast/',
        '/api/audit/',
    ]
    
    def process_request(self, request: HttpRequest) -> HttpResponse:
        """
        Log request patterns for security monitoring.
        
        Args:
            request: HTTP request object
            
        Returns:
            None (no response modification)
        """
        # Check if this is a sensitive endpoint
        is_sensitive = any(
            request.path.startswith(endpoint) 
            for endpoint in self.SENSITIVE_ENDPOINTS
        )
        
        if is_sensitive:
            # Log high-level access pattern (without sensitive data)
            user_identifier = 'Anonymous'
            if hasattr(request, 'user') and request.user.is_authenticated:
                user_identifier = request.user.email
            
            logger.info(
                'Sensitive endpoint access',
                extra={
                    'endpoint': request.path,
                    'method': request.method,
                    'user': user_identifier,
                    'ip_address': self._get_client_ip(request),
                    'user_agent': request.META.get('HTTP_USER_AGENT', '')[:100],  # Truncate long user agents
                }
            )
        
        return None
    
    def process_exception(self, request: HttpRequest, exception: Exception) -> HttpResponse:
        """
        Log exceptions for security monitoring.
        
        Args:
            request: HTTP request object
            exception: Exception that occurred
            
        Returns:
            None (no response modification)
        """
        # Log security-relevant exceptions
        log_system_event(
            action_type=AuditActionType.SYSTEM_ERROR,
            description=f'Request processing exception: {type(exception).__name__}',
            outcome='error',
            metadata={
                'path': request.path,
                'method': request.method,
                'exception_type': type(exception).__name__,
                'ip_address': self._get_client_ip(request),
                'user_agent': request.META.get('HTTP_USER_AGENT', '')[:100],
                'user': request.user.email if hasattr(request, 'user') and request.user.is_authenticated else 'Anonymous',
            },
            error_details=str(exception)[:500]  # Truncate long error messages
        )
        
        return None
    
    def _get_client_ip(self, request: HttpRequest) -> str:
        """Extract client IP address from request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            return x_forwarded_for.split(',')[0].strip()
        return request.META.get('REMOTE_ADDR', '')


class TamperDetectionMiddleware(MiddlewareMixin):
    """
    Middleware for detecting potential tampering attempts.
    
    Monitors for suspicious patterns that might indicate
    attempts to compromise the audit system.
    """
    
    def process_request(self, request: HttpRequest) -> HttpResponse:
        """
        Monitor for tampering attempts.
        
        Args:
            request: HTTP request object
            
        Returns:
            HttpResponse: Block response if tampering detected, None otherwise
        """
        suspicious_patterns = []
        
        # Check for common injection patterns in audit endpoints
        if request.path.startswith('/api/audit/'):
            query_params = request.GET.urlencode()
            post_data = ''
            
            if hasattr(request, 'body'):
                try:
                    post_data = request.body.decode('utf-8', errors='ignore')[:1000]
                except:
                    post_data = ''
            
            # Check for SQL injection patterns
            sql_patterns = ['union', 'select', 'insert', 'update', 'delete', 'drop', '--', '/*', '*/', 'xp_']
            for pattern in sql_patterns:
                if pattern in query_params.lower() or pattern in post_data.lower():
                    suspicious_patterns.append(f'sql_injection_attempt:{pattern}')
            
            # Check for XSS patterns
            xss_patterns = ['<script', 'javascript:', 'onerror=', 'onload=', '<img', '<iframe']
            for pattern in xss_patterns:
                if pattern in query_params.lower() or pattern in post_data.lower():
                    suspicious_patterns.append(f'xss_attempt:{pattern}')
            
            # Check for path traversal
            if '../' in query_params or '../' in post_data:
                suspicious_patterns.append('path_traversal_attempt')
            
            # Check for unusual user agent patterns
            user_agent = request.META.get('HTTP_USER_AGENT', '').lower()
            suspicious_agents = ['sqlmap', 'nmap', 'nikto', 'burp', 'owasp', 'wget', 'curl']
            for agent in suspicious_agents:
                if agent in user_agent:
                    suspicious_patterns.append(f'suspicious_user_agent:{agent}')
            
            if suspicious_patterns:
                # Log tampering attempt
                log_system_event(
                    action_type=AuditActionType.SYSTEM_ERROR,
                    description='Potential tampering attempt detected on audit endpoint',
                    outcome='error',
                    metadata={
                        'path': request.path,
                        'method': request.method,
                        'suspicious_patterns': suspicious_patterns,
                        'ip_address': self._get_client_ip(request),
                        'user_agent': request.META.get('HTTP_USER_AGENT', ''),
                        'query_params': query_params[:500],  # Truncate
                        'post_data_sample': post_data[:200],  # Small sample
                        'security_violation': 'potential_tampering_attempt'
                    },
                    error_details=f'Detected patterns: {", ".join(suspicious_patterns)}'
                )
                
                logger.critical(
                    'Potential audit tampering attempt blocked',
                    extra={
                        'patterns': suspicious_patterns,
                        'ip_address': self._get_client_ip(request),
                        'path': request.path
                    }
                )
                
                # Block the request
                return HttpResponse(
                    'Request blocked due to security policy violation',
                    status=403,
                    content_type='text/plain'
                )
        
        return None
    
    def _get_client_ip(self, request: HttpRequest) -> str:
        """Extract client IP address from request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            return x_forwarded_for.split(',')[0].strip()
        return request.META.get('REMOTE_ADDR', '')