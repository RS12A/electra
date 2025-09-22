"""
Custom exception handlers for Electra Server.
Provides structured error responses and logging.
"""

import logging
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
from django.http import Http404
from django.core.exceptions import PermissionDenied
from django.db import IntegrityError


logger = logging.getLogger('electra_server.exceptions')


def custom_exception_handler(exc, context):
    """
    Custom exception handler that provides structured error responses.
    """
    
    # Call REST framework's default exception handler first,
    # to get the standard error response.
    response = exception_handler(exc, context)
    
    # Get request information
    request = context.get('request')
    request_id = getattr(request, 'request_id', 'unknown') if request else 'unknown'
    
    if response is not None:
        # Standard DRF exception
        custom_response_data = {
            'error': {
                'code': response.status_code,
                'message': 'An error occurred',
                'details': response.data,
                'request_id': request_id,
            }
        }
        
        # Customize error messages based on status code
        if response.status_code == status.HTTP_400_BAD_REQUEST:
            custom_response_data['error']['message'] = 'Invalid request data'
        elif response.status_code == status.HTTP_401_UNAUTHORIZED:
            custom_response_data['error']['message'] = 'Authentication required'
        elif response.status_code == status.HTTP_403_FORBIDDEN:
            custom_response_data['error']['message'] = 'Permission denied'
        elif response.status_code == status.HTTP_404_NOT_FOUND:
            custom_response_data['error']['message'] = 'Resource not found'
        elif response.status_code == status.HTTP_405_METHOD_NOT_ALLOWED:
            custom_response_data['error']['message'] = 'Method not allowed'
        elif response.status_code == status.HTTP_429_TOO_MANY_REQUESTS:
            custom_response_data['error']['message'] = 'Too many requests'
        elif response.status_code >= status.HTTP_500_INTERNAL_SERVER_ERROR:
            custom_response_data['error']['message'] = 'Internal server error'
            # Don't expose internal error details in production
            if hasattr(request, 'user') and request.user.is_staff:
                custom_response_data['error']['details'] = response.data
            else:
                custom_response_data['error']['details'] = 'An unexpected error occurred'
        
        response.data = custom_response_data
        
        # Log the exception
        logger.warning(
            f'API exception: {exc}',
            extra={
                'exception_type': type(exc).__name__,
                'status_code': response.status_code,
                'request_id': request_id,
                'path': request.path if request else 'unknown',
                'method': request.method if request else 'unknown',
            }
        )
        
    else:
        # Non-DRF exception, handle custom cases
        if isinstance(exc, Http404):
            custom_response_data = {
                'error': {
                    'code': status.HTTP_404_NOT_FOUND,
                    'message': 'Resource not found',
                    'details': str(exc),
                    'request_id': request_id,
                }
            }
            response = Response(custom_response_data, status=status.HTTP_404_NOT_FOUND)
            
        elif isinstance(exc, PermissionDenied):
            custom_response_data = {
                'error': {
                    'code': status.HTTP_403_FORBIDDEN,
                    'message': 'Permission denied',
                    'details': str(exc),
                    'request_id': request_id,
                }
            }
            response = Response(custom_response_data, status=status.HTTP_403_FORBIDDEN)
            
        elif isinstance(exc, IntegrityError):
            custom_response_data = {
                'error': {
                    'code': status.HTTP_400_BAD_REQUEST,
                    'message': 'Data integrity error',
                    'details': 'The requested operation violates data constraints',
                    'request_id': request_id,
                }
            }
            response = Response(custom_response_data, status=status.HTTP_400_BAD_REQUEST)
            
        else:
            # Unexpected exception
            logger.error(
                f'Unhandled exception: {exc}',
                extra={
                    'exception_type': type(exc).__name__,
                    'request_id': request_id,
                    'path': request.path if request else 'unknown',
                    'method': request.method if request else 'unknown',
                },
                exc_info=True
            )
            
            custom_response_data = {
                'error': {
                    'code': status.HTTP_500_INTERNAL_SERVER_ERROR,
                    'message': 'Internal server error',
                    'details': 'An unexpected error occurred',
                    'request_id': request_id,
                }
            }
            response = Response(custom_response_data, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return response