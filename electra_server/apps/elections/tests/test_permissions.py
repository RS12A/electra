"""
Test permissions for elections app.

Unit tests for election-related permissions.
"""
from unittest.mock import Mock
from django.test import TestCase
from rest_framework.request import Request

from electra_server.apps.auth.models import UserRole
from electra_server.apps.auth.tests.factories import (
    AdminUserFactory,
    ElectoralCommitteeUserFactory,
    StudentUserFactory,
    StaffUserFactory
)
from ..models import ElectionStatus
from ..permissions import (
    CanManageElections,
    CanViewElections,
    CanVoteInElections,
    IsElectionCreatorOrManager,
    ElectionManagementPermission
)
from .factories import DraftElectionFactory, ActiveElectionFactory


class CanManageElectionsTest(TestCase):
    """Test CanManageElections permission."""
    
    def setUp(self):
        """Set up test data."""
        self.permission = CanManageElections()
        self.view = Mock()
    
    def test_unauthenticated_user(self):
        """Test unauthenticated user."""
        request = Mock()
        request.user = None
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertFalse(result)
    
    def test_inactive_user(self):
        """Test inactive user."""
        user = AdminUserFactory(is_active=False)
        request = Mock()
        request.user = user
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertFalse(result)
    
    def test_admin_user(self):
        """Test admin user."""
        user = AdminUserFactory()
        request = Mock()
        request.user = user
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertTrue(result)
    
    def test_electoral_committee_user(self):
        """Test electoral committee user."""
        user = ElectoralCommitteeUserFactory()
        request = Mock()
        request.user = user
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertTrue(result)
    
    def test_student_user(self):
        """Test student user."""
        user = StudentUserFactory()
        request = Mock()
        request.user = user
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertFalse(result)
    
    def test_staff_user(self):
        """Test staff user."""
        user = StaffUserFactory()
        request = Mock()
        request.user = user
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertFalse(result)


class CanViewElectionsTest(TestCase):
    """Test CanViewElections permission."""
    
    def setUp(self):
        """Set up test data."""
        self.permission = CanViewElections()
        self.view = Mock()
        self.admin_user = AdminUserFactory()
        self.student_user = StudentUserFactory()
    
    def test_unauthenticated_user(self):
        """Test unauthenticated user."""
        request = Mock()
        request.user = None
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertFalse(result)
    
    def test_authenticated_user(self):
        """Test authenticated user."""
        request = Mock()
        request.user = self.student_user
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertTrue(result)
    
    def test_admin_view_draft_election(self):
        """Test admin viewing draft election."""
        election = DraftElectionFactory(created_by=self.admin_user)
        request = Mock()
        request.user = self.admin_user
        
        result = self.permission.has_object_permission(request, self.view, election)
        
        self.assertTrue(result)
    
    def test_student_view_draft_election(self):
        """Test student viewing draft election."""
        election = DraftElectionFactory(created_by=self.admin_user)
        request = Mock()
        request.user = self.student_user
        
        result = self.permission.has_object_permission(request, self.view, election)
        
        self.assertFalse(result)
    
    def test_student_view_active_election(self):
        """Test student viewing active election."""
        election = ActiveElectionFactory(created_by=self.admin_user)
        request = Mock()
        request.user = self.student_user
        
        result = self.permission.has_object_permission(request, self.view, election)
        
        self.assertTrue(result)


class CanVoteInElectionsTest(TestCase):
    """Test CanVoteInElections permission."""
    
    def setUp(self):
        """Set up test data."""
        self.permission = CanVoteInElections()
        self.view = Mock()
    
    def test_student_can_vote(self):
        """Test student can vote."""
        user = StudentUserFactory()
        request = Mock()
        request.user = user
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertTrue(result)
    
    def test_staff_can_vote(self):
        """Test staff can vote."""
        user = StaffUserFactory()
        request = Mock()
        request.user = user
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertTrue(result)
    
    def test_admin_cannot_vote(self):
        """Test admin cannot vote (neutrality)."""
        user = AdminUserFactory()
        request = Mock()
        request.user = user
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertFalse(result)
    
    def test_electoral_committee_cannot_vote(self):
        """Test electoral committee cannot vote (neutrality)."""
        user = ElectoralCommitteeUserFactory()
        request = Mock()
        request.user = user
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertFalse(result)


