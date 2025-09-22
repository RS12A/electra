"""
Request logging middleware for structured logging.
"""
import json
import time
import uuid
import logging
from django.utils.deprecation import MiddlewareMixin
from django.contrib.auth.models import AnonymousUser

logger = logging.getLogger('electra_server')


class RequestLoggingMiddleware(MiddlewareMixin):
    """
    Middleware to log all HTTP requests with structured data including:
    - Request ID (UUID)
    - Timestamp
    - HTTP method
    - Path
    - User (if authenticated)
    - Response time
    - Status code
    """
    
    def process_request(self, request):
        """Process incoming request and set up logging context."""
        # Generate unique request ID
        request.request_id = str(uuid.uuid4())
        request.start_time = time.time()
        
        # Log incoming request
        user_info = None
        if hasattr(request, 'user') and not isinstance(request.user, AnonymousUser):
            user_info = {
                'id': request.user.id,
                'username': getattr(request.user, 'username', 'unknown'),
                'email': getattr(request.user, 'email', 'unknown')
            }
        
        log_data = {
            'event': 'request_started',
            'request_id': request.request_id,
            'timestamp': time.time(),
            'method': request.method,
            'path': request.path,
            'query_params': dict(request.GET),
            'user': user_info,
            'user_agent': request.META.get('HTTP_USER_AGENT', ''),
            'ip_address': self._get_client_ip(request),
            'content_type': request.content_type,
        }
        
        logger.info('Request started', extra={'log_data': log_data})
        return None
    
    def process_response(self, request, response):
        """Process response and log completion."""
        if hasattr(request, 'start_time'):
            response_time = time.time() - request.start_time
            
            user_info = None
            if hasattr(request, 'user') and not isinstance(request.user, AnonymousUser):
                user_info = {
                    'id': request.user.id,
                    'username': getattr(request.user, 'username', 'unknown'),
                    'email': getattr(request.user, 'email', 'unknown')
                }
            
            log_data = {
                'event': 'request_completed',
                'request_id': getattr(request, 'request_id', 'unknown'),
                'timestamp': time.time(),
                'method': request.method,
                'path': request.path,
                'status_code': response.status_code,
                'response_time_ms': round(response_time * 1000, 2),
                'user': user_info,
                'content_length': len(response.content) if hasattr(response, 'content') else 0,
            }
            
            # Use different log levels based on status code
            if response.status_code >= 500:
                logger.error('Request completed with server error', extra={'log_data': log_data})
            elif response.status_code >= 400:
                logger.warning('Request completed with client error', extra={'log_data': log_data})
            else:
                logger.info('Request completed successfully', extra={'log_data': log_data})
        
        return response
    
    def process_exception(self, request, exception):
        """Log exceptions that occur during request processing."""
        if hasattr(request, 'start_time'):
            response_time = time.time() - request.start_time
            
            user_info = None
            if hasattr(request, 'user') and not isinstance(request.user, AnonymousUser):
                user_info = {
                    'id': request.user.id,
                    'username': getattr(request.user, 'username', 'unknown'),
                    'email': getattr(request.user, 'email', 'unknown')
                }
            
            log_data = {
                'event': 'request_exception',
                'request_id': getattr(request, 'request_id', 'unknown'),
                'timestamp': time.time(),
                'method': request.method,
                'path': request.path,
                'exception_type': type(exception).__name__,
                'exception_message': str(exception),
                'response_time_ms': round(response_time * 1000, 2),
                'user': user_info,
            }
            
            logger.error('Request failed with exception', extra={'log_data': log_data}, exc_info=True)
        
        return None
    
    def _get_client_ip(self, request):
        """Get client IP address from request headers."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR', 'unknown')
        return ip