"""
Unit tests for authentication models.

This module tests all the model functionality including validation,
methods, managers, and database constraints.
"""
import uuid
from datetime import timedelta

from django.test import TestCase
from django.core.exceptions import ValidationError
from django.db import IntegrityError
from django.utils import timezone

from ..models import User, UserRole, PasswordResetOTP, LoginAttempt
from .factories import (
    UserFactory, StudentUserFactory, StaffUserFactory,
    AdminUserFactory, ElectoralCommitteeUserFactory,
    PasswordResetOTPFactory, LoginAttemptFactory
)


class UserModelTest(TestCase):
    """Test cases for User model."""
    
    def test_student_user_creation(self):
        """Test creating a student user."""
        user = StudentUserFactory()
        
        self.assertEqual(user.role, UserRole.STUDENT)
        self.assertIsNotNone(user.matric_number)
        self.assertIsNone(user.staff_id)
        self.assertTrue(user.is_active)
        self.assertFalse(user.is_staff)
        self.assertIsInstance(user.id, uuid.UUID)
    
    def test_staff_user_creation(self):
        """Test creating a staff user."""
        user = StaffUserFactory()
        
        self.assertEqual(user.role, UserRole.STAFF)
        self.assertIsNotNone(user.staff_id)
        self.assertIsNone(user.matric_number)
        self.assertTrue(user.is_active)
    
    def test_admin_user_creation(self):
        """Test creating an admin user."""
        user = AdminUserFactory()
        
        self.assertEqual(user.role, UserRole.ADMIN)
        self.assertIsNotNone(user.staff_id)
        self.assertIsNone(user.matric_number)
        self.assertTrue(user.is_staff)
        self.assertTrue(user.is_superuser)
    
    def test_user_str_representation(self):
        """Test user string representation."""
        user = StudentUserFactory(
            full_name='John Doe',
            matric_number='U1234567'
        )
        expected = "John Doe (U1234567) - Student"
        self.assertEqual(str(user), expected)
    
    def test_get_login_identifier(self):
        """Test getting login identifier based on role."""
        student = StudentUserFactory(matric_number='U1234567')
        staff = StaffUserFactory(staff_id='ST123456')
        
        self.assertEqual(student.get_login_identifier(), 'U1234567')
        self.assertEqual(staff.get_login_identifier(), 'ST123456')
    
    def test_can_manage_elections(self):
        """Test election management permission."""
        student = StudentUserFactory()
        staff = StaffUserFactory()
        admin = AdminUserFactory()
        committee = ElectoralCommitteeUserFactory()
        
        self.assertFalse(student.can_manage_elections())
        self.assertFalse(staff.can_manage_elections())
        self.assertTrue(admin.can_manage_elections())
        self.assertTrue(committee.can_manage_elections())
    
    def test_student_validation_requires_matric_number(self):
        """Test that students must have matric_number."""
        user = User(
            email='test@example.com',
            full_name='Test User',
            role=UserRole.STUDENT,
            staff_id='ST123456'  # Wrong identifier type
        )
        
        with self.assertRaises(ValidationError) as context:
            user.full_clean()
        
        self.assertIn('matric_number', context.exception.error_dict)
    
    def test_staff_validation_requires_staff_id(self):
        """Test that staff must have staff_id."""
        user = User(
            email='test@example.com',
            full_name='Test User',
            role=UserRole.STAFF,
            matric_number='U1234567'  # Wrong identifier type
        )
        
        with self.assertRaises(ValidationError) as context:
            user.full_clean()
        
        self.assertIn('staff_id', context.exception.error_dict)
    
    def test_email_uniqueness(self):
        """Test that email addresses are unique."""
        email = 'test@example.com'
        StudentUserFactory(email=email)
        
        with self.assertRaises(IntegrityError):
            StudentUserFactory(email=email)
    
    def test_matric_number_uniqueness(self):
        """Test that matric numbers are unique."""
        matric_number = 'U1234567'
        StudentUserFactory(matric_number=matric_number)
        
        with self.assertRaises(IntegrityError):
            StudentUserFactory(matric_number=matric_number)
    
    def test_staff_id_uniqueness(self):
        """Test that staff IDs are unique."""
        staff_id = 'ST123456'
        StaffUserFactory(staff_id=staff_id)
        
        with self.assertRaises(IntegrityError):
            StaffUserFactory(staff_id=staff_id)
    
    def test_identifier_normalization(self):
        """Test that identifiers are normalized to uppercase."""
        student = User(
            email='test@example.com',
            full_name='Test User',
            role=UserRole.STUDENT,
            matric_number='u1234567'  # lowercase
        )
        student.clean()
        
        self.assertEqual(student.matric_number, 'U1234567')
    
    def test_password_hashing(self):
        """Test that passwords are properly hashed."""
        user = StudentUserFactory()
        
        # Password should be hashed
        self.assertNotEqual(user.password, 'TestPassword123')
        self.assertTrue(user.check_password('TestPassword123'))
    
    def test_user_manager_create_user(self):
        """Test UserManager create_user method."""
        user = User.objects.create_user(
            email='test@example.com',
            password='TestPassword123',
            full_name='Test User',
            role=UserRole.STUDENT,
            matric_number='U1234567'
        )
        
        self.assertEqual(user.email, 'test@example.com')
        self.assertTrue(user.check_password('TestPassword123'))
        self.assertEqual(user.role, UserRole.STUDENT)
        self.assertTrue(user.is_active)
    
    def test_user_manager_create_superuser(self):
        """Test UserManager create_superuser method."""
        user = User.objects.create_superuser(
            email='admin@example.com',
            password='AdminPassword123',
            staff_id='AD123456',
            full_name='Super Admin'
        )
        
        self.assertEqual(user.email, 'admin@example.com')
        self.assertTrue(user.is_staff)
        self.assertTrue(user.is_superuser)
        self.assertEqual(user.role, UserRole.ADMIN)
    
    def test_user_manager_validation_errors(self):
        """Test UserManager validation errors."""
        # Student without matric_number
        with self.assertRaises(ValueError):
            User.objects.create_user(
                email='test@example.com',
                password='TestPassword123',
                full_name='Test User',
                role=UserRole.STUDENT
            )
        
        # Staff without staff_id
        with self.assertRaises(ValueError):
            User.objects.create_user(
                email='test@example.com',
                password='TestPassword123',
                full_name='Test User',
                role=UserRole.STAFF
            )
    
    def test_user_manager_get_by_login_credential(self):
        """Test getting user by login credential."""
        student = StudentUserFactory(
            email='student@example.com',
            matric_number='U1234567'
        )
        staff = StaffUserFactory(
            email='staff@example.com',
            staff_id='ST123456'
        )
        
        # Test finding by email
        found = User.objects.get_by_login_credential('student@example.com')
        self.assertEqual(found, student)
        
        # Test finding by matric_number
        found = User.objects.get_by_login_credential('U1234567')
        self.assertEqual(found, student)
        
        # Test finding by staff_id
        found = User.objects.get_by_login_credential('ST123456')
        self.assertEqual(found, staff)
    
    def test_user_manager_role_filters(self):
        """Test UserManager role filter methods."""
        student = StudentUserFactory()
        staff = StaffUserFactory()
        admin = AdminUserFactory()
        committee = ElectoralCommitteeUserFactory()
        
        self.assertIn(student, User.objects.students())
        self.assertIn(staff, User.objects.staff_users())
        self.assertIn(admin, User.objects.admins())
        self.assertIn(committee, User.objects.electoral_committee())
        
        election_managers = User.objects.election_managers()
        self.assertIn(admin, election_managers)
        self.assertIn(committee, election_managers)
        self.assertNotIn(student, election_managers)
        self.assertNotIn(staff, election_managers)


