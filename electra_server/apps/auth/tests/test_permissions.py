"""
Unit tests for authentication permissions.

This module tests all custom permission classes and utility functions
for role-based access control.
"""
from unittest.mock import Mock

from django.test import TestCase
from rest_framework.request import Request

from ..permissions import (
    IsAuthenticated, IsOwnerOrReadOnly, RoleBasedPermission,
    IsStudent, IsStaff, IsAdmin, IsElectoralCommittee,
    IsElectionManager, CanVote, CanRunForElection,
    has_role, can_manage_elections, can_vote, can_be_candidate
)
from ..models import UserRole
from .factories import (
    StudentUserFactory, StaffUserFactory, AdminUserFactory,
    ElectoralCommitteeUserFactory, CandidateUserFactory
)


class IsAuthenticatedTest(TestCase):
    """Test IsAuthenticated permission."""
    
    def setUp(self):
        self.permission = IsAuthenticated()
        self.view = Mock()
    
    def test_authenticated_active_user(self):
        """Test authenticated active user."""
        user = StudentUserFactory()
        request = Mock()
        request.user = user
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertTrue(result)
    
    def test_authenticated_inactive_user(self):
        """Test authenticated inactive user."""
        user = StudentUserFactory(is_active=False)
        request = Mock()
        request.user = user
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertFalse(result)
    
    def test_unauthenticated_user(self):
        """Test unauthenticated user."""
        request = Mock()
        request.user = None
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertFalse(result)
    
    def test_anonymous_user(self):
        """Test anonymous user."""
        request = Mock()
        request.user = Mock()
        request.user.is_authenticated = False
        request.user.is_active = True
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertFalse(result)


class IsOwnerOrReadOnlyTest(TestCase):
    """Test IsOwnerOrReadOnly permission."""
    
    def setUp(self):
        self.permission = IsOwnerOrReadOnly()
        self.view = Mock()
        self.user = StudentUserFactory()
        self.other_user = StudentUserFactory()
    
    def test_read_permission_any_user(self):
        """Test read permission for any user."""
        request = Mock()
        request.method = 'GET'
        request.user = self.other_user
        
        result = self.permission.has_object_permission(request, self.view, self.user)
        
        self.assertTrue(result)
    
    def test_write_permission_owner(self):
        """Test write permission for owner."""
        request = Mock()
        request.method = 'PUT'
        request.user = self.user
        
        result = self.permission.has_object_permission(request, self.view, self.user)
        
        self.assertTrue(result)
    
    def test_write_permission_non_owner(self):
        """Test write permission for non-owner."""
        request = Mock()
        request.method = 'PUT'
        request.user = self.other_user
        
        result = self.permission.has_object_permission(request, self.view, self.user)
        
        self.assertFalse(result)


class RoleBasedPermissionTest(TestCase):
    """Test RoleBasedPermission base class."""
    
    def setUp(self):
        self.view = Mock()
    
    def test_unauthenticated_user(self):
        """Test unauthenticated user."""
        permission = RoleBasedPermission()
        permission.allowed_roles = [UserRole.STUDENT]
        
        request = Mock()
        request.user = None
        
        result = permission.has_permission(request, self.view)
        
        self.assertFalse(result)
    
    def test_inactive_user(self):
        """Test inactive user."""
        permission = RoleBasedPermission()
        permission.allowed_roles = [UserRole.STUDENT]
        
        user = StudentUserFactory(is_active=False)
        request = Mock()
        request.user = user
        
        result = permission.has_permission(request, self.view)
        
        self.assertFalse(result)
    
    def test_allowed_role(self):
        """Test user with allowed role."""
        permission = RoleBasedPermission()
        permission.allowed_roles = [UserRole.STUDENT]
        
        user = StudentUserFactory()
        request = Mock()
        request.user = user
        
        result = permission.has_permission(request, self.view)
        
        self.assertTrue(result)
    
    def test_disallowed_role(self):
        """Test user with disallowed role."""
        permission = RoleBasedPermission()
        permission.allowed_roles = [UserRole.STUDENT]
        
        user = StaffUserFactory()
        request = Mock()
        request.user = user
        
        result = permission.has_permission(request, self.view)
        
        self.assertFalse(result)


class SpecificRolePermissionTest(TestCase):
    """Test specific role permission classes."""
    
    def setUp(self):
        self.view = Mock()
        self.student = StudentUserFactory()
        self.staff = StaffUserFactory()
        self.admin = AdminUserFactory()
        self.committee = ElectoralCommitteeUserFactory()
        self.candidate = CandidateUserFactory()
    
    def test_is_student_permission(self):
        """Test IsStudent permission."""
        permission = IsStudent()
        
        # Student should have permission
        request = Mock()
        request.user = self.student
        self.assertTrue(permission.has_permission(request, self.view))
        
        # Staff should not have permission
        request.user = self.staff
        self.assertFalse(permission.has_permission(request, self.view))
    
    def test_is_staff_permission(self):
        """Test IsStaff permission."""
        permission = IsStaff()
        
        # Staff should have permission
        request = Mock()
        request.user = self.staff
        self.assertTrue(permission.has_permission(request, self.view))
        
        # Student should not have permission
        request.user = self.student
        self.assertFalse(permission.has_permission(request, self.view))
    
    def test_is_admin_permission(self):
        """Test IsAdmin permission."""
        permission = IsAdmin()
        
        # Admin should have permission
        request = Mock()
        request.user = self.admin
        self.assertTrue(permission.has_permission(request, self.view))
        
        # Student should not have permission
        request.user = self.student
        self.assertFalse(permission.has_permission(request, self.view))
    
    def test_is_electoral_committee_permission(self):
        """Test IsElectoralCommittee permission."""
        permission = IsElectoralCommittee()
        
        # Committee member should have permission
        request = Mock()
        request.user = self.committee
        self.assertTrue(permission.has_permission(request, self.view))
        
        # Student should not have permission
        request.user = self.student
        self.assertFalse(permission.has_permission(request, self.view))
    
    def test_is_election_manager_permission(self):
        """Test IsElectionManager permission."""
        permission = IsElectionManager()
        
        # Admin should have permission
        request = Mock()
        request.user = self.admin
        self.assertTrue(permission.has_permission(request, self.view))
        
        # Committee member should have permission
        request.user = self.committee
        self.assertTrue(permission.has_permission(request, self.view))
        
        # Student should not have permission
        request.user = self.student
        self.assertFalse(permission.has_permission(request, self.view))
        
        # Staff should not have permission
        request.user = self.staff
        self.assertFalse(permission.has_permission(request, self.view))


