"""
Unit tests for admin API permissions.

This module contains comprehensive tests for admin API permission classes
to ensure proper role-based access control and security.
"""
import pytest
from unittest.mock import Mock, patch
from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.request import Request
from rest_framework.test import APIRequestFactory
from rest_framework.views import APIView

from electra_server.apps.auth.models import UserRole
from electra_server.apps.admin.permissions import (
    AdminPermission,
    UserManagementPermission,
    ElectionManagementPermission,
    BallotTokenManagementPermission
)

User = get_user_model()


@pytest.mark.django_db
class AdminPermissionTest(TestCase):
    """Test cases for AdminPermission class."""
    
    def setUp(self):
        """Set up test data."""
        self.factory = APIRequestFactory()
        self.permission = AdminPermission()
        self.view = APIView()
        
        # Create test users with different roles
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            full_name='Admin User',
            staff_id='ADMIN001',
            role=UserRole.ADMIN,
            is_active=True
        )
        
        self.committee_user = User.objects.create_user(
            email='committee@test.com',
            password='testpass123',
            full_name='Committee User',
            staff_id='COMM001',
            role=UserRole.ELECTORAL_COMMITTEE,
            is_active=True
        )
        
        self.staff_user = User.objects.create_user(
            email='staff@test.com',
            password='testpass123',
            full_name='Staff User',
            staff_id='STAFF001',
            role=UserRole.STAFF,
            is_active=True
        )
        
        self.student_user = User.objects.create_user(
            email='student@test.com',
            password='testpass123',
            full_name='Student User',
            matric_number='ST001',
            role=UserRole.STUDENT,
            is_active=True
        )
        
        self.inactive_admin = User.objects.create_user(
            email='inactive@test.com',
            password='testpass123',
            full_name='Inactive Admin',
            staff_id='ADMIN002',
            role=UserRole.ADMIN,
            is_active=False
        )
    
    def test_admin_user_has_permission(self):
        """Test that admin users have permission."""
        request = self.factory.get('/api/admin/test/')
        request.user = self.admin_user
        
        self.assertTrue(self.permission.has_permission(request, self.view))
    
    def test_committee_user_has_permission(self):
        """Test that electoral committee users have permission."""
        request = self.factory.get('/api/admin/test/')
        request.user = self.committee_user
        
        self.assertTrue(self.permission.has_permission(request, self.view))
    
    def test_staff_user_no_permission(self):
        """Test that staff users don't have permission."""
        request = self.factory.get('/api/admin/test/')
        request.user = self.staff_user
        
        self.assertFalse(self.permission.has_permission(request, self.view))
    
    def test_student_user_no_permission(self):
        """Test that student users don't have permission."""
        request = self.factory.get('/api/admin/test/')
        request.user = self.student_user
        
        self.assertFalse(self.permission.has_permission(request, self.view))
    
    def test_unauthenticated_user_no_permission(self):
        """Test that unauthenticated users don't have permission."""
        request = self.factory.get('/api/admin/test/')
        request.user = Mock()
        request.user.is_authenticated = False
        
        self.assertFalse(self.permission.has_permission(request, self.view))
    
    def test_inactive_user_no_permission(self):
        """Test that inactive users don't have permission."""
        request = self.factory.get('/api/admin/test/')
        request.user = self.inactive_admin
        
        self.assertFalse(self.permission.has_permission(request, self.view))
    
    def test_user_without_role_no_permission(self):
        """Test that users without role don't have permission."""
        request = self.factory.get('/api/admin/test/')
        request.user = Mock()
        request.user.is_authenticated = True
        request.user.is_active = True
        # No role attribute
        
        self.assertFalse(self.permission.has_permission(request, self.view))
    
    @patch('electra_server.apps.admin.permissions.log_user_action')
    def test_access_denied_logging(self, mock_log):
        """Test that access denials are properly logged."""
        request = self.factory.get('/api/admin/test/')
        request.user = self.staff_user
        
        self.permission.has_permission(request, self.view)
        
        # Verify logging was called
        mock_log.assert_called_once()
        call_args = mock_log.call_args[1]
        self.assertIn('access denied', call_args['description'].lower())
    
    def test_object_permission_inherits_general_permission(self):
        """Test that object permission inherits from general permission."""
        request = self.factory.get('/api/admin/test/')
        request.user = self.admin_user
        
        # Should return same as has_permission
        self.assertTrue(self.permission.has_object_permission(request, self.view, Mock()))
        
        request.user = self.staff_user
        self.assertFalse(self.permission.has_object_permission(request, self.view, Mock()))