class PasswordResetOTPModelTest(TestCase):
    """Test cases for PasswordResetOTP model."""
    
    def test_otp_creation(self):
        """Test OTP creation."""
        user = StudentUserFactory()
        otp = PasswordResetOTP.objects.create_otp(user=user)
        
        self.assertEqual(otp.user, user)
        self.assertEqual(len(otp.otp_code), 6)
        self.assertFalse(otp.is_used)
        self.assertTrue(otp.is_valid())
    
    def test_otp_expiry(self):
        """Test OTP expiry functionality."""
        user = StudentUserFactory()
        
        # Create expired OTP
        otp = PasswordResetOTPFactory(
            user=user,
            expires_at=timezone.now() - timedelta(minutes=1)
        )
        
        self.assertTrue(otp.is_expired())
        self.assertFalse(otp.is_valid())
    
    def test_otp_usage(self):
        """Test OTP usage functionality."""
        user = StudentUserFactory()
        otp = PasswordResetOTP.objects.create_otp(user=user)
        
        # Mark as used
        otp.mark_as_used()
        otp.refresh_from_db()
        
        self.assertTrue(otp.is_used)
        self.assertFalse(otp.is_valid())
    
    def test_otp_validation(self):
        """Test OTP validation."""
        user = StudentUserFactory()
        otp = PasswordResetOTP.objects.create_otp(user=user)
        
        # Valid OTP
        found_otp = PasswordResetOTP.objects.validate_otp(user, otp.otp_code)
        self.assertEqual(found_otp, otp)
        
        # Invalid OTP code
        with self.assertRaises(PasswordResetOTP.DoesNotExist):
            PasswordResetOTP.objects.validate_otp(user, '000000')
    
    def test_otp_cleanup(self):
        """Test OTP cleanup functionality."""
        user = StudentUserFactory()
        
        # Create expired OTP
        expired_otp = PasswordResetOTPFactory(
            user=user,
            expires_at=timezone.now() - timedelta(minutes=1)
        )
        
        # Create used OTP
        used_otp = PasswordResetOTPFactory(user=user, is_used=True)
        
        # Create valid OTP
        valid_otp = PasswordResetOTPFactory(user=user)
        
        # Cleanup should remove expired and used OTPs
        count = PasswordResetOTP.objects.cleanup_expired()
        self.assertEqual(count, 2)
        
        # Valid OTP should remain
        self.assertTrue(PasswordResetOTP.objects.filter(id=valid_otp.id).exists())
        self.assertFalse(PasswordResetOTP.objects.filter(id=expired_otp.id).exists())
        self.assertFalse(PasswordResetOTP.objects.filter(id=used_otp.id).exists())
    
    def test_multiple_otps_invalidation(self):
        """Test that creating new OTP invalidates previous ones."""
        user = StudentUserFactory()
        
        # Create first OTP
        otp1 = PasswordResetOTP.objects.create_otp(user=user)
        self.assertFalse(otp1.is_used)
        
        # Create second OTP
        otp2 = PasswordResetOTP.objects.create_otp(user=user)
        
        # First OTP should be invalidated
        otp1.refresh_from_db()
        self.assertTrue(otp1.is_used)
        self.assertFalse(otp2.is_used)


