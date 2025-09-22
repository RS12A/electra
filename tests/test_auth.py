"""
Tests for authentication endpoints and functionality.
"""
import json
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.urls import reverse
from django.core import mail
from rest_framework.test import APITestCase
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from unittest.mock import patch, MagicMock

User = get_user_model()


class AuthenticationTest(APITestCase):
    """Test cases for authentication endpoints."""
    
    def setUp(self):
        """Set up test data."""
        self.register_url = reverse('auth:register')
        self.login_url = reverse('auth:login')
        self.logout_url = reverse('auth:logout')
        self.profile_url = reverse('auth:profile')
        self.token_refresh_url = reverse('auth:token_refresh')
        
        # Test user data
        self.user_data = {
            'username': 'testuser',
            'email': 'test@electra.com',
            'password': 'TestPassword123',
            'password_confirm': 'TestPassword123',
            'first_name': 'Test',
            'last_name': 'User',
            'matric_staff_id': 'U1234567',
            'phone_number': '1234567890',
            'is_staff_member': False
        }
        
        # Create a test user for login tests
        self.test_user = User.objects.create_user(
            username='existing_user',
            email='existing@electra.com',
            password='ExistingPassword123',
            first_name='Existing',
            last_name='User',
            matric_staff_id='U7654321'
        )
    
    def test_user_registration_success(self):
        """Test successful user registration."""
        response = self.client.post(self.register_url, self.user_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        data = response.json()
        self.assertIn('message', data)
        self.assertIn('tokens', data)
        self.assertIn('user', data)
        
        # Check tokens
        tokens = data['tokens']
        self.assertIn('access', tokens)
        self.assertIn('refresh', tokens)
        
        # Check user data
        user_data = data['user']
        self.assertEqual(user_data['email'], self.user_data['email'])
        self.assertEqual(user_data['first_name'], self.user_data['first_name'])
        self.assertEqual(user_data['matric_staff_id'], self.user_data['matric_staff_id'])
        
        # Verify user was created in database
        user = User.objects.get(email=self.user_data['email'])
        self.assertTrue(user.check_password(self.user_data['password']))
        self.assertEqual(user.matric_staff_id, self.user_data['matric_staff_id'].upper())
    
    def test_user_registration_password_mismatch(self):
        """Test registration with password mismatch."""
        invalid_data = self.user_data.copy()
        invalid_data['password_confirm'] = 'DifferentPassword123'
        
        response = self.client.post(self.register_url, invalid_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
        data = response.json()
        self.assertIn('error', data)
        self.assertIn('details', data)
        self.assertIn('password_confirm', data['details'])
    
    def test_user_registration_duplicate_email(self):
        """Test registration with existing email."""
        duplicate_data = self.user_data.copy()
        duplicate_data['email'] = self.test_user.email
        
        response = self.client.post(self.register_url, duplicate_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
        data = response.json()
        self.assertIn('error', data)
        self.assertIn('details', data)
        self.assertIn('email', data['details'])
    
    def test_user_registration_duplicate_matric_id(self):
        """Test registration with existing matric/staff ID."""
        duplicate_data = self.user_data.copy()
        duplicate_data['matric_staff_id'] = self.test_user.matric_staff_id
        
        response = self.client.post(self.register_url, duplicate_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
        data = response.json()
        self.assertIn('error', data)
        self.assertIn('details', data)
        self.assertIn('matric_staff_id', data['details'])
    
    def test_user_registration_invalid_matric_id(self):
        """Test registration with invalid matric/staff ID format."""
        invalid_data = self.user_data.copy()
        invalid_data['matric_staff_id'] = 'invalid123'
        
        response = self.client.post(self.register_url, invalid_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    @patch('apps.auth_app.serializers.send_mail')
    def test_user_registration_email_sent(self, mock_send_mail):
        """Test that verification email is sent after registration."""
        mock_send_mail.return_value = True
        
        response = self.client.post(self.register_url, self.user_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Check that send_mail was called
        mock_send_mail.assert_called_once()
        
        # Check user has verification token
        user = User.objects.get(email=self.user_data['email'])
        self.assertIsNotNone(user.email_verification_token)
        self.assertFalse(user.email_verified)
    
    def test_user_login_success(self):
        """Test successful user login."""
        login_data = {
            'email': self.test_user.email,
            'password': 'ExistingPassword123'
        }
        
        response = self.client.post(self.login_url, login_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        self.assertIn('message', data)
        self.assertIn('tokens', data)
        self.assertIn('user', data)
        
        # Check tokens
        tokens = data['tokens']
        self.assertIn('access', tokens)
        self.assertIn('refresh', tokens)
        
        # Check user data
        user_data = data['user']
        self.assertEqual(user_data['email'], self.test_user.email)
    
    def test_user_login_invalid_credentials(self):
        """Test login with invalid credentials."""
        login_data = {
            'email': self.test_user.email,
            'password': 'WrongPassword'
        }
        
        response = self.client.post(self.login_url, login_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        
        data = response.json()
        self.assertIn('error', data)
        self.assertIn('message', data)
    
    def test_user_login_nonexistent_user(self):
        """Test login with non-existent user."""
        login_data = {
            'email': 'nonexistent@electra.com',
            'password': 'SomePassword123'
        }
        
        response = self.client.post(self.login_url, login_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_user_logout_success(self):
        """Test successful user logout."""
        # First login to get tokens
        login_data = {
            'email': self.test_user.email,
            'password': 'ExistingPassword123'
        }
        login_response = self.client.post(self.login_url, login_data, format='json')
        tokens = login_response.json()['tokens']
        
        # Set authorization header
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {tokens["access"]}')
        
        # Logout with refresh token
        logout_data = {'refresh': tokens['refresh']}
        response = self.client.post(self.logout_url, logout_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        self.assertIn('message', data)
    
    def test_user_logout_invalid_token(self):
        """Test logout with invalid refresh token."""
        # Authenticate user
        self.client.force_authenticate(user=self.test_user)
        
        logout_data = {'refresh': 'invalid_token'}
        response = self.client.post(self.logout_url, logout_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_profile_view_authenticated(self):
        """Test profile view for authenticated user."""
        self.client.force_authenticate(user=self.test_user)
        
        response = self.client.get(self.profile_url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        self.assertIn('user', data)
        
        user_data = data['user']
        self.assertEqual(user_data['email'], self.test_user.email)
        self.assertEqual(user_data['matric_staff_id'], self.test_user.matric_staff_id)
    
    def test_profile_view_unauthenticated(self):
        """Test profile view for unauthenticated user."""
        response = self.client.get(self.profile_url)
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_profile_update_success(self):
        """Test successful profile update."""
        self.client.force_authenticate(user=self.test_user)
        
        update_data = {
            'first_name': 'Updated',
            'last_name': 'Name',
            'phone_number': '9876543210'
        }
        
        response = self.client.patch(self.profile_url + 'update/', update_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        self.assertIn('message', data)
        self.assertIn('user', data)
        
        # Verify changes in database
        self.test_user.refresh_from_db()
        self.assertEqual(self.test_user.first_name, 'Updated')
        self.assertEqual(self.test_user.last_name, 'Name')
        self.assertEqual(self.test_user.phone_number, '9876543210')
    
    def test_token_refresh_success(self):
        """Test successful token refresh."""
        # Get initial tokens
        refresh = RefreshToken.for_user(self.test_user)
        
        refresh_data = {'refresh': str(refresh)}
        response = self.client.post(self.token_refresh_url, refresh_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        self.assertIn('access', data)
    
    def test_token_refresh_invalid_token(self):
        """Test token refresh with invalid token."""
        refresh_data = {'refresh': 'invalid_refresh_token'}
        response = self.client.post(self.token_refresh_url, refresh_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class UserModelTest(TestCase):
    """Test cases for User model."""
    
    def test_user_creation(self):
        """Test creating a user with valid data."""
        user = User.objects.create_user(
            username='testuser',
            email='test@electra.com',
            password='TestPassword123',
            first_name='Test',
            last_name='User',
            matric_staff_id='U1234567'
        )
        
        self.assertEqual(user.email, 'test@electra.com')
        self.assertEqual(user.matric_staff_id, 'U1234567')
        self.assertTrue(user.check_password('TestPassword123'))
        self.assertFalse(user.email_verified)
        self.assertTrue(user.is_active)
        self.assertFalse(user.is_staff)
    
    def test_user_str_representation(self):
        """Test user string representation."""
        user = User(email='test@electra.com', matric_staff_id='U1234567')
        self.assertEqual(str(user), 'test@electra.com (U1234567)')
    
    def test_user_full_name(self):
        """Test user full name method."""
        user = User(first_name='Test', last_name='User')
        self.assertEqual(user.get_full_name(), 'Test User')
    
    def test_matric_id_normalization(self):
        """Test that matric ID is normalized to uppercase."""
        user = User(email='test@electra.com', matric_staff_id='u1234567')
        user.clean()
        self.assertEqual(user.matric_staff_id, 'U1234567')
    
    def test_matric_id_validation(self):
        """Test matric ID validation."""
        from django.core.exceptions import ValidationError
        from apps.auth_app.models import validate_matric_staff_id
        
        # Valid formats
        valid_ids = ['U1234567', 'ST123456789', '123456789', 'A1234567']
        for valid_id in valid_ids:
            try:
                validate_matric_staff_id(valid_id)
            except ValidationError:
                self.fail(f"Valid ID {valid_id} raised ValidationError")
        
        # Invalid formats
        invalid_ids = ['123', 'TOOLONG12345678901', 'U12', '']
        for invalid_id in invalid_ids:
            with self.assertRaises(ValidationError):
                validate_matric_staff_id(invalid_id)