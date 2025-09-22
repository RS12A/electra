"""
Unit tests for analytics permissions.

This module tests the permission classes for analytics endpoints
including role-based access control and security logging.
"""
from unittest.mock import patch, MagicMock

import pytest
from django.contrib.auth import get_user_model
from django.test import TestCase, RequestFactory
from rest_framework.request import Request

from electra_server.apps.auth.models import UserRole
from electra_server.apps.analytics.permissions import (
    AnalyticsPermission,
    AnalyticsExportPermission,
    ReadOnlyAnalyticsPermission
)

User = get_user_model()


@pytest.mark.unit
class TestAnalyticsPermissions(TestCase):
    """Test cases for analytics permission classes."""
    
    def setUp(self):
        """Set up test data."""
        self.factory = RequestFactory()
        
        # Create test users with different roles
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            full_name='Admin User',
            role=UserRole.ADMIN,
            staff_id='ADMIN001',
            is_active=True
        )
        
        self.electoral_committee_user = User.objects.create_user(
            email='committee@test.com',
            password='testpass123',
            full_name='Committee User',
            role=UserRole.ELECTORAL_COMMITTEE,
            staff_id='EC001',
            is_active=True
        )
        
        self.student_user = User.objects.create_user(
            email='student@test.com',
            password='testpass123',
            full_name='Student User',
            role=UserRole.STUDENT,
            matric_number='STU001',
            is_active=True
        )
        
        self.staff_user = User.objects.create_user(
            email='staff@test.com',
            password='testpass123',
            full_name='Staff User',
            role=UserRole.STAFF,
            staff_id='STF001',
            is_active=True
        )
        
        self.inactive_admin = User.objects.create_user(
            email='inactive@test.com',
            password='testpass123',
            full_name='Inactive Admin',
            role=UserRole.ADMIN,
            staff_id='INACTIVE001',
            is_active=False
        )
        
        # Mock view
        self.mock_view = MagicMock()
    
    def _create_request(self, user=None, method='GET'):
        """Helper to create a request with user."""
        request = self.factory.get('/test/')
        request.method = method
        
        # Handle user authentication properly
        if user:
            request.user = user
            # For test users, we need to mock is_authenticated
            user._is_authenticated = True
        else:
            from django.contrib.auth.models import AnonymousUser
            request.user = AnonymousUser()
        
        request.META = {
            'HTTP_X_FORWARDED_FOR': '192.168.1.100',
            'REMOTE_ADDR': '127.0.0.1',
            'HTTP_USER_AGENT': 'Test Agent'
        }
        return Request(request)


