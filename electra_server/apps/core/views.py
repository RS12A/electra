"""
Core views for Electra Server.
Includes health checks and system status endpoints.
"""

import os
import uuid
from django.db import connection
from django.core.cache import cache
from django.conf import settings
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
import logging

logger = logging.getLogger(__name__)

# Try to import psutil for system monitoring
try:
    import psutil
    HAS_PSUTIL = True
except ImportError:
    HAS_PSUTIL = False


@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    """
    Comprehensive health check endpoint.
    Returns system status including database, cache, and file system checks.
    """
    
    health_data = {
        'status': 'healthy',
        'timestamp': timezone.now().isoformat(),
        'version': '1.0.0',
        'request_id': getattr(request, 'request_id', str(uuid.uuid4())),
        'checks': {}
    }
    
    overall_status = True
    
    # Database check
    try:
        with connection.cursor() as cursor:
            cursor.execute('SELECT 1')
            cursor.fetchone()
        health_data['checks']['database'] = {
            'status': 'healthy',
            'message': 'Database connection successful'
        }
    except Exception as e:
        health_data['checks']['database'] = {
            'status': 'unhealthy',
            'message': f'Database connection failed: {str(e)}'
        }
        overall_status = False
    
    # Cache check
    try:
        test_key = f'health_check_{uuid.uuid4().hex}'
        cache.set(test_key, 'test_value', 30)
        cached_value = cache.get(test_key)
        if cached_value == 'test_value':
            health_data['checks']['cache'] = {
                'status': 'healthy',
                'message': 'Cache is working'
            }
        else:
            health_data['checks']['cache'] = {
                'status': 'unhealthy',
                'message': 'Cache read/write test failed'
            }
            overall_status = False
        cache.delete(test_key)
    except Exception as e:
        health_data['checks']['cache'] = {
            'status': 'unhealthy',
            'message': f'Cache check failed: {str(e)}'
        }
        overall_status = False
    
    # File system checks
    try:
        # Check if required directories exist and are writable
        directories_to_check = [
            settings.MEDIA_ROOT,
            os.path.join(settings.BASE_DIR, 'logs'),
        ]
        
        # Only add STATIC_ROOT if it's defined
        if hasattr(settings, 'STATIC_ROOT') and settings.STATIC_ROOT:
            directories_to_check.append(settings.STATIC_ROOT)
        
        filesystem_status = True
        filesystem_messages = []
        
        for directory in directories_to_check:
            if not os.path.exists(directory):
                try:
                    os.makedirs(directory, exist_ok=True)
                    filesystem_messages.append(f'Created directory: {directory}')
                except Exception as e:
                    filesystem_messages.append(f'Cannot create directory {directory}: {str(e)}')
                    filesystem_status = False
            
            if os.path.exists(directory) and not os.access(directory, os.W_OK):
                filesystem_messages.append(f'Directory not writable: {directory}')
                filesystem_status = False
        
        health_data['checks']['filesystem'] = {
            'status': 'healthy' if filesystem_status else 'unhealthy',
            'message': '; '.join(filesystem_messages) if filesystem_messages else 'All directories accessible'
        }
        
        if not filesystem_status:
            overall_status = False
            
    except Exception as e:
        health_data['checks']['filesystem'] = {
            'status': 'unhealthy',
            'message': f'Filesystem check failed: {str(e)}'
        }
        overall_status = False
    
    # RSA keys check
    try:
        rsa_private_key_path = getattr(settings, 'RSA_PRIVATE_KEY_PATH', None)
        rsa_public_key_path = getattr(settings, 'RSA_PUBLIC_KEY_PATH', None)
        
        if rsa_private_key_path and rsa_public_key_path:
            if os.path.exists(rsa_private_key_path) and os.path.exists(rsa_public_key_path):
                health_data['checks']['rsa_keys'] = {
                    'status': 'healthy',
                    'message': 'RSA keys are available'
                }
            else:
                health_data['checks']['rsa_keys'] = {
                    'status': 'warning',
                    'message': 'RSA keys not found - run key generation script'
                }
        else:
            health_data['checks']['rsa_keys'] = {
                'status': 'warning',
                'message': 'RSA key paths not configured'
            }
    except Exception as e:
        health_data['checks']['rsa_keys'] = {
            'status': 'unhealthy',
            'message': f'RSA keys check failed: {str(e)}'
        }
    
    # System resource checks (only if psutil is available)
    if HAS_PSUTIL:
        try:
            # Memory check
            memory_info = psutil.virtual_memory()
            memory_available_mb = memory_info.available / (1024 * 1024)
            
            if memory_available_mb > 100:  # At least 100MB available
                memory_status = 'healthy'
                memory_message = f'Available memory: {memory_available_mb:.1f}MB'
            else:
                memory_status = 'warning'
                memory_message = f'Low memory: {memory_available_mb:.1f}MB available'
            
            # Disk check
            disk_info = psutil.disk_usage(str(settings.BASE_DIR))
            disk_free_percent = (disk_info.free / disk_info.total) * 100
            
            if disk_free_percent > 10:  # At least 10% free space
                disk_status = 'healthy'
                disk_message = f'Disk space: {disk_free_percent:.1f}% free'
            else:
                disk_status = 'warning'
                disk_message = f'Low disk space: {disk_free_percent:.1f}% free'
            
            health_data['checks']['resources'] = {
                'status': 'healthy',
                'message': f'{memory_message}; {disk_message}',
                'memory': {
                    'status': memory_status,
                    'available_mb': round(memory_available_mb, 1)
                },
                'disk': {
                    'status': disk_status,
                    'free_percent': round(disk_free_percent, 1)
                }
            }
            
        except Exception as e:
            health_data['checks']['resources'] = {
                'status': 'warning',
                'message': f'Resource check failed: {str(e)}'
            }
    else:
        health_data['checks']['resources'] = {
            'status': 'info',
            'message': 'System monitoring unavailable (psutil not installed)'
        }
    
    # Overall status
    health_data['status'] = 'healthy' if overall_status else 'unhealthy'
    
    # Log health check
    logger.info(f'Health check performed: {health_data["status"]}', extra={
        'request_id': health_data['request_id'],
        'health_status': health_data['status']
    })
    
    response_status = status.HTTP_200_OK if overall_status else status.HTTP_503_SERVICE_UNAVAILABLE
    
    return Response(health_data, status=response_status)


@api_view(['GET'])
@permission_classes([AllowAny])
def simple_health(request):
    """
    Simple health check endpoint for load balancers.
    Returns minimal response for basic availability checking.
    """
    return Response({
        'status': 'ok',
        'timestamp': timezone.now().isoformat()
    })