"""
Request logging middleware for structured JSON logging.
Includes request ID tracking, response time, and user identification.
"""

import json
import logging
import time
import uuid
from django.utils.deprecation import MiddlewareMixin
from django.http import JsonResponse


logger = logging.getLogger('electra_server.requests')


class RequestLoggingMiddleware(MiddlewareMixin):
    """
    Middleware for structured JSON request logging with UUID tracking.
    """
    
    def process_request(self, request):
        """
        Process incoming request and generate request ID.
        """
        request.start_time = time.time()
        request.request_id = str(uuid.uuid4())
        
        # Add request ID to response headers
        request.META['HTTP_X_REQUEST_ID'] = request.request_id
        
        return None
    
    def process_response(self, request, response):
        """
        Log request details after processing.
        """
        try:
            # Calculate response time
            if hasattr(request, 'start_time'):
                response_time = time.time() - request.start_time
            else:
                response_time = 0
            
            # Get user information
            user_info = None
            if hasattr(request, 'user') and request.user.is_authenticated:
                user_info = {
                    'id': str(request.user.id),
                    'matric_number': getattr(request.user, 'matric_number', None),
                    'email': request.user.email,
                }
            
            # Prepare log data
            log_data = {
                'request_id': getattr(request, 'request_id', 'unknown'),
                'timestamp': time.time(),
                'method': request.method,
                'path': request.path,
                'query_params': dict(request.GET),
                'status_code': response.status_code,
                'response_time_ms': round(response_time * 1000, 2),
                'user_agent': request.META.get('HTTP_USER_AGENT', ''),
                'ip_address': self.get_client_ip(request),
                'user': user_info,
                'content_length': len(getattr(response, 'content', '')),
            }
            
            # Log sensitive endpoints differently
            if self.is_sensitive_endpoint(request.path):
                log_data['query_params'] = '[REDACTED]'
            
            # Add request ID to response headers
            response['X-Request-ID'] = getattr(request, 'request_id', 'unknown')
            
            # Log the request
            if response.status_code >= 400:
                logger.warning('HTTP request processed', extra={'request_data': log_data})
            else:
                logger.info('HTTP request processed', extra={'request_data': log_data})
                
        except Exception as e:
            logger.error(f'Error in request logging middleware: {e}')
        
        return response
    
    def process_exception(self, request, exception):
        """
        Log exceptions that occur during request processing.
        """
        try:
            response_time = time.time() - getattr(request, 'start_time', time.time())
            
            log_data = {
                'request_id': getattr(request, 'request_id', 'unknown'),
                'timestamp': time.time(),
                'method': request.method,
                'path': request.path,
                'exception': str(exception),
                'exception_type': type(exception).__name__,
                'response_time_ms': round(response_time * 1000, 2),
                'ip_address': self.get_client_ip(request),
                'user_agent': request.META.get('HTTP_USER_AGENT', ''),
            }
            
            logger.error('HTTP request exception', extra={'request_data': log_data})
            
        except Exception as e:
            logger.error(f'Error in exception logging: {e}')
        
        return None
    
    def get_client_ip(self, request):
        """
        Get the client's IP address, handling proxy headers.
        """
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0].strip()
        else:
            ip = request.META.get('REMOTE_ADDR', 'unknown')
        return ip
    
    def is_sensitive_endpoint(self, path):
        """
        Check if the endpoint contains sensitive data.
        """
        sensitive_patterns = [
            '/api/auth/login',
            '/api/auth/register',
            '/api/auth/refresh',
            '/admin',
        ]
        
        for pattern in sensitive_patterns:
            if pattern in path:
                return True
        
        return False