class TestAnalyticsPermission(TestAnalyticsPermissions):
    """Test cases for AnalyticsPermission class."""
    
    def test_admin_user_has_permission(self):
        """Test that admin users have analytics permission."""
        permission = AnalyticsPermission()
        request = self._create_request(self.admin_user)
        
        with patch('electra_server.apps.analytics.permissions.log_user_action'):
            result = permission.has_permission(request, self.mock_view)
        
        self.assertTrue(result)
    
    def test_electoral_committee_user_has_permission(self):
        """Test that electoral committee users have analytics permission."""
        permission = AnalyticsPermission()
        request = self._create_request(self.electoral_committee_user)
        
        with patch('electra_server.apps.analytics.permissions.log_user_action'):
            result = permission.has_permission(request, self.mock_view)
        
        self.assertTrue(result)
    
    def test_student_user_denied_permission(self):
        """Test that student users are denied analytics permission."""
        permission = AnalyticsPermission()
        request = self._create_request(self.student_user)
        
        with patch('electra_server.apps.analytics.permissions.log_user_action') as mock_log:
            result = permission.has_permission(request, self.mock_view)
        
        self.assertFalse(result)
        
        # Verify access denial was logged
        mock_log.assert_called_once()
        call_args = mock_log.call_args[1]
        self.assertEqual(call_args['outcome'], 'denied')
        self.assertIn('insufficient_role', call_args['description'])
    
    def test_staff_user_denied_permission(self):
        """Test that staff users are denied analytics permission."""
        permission = AnalyticsPermission()
        request = self._create_request(self.staff_user)
        
        with patch('electra_server.apps.analytics.permissions.log_user_action'):
            result = permission.has_permission(request, self.mock_view)
        
        self.assertFalse(result)
    
    def test_unauthenticated_user_denied_permission(self):
        """Test that unauthenticated users are denied permission."""
        permission = AnalyticsPermission()
        request = self._create_request()  # No user
        
        result = permission.has_permission(request, self.mock_view)
        
        self.assertFalse(result)
    
    def test_inactive_user_denied_permission(self):
        """Test that inactive users are denied permission."""
        permission = AnalyticsPermission()
        request = self._create_request(self.inactive_admin)
        
        with patch('electra_server.apps.analytics.permissions.log_user_action') as mock_log:
            result = permission.has_permission(request, self.mock_view)
        
        self.assertFalse(result)
        
        # Verify access denial was logged
        mock_log.assert_called_once()
        call_args = mock_log.call_args[1]
        self.assertEqual(call_args['outcome'], 'denied')
        self.assertIn('user_not_active', call_args['description'])
    
    def test_has_object_permission_calls_has_permission(self):
        """Test that has_object_permission calls has_permission first."""
        permission = AnalyticsPermission()
        request = self._create_request(self.admin_user)
        mock_obj = MagicMock()
        
        with patch.object(permission, 'has_permission', return_value=True) as mock_has_perm:
            result = permission.has_object_permission(request, self.mock_view, mock_obj)
        
        self.assertTrue(result)
        mock_has_perm.assert_called_once_with(request, self.mock_view)
    
    def test_has_object_permission_respects_has_permission_false(self):
        """Test that has_object_permission returns False if has_permission is False."""
        permission = AnalyticsPermission()
        request = self._create_request(self.student_user)
        mock_obj = MagicMock()
        
        with patch.object(permission, 'has_permission', return_value=False) as mock_has_perm:
            result = permission.has_object_permission(request, self.mock_view, mock_obj)
        
        self.assertFalse(result)
        mock_has_perm.assert_called_once_with(request, self.mock_view)
    
    @patch('electra_server.apps.analytics.permissions.logger')
    def test_access_granted_logging(self, mock_logger):
        """Test that successful access is logged properly."""
        permission = AnalyticsPermission()
        request = self._create_request(self.admin_user)
        
        with patch('electra_server.apps.analytics.permissions.log_user_action'):
            permission.has_permission(request, self.mock_view)
        
        # Verify info logging
        mock_logger.info.assert_called_once()
        log_call = mock_logger.info.call_args
        self.assertIn('Analytics access granted', log_call[0][0])
    
    @patch('electra_server.apps.analytics.permissions.logger')
    def test_access_denied_logging(self, mock_logger):
        """Test that access denial is logged properly."""
        permission = AnalyticsPermission()
        request = self._create_request(self.student_user)
        
        with patch('electra_server.apps.analytics.permissions.log_user_action'):
            permission.has_permission(request, self.mock_view)
        
        # Verify warning logging
        mock_logger.warning.assert_called_once()
        log_call = mock_logger.warning.call_args
        self.assertIn('Analytics access denied', log_call[0][0])
    
    def test_client_ip_extraction_x_forwarded_for(self):
        """Test client IP extraction with X-Forwarded-For header."""
        permission = AnalyticsPermission()
        request = self.factory.get('/test/')
        request.META = {
            'HTTP_X_FORWARDED_FOR': '10.0.0.1, 192.168.1.1',
            'REMOTE_ADDR': '127.0.0.1'
        }
        
        ip = permission._get_client_ip(Request(request))
        
        self.assertEqual(ip, '10.0.0.1')  # Should use first IP from X-Forwarded-For
    
    def test_client_ip_extraction_remote_addr(self):
        """Test client IP extraction with REMOTE_ADDR only."""
        permission = AnalyticsPermission()
        request = self.factory.get('/test/')
        request.META = {
            'REMOTE_ADDR': '192.168.1.100'
        }
        
        ip = permission._get_client_ip(Request(request))
        
        self.assertEqual(ip, '192.168.1.100')
    
    def test_client_ip_extraction_fallback(self):
        """Test client IP extraction fallback to 'unknown'."""
        permission = AnalyticsPermission()
        request = self.factory.get('/test/')
        request.META = {}  # No IP headers
        
        ip = permission._get_client_ip(Request(request))
        
        self.assertEqual(ip, 'unknown')


