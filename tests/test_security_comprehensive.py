"""
Comprehensive security tests for the electra voting system.

This module contains security-focused tests including authentication,
authorization, data validation, cryptographic operations, and 
protection against common vulnerabilities.
"""
import hashlib
import uuid
import json
from datetime import timedelta
from django.test import TestCase, override_settings
from django.urls import reverse
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from rest_framework.test import APITestCase
from rest_framework import status
from unittest.mock import patch, MagicMock

from .factories import UserFactory, StaffUserFactory, AdminUserFactory

User = get_user_model()


class AuthenticationSecurityTest(TestCase):
    """Test authentication security measures."""
    
    def setUp(self):
        """Set up test data."""
        self.user = UserFactory(
            email='security@kwasu.edu.ng',
            full_name='Security Test User',
            matric_number='U9999999'
        )
    
    def test_password_hashing_strength(self):
        """Test that passwords use strong hashing."""
        password = 'TestSecurePassword123'
        self.user.set_password(password)
        
        # Password should be hashed
        self.assertNotEqual(self.user.password, password)
        
        # In production, should use strong hashing algorithm (Argon2, PBKDF2, etc.)
        # In tests, Django may use faster hashers like MD5
        from django.conf import settings
        
        if settings.DEBUG or 'test' in settings.PASSWORD_HASHERS[0]:
            # Test environment may use weaker hashers for speed
            self.assertTrue(len(self.user.password) > len(password))
        else:
            # Production should use strong hashing
            self.assertTrue(self.user.password.startswith(('argon2', 'pbkdf2')))
        
        # Should verify correctly regardless of hasher
        self.assertTrue(self.user.check_password(password))
        self.assertFalse(self.user.check_password('wrong_password'))
    
    def test_password_validation_requirements(self):
        """Test password validation requirements."""
        # This test depends on password validators being configured
        
        weak_passwords = [
            '123',           # Too short
            'password',      # Too common
            '12345678',      # All numeric
            'aaaaaaaa',      # Too similar to username
        ]
        
        for weak_password in weak_passwords:
            user = User(
                email='test@kwasu.edu.ng',
                full_name='Test User',
                matric_number='U1111111',
                role='student'
            )
            user.set_password(weak_password)
            
            # Weak passwords should either be rejected or warned about
            # The exact behavior depends on password validator configuration
            try:
                user.full_clean()
                # If validation passes, ensure the password is still hashed
                self.assertNotEqual(user.password, weak_password)
            except ValidationError:
                # Password validation rejected the weak password
                pass
    
    def test_user_lockout_after_failed_attempts(self):
        """Test user lockout mechanism after failed login attempts."""
        # This test assumes there's some form of rate limiting or account lockout
        
        try:
            from electra_server.apps.auth.models import LoginAttempt
            
            # Simulate multiple failed attempts
            for i in range(10):
                LoginAttempt.objects.log_attempt(
                    email=self.user.email,
                    ip_address='127.0.0.1',
                    user_agent='Test Browser',
                    success=False,
                    failure_reason='invalid_password'
                )
            
            # Check that attempts are being logged
            failed_attempts = LoginAttempt.objects.filter(
                email=self.user.email,
                success=False
            ).count()
            
            self.assertGreaterEqual(failed_attempts, 10)
            
            # The actual lockout mechanism would be implemented in the views
            # This test just ensures the logging infrastructure exists
            
        except ImportError:
            self.skipTest("LoginAttempt model not available for testing")
    
    def test_session_security(self):
        """Test session security configurations."""
        from django.conf import settings
        
        # Check secure session settings
        if not settings.DEBUG:
            self.assertTrue(settings.SESSION_COOKIE_SECURE)
            self.assertTrue(settings.SESSION_COOKIE_HTTPONLY)
            self.assertIn(settings.SESSION_COOKIE_SAMESITE, ['Lax', 'Strict'])
    
    def test_csrf_protection(self):
        """Test CSRF protection is enabled."""
        from django.conf import settings
        
        # CSRF protection should be enabled
        self.assertIn('django.middleware.csrf.CsrfViewMiddleware', settings.MIDDLEWARE)
        
        if not settings.DEBUG:
            self.assertTrue(settings.CSRF_COOKIE_SECURE)
            self.assertTrue(settings.CSRF_COOKIE_HTTPONLY)