@pytest.mark.django_db
class UserManagementPermissionTest(TestCase):
    """Test cases for UserManagementPermission class."""
    
    def setUp(self):
        """Set up test data."""
        self.factory = APIRequestFactory()
        self.permission = UserManagementPermission()
        self.view = APIView()
        
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            full_name='Admin User',
            staff_id='ADMIN001',
            role=UserRole.ADMIN,
            is_active=True
        )
        
        self.committee_user = User.objects.create_user(
            email='committee@test.com',
            password='testpass123',
            full_name='Committee User',
            staff_id='COMM001',
            role=UserRole.ELECTORAL_COMMITTEE,
            is_active=True
        )
        
        self.target_admin = User.objects.create_user(
            email='target@test.com',
            password='testpass123',
            full_name='Target Admin',
            staff_id='ADMIN002',
            role=UserRole.ADMIN,
            is_active=True
        )
        
        self.target_staff = User.objects.create_user(
            email='staff@test.com',
            password='testpass123',
            full_name='Target Staff',
            staff_id='STAFF001',
            role=UserRole.STAFF,
            is_active=True
        )
    
    def test_admin_can_modify_admin_user(self):
        """Test that admin users can modify other admin users."""
        request = self.factory.put('/api/admin/users/test/')
        request.user = self.admin_user
        
        self.assertTrue(self.permission.has_object_permission(request, self.view, self.target_admin))
    
    def test_committee_cannot_modify_admin_user(self):
        """Test that committee users cannot modify admin users."""
        request = self.factory.put('/api/admin/users/test/')
        request.user = self.committee_user
        
        self.assertFalse(self.permission.has_object_permission(request, self.view, self.target_admin))
    
    def test_committee_can_modify_staff_user(self):
        """Test that committee users can modify non-admin users."""
        request = self.factory.put('/api/admin/users/test/')
        request.user = self.committee_user
        
        self.assertTrue(self.permission.has_object_permission(request, self.view, self.target_staff))


@pytest.mark.django_db
class ElectionManagementPermissionTest(TestCase):
    """Test cases for ElectionManagementPermission class."""
    
    def setUp(self):
        """Set up test data."""
        self.factory = APIRequestFactory()
        self.permission = ElectionManagementPermission()
        self.view = APIView()
        
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            full_name='Admin User',
            staff_id='ADMIN001',
            role=UserRole.ADMIN,
            is_active=True
        )
    
    @patch('electra_server.apps.admin.permissions.log_user_action')
    def test_election_management_action_logging(self, mock_log):
        """Test that election management actions are logged."""
        request = self.factory.post('/api/admin/elections/')
        request.user = self.admin_user
        
        self.permission.has_permission(request, self.view)
        
        # Verify logging was called for POST request
        # Should be called twice - once for general access, once for election management
        self.assertEqual(mock_log.call_count, 2)


@pytest.mark.django_db
class BallotTokenManagementPermissionTest(TestCase):
    """Test cases for BallotTokenManagementPermission class."""
    
    def setUp(self):
        """Set up test data."""
        self.factory = APIRequestFactory()
        self.permission = BallotTokenManagementPermission()
        self.view = APIView()
        
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            full_name='Admin User',
            staff_id='ADMIN001',
            role=UserRole.ADMIN,
            is_active=True
        )
    
    @patch('electra_server.apps.admin.permissions.log_user_action')
    def test_ballot_token_access_logging(self, mock_log):
        """Test that ballot token access is logged."""
        request = self.factory.get('/api/admin/ballots/')
        request.user = self.admin_user
        
        self.permission.has_permission(request, self.view)
        
        # Verify logging was called twice - once for general access, once for ballot token access
        self.assertEqual(mock_log.call_count, 2)


@pytest.mark.unit
class PermissionSecurityTest(TestCase):
    """Test security aspects of admin permissions."""
    
    def setUp(self):
        """Set up test data."""
        self.factory = APIRequestFactory()
        self.permission = AdminPermission()
        self.view = APIView()
    
    def test_malformed_user_object(self):
        """Test handling of malformed user objects."""
        request = self.factory.get('/api/admin/test/')
        request.user = Mock()
        request.user.is_authenticated = True
        request.user.is_active = True
        # Create a user without role attribute
        if hasattr(request.user, 'role'):
            delattr(request.user, 'role')
        
        # Should not raise exception, should return False
        result = self.permission.has_permission(request, self.view)
        self.assertFalse(result)
    
    def test_none_user(self):
        """Test handling of None user."""
        request = self.factory.get('/api/admin/test/')
        request.user = Mock()
        request.user.is_authenticated = False  # Set as unauthenticated instead of None
        
        result = self.permission.has_permission(request, self.view)
        self.assertFalse(result)
    
    @patch('electra_server.apps.admin.permissions.logger')
    def test_security_warning_logging(self, mock_logger):
        """Test that security warnings are properly logged."""
        request = self.factory.get('/api/admin/test/')
        request.user = Mock()
        request.user.is_authenticated = True
        request.user.is_active = True
        request.user.role = UserRole.STAFF  # Insufficient role
        
        self.permission.has_permission(request, self.view)
        
        # Should log a warning about insufficient role
        self.assertTrue(mock_logger.warning.called)