class TestAnalyticsExportPermission(TestAnalyticsPermissions):
    """Test cases for AnalyticsExportPermission class."""
    
    def test_inherits_from_analytics_permission(self):
        """Test that AnalyticsExportPermission inherits from AnalyticsPermission."""
        self.assertTrue(issubclass(AnalyticsExportPermission, AnalyticsPermission))
    
    def test_admin_user_has_export_permission(self):
        """Test that admin users have export permission."""
        permission = AnalyticsExportPermission()
        request = self._create_request(self.admin_user)
        
        with patch('electra_server.apps.analytics.permissions.log_user_action'):
            result = permission.has_permission(request, self.mock_view)
        
        self.assertTrue(result)
    
    def test_student_user_denied_export_permission(self):
        """Test that student users are denied export permission."""
        permission = AnalyticsExportPermission()
        request = self._create_request(self.student_user)
        
        with patch('electra_server.apps.analytics.permissions.log_user_action'):
            result = permission.has_permission(request, self.mock_view)
        
        self.assertFalse(result)
    
    def test_export_request_logging(self):
        """Test that export requests are specially logged."""
        permission = AnalyticsExportPermission()
        request = self._create_request(self.admin_user, method='POST')
        
        with patch('electra_server.apps.analytics.permissions.log_user_action') as mock_log, \
             patch('electra_server.apps.analytics.permissions.logger') as mock_logger:
            
            permission.has_permission(request, self.mock_view)
        
        # Should have multiple log calls - one for export request, one for access granted
        self.assertGreaterEqual(mock_log.call_count, 2)
        
        # Verify export-specific logging
        export_log_call = None
        for call in mock_log.call_args_list:
            if 'export requested' in call[1]['description']:
                export_log_call = call
                break
        
        self.assertIsNotNone(export_log_call)
        self.assertEqual(export_log_call[1]['outcome'], 'initiated')
        self.assertTrue(export_log_call[1]['metadata']['export_request'])
    
    def test_get_request_no_special_logging(self):
        """Test that GET requests don't trigger export-specific logging."""
        permission = AnalyticsExportPermission()
        request = self._create_request(self.admin_user, method='GET')
        
        with patch('electra_server.apps.analytics.permissions.log_user_action') as mock_log:
            permission.has_permission(request, self.mock_view)
        
        # Should only have access granted log, not export request log
        self.assertEqual(mock_log.call_count, 1)
        call_args = mock_log.call_args[1]
        self.assertNotIn('export requested', call_args['description'])