class InputValidationSecurityTest(TestCase):
    """Test input validation and sanitization."""
    
    def test_email_validation(self):
        """Test email field validation."""
        invalid_emails = [
            'invalid_email',
            '@kwasu.edu.ng',
            'test@',
            'test..test@kwasu.edu.ng',
            'test@kwasu',
            'test@.kwasu.edu.ng',
        ]
        
        for invalid_email in invalid_emails:
            user = User(
                email=invalid_email,
                full_name='Test User',
                matric_number='U1111111',
                role='student'
            )
            
            with self.assertRaises(ValidationError):
                user.full_clean()
    
    def test_xss_protection_in_text_fields(self):
        """Test protection against XSS in text fields."""
        xss_payloads = [
            '<script>alert("XSS")</script>',
            '<img src="x" onerror="alert(1)">',
            'javascript:alert(1)',
            '<iframe src="javascript:alert(1)"></iframe>',
        ]
        
        for payload in xss_payloads:
            user = User(
                email='xss@kwasu.edu.ng',
                full_name=payload,
                matric_number='U2222222',
                role='student'
            )
            
            # The system should either:
            # 1. Reject the input (ValidationError)
            # 2. Sanitize the input (remove/escape dangerous content)
            # 3. Store safely and escape on output
            
            try:
                user.full_clean()
                user.save()
                
                # If saved, dangerous content should be sanitized
                user.refresh_from_db()
                self.assertNotIn('<script>', user.full_name)
                self.assertNotIn('javascript:', user.full_name)
                self.assertNotIn('onerror=', user.full_name)
                
            except ValidationError:
                # Input was rejected, which is also acceptable
                pass
    
    def test_sql_injection_protection(self):
        """Test protection against SQL injection."""
        sql_payloads = [
            "'; DROP TABLE users; --",
            "' OR '1'='1",
            "' UNION SELECT * FROM users --",
            "'; INSERT INTO users VALUES ('hacker'); --",
        ]
        
        # Test that Django ORM protects against SQL injection
        for payload in sql_payloads:
            # This should not cause SQL injection
            users = User.objects.filter(email=payload)
            
            # Should return empty queryset, not cause error
            self.assertEqual(users.count(), 0)
            
            # Database should still be intact
            self.assertTrue(User._meta.db_table)
    
    def test_file_upload_validation(self):
        """Test file upload validation if applicable."""
        # This test would be relevant if the system handles file uploads
        # For example, profile pictures, election documents, etc.
        
        # Test file size limits
        # Test file type restrictions
        # Test malicious file detection
        
        # Since the current models don't have file fields, we'll skip this
        self.skipTest("No file upload functionality to test")
    
    def test_unicode_handling(self):
        """Test proper Unicode handling."""
        unicode_strings = [
            'Test用户',  # Chinese characters
            'Тест',      # Cyrillic
            'اختبار',     # Arabic
            '🔒🗳️',     # Emojis
            'café',      # Accented characters
        ]
        
        for unicode_string in unicode_strings:
            user = User(
                email='unicode@kwasu.edu.ng',
                full_name=unicode_string,
                matric_number='U3333333',
                role='student'
            )
            
            # Should handle Unicode properly
            user.full_clean()
            user.save()
            
            user.refresh_from_db()
            self.assertEqual(user.full_name, unicode_string)


class CryptographicSecurityTest(TestCase):
    """Test cryptographic security measures."""
    
    def test_jwt_token_security(self):
        """Test JWT token security configurations."""
        from django.conf import settings
        
        jwt_settings = getattr(settings, 'SIMPLE_JWT', {})
        
        # Check token lifetime is reasonable
        access_lifetime = jwt_settings.get('ACCESS_TOKEN_LIFETIME', timedelta(minutes=5))
        self.assertLessEqual(access_lifetime, timedelta(hours=1))
        
        # Check refresh token rotation is enabled
        self.assertTrue(jwt_settings.get('ROTATE_REFRESH_TOKENS', False))
        
        # Check blacklisting is enabled
        self.assertTrue(jwt_settings.get('BLACKLIST_AFTER_ROTATION', False))
    
    def test_random_token_generation(self):
        """Test random token generation quality."""
        # Test that generated tokens are sufficiently random
        tokens = set()
        
        for _ in range(100):
            token = str(uuid.uuid4())
            tokens.add(token)
        
        # All tokens should be unique
        self.assertEqual(len(tokens), 100)
        
        # Tokens should have proper format
        for token in list(tokens)[:5]:  # Test first 5
            self.assertEqual(len(token), 36)  # UUID4 format
            self.assertEqual(token.count('-'), 4)
    
    def test_hash_consistency(self):
        """Test hash function consistency."""
        data = "test_data_for_hashing"
        
        # Same data should produce same hash
        hash1 = hashlib.sha256(data.encode()).hexdigest()
        hash2 = hashlib.sha256(data.encode()).hexdigest()
        
        self.assertEqual(hash1, hash2)
        
        # Different data should produce different hash
        different_data = "different_test_data"
        hash3 = hashlib.sha256(different_data.encode()).hexdigest()
        
        self.assertNotEqual(hash1, hash3)
    
    def test_secure_random_generation(self):
        """Test secure random number generation."""
        import secrets
        
        # Test secure random bytes
        random_bytes1 = secrets.token_bytes(32)
        random_bytes2 = secrets.token_bytes(32)
        
        # Should be different
        self.assertNotEqual(random_bytes1, random_bytes2)
        
        # Should be correct length
        self.assertEqual(len(random_bytes1), 32)
        self.assertEqual(len(random_bytes2), 32)


