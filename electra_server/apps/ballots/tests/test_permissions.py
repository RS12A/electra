"""
Tests for ballot permissions.
"""
import pytest
from django.contrib.auth import get_user_model
from django.test import RequestFactory
from rest_framework.test import APIRequestFactory

from electra_server.apps.auth.models import UserRole
from electra_server.apps.elections.models import Election, ElectionStatus
from ..permissions import (
    CanRequestBallotTokens, CanValidateBallotTokens, CanManageBallotTokens,
    CanViewBallotTokenStats, IsBallotTokenOwner, CanAccessOfflineQueue,
    ElectionVotingPermission, can_request_ballot_token, can_validate_ballot_token,
    can_manage_ballot_tokens, can_view_ballot_stats
)
from ..models import BallotToken

User = get_user_model()

pytestmark = pytest.mark.django_db


@pytest.fixture
def student_user():
    """Create a student user for testing."""
    return User.objects.create_user(
        email='student@test.com',
        password='testpass123',
        full_name='Test Student',
        role=UserRole.STUDENT,
        matric_number='ST123456'
    )


@pytest.fixture
def staff_user():
    """Create a staff user for testing."""
    return User.objects.create_user(
        email='staff@test.com',
        password='testpass123',
        full_name='Test Staff',
        role=UserRole.STAFF,
        staff_id='SF123456'
    )


@pytest.fixture
def admin_user():
    """Create an admin user for testing."""
    return User.objects.create_user(
        email='admin@test.com',
        password='testpass123',
        full_name='Test Admin',
        role=UserRole.ADMIN,
        staff_id='AD123456'
    )


@pytest.fixture
def electoral_committee_user():
    """Create an electoral committee user for testing."""
    return User.objects.create_user(
        email='ec@test.com',
        password='testpass123',
        full_name='Test EC',
        role=UserRole.ELECTORAL_COMMITTEE,
        staff_id='EC123456'
    )


@pytest.fixture
def request_factory():
    """Create request factory for testing."""
    return RequestFactory()


@pytest.fixture
def api_request_factory():
    """Create API request factory for testing."""
    return APIRequestFactory()


class TestCanRequestBallotTokens:
    """Test cases for CanRequestBallotTokens permission."""
    
    def test_student_can_request_tokens(self, student_user, api_request_factory):
        """Test that students can request ballot tokens."""
        request = api_request_factory.post('/')
        request.user = student_user
        
        permission = CanRequestBallotTokens()
        assert permission.has_permission(request, None) is True
    
    def test_staff_can_request_tokens(self, staff_user, api_request_factory):
        """Test that staff can request ballot tokens."""
        request = api_request_factory.post('/')
        request.user = staff_user
        
        permission = CanRequestBallotTokens()
        assert permission.has_permission(request, None) is True
    
    def test_admin_cannot_request_tokens(self, admin_user, api_request_factory):
        """Test that admin users cannot request ballot tokens."""
        request = api_request_factory.post('/')
        request.user = admin_user
        
        permission = CanRequestBallotTokens()
        assert permission.has_permission(request, None) is False
    
    def test_electoral_committee_cannot_request_tokens(self, electoral_committee_user, api_request_factory):
        """Test that electoral committee members cannot request ballot tokens."""
        request = api_request_factory.post('/')
        request.user = electoral_committee_user
        
        permission = CanRequestBallotTokens()
        assert permission.has_permission(request, None) is False
    
    def test_unauthenticated_cannot_request_tokens(self, api_request_factory):
        """Test that unauthenticated users cannot request ballot tokens."""
        request = api_request_factory.post('/')
        request.user = None
        
        permission = CanRequestBallotTokens()
        assert permission.has_permission(request, None) is False


class TestCanValidateBallotTokens:
    """Test cases for CanValidateBallotTokens permission."""
    
    def test_authenticated_user_can_validate(self, student_user, api_request_factory):
        """Test that authenticated users can validate tokens."""
        request = api_request_factory.post('/')
        request.user = student_user
        
        permission = CanValidateBallotTokens()
        assert permission.has_permission(request, None) is True
    
    def test_admin_can_validate(self, admin_user, api_request_factory):
        """Test that admin users can validate tokens."""
        request = api_request_factory.post('/')
        request.user = admin_user
        
        permission = CanValidateBallotTokens()
        assert permission.has_permission(request, None) is True
    
    def test_unauthenticated_cannot_validate(self, api_request_factory):
        """Test that unauthenticated users cannot validate tokens."""
        request = api_request_factory.post('/')
        request.user = None
        
        permission = CanValidateBallotTokens()
        assert permission.has_permission(request, None) is False


class TestCanManageBallotTokens:
    """Test cases for CanManageBallotTokens permission."""
    
    def test_admin_can_manage(self, admin_user, api_request_factory):
        """Test that admin users can manage ballot tokens."""
        request = api_request_factory.get('/')
        request.user = admin_user
        
        permission = CanManageBallotTokens()
        assert permission.has_permission(request, None) is True
    
    def test_electoral_committee_can_manage(self, electoral_committee_user, api_request_factory):
        """Test that electoral committee members can manage ballot tokens."""
        request = api_request_factory.get('/')
        request.user = electoral_committee_user
        
        permission = CanManageBallotTokens()
        assert permission.has_permission(request, None) is True
    
    def test_student_cannot_manage(self, student_user, api_request_factory):
        """Test that students cannot manage ballot tokens."""
        request = api_request_factory.get('/')
        request.user = student_user
        
        permission = CanManageBallotTokens()
        assert permission.has_permission(request, None) is False
    
    def test_staff_cannot_manage(self, staff_user, api_request_factory):
        """Test that staff cannot manage ballot tokens."""
        request = api_request_factory.get('/')
        request.user = staff_user
        
        permission = CanManageBallotTokens()
        assert permission.has_permission(request, None) is False


