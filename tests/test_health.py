"""
Tests for health check endpoint.
"""
import json
from django.test import TestCase, TransactionTestCase
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from unittest.mock import patch


class HealthCheckTest(APITestCase):
    """Test cases for health check endpoint."""
    
    def setUp(self):
        """Set up test data."""
        self.health_url = reverse('health:health_check')
    
    def test_health_check_success(self):
        """Test successful health check."""
        response = self.client.get(self.health_url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        self.assertEqual(data['status'], 'healthy')
        self.assertIn('timestamp', data)
        self.assertIn('version', data)
        self.assertIn('services', data)
        self.assertIn('response_time_ms', data)
        
        # Check services
        services = data['services']
        self.assertIn('database', services)
        self.assertIn('cache', services)
        
        # All services should be healthy
        for service_name, service_status in services.items():
            self.assertEqual(service_status['status'], 'healthy', 
                           f"Service {service_name} is not healthy")
    
    def test_health_check_unauthenticated_allowed(self):
        """Test that health check doesn't require authentication."""
        response = self.client.get(self.health_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    @patch('apps.health.views._check_database')
    def test_health_check_database_failure(self, mock_db_check):
        """Test health check when database is down."""
        mock_db_check.return_value = {
            'status': 'unhealthy', 
            'message': 'Database connection failed'
        }
        
        response = self.client.get(self.health_url)
        
        self.assertEqual(response.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)
        
        data = response.json()
        self.assertEqual(data['status'], 'degraded')
        self.assertEqual(data['services']['database']['status'], 'unhealthy')
    
    @patch('apps.health.views._check_cache')
    def test_health_check_cache_failure(self, mock_cache_check):
        """Test health check when cache is down."""
        mock_cache_check.return_value = {
            'status': 'unhealthy', 
            'message': 'Cache connection failed'
        }
        
        response = self.client.get(self.health_url)
        
        self.assertEqual(response.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)
        
        data = response.json()
        self.assertEqual(data['status'], 'degraded')
        self.assertEqual(data['services']['cache']['status'], 'unhealthy')
    
    def test_health_check_response_structure(self):
        """Test that health check response has the correct structure."""
        response = self.client.get(self.health_url)
        data = response.json()
        
        required_fields = ['status', 'timestamp', 'version', 'services', 'response_time_ms']
        for field in required_fields:
            self.assertIn(field, data, f"Missing required field: {field}")
        
        # Check services structure
        services = data['services']
        for service_name in ['database', 'cache']:
            self.assertIn(service_name, services)
            service = services[service_name]
            self.assertIn('status', service)
            self.assertIn('message', service)
            self.assertIn(service['status'], ['healthy', 'unhealthy'])
    
    def test_health_check_response_time(self):
        """Test that response time is recorded and reasonable."""
        response = self.client.get(self.health_url)
        data = response.json()
        
        response_time = data['response_time_ms']
        self.assertIsInstance(response_time, (int, float))
        self.assertGreater(response_time, 0)
        self.assertLess(response_time, 5000, "Health check took too long")  # Should be under 5 seconds


class HealthCheckIntegrationTest(TransactionTestCase):
    """Integration tests for health check with real database connections."""
    
    def test_database_connectivity(self):
        """Test actual database connectivity."""
        from apps.health.views import _check_database
        
        result = _check_database()
        self.assertEqual(result['status'], 'healthy')
        self.assertIn('Database connection successful', result['message'])
    
    def test_cache_connectivity(self):
        """Test actual cache connectivity."""
        from apps.health.views import _check_cache
        
        result = _check_cache()
        self.assertEqual(result['status'], 'healthy')
        self.assertIn('Cache connection successful', result['message'])
    
    def test_health_endpoint_with_real_services(self):
        """Test health endpoint with real service connections."""
        url = reverse('health:health_check')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        self.assertEqual(data['status'], 'healthy')
        
        # All services should be healthy in test environment
        services = data['services']
        for service_name, service_data in services.items():
            self.assertEqual(service_data['status'], 'healthy',
                           f"Service {service_name} failed: {service_data.get('message', '')}")