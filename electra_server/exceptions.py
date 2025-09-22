"""
Custom exception handlers for Django REST Framework.
"""
import logging
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status

logger = logging.getLogger('electra_server')


def custom_exception_handler(exc, context):
    """
    Custom exception handler that provides structured error responses.
    """
    # Call REST framework's default exception handler first,
    # to get the standard error response.
    response = exception_handler(exc, context)
    
    # Get request from context
    request = context.get('request')
    request_id = getattr(request, 'request_id', 'unknown') if request else 'unknown'
    
    if response is not None:
        # Log the exception
        log_data = {
            'event': 'api_exception',
            'request_id': request_id,
            'exception_type': type(exc).__name__,
            'exception_message': str(exc),
            'status_code': response.status_code,
            'path': request.path if request else 'unknown',
            'method': request.method if request else 'unknown',
        }
        
        logger.warning('API exception occurred', extra={'log_data': log_data})
        
        # Customize the response format
        custom_response_data = {
            'error': True,
            'message': 'An error occurred while processing your request.',
            'details': response.data,
            'request_id': request_id,
        }
        
        # Provide more specific messages for common errors
        if response.status_code == status.HTTP_400_BAD_REQUEST:
            custom_response_data['message'] = 'Invalid request data provided.'
        elif response.status_code == status.HTTP_401_UNAUTHORIZED:
            custom_response_data['message'] = 'Authentication credentials were not provided or are invalid.'
        elif response.status_code == status.HTTP_403_FORBIDDEN:
            custom_response_data['message'] = 'You do not have permission to perform this action.'
        elif response.status_code == status.HTTP_404_NOT_FOUND:
            custom_response_data['message'] = 'The requested resource was not found.'
        elif response.status_code == status.HTTP_405_METHOD_NOT_ALLOWED:
            custom_response_data['message'] = 'This HTTP method is not allowed for this endpoint.'
        elif response.status_code == status.HTTP_429_TOO_MANY_REQUESTS:
            custom_response_data['message'] = 'Too many requests. Please try again later.'
        elif response.status_code >= 500:
            custom_response_data['message'] = 'Internal server error. Please contact support if this persists.'
            # Don't expose internal error details in production
            if not getattr(context.get('request'), 'DEBUG', False):
                custom_response_data['details'] = 'Internal server error'
        
        response.data = custom_response_data
    else:
        # Handle unexpected exceptions that DRF doesn't catch
        log_data = {
            'event': 'unhandled_exception',
            'request_id': request_id,
            'exception_type': type(exc).__name__,
            'exception_message': str(exc),
            'path': request.path if request else 'unknown',
            'method': request.method if request else 'unknown',
        }
        
        logger.error('Unhandled exception occurred', extra={'log_data': log_data}, exc_info=True)
        
        # Return a generic error response for unhandled exceptions
        response = Response({
            'error': True,
            'message': 'An unexpected error occurred. Please contact support if this persists.',
            'request_id': request_id,
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return response