class LoginAttemptModelTest(TestCase):
    """Test cases for LoginAttempt model."""
    
    def test_login_attempt_creation(self):
        """Test creating login attempt."""
        user = StudentUserFactory()
        attempt = LoginAttempt.objects.create_attempt(
            email=user.email,
            ip_address='127.0.0.1',
            user_agent='Test Agent',
            success=True,
            user=user
        )
        
        self.assertEqual(attempt.email, user.email)
        self.assertEqual(attempt.ip_address, '127.0.0.1')
        self.assertTrue(attempt.success)
        self.assertEqual(attempt.user, user)
    
    def test_failed_login_attempt(self):
        """Test creating failed login attempt."""
        attempt = LoginAttempt.objects.create_attempt(
            email='nonexistent@example.com',
            ip_address='127.0.0.1',
            success=False,
            failure_reason='User not found'
        )
        
        self.assertFalse(attempt.success)
        self.assertEqual(attempt.failure_reason, 'User not found')
        self.assertIsNone(attempt.user)
    
    def test_login_attempt_manager_methods(self):
        """Test LoginAttemptManager methods."""
        user = StudentUserFactory()
        
        # Create successful attempt
        LoginAttemptFactory(email=user.email, success=True, user=user)
        
        # Create failed attempt
        LoginAttemptFactory(
            email=user.email,
            success=False,
            failure_reason='Invalid password',
            user=user
        )
        
        # Test filter methods
        self.assertEqual(LoginAttempt.objects.successful_attempts().count(), 1)
        self.assertEqual(LoginAttempt.objects.failed_attempts().count(), 1)
        self.assertEqual(LoginAttempt.objects.attempts_by_email(user.email).count(), 2)
    
    def test_rate_limiting_check(self):
        """Test rate limiting functionality."""
        email = 'test@example.com'
        
        # Create multiple failed attempts
        for _ in range(6):
            LoginAttemptFactory(
                email=email,
                success=False,
                failure_reason='Invalid password'
            )
        
        # Should be rate limited
        self.assertTrue(LoginAttempt.objects.is_rate_limited(email, max_attempts=5))
        
        # Different email should not be rate limited
        self.assertFalse(LoginAttempt.objects.is_rate_limited('other@example.com'))
    
    def test_cleanup_old_attempts(self):
        """Test cleanup of old login attempts."""
        # Create old attempt (32 days ago)
        old_timestamp = timezone.now() - timedelta(days=32)
        old_attempt = LoginAttemptFactory()
        LoginAttempt.objects.filter(id=old_attempt.id).update(timestamp=old_timestamp)
        
        # Create recent attempt
        recent_attempt = LoginAttemptFactory()
        
        # Cleanup should remove old attempts
        count = LoginAttempt.objects.cleanup_old_attempts(days=30)
        self.assertEqual(count, 1)
        
        # Recent attempt should remain
        self.assertTrue(LoginAttempt.objects.filter(id=recent_attempt.id).exists())
        self.assertFalse(LoginAttempt.objects.filter(id=old_attempt.id).exists())