class TestReadOnlyAnalyticsPermission(TestAnalyticsPermissions):
    """Test cases for ReadOnlyAnalyticsPermission class."""
    
    def test_inherits_from_analytics_permission(self):
        """Test that ReadOnlyAnalyticsPermission inherits from AnalyticsPermission."""
        self.assertTrue(issubclass(ReadOnlyAnalyticsPermission, AnalyticsPermission))
    
    def test_admin_user_has_readonly_permission_for_get(self):
        """Test that admin users have readonly permission for GET requests."""
        permission = ReadOnlyAnalyticsPermission()
        request = self._create_request(self.admin_user, method='GET')
        
        with patch('electra_server.apps.analytics.permissions.log_user_action'):
            result = permission.has_permission(request, self.mock_view)
        
        self.assertTrue(result)
    
    def test_admin_user_denied_readonly_permission_for_post(self):
        """Test that admin users are denied readonly permission for POST requests."""
        permission = ReadOnlyAnalyticsPermission()
        request = self._create_request(self.admin_user, method='POST')
        
        with patch('electra_server.apps.analytics.permissions.log_user_action') as mock_log:
            result = permission.has_permission(request, self.mock_view)
        
        self.assertFalse(result)
        
        # Verify unsafe method was logged as reason for denial
        mock_log.assert_called()
        call_args = mock_log.call_args[1]
        self.assertEqual(call_args['outcome'], 'denied')
        self.assertIn('unsafe_method:POST', call_args['description'])
    
    def test_admin_user_allowed_head_request(self):
        """Test that HEAD requests are allowed as safe methods."""
        permission = ReadOnlyAnalyticsPermission()
        request = self._create_request(self.admin_user, method='HEAD')
        
        with patch('electra_server.apps.analytics.permissions.log_user_action'):
            result = permission.has_permission(request, self.mock_view)
        
        self.assertTrue(result)
    
    def test_admin_user_allowed_options_request(self):
        """Test that OPTIONS requests are allowed as safe methods."""
        permission = ReadOnlyAnalyticsPermission()
        request = self._create_request(self.admin_user, method='OPTIONS')
        
        with patch('electra_server.apps.analytics.permissions.log_user_action'):
            result = permission.has_permission(request, self.mock_view)
        
        self.assertTrue(result)
    
    def test_admin_user_denied_put_request(self):
        """Test that PUT requests are denied as unsafe methods."""
        permission = ReadOnlyAnalyticsPermission()
        request = self._create_request(self.admin_user, method='PUT')
        
        with patch('electra_server.apps.analytics.permissions.log_user_action'):
            result = permission.has_permission(request, self.mock_view)
        
        self.assertFalse(result)
    
    def test_admin_user_denied_delete_request(self):
        """Test that DELETE requests are denied as unsafe methods."""
        permission = ReadOnlyAnalyticsPermission()
        request = self._create_request(self.admin_user, method='DELETE')
        
        with patch('electra_server.apps.analytics.permissions.log_user_action'):
            result = permission.has_permission(request, self.mock_view)
        
        self.assertFalse(result)
    
    def test_student_user_denied_even_for_get(self):
        """Test that student users are denied even for GET requests."""
        permission = ReadOnlyAnalyticsPermission()
        request = self._create_request(self.student_user, method='GET')
        
        with patch('electra_server.apps.analytics.permissions.log_user_action'):
            result = permission.has_permission(request, self.mock_view)
        
        self.assertFalse(result)
    
    def test_permission_class_allowed_roles(self):
        """Test that permission classes have correct allowed roles."""
        analytics_perm = AnalyticsPermission()
        export_perm = AnalyticsExportPermission()
        readonly_perm = ReadOnlyAnalyticsPermission()
        
        expected_roles = [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]
        
        self.assertEqual(analytics_perm.ALLOWED_ROLES, expected_roles)
        self.assertEqual(export_perm.ALLOWED_ROLES, expected_roles)
        self.assertEqual(readonly_perm.ALLOWED_ROLES, expected_roles)
    
    def test_anonymous_user_handling(self):
        """Test handling of anonymous users (None user)."""
        permission = AnalyticsPermission()
        request = self._create_request()  # No user set (anonymous)
        request.user = None
        
        result = permission.has_permission(request, self.mock_view)
        
        self.assertFalse(result)
    
    def test_user_without_role_handling(self):
        """Test handling of users without proper role attribute."""
        permission = AnalyticsPermission()
        request = self._create_request(self.admin_user)
        
        # Mock user without role attribute
        request.user.role = None
        
        with patch('electra_server.apps.analytics.permissions.log_user_action'):
            result = permission.has_permission(request, self.mock_view)
        
        # Should be denied due to role not in allowed roles
        self.assertFalse(result)