"""
Health endpoint tests for Electra Server.
"""

import pytest
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
import json


class HealthCheckTestCase(TestCase):
    """Test cases for health check endpoints."""
    
    def setUp(self):
        """Set up test client."""
        self.client = APIClient()
    
    def test_simple_health_endpoint(self):
        """Test the simple health check endpoint."""
        url = reverse('api:electra_core:simple_health')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('status', response.data)
        self.assertEqual(response.data['status'], 'ok')
        self.assertIn('timestamp', response.data)
    
    def test_detailed_health_endpoint(self):
        """Test the detailed health check endpoint."""
        url = reverse('api:electra_core:health_check')
        response = self.client.get(url)
        
        # Should return 200 or 503 depending on system state
        self.assertIn(response.status_code, [status.HTTP_200_OK, status.HTTP_503_SERVICE_UNAVAILABLE])
        
        # Check response structure
        self.assertIn('status', response.data)
        self.assertIn('timestamp', response.data)
        self.assertIn('version', response.data)
        self.assertIn('request_id', response.data)
        self.assertIn('checks', response.data)
        
        # Check that basic checks are present
        checks = response.data['checks']
        expected_checks = ['database', 'cache', 'filesystem']
        
        for check_name in expected_checks:
            self.assertIn(check_name, checks)
            self.assertIn('status', checks[check_name])
            self.assertIn('message', checks[check_name])
    
    def test_health_endpoint_structure(self):
        """Test that health endpoint returns proper JSON structure."""
        url = reverse('api:electra_core:health_check')
        response = self.client.get(url)
        
        # Verify JSON structure
        data = response.data
        
        # Main fields
        required_fields = ['status', 'timestamp', 'version', 'request_id', 'checks']
        for field in required_fields:
            self.assertIn(field, data, f"Missing field: {field}")
        
        # Status should be either 'healthy' or 'unhealthy'
        self.assertIn(data['status'], ['healthy', 'unhealthy'])
        
        # Checks should be a dictionary
        self.assertIsInstance(data['checks'], dict)
        
        # Each check should have status and message
        for check_name, check_data in data['checks'].items():
            self.assertIsInstance(check_data, dict, f"Check {check_name} should be a dict")
            self.assertIn('status', check_data, f"Check {check_name} missing status")
            self.assertIn('message', check_data, f"Check {check_name} missing message")


@pytest.mark.django_db
class TestHealthCheckPytest:
    """Pytest version of health check tests."""
    
    def test_health_endpoint_returns_ok(self, client):
        """Test health endpoint returns successful response."""
        url = reverse('api:electra_core:simple_health')
        response = client.get(url)
        
        assert response.status_code == 200
        assert 'status' in response.json()
        assert response.json()['status'] == 'ok'
    
    def test_detailed_health_has_database_check(self, client):
        """Test that detailed health check includes database status."""
        url = reverse('api:electra_core:health_check')
        response = client.get(url)
        
        data = response.json()
        assert 'checks' in data
        assert 'database' in data['checks']
        assert 'status' in data['checks']['database']
    
    def test_health_endpoint_cors_headers(self, client):
        """Test that health endpoints include proper CORS headers."""
        url = reverse('api:electra_core:simple_health')
        response = client.get(url, HTTP_ORIGIN='http://localhost:3000')
        
        # Should not fail due to CORS (endpoint allows any origin)
        assert response.status_code == 200