class TestCanViewBallotTokenStats:
    """Test cases for CanViewBallotTokenStats permission."""
    
    def test_admin_can_view_stats(self, admin_user, api_request_factory):
        """Test that admin users can view ballot token statistics."""
        request = api_request_factory.get('/')
        request.user = admin_user
        
        permission = CanViewBallotTokenStats()
        assert permission.has_permission(request, None) is True
    
    def test_electoral_committee_can_view_stats(self, electoral_committee_user, api_request_factory):
        """Test that electoral committee members can view ballot token statistics."""
        request = api_request_factory.get('/')
        request.user = electoral_committee_user
        
        permission = CanViewBallotTokenStats()
        assert permission.has_permission(request, None) is True
    
    def test_student_cannot_view_stats(self, student_user, api_request_factory):
        """Test that students cannot view ballot token statistics."""
        request = api_request_factory.get('/')
        request.user = student_user
        
        permission = CanViewBallotTokenStats()
        assert permission.has_permission(request, None) is False


class TestIsBallotTokenOwner:
    """Test cases for IsBallotTokenOwner permission."""
    
    def test_token_owner_can_access(self, student_user, api_request_factory):
        """Test that token owners can access their tokens."""
        creator = User.objects.create_user(
            email='creator@test.com',
            password='testpass123',
            full_name='Creator',
            role=UserRole.ELECTORAL_COMMITTEE,
            staff_id='EC123456'
        )
        
        election = Election.objects.create(
            title='Test Election',
            description='Test election',
            start_time=timezone.now() - timedelta(hours=1),
            end_time=timezone.now() + timedelta(hours=1),
            status=ElectionStatus.ACTIVE,
            created_by=creator
        )
        
        token = BallotToken.objects.create(
            user=student_user,
            election=election,
            issued_ip='192.168.1.1',
            signature='fake_signature'
        )
        
        request = api_request_factory.get('/')
        request.user = student_user
        
        permission = IsBallotTokenOwner()
        assert permission.has_object_permission(request, None, token) is True
    
    def test_non_owner_cannot_access(self, student_user, staff_user, api_request_factory):
        """Test that non-owners cannot access tokens."""
        creator = User.objects.create_user(
            email='creator@test.com',
            password='testpass123',
            full_name='Creator',
            role=UserRole.ELECTORAL_COMMITTEE,
            staff_id='EC123456'
        )
        
        election = Election.objects.create(
            title='Test Election',
            description='Test election',
            start_time='2023-01-01 10:00:00',
            end_time='2023-01-01 18:00:00',
            status=ElectionStatus.ACTIVE,
            created_by=creator
        )
        
        token = BallotToken.objects.create(
            user=student_user,
            election=election,
            issued_ip='192.168.1.1',
            signature='fake_signature'
        )
        
        request = api_request_factory.get('/')
        request.user = staff_user  # Different user
        
        permission = IsBallotTokenOwner()
        assert permission.has_object_permission(request, None, token) is False


class TestUtilityFunctions:
    """Test cases for utility functions."""
    
    def test_can_request_ballot_token_utility(self, student_user):
        """Test can_request_ballot_token utility function."""
        creator = User.objects.create_user(
            email='creator@test.com',
            password='testpass123',
            full_name='Creator',
            role=UserRole.ELECTORAL_COMMITTEE,
            staff_id='EC123456'
        )
        
        election = Election.objects.create(
            title='Test Election',
            description='Test election',
            start_time='2023-01-01 10:00:00',
            end_time='2023-01-01 18:00:00',
            status=ElectionStatus.ACTIVE,
            created_by=creator
        )
        
        # Should be able to request initially
        assert can_request_ballot_token(student_user, election) is True
        
        # Create a token for the user
        BallotToken.objects.create(
            user=student_user,
            election=election,
            issued_ip='192.168.1.1',
            signature='fake_signature'
        )
        
        # Should not be able to request again
        assert can_request_ballot_token(student_user, election) is False
    
    def test_can_validate_ballot_token_utility(self, student_user, admin_user):
        """Test can_validate_ballot_token utility function."""
        assert can_validate_ballot_token(student_user) is True
        assert can_validate_ballot_token(admin_user) is True
        assert can_validate_ballot_token(None) is False
    
    def test_can_manage_ballot_tokens_utility(self, student_user, admin_user, electoral_committee_user):
        """Test can_manage_ballot_tokens utility function."""
        assert can_manage_ballot_tokens(student_user) is False
        assert can_manage_ballot_tokens(admin_user) is True
        assert can_manage_ballot_tokens(electoral_committee_user) is True
    
    def test_can_view_ballot_stats_utility(self, student_user, admin_user, electoral_committee_user):
        """Test can_view_ballot_stats utility function."""
        assert can_view_ballot_stats(student_user) is False
        assert can_view_ballot_stats(admin_user) is True
        assert can_view_ballot_stats(electoral_committee_user) is True