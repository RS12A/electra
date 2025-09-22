"""
Health check views.
"""
import time
from django.db import connection
from django.core.cache import cache
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status


@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    """
    Simple health check endpoint that returns system status.
    """
    start_time = time.time()
    
    health_data = {
        'status': 'healthy',
        'timestamp': time.time(),
        'version': '1.0.0',
        'environment': 'development',  # This would be set from env
        'services': {
            'database': _check_database(),
            'cache': _check_cache(),
        }
    }
    
    # Calculate response time
    health_data['response_time_ms'] = round((time.time() - start_time) * 1000, 2)
    
    # Determine overall health status
    all_services_healthy = all(
        service_status['status'] == 'healthy' 
        for service_status in health_data['services'].values()
    )
    
    if not all_services_healthy:
        health_data['status'] = 'degraded'
        return Response(health_data, status=status.HTTP_503_SERVICE_UNAVAILABLE)
    
    return Response(health_data, status=status.HTTP_200_OK)


def _check_database():
    """Check database connectivity."""
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            return {'status': 'healthy', 'message': 'Database connection successful'}
    except Exception as e:
        return {'status': 'unhealthy', 'message': f'Database connection failed: {str(e)}'}


def _check_cache():
    """Check cache connectivity."""
    try:
        # Test cache by setting and getting a value
        test_key = 'health_check_test'
        test_value = 'ok'
        cache.set(test_key, test_value, 30)  # 30 seconds
        cached_value = cache.get(test_key)
        
        if cached_value == test_value:
            cache.delete(test_key)  # Clean up
            return {'status': 'healthy', 'message': 'Cache connection successful'}
        else:
            return {'status': 'unhealthy', 'message': 'Cache read/write test failed'}
    except Exception as e:
        return {'status': 'unhealthy', 'message': f'Cache connection failed: {str(e)}'}
