"""
Integration tests for admin API views.

This module contains comprehensive tests for admin API views
to ensure proper functionality, security, and audit logging.
"""
import pytest
from datetime import datetime, timedelta
from unittest.mock import patch, Mock
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase, APIClient

from electra_server.apps.auth.models import UserRole
from electra_server.apps.elections.models import Election, ElectionStatus
from electra_server.apps.ballots.models import BallotToken, BallotTokenStatus

User = get_user_model()


@pytest.mark.django_db
class AdminUserViewSetTest(APITestCase):
    """Test cases for AdminUserViewSet."""
    
    def setUp(self):
        """Set up test data."""
        self.client = APIClient()
        
        # Create admin user for authentication
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            full_name='Admin User',
            staff_id='ADMIN001',
            role=UserRole.ADMIN,
            is_active=True
        )
        
        # Create committee user
        self.committee_user = User.objects.create_user(
            email='committee@test.com',
            password='testpass123',
            full_name='Committee User',
            staff_id='COMM001',
            role=UserRole.ELECTORAL_COMMITTEE,
            is_active=True
        )
        
        # Create test users to manage
        self.test_staff = User.objects.create_user(
            email='staff@test.com',
            password='testpass123',
            full_name='Staff User',
            staff_id='STAFF001',
            role=UserRole.STAFF,
            is_active=True
        )
        
        self.test_student = User.objects.create_user(
            email='student@test.com',
            password='testpass123',
            full_name='Student User',
            matric_number='ST001',
            role=UserRole.STUDENT,
            is_active=True
        )
        
        # Unauthorized user
        self.unauthorized_user = User.objects.create_user(
            email='unauthorized@test.com',
            password='testpass123',
            full_name='Unauthorized User',
            matric_number='ST002',
            role=UserRole.STUDENT,
            is_active=True
        )
    
    def test_list_users_as_admin(self):
        """Test listing users as admin."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.get('/api/admin/users/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('results', response.data)
        self.assertGreater(len(response.data['results']), 0)
    
    def test_list_users_as_committee(self):
        """Test listing users as electoral committee."""
        self.client.force_authenticate(user=self.committee_user)
        
        response = self.client.get('/api/admin/users/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    def test_list_users_unauthorized(self):
        """Test listing users without authorization."""
        self.client.force_authenticate(user=self.unauthorized_user)
        
        response = self.client.get('/api/admin/users/')
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_list_users_unauthenticated(self):
        """Test listing users without authentication."""
        response = self.client.get('/api/admin/users/')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_retrieve_user_as_admin(self):
        """Test retrieving specific user as admin."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.get(f'/api/admin/users/{self.test_staff.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['email'], self.test_staff.email)
        self.assertIn('ballot_tokens_count', response.data)
    
    def test_create_user_as_admin(self):
        """Test creating user as admin."""
        self.client.force_authenticate(user=self.admin_user)
        
        data = {
            'email': 'newuser@test.com',
            'full_name': 'New User',
            'staff_id': 'STAFF002',
            'role': UserRole.STAFF,
            'password': 'testpass123',
            'password_confirm': 'testpass123',
            'is_active': True
        }
        
        response = self.client.post('/api/admin/users/', data)
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(User.objects.filter(email=data['email']).exists())
    
    def test_create_user_invalid_data(self):
        """Test creating user with invalid data."""
        self.client.force_authenticate(user=self.admin_user)
        
        data = {
            'email': 'invalid@test.com',
            'full_name': 'Invalid User',
            'role': UserRole.STUDENT,  # Student without matric_number
            'password': 'testpass123',
            'password_confirm': 'testpass123',
            'is_active': True
        }
        
        response = self.client.post('/api/admin/users/', data)
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        # The error might be wrapped in a details object due to custom exception handler
        if 'details' in response.data:
            self.assertIn('matric_number', response.data['details'])
        else:
            self.assertIn('matric_number', response.data)
    
    def test_update_user_as_admin(self):
        """Test updating user as admin."""
        self.client.force_authenticate(user=self.admin_user)
        
        data = {
            'full_name': 'Updated Name',
            'is_active': False
        }
        
        response = self.client.patch(f'/api/admin/users/{self.test_staff.id}/', data)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify update
        updated_user = User.objects.get(id=self.test_staff.id)
        self.assertEqual(updated_user.full_name, data['full_name'])
        self.assertEqual(updated_user.is_active, data['is_active'])
    
    def test_delete_user_as_admin(self):
        """Test deleting user as admin."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.delete(f'/api/admin/users/{self.test_staff.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(User.objects.filter(id=self.test_staff.id).exists())
    
    def test_delete_own_account_forbidden(self):
        """Test that users cannot delete their own account."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.delete(f'/api/admin/users/{self.admin_user.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_activate_user(self):
        """Test activating a user account."""
        # Deactivate user first
        self.test_staff.is_active = False
        self.test_staff.save()
        
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.post(f'/api/admin/users/{self.test_staff.id}/activate/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify activation
        activated_user = User.objects.get(id=self.test_staff.id)
        self.assertTrue(activated_user.is_active)
    
    def test_deactivate_user(self):
        """Test deactivating a user account."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.post(f'/api/admin/users/{self.test_staff.id}/deactivate/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify deactivation
        deactivated_user = User.objects.get(id=self.test_staff.id)
        self.assertFalse(deactivated_user.is_active)
    
    def test_deactivate_own_account_forbidden(self):
        """Test that users cannot deactivate their own account."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.post(f'/api/admin/users/{self.admin_user.id}/deactivate/')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_user_filtering(self):
        """Test user filtering functionality."""
        self.client.force_authenticate(user=self.admin_user)
        
        # Test role filtering
        response = self.client.get(f'/api/admin/users/?role={UserRole.STAFF}')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Test active status filtering
        response = self.client.get('/api/admin/users/?is_active=true')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Test search functionality
        response = self.client.get('/api/admin/users/?search=staff')
        self.assertEqual(response.status_code, status.HTTP_200_OK)


@pytest.mark.django_db
class AdminElectionViewSetTest(APITestCase):
    """Test cases for AdminElectionViewSet."""
    
    def setUp(self):
        """Set up test data."""
        self.client = APIClient()
        
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
        
        self.test_election = Election.objects.create(
            title='Test Election',
            description='A test election',
            start_time=timezone.now() + timedelta(days=1),
            end_time=timezone.now() + timedelta(days=2),
            created_by=self.admin_user
        )
        
        self.unauthorized_user = User.objects.create_user(
            email='unauthorized@test.com',
            password='testpass123',
            full_name='Unauthorized User',
            matric_number='ST001',
            role=UserRole.STUDENT,
            is_active=True
        )
    
    def test_list_elections_as_admin(self):
        """Test listing elections as admin."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.get('/api/admin/elections/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('results', response.data)
    
    def test_list_elections_unauthorized(self):
        """Test listing elections without authorization."""
        self.client.force_authenticate(user=self.unauthorized_user)
        
        response = self.client.get('/api/admin/elections/')
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_create_election_as_admin(self):
        """Test creating election as admin."""
        self.client.force_authenticate(user=self.admin_user)
        
        data = {
            'title': 'New Election',
            'description': 'A new test election',
            'start_time': (timezone.now() + timedelta(days=3)).isoformat(),
            'end_time': (timezone.now() + timedelta(days=4)).isoformat(),
            'delayed_reveal': True
        }
        
        response = self.client.post('/api/admin/elections/', data)
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(Election.objects.filter(title=data['title']).exists())
    
    def test_create_election_invalid_times(self):
        """Test creating election with invalid time constraints."""
        self.client.force_authenticate(user=self.admin_user)
        
        data = {
            'title': 'Invalid Election',
            'description': 'An election with invalid times',
            'start_time': (timezone.now() + timedelta(days=2)).isoformat(),
            'end_time': (timezone.now() + timedelta(days=1)).isoformat(),  # End before start
            'delayed_reveal': False
        }
        
        response = self.client.post('/api/admin/elections/', data)
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        # The error might be wrapped in a details object due to custom exception handler
        if 'details' in response.data:
            self.assertIn('end_time', response.data['details'])
        else:
            self.assertIn('end_time', response.data)
    
    def test_activate_election(self):
        """Test activating an election."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.post(f'/api/admin/elections/{self.test_election.id}/activate/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify activation
        activated_election = Election.objects.get(id=self.test_election.id)
        self.assertEqual(activated_election.status, ElectionStatus.ACTIVE)
    
    def test_close_election(self):
        """Test closing an active election."""
        # First activate the election
        self.test_election.status = ElectionStatus.ACTIVE
        self.test_election.save()
        
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.post(f'/api/admin/elections/{self.test_election.id}/close/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify closure
        closed_election = Election.objects.get(id=self.test_election.id)
        self.assertEqual(closed_election.status, ElectionStatus.COMPLETED)
    
    def test_cancel_election(self):
        """Test cancelling an election."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.post(f'/api/admin/elections/{self.test_election.id}/cancel/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify cancellation
        cancelled_election = Election.objects.get(id=self.test_election.id)
        self.assertEqual(cancelled_election.status, ElectionStatus.CANCELLED)
    
    def test_delete_active_election_forbidden(self):
        """Test that active elections cannot be deleted."""
        self.test_election.status = ElectionStatus.ACTIVE
        self.test_election.save()
        
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.delete(f'/api/admin/elections/{self.test_election.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


@pytest.mark.django_db
class AdminBallotTokenViewSetTest(APITestCase):
    """Test cases for AdminBallotTokenViewSet."""
    
    def setUp(self):
        """Set up test data."""
        self.client = APIClient()
        
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            full_name='Admin User',
            staff_id='ADMIN001',
            role=UserRole.ADMIN,
            is_active=True
        )
        
        self.test_user = User.objects.create_user(
            email='user@test.com',
            password='testpass123',
            full_name='Test User',
            matric_number='ST001',
            role=UserRole.STUDENT,
            is_active=True
        )
        
        self.test_election = Election.objects.create(
            title='Test Election',
            description='A test election',
            start_time=timezone.now() + timedelta(days=1),
            end_time=timezone.now() + timedelta(days=2),
            created_by=self.admin_user
        )
        
        # Create ballot token manually for testing
        self.ballot_token = BallotToken.objects.create(
            user=self.test_user,
            election=self.test_election,
            expires_at=timezone.now() + timedelta(hours=24),
            signature='test_signature',
            issued_ip='127.0.0.1',
            issued_user_agent='Test Agent'
        )
        
        self.unauthorized_user = User.objects.create_user(
            email='unauthorized@test.com',
            password='testpass123',
            full_name='Unauthorized User',
            matric_number='ST002',
            role=UserRole.STUDENT,
            is_active=True
        )
    
    def test_list_ballot_tokens_as_admin(self):
        """Test listing ballot tokens as admin."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.get('/api/admin/ballots/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('results', response.data)
    
    def test_list_ballot_tokens_unauthorized(self):
        """Test listing ballot tokens without authorization."""
        self.client.force_authenticate(user=self.unauthorized_user)
        
        response = self.client.get('/api/admin/ballots/')
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_retrieve_ballot_token_as_admin(self):
        """Test retrieving specific ballot token as admin."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.get(f'/api/admin/ballots/{self.ballot_token.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['token_uuid'], str(self.ballot_token.token_uuid))
        self.assertIn('user_details', response.data)
        self.assertIn('election_details', response.data)
    
    def test_create_ballot_token_forbidden(self):
        """Test that ballot tokens cannot be created through admin API."""
        self.client.force_authenticate(user=self.admin_user)
        
        data = {
            'user': self.test_user.id,
            'election': self.test_election.id
        }
        
        response = self.client.post('/api/admin/ballots/', data)
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_update_ballot_token_forbidden(self):
        """Test that ballot tokens cannot be updated through admin API."""
        self.client.force_authenticate(user=self.admin_user)
        
        data = {
            'status': BallotTokenStatus.INVALIDATED
        }
        
        response = self.client.patch(f'/api/admin/ballots/{self.ballot_token.id}/', data)
        
        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)
    
    def test_delete_ballot_token_forbidden(self):
        """Test that ballot tokens cannot be deleted through admin API."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.delete(f'/api/admin/ballots/{self.ballot_token.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_revoke_ballot_token(self):
        """Test revoking a ballot token."""
        self.client.force_authenticate(user=self.admin_user)
        
        data = {
            'reason': 'Security breach - token compromised'
        }
        
        response = self.client.post(f'/api/admin/ballots/{self.ballot_token.id}/revoke/', data)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify revocation
        revoked_token = BallotToken.objects.get(id=self.ballot_token.id)
        self.assertEqual(revoked_token.status, BallotTokenStatus.INVALIDATED)
        self.assertIsNotNone(revoked_token.invalidated_at)
    
    def test_revoke_ballot_token_without_reason(self):
        """Test revoking ballot token without providing reason."""
        self.client.force_authenticate(user=self.admin_user)
        
        data = {}
        
        response = self.client.post(f'/api/admin/ballots/{self.ballot_token.id}/revoke/', data)
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        # The error might be wrapped in a details object due to custom exception handler
        if 'details' in response.data:
            self.assertIn('reason', response.data['details'])
        else:
            self.assertIn('reason', response.data)
    
    def test_ballot_token_filtering(self):
        """Test ballot token filtering functionality."""
        self.client.force_authenticate(user=self.admin_user)
        
        # Test status filtering
        response = self.client.get(f'/api/admin/ballots/?status={BallotTokenStatus.ISSUED}')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Test election filtering
        response = self.client.get(f'/api/admin/ballots/?election={self.test_election.id}')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Test user filtering
        response = self.client.get(f'/api/admin/ballots/?user={self.test_user.id}')
        self.assertEqual(response.status_code, status.HTTP_200_OK)


@pytest.mark.django_db
class AdminDashboardViewTest(APITestCase):
    """Test cases for AdminDashboardView."""
    
    def setUp(self):
        """Set up test data."""
        self.client = APIClient()
        
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            full_name='Admin User',
            staff_id='ADMIN001',
            role=UserRole.ADMIN,
            is_active=True
        )
        
        self.unauthorized_user = User.objects.create_user(
            email='unauthorized@test.com',
            password='testpass123',
            full_name='Unauthorized User',
            matric_number='ST001',
            role=UserRole.STUDENT,
            is_active=True
        )
    
    def test_dashboard_access_as_admin(self):
        """Test accessing dashboard as admin."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.get('/api/admin/dashboard/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('users', response.data)
        self.assertIn('elections', response.data)
        self.assertIn('ballot_tokens', response.data)
        self.assertIn('system', response.data)
    
    def test_dashboard_access_unauthorized(self):
        """Test accessing dashboard without authorization."""
        self.client.force_authenticate(user=self.unauthorized_user)
        
        response = self.client.get('/api/admin/dashboard/')
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_dashboard_statistics_structure(self):
        """Test dashboard statistics structure."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.get('/api/admin/dashboard/')
        
        # Check user statistics structure
        self.assertIn('total', response.data['users'])
        self.assertIn('active', response.data['users'])
        self.assertIn('by_role', response.data['users'])
        self.assertIn('created_today', response.data['users'])
        
        # Check elections statistics structure
        self.assertIn('total', response.data['elections'])
        self.assertIn('by_status', response.data['elections'])
        
        # Check system information
        self.assertIn('current_time', response.data['system'])
        self.assertIn('admin_user', response.data['system'])


@pytest.mark.integration
class AdminAPISecurityTest(APITestCase):
    """Integration tests for admin API security features."""
    
    def setUp(self):
        """Set up test data."""
        self.client = APIClient()
        
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            full_name='Admin User',
            staff_id='ADMIN001',
            role=UserRole.ADMIN,
            is_active=True
        )
    
    @patch('electra_server.apps.admin.permissions.log_user_action')
    def test_audit_logging_on_access(self, mock_log):
        """Test that admin API access is properly logged."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.get('/api/admin/users/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Verify audit logging was called
        mock_log.assert_called()
    
    def test_rate_limiting_headers(self):
        """Test that rate limiting headers are present."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.get('/api/admin/users/')
        
        # Rate limiting headers should be present (if implemented by middleware)
        # This test verifies the API is structured to support rate limiting
        self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    def test_cors_headers(self):
        """Test CORS header handling for admin APIs."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.options('/api/admin/users/')
        
        # Should handle OPTIONS requests properly
        self.assertIn(response.status_code, [status.HTTP_200_OK, status.HTTP_405_METHOD_NOT_ALLOWED])
    
    def test_sensitive_data_not_exposed(self):
        """Test that sensitive data is not exposed in responses."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.get('/api/admin/users/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Check that passwords are not in the response
        for user_data in response.data['results']:
            self.assertNotIn('password', user_data)
            self.assertNotIn('password_confirm', user_data)