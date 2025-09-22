"""
Authentication tests for Electra Server.
Tests user registration, login, and token management.
"""

import pytest
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from apps.auth.models import User
from unittest.mock import patch
import json


class AuthenticationTestCase(TestCase):
    """Test cases for authentication endpoints."""
    
    def setUp(self):
        """Set up test client and test data."""
        self.client = APIClient()
        
        # Test user data
        self.valid_user_data = {
            'matric_number': 'KWU/SCI/001',
            'email': 'test@kwasu.edu.ng',
            'first_name': 'Test',
            'last_name': 'User',
            'password': 'testpass123!',
            'password_confirm': 'testpass123!',
            'faculty': 'Science',
            'department': 'Computer Science',
            'level': '300',
        }
        
        # Create a test user for login tests
        self.test_user = User.objects.create_user(
            username='KWU/SCI/002',
            matric_number='KWU/SCI/002',
            email='existing@kwasu.edu.ng',
            password='existingpass123!',
            first_name='Existing',
            last_name='User',
            faculty='Science',
            department='Mathematics',
            level='200',
            is_verified=True,
            is_active=True,
        )
    
    def test_user_registration_success(self):
        """Test successful user registration."""
        url = reverse('api:electra_auth:register')
        response = self.client.post(url, data=self.valid_user_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('status', response.data)
        self.assertEqual(response.data['status'], 'success')
        self.assertIn('data', response.data)
        
        # Check that tokens are returned
        token_data = response.data['data']
        self.assertIn('access', token_data)
        self.assertIn('refresh', token_data)
        self.assertIn('user', token_data)
        
        # Verify user was created in database
        self.assertTrue(User.objects.filter(matric_number='KWU/SCI/001').exists())
        
        created_user = User.objects.get(matric_number='KWU/SCI/001')
        self.assertEqual(created_user.email, 'test@kwasu.edu.ng')
        self.assertEqual(created_user.first_name, 'Test')
        self.assertTrue(created_user.check_password('testpass123!'))
    
    def test_user_registration_invalid_matric_format(self):
        """Test registration with invalid matric number format."""
        invalid_data = self.valid_user_data.copy()
        invalid_data['matric_number'] = 'INVALID_FORMAT'
        
        url = reverse('api:electra_auth:register')
        response = self.client.post(url, data=invalid_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('errors', response.data)
        self.assertIn('matric_number', response.data['errors'])
    
    def test_user_registration_password_mismatch(self):
        """Test registration with mismatched passwords."""
        invalid_data = self.valid_user_data.copy()
        invalid_data['password_confirm'] = 'different_password'
        
        url = reverse('api:electra_auth:register')
        response = self.client.post(url, data=invalid_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('errors', response.data)
        self.assertIn('password_confirm', response.data['errors'])
    
    def test_user_registration_duplicate_matric(self):
        """Test registration with duplicate matric number."""
        duplicate_data = self.valid_user_data.copy()
        duplicate_data['matric_number'] = 'KWU/SCI/002'  # Already exists
        duplicate_data['email'] = 'different@kwasu.edu.ng'
        
        url = reverse('api:electra_auth:register')
        response = self.client.post(url, data=duplicate_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('errors', response.data)
        self.assertIn('matric_number', response.data['errors'])
    
    def test_user_login_success(self):
        """Test successful user login."""
        url = reverse('api:electra_auth:login')
        login_data = {
            'matric_number': 'KWU/SCI/002',
            'password': 'existingpass123!',
        }
        
        response = self.client.post(url, data=login_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('status', response.data)
        self.assertEqual(response.data['status'], 'success')
        self.assertIn('data', response.data)
        
        # Check that tokens are returned
        token_data = response.data['data']
        self.assertIn('access', token_data)
        self.assertIn('refresh', token_data)
        self.assertIn('user', token_data)
        
        # Verify user data in response
        user_data = token_data['user']
        self.assertEqual(user_data['matric_number'], 'KWU/SCI/002')
        self.assertEqual(user_data['email'], 'existing@kwasu.edu.ng')
    
    def test_user_login_invalid_credentials(self):
        """Test login with invalid credentials."""
        url = reverse('api:electra_auth:login')
        login_data = {
            'matric_number': 'KWU/SCI/002',
            'password': 'wrong_password',
        }
        
        response = self.client.post(url, data=login_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('status', response.data)
        self.assertEqual(response.data['status'], 'error')
        self.assertIn('errors', response.data)
    
    def test_user_login_nonexistent_user(self):
        """Test login with non-existent user."""
        url = reverse('api:electra_auth:login')
        login_data = {
            'matric_number': 'KWU/SCI/999',
            'password': 'somepassword',
        }
        
        response = self.client.post(url, data=login_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('status', response.data)
        self.assertEqual(response.data['status'], 'error')
    
    def test_get_user_profile_authenticated(self):
        """Test getting user profile when authenticated."""
        # Login first to get token
        login_url = reverse('api:electra_auth:login')
        login_data = {
            'matric_number': 'KWU/SCI/002',
            'password': 'existingpass123!',
        }
        login_response = self.client.post(login_url, data=login_data, format='json')
        access_token = login_response.data['data']['access']
        
        # Get profile
        profile_url = reverse('api:electra_auth:profile')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')
        response = self.client.get(profile_url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('status', response.data)
        self.assertEqual(response.data['status'], 'success')
        self.assertIn('data', response.data)
        
        user_data = response.data['data']
        self.assertEqual(user_data['matric_number'], 'KWU/SCI/002')
        self.assertEqual(user_data['email'], 'existing@kwasu.edu.ng')
    
    def test_get_user_profile_unauthenticated(self):
        """Test getting user profile without authentication."""
        profile_url = reverse('api:electra_auth:profile')
        response = self.client.get(profile_url)
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    @patch('apps.auth.views.logger')
    def test_logout_success(self, mock_logger):
        """Test successful logout."""
        # Login first to get tokens
        login_url = reverse('api:electra_auth:login')
        login_data = {
            'matric_number': 'KWU/SCI/002',
            'password': 'existingpass123!',
        }
        login_response = self.client.post(login_url, data=login_data, format='json')
        access_token = login_response.data['data']['access']
        refresh_token = login_response.data['data']['refresh']
        
        # Logout
        logout_url = reverse('api:electra_auth:logout')
        logout_data = {'refresh': refresh_token}
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')
        response = self.client.post(logout_url, data=logout_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('status', response.data)
        self.assertEqual(response.data['status'], 'success')
        
        # Verify logout was logged
        mock_logger.info.assert_called()


@pytest.mark.django_db
class TestAuthenticationPytest:
    """Pytest version of authentication tests."""
    
    @pytest.fixture
    def api_client(self):
        return APIClient()
    
    @pytest.fixture
    def test_user_data(self):
        return {
            'matric_number': 'KWU/SCI/TEST',
            'email': 'pytest@kwasu.edu.ng',
            'first_name': 'Pytest',
            'last_name': 'User',
            'password': 'pytest123!',
            'password_confirm': 'pytest123!',
            'faculty': 'Science',
            'department': 'Computer Science',
            'level': '300',
        }
    
    def test_registration_creates_user(self, api_client, test_user_data):
        """Test that registration creates a user in the database."""
        url = reverse('api:electra_auth:register')
        response = api_client.post(url, data=test_user_data, format='json')
        
        assert response.status_code == 201
        assert User.objects.filter(matric_number='KWU/SCI/TEST').exists()
    
    def test_registration_returns_tokens(self, api_client, test_user_data):
        """Test that successful registration returns JWT tokens."""
        url = reverse('api:electra_auth:register')
        response = api_client.post(url, data=test_user_data, format='json')
        
        assert response.status_code == 201
        data = response.json()
        assert 'data' in data
        assert 'access' in data['data']
        assert 'refresh' in data['data']
    
    def test_login_with_valid_credentials(self, api_client):
        """Test login with valid credentials."""
        # Create test user
        User.objects.create_user(
            username='PYTEST001',
            matric_number='PYTEST001',
            email='pytest_login@kwasu.edu.ng',
            password='pytest_pass123!',
            first_name='Login',
            last_name='Test',
            is_verified=True,
            is_active=True,
        )
        
        url = reverse('api:electra_auth:login')
        login_data = {
            'matric_number': 'PYTEST001',
            'password': 'pytest_pass123!',
        }
        
        response = api_client.post(url, data=login_data, format='json')
        
        assert response.status_code == 200
        data = response.json()
        assert data['status'] == 'success'
        assert 'access' in data['data']