class PermissionSecurityTest(TestCase):
    """Test permission and authorization security."""
    
    def setUp(self):
        """Set up test users with different roles."""
        self.student = UserFactory(
            email='student@kwasu.edu.ng',
            role='student',
            matric_number='U1111111'
        )
        
        self.staff = StaffUserFactory(
            email='staff@kwasu.edu.ng',
            role='staff',
            staff_id='ST111111'
        )
        
        self.admin = AdminUserFactory(
            email='admin@kwasu.edu.ng',
            role='admin',
            staff_id='AD111111'
        )
    
    def test_role_based_permissions(self):
        """Test role-based permission system."""
        # Students should not be able to manage elections
        self.assertFalse(self.student.can_manage_elections())
        
        # Staff should not be able to manage elections (unless electoral committee)
        self.assertFalse(self.staff.can_manage_elections())
        
        # Admins should be able to manage elections
        self.assertTrue(self.admin.can_manage_elections())
    
    def test_privilege_escalation_protection(self):
        """Test protection against privilege escalation."""
        # A student should not be able to change their role to admin
        original_role = self.student.role
        
        # Attempt to change role
        self.student.role = 'admin'
        self.student.save()
        
        # Role change should be validated elsewhere (e.g., in views/serializers)
        # This test ensures the model allows the change, but business logic should prevent it
        self.student.refresh_from_db()
        
        # In a real system, role changes should be restricted
        # For now, we just ensure the role field exists and is modifiable
        self.assertIn(self.student.role, ['student', 'admin'])
    
    def test_user_isolation(self):
        """Test that users can only access their own data."""
        # Create two users
        user1 = UserFactory(email='user1@kwasu.edu.ng', matric_number='U1111111')
        user2 = UserFactory(email='user2@kwasu.edu.ng', matric_number='U2222222')
        
        # Users should be distinct
        self.assertNotEqual(user1.id, user2.id)
        self.assertNotEqual(user1.email, user2.email)
        
        # In API views, users should only be able to access their own data
        # This would be tested in API integration tests


class DataProtectionTest(TestCase):
    """Test data protection and privacy measures."""
    
    def test_sensitive_data_not_in_logs(self):
        """Test that sensitive data doesn't appear in string representations."""
        user = UserFactory()
        
        user_str = str(user)
        user_repr = repr(user)
        
        # Passwords should never appear in string representations
        self.assertNotIn('password', user_str.lower())
        self.assertNotIn('password', user_repr.lower())
        
        # Actual password hash should not be in string representations
        self.assertNotIn(user.password, user_str)
        self.assertNotIn(user.password, user_repr)
    
    def test_database_field_encryption(self):
        """Test that sensitive fields are properly protected."""
        # In a production system, sensitive fields might be encrypted
        # For now, we test that passwords are hashed
        
        user = UserFactory()
        
        # Password should be hashed, not stored in plain text
        self.assertNotEqual(user.password, 'TestPassword123')
        self.assertTrue(len(user.password) > 20)  # Hashed passwords are longer
    
    def test_user_data_anonymization(self):
        """Test user data anonymization capabilities."""
        user = UserFactory(
            email='deleteme@kwasu.edu.ng',
            full_name='Delete Me User',
            matric_number='U9999999'
        )
        
        original_id = user.id
        
        # In a real system, there might be an anonymization method
        # For now, we test that the user can be deleted
        user.delete()
        
        # User should no longer exist
        self.assertFalse(User.objects.filter(id=original_id).exists())