class CanVotePermissionTest(TestCase):
    """Test CanVote permission."""
    
    def setUp(self):
        self.permission = CanVote()
        self.view = Mock()
        self.student = StudentUserFactory()
        self.staff = StaffUserFactory()
        self.admin = AdminUserFactory()
        self.committee = ElectoralCommitteeUserFactory()
        self.candidate = CandidateUserFactory()
    
    def test_student_can_vote(self):
        """Test that students can vote."""
        request = Mock()
        request.user = self.student
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertTrue(result)
    
    def test_staff_can_vote(self):
        """Test that staff can vote."""
        request = Mock()
        request.user = self.staff
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertTrue(result)
    
    def test_candidate_can_vote(self):
        """Test that candidates can vote."""
        request = Mock()
        request.user = self.candidate
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertTrue(result)
    
    def test_admin_cannot_vote(self):
        """Test that admins cannot vote (neutrality)."""
        request = Mock()
        request.user = self.admin
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertFalse(result)
    
    def test_committee_cannot_vote(self):
        """Test that committee members cannot vote (neutrality)."""
        request = Mock()
        request.user = self.committee
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertFalse(result)


class CanRunForElectionPermissionTest(TestCase):
    """Test CanRunForElection permission."""
    
    def setUp(self):
        self.permission = CanRunForElection()
        self.view = Mock()
        self.student = StudentUserFactory()
        self.staff = StaffUserFactory()
        self.admin = AdminUserFactory()
        self.committee = ElectoralCommitteeUserFactory()
    
    def test_student_can_run(self):
        """Test that students can run for election."""
        request = Mock()
        request.user = self.student
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertTrue(result)
    
    def test_staff_can_run(self):
        """Test that staff can run for election."""
        request = Mock()
        request.user = self.staff
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertTrue(result)
    
    def test_admin_cannot_run(self):
        """Test that admins cannot run for election."""
        request = Mock()
        request.user = self.admin
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertFalse(result)
    
    def test_committee_cannot_run(self):
        """Test that committee members cannot run for election."""
        request = Mock()
        request.user = self.committee
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertFalse(result)


class PermissionUtilityFunctionTest(TestCase):
    """Test permission utility functions."""
    
    def setUp(self):
        self.student = StudentUserFactory()
        self.staff = StaffUserFactory()
        self.admin = AdminUserFactory()
        self.committee = ElectoralCommitteeUserFactory()
        self.candidate = CandidateUserFactory()
    
    def test_has_role_function(self):
        """Test has_role utility function."""
        # Test single role
        self.assertTrue(has_role(self.student, UserRole.STUDENT))
        self.assertFalse(has_role(self.student, UserRole.STAFF))
        
        # Test multiple roles
        self.assertTrue(has_role(self.admin, UserRole.ADMIN, UserRole.STAFF))
        self.assertFalse(has_role(self.student, UserRole.ADMIN, UserRole.STAFF))
        
        # Test None user
        self.assertFalse(has_role(None, UserRole.STUDENT))
        
        # Test unauthenticated user
        user = Mock()
        user.is_authenticated = False
        self.assertFalse(has_role(user, UserRole.STUDENT))
    
    def test_can_manage_elections_function(self):
        """Test can_manage_elections utility function."""
        self.assertFalse(can_manage_elections(self.student))
        self.assertFalse(can_manage_elections(self.staff))
        self.assertTrue(can_manage_elections(self.admin))
        self.assertTrue(can_manage_elections(self.committee))
        
        # Test None user
        self.assertFalse(can_manage_elections(None))
    
    def test_can_vote_function(self):
        """Test can_vote utility function."""
        self.assertTrue(can_vote(self.student))
        self.assertTrue(can_vote(self.staff))
        self.assertTrue(can_vote(self.candidate))
        self.assertFalse(can_vote(self.admin))
        self.assertFalse(can_vote(self.committee))
        
        # Test None user
        self.assertFalse(can_vote(None))
    
    def test_can_be_candidate_function(self):
        """Test can_be_candidate utility function."""
        self.assertTrue(can_be_candidate(self.student))
        self.assertTrue(can_be_candidate(self.staff))
        self.assertFalse(can_be_candidate(self.admin))
        self.assertFalse(can_be_candidate(self.committee))
        
        # Test None user
        self.assertFalse(can_be_candidate(None))