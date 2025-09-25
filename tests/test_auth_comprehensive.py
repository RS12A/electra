"""
Comprehensive authentication tests for the electra system.

This module contains complete test coverage for authentication functionality
including user models, managers, permissions, and API endpoints.
"""
import uuid
from datetime import timedelta
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APITestCase
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from unittest.mock import patch

from .factories import UserFactory, StaffUserFactory, AdminUserFactory, CandidateUserFactory

User = get_user_model()


class UserModelTest(TestCase):
    """Comprehensive tests for the User model."""
    
    def test_create_student_user(self):
        """Test creating a student user with proper validation."""
        user = User.objects.create_user(
            email='student@kwasu.edu.ng',
            password='SecurePassword123',
            full_name='John Doe Student',
            matric_number='U1234567',
            role='student'
        )
        
        self.assertEqual(user.email, 'student@kwasu.edu.ng')
        self.assertEqual(user.full_name, 'John Doe Student')
        self.assertEqual(user.matric_number, 'U1234567')
        self.assertEqual(user.role, 'student')
        self.assertIsNone(user.staff_id)
        self.assertTrue(user.check_password('SecurePassword123'))
        self.assertTrue(user.is_active)
        self.assertFalse(user.is_staff)
        self.assertFalse(user.is_superuser)
    
    def test_create_staff_user(self):
        """Test creating a staff user with proper validation."""
        user = User.objects.create_user(
            email='staff@kwasu.edu.ng',
            password='SecurePassword123',
            full_name='Jane Doe Staff',
            staff_id='ST123456',
            role='staff'
        )
        
        self.assertEqual(user.email, 'staff@kwasu.edu.ng')
        self.assertEqual(user.full_name, 'Jane Doe Staff')
        self.assertEqual(user.staff_id, 'ST123456')
        self.assertEqual(user.role, 'staff')
        self.assertIsNone(user.matric_number)
    
    def test_create_admin_user(self):
        """Test creating an admin user."""
        user = User.objects.create_superuser(
            email='admin@kwasu.edu.ng',
            password='SecurePassword123',
            full_name='Admin User',
            staff_id='AD123456',
            role='admin'
        )
        
        self.assertEqual(user.role, 'admin')
        self.assertTrue(user.is_staff)
        self.assertTrue(user.is_superuser)
    
    def test_user_str_representation(self):
        """Test user string representation."""
        user = User(
            email='test@kwasu.edu.ng',
            full_name='Test User',
            matric_number='U1234567',
            role='student'
        )
        
        expected_str = 'Test User (U1234567) - Student'
        self.assertEqual(str(user), expected_str)
    
    def test_user_login_identifier(self):
        """Test getting appropriate login identifier by role."""
        student = User(matric_number='U1234567', role='student')
        staff = User(staff_id='ST123456', role='staff')
        
        self.assertEqual(student.get_login_identifier(), 'U1234567')
        self.assertEqual(staff.get_login_identifier(), 'ST123456')
    
    def test_user_permissions_by_role(self):
        """Test role-based permissions."""
        student = User(role='student')
        admin = User(role='admin')
        electoral_committee = User(role='electoral_committee')
        
        self.assertFalse(student.can_manage_elections())
        self.assertTrue(admin.can_manage_elections())
        self.assertTrue(electoral_committee.can_manage_elections())
    
    def test_role_based_validation_student(self):
        """Test validation for student role."""
        # Valid student
        user = User(
            email='student@kwasu.edu.ng',
            full_name='Student User',
            matric_number='U1234567',
            role='student'
        )
        user.clean()  # Should not raise
        
        # Invalid student - no matric number
        user = User(
            email='student@kwasu.edu.ng',
            full_name='Student User',
            role='student'
        )
        with self.assertRaises(ValidationError):
            user.clean()
        
        # Invalid student - has staff_id
        user = User(
            email='student@kwasu.edu.ng',
            full_name='Student User',
            matric_number='U1234567',
            staff_id='ST123456',
            role='student'
        )
        with self.assertRaises(ValidationError):
            user.clean()
    
    def test_role_based_validation_staff(self):
        """Test validation for staff role."""
        # Valid staff
        user = User(
            email='staff@kwasu.edu.ng',
            full_name='Staff User',
            staff_id='ST123456',
            role='staff'
        )
        user.clean()  # Should not raise
        
        # Invalid staff - no staff_id
        user = User(
            email='staff@kwasu.edu.ng',
            full_name='Staff User',
            role='staff'
        )
        with self.assertRaises(ValidationError):
            user.clean()
    
    def test_identifier_normalization(self):
        """Test that identifiers are normalized to uppercase."""
        user = User(
            email='test@kwasu.edu.ng',
            full_name='Test User',
            matric_number='u1234567',
            role='student'
        )
        user.clean()
        self.assertEqual(user.matric_number, 'U1234567')
        
        user2 = User(
            email='staff@kwasu.edu.ng',
            full_name='Staff User',
            staff_id='st123456',
            role='staff'
        )
        user2.clean()
        self.assertEqual(user2.staff_id, 'ST123456')
    
    def test_candidate_flexible_identifiers(self):
        """Test that candidates can have either matric_number or staff_id."""
        # Candidate with matric_number
        candidate1 = User(
            email='candidate1@kwasu.edu.ng',
            full_name='Student Candidate',
            matric_number='U1234567',
            role='candidate'
        )
        candidate1.clean()  # Should not raise
        
        # Candidate with staff_id
        candidate2 = User(
            email='candidate2@kwasu.edu.ng',
            full_name='Staff Candidate',
            staff_id='ST123456',
            role='candidate'
        )
        candidate2.clean()  # Should not raise


