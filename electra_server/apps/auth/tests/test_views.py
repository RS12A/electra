"""
Integration tests for authentication views.

This module tests all the API endpoints for registration, login,
password recovery, and profile management.
"""
from unittest.mock import patch, MagicMock
from datetime import timedelta

from django.test import TestCase
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase, APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from ..models import User, UserRole, PasswordResetOTP, LoginAttempt
from .factories import (
    StudentUserFactory, StaffUserFactory, AdminUserFactory,
    ElectoralCommitteeUserFactory, PasswordResetOTPFactory
)


class UserRegistrationViewTest(APITestCase):
    """Test cases for user registration endpoint."""
    
    def setUp(self):
        self.url = reverse('auth:register')
        self.valid_student_data = {
            'email': 'student@example.com',
            'password': 'TestPassword123',
            'password_confirm': 'TestPassword123',
            'full_name': 'Test Student',
            'role': UserRole.STUDENT,
            'matric_number': 'U1234567'
        }
        self.valid_staff_data = {
            'email': 'staff@example.com',
            'password': 'TestPassword123',
            'password_confirm': 'TestPassword123',
            'full_name': 'Test Staff',
            'role': UserRole.STAFF,
            'staff_id': 'ST123456'
        }
    
    def test_student_registration_success(self):
        """Test successful student registration."""
        response = self.client.post(self.url, self.valid_student_data, format='json')
        
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
        self.assertEqual(user_data['email'], self.valid_student_data['email'])
        self.assertEqual(user_data['full_name'], self.valid_student_data['full_name'])
        self.assertEqual(user_data['role'], UserRole.STUDENT)
        
        # Verify user was created in database
        user = User.objects.get(email=self.valid_student_data['email'])
        self.assertTrue(user.check_password('TestPassword123'))
        self.assertEqual(user.matric_number, 'U1234567')
        self.assertIsNone(user.staff_id)
    
    def test_staff_registration_success(self):
        """Test successful staff registration."""
        response = self.client.post(self.url, self.valid_staff_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Verify user was created in database
        user = User.objects.get(email=self.valid_staff_data['email'])
        self.assertEqual(user.staff_id, 'ST123456')
        self.assertIsNone(user.matric_number)
    
    def test_registration_password_mismatch(self):
        """Test registration with password mismatch."""
        invalid_data = self.valid_student_data.copy()
        invalid_data['password_confirm'] = 'DifferentPassword123'
        
        response = self.client.post(self.url, invalid_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
        data = response.json()
        self.assertIn('error', data)
        self.assertIn('details', data)
        self.assertIn('password_confirm', data['details'])
    
    def test_registration_duplicate_email(self):
        """Test registration with existing email."""
        StudentUserFactory(email='duplicate@example.com')
        
        duplicate_data = self.valid_student_data.copy()
        duplicate_data['email'] = 'duplicate@example.com'
        
        response = self.client.post(self.url, duplicate_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_student_registration_without_matric_number(self):
        """Test student registration without matric number."""
        invalid_data = self.valid_student_data.copy()
        del invalid_data['matric_number']
        
        response = self.client.post(self.url, invalid_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
        data = response.json()
        self.assertIn('matric_number', data['details'])
    
    def test_staff_registration_without_staff_id(self):
        """Test staff registration without staff ID."""
        invalid_data = self.valid_staff_data.copy()
        del invalid_data['staff_id']
        
        response = self.client.post(self.url, invalid_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
        data = response.json()
        self.assertIn('staff_id', data['details'])
    
    def test_registration_weak_password(self):
        """Test registration with weak password."""
        invalid_data = self.valid_student_data.copy()
        invalid_data['password'] = '123'
        invalid_data['password_confirm'] = '123'
        
        response = self.client.post(self.url, invalid_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class UserLoginViewTest(APITestCase):
    """Test cases for user login endpoint."""
    
    def setUp(self):
        self.url = reverse('auth:login')
        self.student = StudentUserFactory(
            email='student@example.com',
            matric_number='U1234567'
        )
        self.staff = StaffUserFactory(
            email='staff@example.com',
            staff_id='ST123456'
        )
        self.password = 'TestPassword123'
        # Set same password for both users
        self.student.set_password(self.password)
        self.student.save()
        self.staff.set_password(self.password)
        self.staff.save()
    
    def test_login_with_email_success(self):
        """Test successful login with email."""
        login_data = {
            'identifier': self.student.email,
            'password': self.password
        }
        
        response = self.client.post(self.url, login_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        self.assertIn('message', data)
        self.assertIn('tokens', data)
        self.assertIn('user', data)
        
        # Check that login attempt was recorded
        self.assertTrue(
            LoginAttempt.objects.filter(
                email=self.student.email,
                success=True
            ).exists()
        )
    
    def test_login_with_matric_number_success(self):
        """Test successful login with matric number."""
        login_data = {
            'identifier': self.student.matric_number,
            'password': self.password
        }
        
        response = self.client.post(self.url, login_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    def test_login_with_staff_id_success(self):
        """Test successful login with staff ID."""
        login_data = {
            'identifier': self.staff.staff_id,
            'password': self.password
        }
        
        response = self.client.post(self.url, login_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    def test_login_invalid_credentials(self):
        """Test login with invalid credentials."""
        login_data = {
            'identifier': self.student.email,
            'password': 'WrongPassword'
        }
        
        response = self.client.post(self.url, login_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        
        # Check that failed login attempt was recorded
        self.assertTrue(
            LoginAttempt.objects.filter(
                email=self.student.email,
                success=False
            ).exists()
        )
    
    def test_login_nonexistent_user(self):
        """Test login with nonexistent user."""
        login_data = {
            'identifier': 'nonexistent@example.com',
            'password': self.password
        }
        
        response = self.client.post(self.url, login_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_login_inactive_user(self):
        """Test login with inactive user."""
        self.student.is_active = False
        self.student.save()
        
        login_data = {
            'identifier': self.student.email,
            'password': self.password
        }
        
        response = self.client.post(self.url, login_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_login_updates_last_login(self):
        """Test that successful login updates last_login."""
        old_last_login = self.student.last_login
        
        login_data = {
            'identifier': self.student.email,
            'password': self.password
        }
        
        response = self.client.post(self.url, login_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        self.student.refresh_from_db()
        self.assertNotEqual(self.student.last_login, old_last_login)
        self.assertIsNotNone(self.student.last_login)


class UserLogoutViewTest(APITestCase):
    """Test cases for user logout endpoint."""
    
    def setUp(self):
        self.url = reverse('auth:logout')
        self.user = StudentUserFactory()
        self.refresh_token = RefreshToken.for_user(self.user)
        self.client.force_authenticate(user=self.user)
    
    def test_logout_success(self):
        """Test successful logout."""
        logout_data = {
            'refresh': str(self.refresh_token)
        }
        
        response = self.client.post(self.url, logout_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        self.assertIn('message', data)
    
    def test_logout_invalid_token(self):
        """Test logout with invalid token."""
        logout_data = {
            'refresh': 'invalid_token'
        }
        
        response = self.client.post(self.url, logout_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_logout_unauthenticated(self):
        """Test logout without authentication."""
        self.client.force_authenticate(user=None)
        
        logout_data = {
            'refresh': str(self.refresh_token)
        }
        
        response = self.client.post(self.url, logout_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class UserProfileViewTest(APITestCase):
    """Test cases for user profile endpoints."""
    
    def setUp(self):
        self.profile_url = reverse('auth:profile')
        self.user = StudentUserFactory(full_name='Original Name')
        self.client.force_authenticate(user=self.user)
    
    def test_get_profile_success(self):
        """Test retrieving user profile."""
        response = self.client.get(self.profile_url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        self.assertEqual(data['email'], self.user.email)
        self.assertEqual(data['full_name'], self.user.full_name)
        self.assertEqual(data['role'], self.user.role)
    
    def test_update_profile_success(self):
        """Test updating user profile."""
        update_data = {
            'full_name': 'Updated Name'
        }
        
        response = self.client.patch(self.profile_url, update_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        self.assertEqual(data['user']['full_name'], 'Updated Name')
        
        self.user.refresh_from_db()
        self.assertEqual(self.user.full_name, 'Updated Name')
    
    def test_get_profile_unauthenticated(self):
        """Test retrieving profile without authentication."""
        self.client.force_authenticate(user=None)
        
        response = self.client.get(self.profile_url)
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class PasswordResetViewTest(APITestCase):
    """Test cases for password reset endpoints."""
    
    def setUp(self):
        self.request_url = reverse('auth:password_reset_request')
        self.confirm_url = reverse('auth:password_reset_confirm')
        self.user = StudentUserFactory(email='user@example.com')
    
    @patch('electra_server.apps.auth.serializers.send_mail')
    def test_password_reset_request_success(self, mock_send_mail):
        """Test successful password reset request."""
        mock_send_mail.return_value = True
        
        request_data = {
            'email': self.user.email
        }
        
        response = self.client.post(self.request_url, request_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        self.assertIn('message', data)
        
        # Check that OTP was created
        self.assertTrue(
            PasswordResetOTP.objects.filter(user=self.user).exists()
        )
        
        # Check that email was sent
        mock_send_mail.assert_called_once()
    
    def test_password_reset_request_nonexistent_email(self):
        """Test password reset request for nonexistent email."""
        request_data = {
            'email': 'nonexistent@example.com'
        }
        
        response = self.client.post(self.request_url, request_data, format='json')
        
        # Should still return success to avoid email enumeration
        self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    def test_password_reset_confirm_success(self):
        """Test successful password reset confirmation."""
        # Create OTP
        otp = PasswordResetOTP.objects.create_otp(user=self.user)
        
        confirm_data = {
            'email': self.user.email,
            'otp_code': otp.otp_code,
            'new_password': 'NewPassword123',
            'new_password_confirm': 'NewPassword123'
        }
        
        response = self.client.post(self.confirm_url, confirm_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Check that password was changed
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('NewPassword123'))
        
        # Check that OTP was marked as used
        otp.refresh_from_db()
        self.assertTrue(otp.is_used)
    
    def test_password_reset_confirm_invalid_otp(self):
        """Test password reset confirmation with invalid OTP."""
        confirm_data = {
            'email': self.user.email,
            'otp_code': '000000',
            'new_password': 'NewPassword123',
            'new_password_confirm': 'NewPassword123'
        }
        
        response = self.client.post(self.confirm_url, confirm_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
        data = response.json()
        self.assertIn('otp_code', data['details'])
    
    def test_password_reset_confirm_password_mismatch(self):
        """Test password reset confirmation with password mismatch."""
        otp = PasswordResetOTP.objects.create_otp(user=self.user)
        
        confirm_data = {
            'email': self.user.email,
            'otp_code': otp.otp_code,
            'new_password': 'NewPassword123',
            'new_password_confirm': 'DifferentPassword123'
        }
        
        response = self.client.post(self.confirm_url, confirm_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
        data = response.json()
        self.assertIn('new_password_confirm', data['details'])
    
    def test_password_reset_confirm_expired_otp(self):
        """Test password reset confirmation with expired OTP."""
        # Create expired OTP
        otp = PasswordResetOTPFactory(
            user=self.user,
            expires_at=timezone.now() - timedelta(minutes=1)
        )
        
        confirm_data = {
            'email': self.user.email,
            'otp_code': otp.otp_code,
            'new_password': 'NewPassword123',
            'new_password_confirm': 'NewPassword123'
        }
        
        response = self.client.post(self.confirm_url, confirm_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class ChangePasswordViewTest(APITestCase):
    """Test cases for change password endpoint."""
    
    def setUp(self):
        self.url = reverse('auth:change_password')
        self.user = StudentUserFactory()
        self.password = 'CurrentPassword123'
        self.user.set_password(self.password)
        self.user.save()
        self.client.force_authenticate(user=self.user)
    
    def test_change_password_success(self):
        """Test successful password change."""
        change_data = {
            'current_password': self.password,
            'new_password': 'NewPassword123',
            'new_password_confirm': 'NewPassword123'
        }
        
        response = self.client.post(self.url, change_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Check that password was changed
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('NewPassword123'))
        self.assertFalse(self.user.check_password(self.password))
    
    def test_change_password_wrong_current(self):
        """Test password change with wrong current password."""
        change_data = {
            'current_password': 'WrongPassword',
            'new_password': 'NewPassword123',
            'new_password_confirm': 'NewPassword123'
        }
        
        response = self.client.post(self.url, change_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
        data = response.json()
        self.assertIn('current_password', data['details'])
    
    def test_change_password_mismatch(self):
        """Test password change with password mismatch."""
        change_data = {
            'current_password': self.password,
            'new_password': 'NewPassword123',
            'new_password_confirm': 'DifferentPassword123'
        }
        
        response = self.client.post(self.url, change_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
        data = response.json()
        self.assertIn('new_password_confirm', data['details'])
    
    def test_change_password_unauthenticated(self):
        """Test password change without authentication."""
        self.client.force_authenticate(user=None)
        
        change_data = {
            'current_password': self.password,
            'new_password': 'NewPassword123',
            'new_password_confirm': 'NewPassword123'
        }
        
        response = self.client.post(self.url, change_data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class PermissionTest(APITestCase):
    """Test cases for permission-based endpoints."""
    
    def setUp(self):
        self.student = StudentUserFactory()
        self.staff = StaffUserFactory()
        self.admin = AdminUserFactory()
        self.committee = ElectoralCommitteeUserFactory()
        
        self.user_list_url = reverse('auth:user_list')
        self.stats_url = reverse('auth:user_stats')
    
    def test_user_list_admin_access(self):
        """Test that admin can access user list."""
        self.client.force_authenticate(user=self.admin)
        
        response = self.client.get(self.user_list_url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    def test_user_list_committee_access(self):
        """Test that electoral committee can access user list."""
        self.client.force_authenticate(user=self.committee)
        
        response = self.client.get(self.user_list_url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    def test_user_list_student_denied(self):
        """Test that students cannot access user list."""
        self.client.force_authenticate(user=self.student)
        
        response = self.client.get(self.user_list_url)
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_user_list_staff_denied(self):
        """Test that staff cannot access user list."""
        self.client.force_authenticate(user=self.staff)
        
        response = self.client.get(self.user_list_url)
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_stats_admin_access(self):
        """Test that admin can access user statistics."""
        self.client.force_authenticate(user=self.admin)
        
        response = self.client.get(self.stats_url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        self.assertIn('total_users', data)
        self.assertIn('active_users', data)
        self.assertIn('users_by_role', data)


class AuthStatusViewTest(APITestCase):
    """Test cases for authentication status endpoint."""
    
    def setUp(self):
        self.url = reverse('auth:auth_status')
        self.user = StudentUserFactory()
    
    def test_auth_status_authenticated(self):
        """Test authentication status for authenticated user."""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.get(self.url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        self.assertTrue(data['authenticated'])
        self.assertEqual(data['user']['email'], self.user.email)
    
    def test_auth_status_unauthenticated(self):
        """Test authentication status for unauthenticated user."""
        response = self.client.get(self.url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        self.assertFalse(data['authenticated'])
        self.assertIsNone(data['user'])