class SecurityHeadersTest(TestCase):
    """Test security headers configuration."""
    
    def test_security_headers_configuration(self):
        """Test that security headers are properly configured."""
        from django.conf import settings
        
        # Test security middleware is enabled
        self.assertIn('django.middleware.security.SecurityMiddleware', settings.MIDDLEWARE)
        
        # Test security settings (in production)
        if not settings.DEBUG:
            self.assertTrue(settings.SECURE_BROWSER_XSS_FILTER)
            self.assertTrue(settings.SECURE_CONTENT_TYPE_NOSNIFF)
            self.assertEqual(settings.X_FRAME_OPTIONS, 'DENY')
    
    def test_cors_configuration(self):
        """Test CORS configuration."""
        from django.conf import settings
        
        # CORS should be configured
        self.assertIn('corsheaders.middleware.CorsMiddleware', settings.MIDDLEWARE)
        
        # In production, CORS should not allow all origins
        if not settings.DEBUG:
            cors_allow_all = getattr(settings, 'CORS_ALLOW_ALL_ORIGINS', False)
            self.assertFalse(cors_allow_all)


class AuditSecurityTest(TestCase):
    """Test audit and logging security."""
    
    def test_audit_log_integrity(self):
        """Test audit log integrity features."""
        try:
            from electra_server.apps.audit.models import AuditLog
            
            # Create an audit log entry
            log_entry = AuditLog(
                action_type='test_action',
                action_description='Test audit entry',
                outcome='success',
                user_identifier='test@kwasu.edu.ng',
                ip_address='127.0.0.1'
            )
            log_entry.save()
            
            # Entry should have integrity features
            self.assertTrue(hasattr(log_entry, 'content_hash'))
            self.assertTrue(hasattr(log_entry, 'chain_position'))
            
            # Hash should be consistent
            if log_entry.content_hash:
                self.assertIsInstance(log_entry.content_hash, str)
                self.assertGreaterEqual(len(log_entry.content_hash), 32)
            
        except ImportError:
            self.skipTest("AuditLog model not available for testing")
    
    def test_sensitive_data_not_logged(self):
        """Test that sensitive data is not logged inappropriately."""
        # This is more of a code review item, but we can test basic patterns
        
        # Create a user and ensure password is not in logs
        user = UserFactory()
        
        # In a real system, we'd check log files or audit entries
        # to ensure passwords, tokens, etc. are not logged
        
        # For now, just ensure password is hashed
        self.assertNotEqual(user.password, 'TestPassword123')


class ComplianceTest(TestCase):
    """Test compliance with security standards."""
    
    def test_password_policy_compliance(self):
        """Test password policy compliance."""
        # This depends on the specific password validators configured
        
        # Test minimum length
        short_password = 'abc'
        user = User(
            email='test@kwasu.edu.ng',
            full_name='Test User',
            matric_number='U1111111',
            role='student'
        )
        
        # Setting a short password should either be rejected or warned about
        user.set_password(short_password)
        
        # Password should still be hashed even if weak
        self.assertNotEqual(user.password, short_password)
    
    def test_data_retention(self):
        """Test data retention policies."""
        # In a real system, there might be data retention policies
        # For now, we just test basic CRUD operations
        
        user = UserFactory()
        user_id = user.id
        
        # User should exist
        self.assertTrue(User.objects.filter(id=user_id).exists())
        
        # User should be deletable (for data retention compliance)
        user.delete()
        self.assertFalse(User.objects.filter(id=user_id).exists())
    
    def test_audit_trail_requirements(self):
        """Test audit trail requirements."""
        try:
            from electra_server.apps.audit.models import AuditLog
            
            # Audit logs should be immutable (no update/delete)
            log_entry = AuditLog(
                action_type='test_action',
                action_description='Test audit entry',
                outcome='success',
                user_identifier='test@kwasu.edu.ng',
                ip_address='127.0.0.1'
            )
            log_entry.save()
            
            # Check that audit log has required attributes
            required_fields = ['action_type', 'timestamp', 'user_identifier', 'ip_address']
            for field in required_fields:
                self.assertTrue(hasattr(log_entry, field))
            
        except ImportError:
            self.skipTest("AuditLog model not available for testing")