class IsElectionCreatorOrManagerTest(TestCase):
    """Test IsElectionCreatorOrManager permission."""
    
    def setUp(self):
        """Set up test data."""
        self.permission = IsElectionCreatorOrManager()
        self.view = Mock()
        self.admin_user = AdminUserFactory()
        self.student_user = StudentUserFactory()
        self.other_admin = AdminUserFactory()
    
    def test_unauthenticated_user(self):
        """Test unauthenticated user."""
        election = DraftElectionFactory(created_by=self.admin_user)
        request = Mock()
        request.user = None
        
        result = self.permission.has_object_permission(request, self.view, election)
        
        self.assertFalse(result)
    
    def test_admin_user_any_election(self):
        """Test admin user can access any election."""
        election = DraftElectionFactory(created_by=self.other_admin)
        request = Mock()
        request.user = self.admin_user
        
        result = self.permission.has_object_permission(request, self.view, election)
        
        self.assertTrue(result)
    
    def test_electoral_committee_any_election(self):
        """Test electoral committee can access any election."""
        user = ElectoralCommitteeUserFactory()
        election = DraftElectionFactory(created_by=self.admin_user)
        request = Mock()
        request.user = user
        
        result = self.permission.has_object_permission(request, self.view, election)
        
        self.assertTrue(result)
    
    def test_creator_own_election(self):
        """Test creator can access their own election."""
        election = DraftElectionFactory(created_by=self.admin_user)
        request = Mock()
        request.user = self.admin_user
        
        result = self.permission.has_object_permission(request, self.view, election)
        
        self.assertTrue(result)
    
    def test_non_creator_non_manager(self):
        """Test non-creator non-manager cannot access election."""
        election = DraftElectionFactory(created_by=self.admin_user)
        request = Mock()
        request.user = self.student_user
        
        result = self.permission.has_object_permission(request, self.view, election)
        
        self.assertFalse(result)


class ElectionManagementPermissionTest(TestCase):
    """Test ElectionManagementPermission comprehensive permission."""
    
    def setUp(self):
        """Set up test data."""
        self.permission = ElectionManagementPermission()
        self.view = Mock()
        self.admin_user = AdminUserFactory()
        self.student_user = StudentUserFactory()
    
    def test_get_request_authenticated_user(self):
        """Test GET request by authenticated user."""
        request = Mock()
        request.method = 'GET'
        request.user = self.student_user
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertTrue(result)
    
    def test_post_request_admin_user(self):
        """Test POST request by admin user."""
        request = Mock()
        request.method = 'POST'
        request.user = self.admin_user
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertTrue(result)
    
    def test_post_request_student_user(self):
        """Test POST request by student user."""
        request = Mock()
        request.method = 'POST'
        request.user = self.student_user
        
        result = self.permission.has_permission(request, self.view)
        
        self.assertFalse(result)
    
    def test_object_permission_get_draft_election_student(self):
        """Test object permission for GET request on draft election by student."""
        election = DraftElectionFactory(created_by=self.admin_user)
        request = Mock()
        request.method = 'GET'
        request.user = self.student_user
        
        result = self.permission.has_object_permission(request, self.view, election)
        
        self.assertFalse(result)
    
    def test_object_permission_get_active_election_student(self):
        """Test object permission for GET request on active election by student."""
        election = ActiveElectionFactory(created_by=self.admin_user)
        request = Mock()
        request.method = 'GET'
        request.user = self.student_user
        
        result = self.permission.has_object_permission(request, self.view, election)
        
        self.assertTrue(result)
    
    def test_object_permission_patch_request_admin(self):
        """Test object permission for PATCH request by admin."""
        election = DraftElectionFactory(created_by=self.admin_user)
        request = Mock()
        request.method = 'PATCH'
        request.user = self.admin_user
        
        result = self.permission.has_object_permission(request, self.view, election)
        
        self.assertTrue(result)
    
    def test_object_permission_patch_request_student(self):
        """Test object permission for PATCH request by student."""
        election = DraftElectionFactory(created_by=self.admin_user)
        request = Mock()
        request.method = 'PATCH'
        request.user = self.student_user
        
        result = self.permission.has_object_permission(request, self.view, election)
        
        self.assertFalse(result)