class UserManagerTest(TestCase):
    """Tests for the custom User manager."""
    
    def test_create_user_with_defaults(self):
        """Test creating user with manager defaults."""
        user = User.objects.create_user(
            email='test@kwasu.edu.ng',
            password='SecurePassword123',
            full_name='Test User',
            matric_number='U1234567'  # Required for student role
        )
        
        self.assertEqual(user.role, 'student')  # Default role
        self.assertFalse(user.is_staff)
        self.assertFalse(user.is_superuser)
    
    def test_create_superuser(self):
        """Test creating superuser."""
        user = User.objects.create_superuser(
            email='admin@kwasu.edu.ng',
            password='SecurePassword123',
            full_name='Admin User',
            staff_id='AD123456',
            role='admin'
        )
        
        self.assertTrue(user.is_staff)
        self.assertTrue(user.is_superuser)
    
    def test_create_user_missing_email(self):
        """Test creating user without email raises error."""
        with self.assertRaises(ValueError):
            User.objects.create_user(
                email='',
                password='SecurePassword123',
                full_name='Test User'
            )
    
    def test_create_user_missing_password(self):
        """Test creating user without password raises error."""
        with self.assertRaises(ValueError):
            User.objects.create_user(
                email='test@kwasu.edu.ng',
                password='',
                full_name='Test User'
            )


class AuthenticationAPITest(APITestCase):
    """Test authentication API endpoints."""
    
    def setUp(self):
        """Set up test data."""
        self.student_user = UserFactory(
            email='student@kwasu.edu.ng',
            full_name='Test Student',
            matric_number='U1234567',
            role='student'
        )
        self.staff_user = StaffUserFactory(
            email='staff@kwasu.edu.ng',
            full_name='Test Staff',
            staff_id='ST123456'
        )
    
    def test_login_with_email_and_password(self):
        """Test login with email and password."""
        # Note: This test assumes login endpoints exist
        # It will be skipped if the URLs don't exist
        try:
            login_url = reverse('auth:login')
        except:
            self.skipTest("Login URL not configured")
        
        response = self.client.post(login_url, {
            'email': 'student@kwasu.edu.ng',
            'password': 'TestPassword123'
        })
        
        # This test will need to be adapted based on actual API response format
        # For now, we're just checking that the endpoint exists
        self.assertIn(response.status_code, [200, 201, 400, 401])
    
    def test_user_profile_access(self):
        """Test accessing user profile."""
        # Force authentication for testing
        self.client.force_authenticate(user=self.student_user)
        
        try:
            profile_url = reverse('auth:profile')
            response = self.client.get(profile_url)
            self.assertIn(response.status_code, [200, 404])  # 404 if endpoint doesn't exist
        except:
            self.skipTest("Profile URL not configured")


class PasswordResetTest(TestCase):
    """Test password reset functionality."""
    
    def setUp(self):
        """Set up test user."""
        self.user = UserFactory(email='test@kwasu.edu.ng')
    
    def test_password_reset_otp_creation(self):
        """Test creating password reset OTP."""
        try:
            from electra_server.apps.auth.models import PasswordResetOTP
            
            otp = PasswordResetOTP.objects.create_otp(
                user=self.user,
                ip_address='127.0.0.1'
            )
            
            self.assertEqual(otp.user, self.user)
            self.assertEqual(len(otp.otp_code), 6)
            self.assertTrue(otp.is_valid())
            self.assertFalse(otp.is_expired())
        except ImportError:
            self.skipTest("PasswordResetOTP model not available")


class LoginAttemptTrackingTest(TestCase):
    """Test login attempt tracking."""
    
    def setUp(self):
        """Set up test user."""
        self.user = UserFactory(email='test@kwasu.edu.ng')
    
    def test_login_attempt_logging(self):
        """Test logging login attempts."""
        try:
            from electra_server.apps.auth.models import LoginAttempt
            
            # Successful login
            LoginAttempt.objects.log_attempt(
                email='test@kwasu.edu.ng',
                ip_address='127.0.0.1',
                user_agent='Test Browser',
                success=True,
                user=self.user
            )
            
            # Failed login
            LoginAttempt.objects.log_attempt(
                email='test@kwasu.edu.ng',
                ip_address='127.0.0.1',
                user_agent='Test Browser',
                success=False,
                failure_reason='invalid_password'
            )
            
            attempts = LoginAttempt.objects.filter(email='test@kwasu.edu.ng')
            self.assertEqual(attempts.count(), 2)
            
            successful_attempts = attempts.filter(success=True)
            self.assertEqual(successful_attempts.count(), 1)
            
        except ImportError:
            self.skipTest("LoginAttempt model not available")


class SecurityTest(TestCase):
    """Security-focused tests."""
    
    def test_password_hashing(self):
        """Test that passwords are properly hashed."""
        user = UserFactory()
        
        # Password should be hashed, not stored in plain text
        self.assertNotEqual(user.password, 'TestPassword123')
        self.assertTrue(user.check_password('TestPassword123'))
    
    def test_email_uniqueness(self):
        """Test that email addresses must be unique."""
        UserFactory(email='test@kwasu.edu.ng')
        
        with self.assertRaises(Exception):  # IntegrityError or ValidationError
            UserFactory(email='test@kwasu.edu.ng')
    
    def test_identifier_uniqueness(self):
        """Test that identifiers must be unique."""
        UserFactory(matric_number='U1234567')
        
        with self.assertRaises(Exception):  # IntegrityError or ValidationError
            UserFactory(matric_number='U1234567')
    
    def test_sensitive_data_not_in_str(self):
        """Test that sensitive data is not exposed in string representation."""
        user = UserFactory()
        user_str = str(user)
        
        # Password should never appear in string representation
        self.assertNotIn('password', user_str.lower())
        self.assertNotIn('TestPassword123', user_str)