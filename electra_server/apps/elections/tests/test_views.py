"""
Test views for elections app.

Integration tests for election management API endpoints.
"""
import json
from datetime import timedelta
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from electra_server.apps.auth.tests.factories import (
    AdminUserFactory,
    ElectoralCommitteeUserFactory,
    StudentUserFactory,
    StaffUserFactory
)
from ..models import Election, ElectionStatus
from .factories import (
    DraftElectionFactory,
    ActiveElectionFactory,
    CompletedElectionFactory,
    CancelledElectionFactory
)


class ElectionListViewTest(APITestCase):
    """Test ElectionListView."""
    
    def setUp(self):
        """Set up test data."""
        self.admin_user = AdminUserFactory()
        self.student_user = StudentUserFactory()
        self.url = reverse('elections:election_list')
        
        # Clear any existing elections
        Election.objects.all().delete()
        
        # Create test elections
        self.draft_election = DraftElectionFactory(created_by=self.admin_user)
        self.active_election = ActiveElectionFactory(created_by=self.admin_user)
        self.completed_election = CompletedElectionFactory(created_by=self.admin_user)
    
    def test_unauthenticated_access(self):
        """Test unauthenticated access is denied."""
        response = self.client.get(self.url)
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_admin_sees_all_elections(self):
        """Test admin user sees all elections including drafts."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get(self.url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Check that we can see all our test elections
        election_ids = [item['id'] for item in response.data]
        self.assertIn(str(self.draft_election.id), election_ids)
        self.assertIn(str(self.active_election.id), election_ids)
        self.assertIn(str(self.completed_election.id), election_ids)
    
    def test_student_sees_non_draft_elections(self):
        """Test student user only sees non-draft elections."""
        self.client.force_authenticate(user=self.student_user)
        response = self.client.get(self.url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Ensure draft is not in the response
        election_ids = [item['id'] for item in response.data]
        self.assertNotIn(str(self.draft_election.id), election_ids)
        
        # But active and completed should be visible
        self.assertIn(str(self.active_election.id), election_ids)
        self.assertIn(str(self.completed_election.id), election_ids)


class ElectionDetailViewTest(APITestCase):
    """Test ElectionDetailView."""
    
    def setUp(self):
        """Set up test data."""
        self.admin_user = AdminUserFactory()
        self.student_user = StudentUserFactory()
        
        self.draft_election = DraftElectionFactory(created_by=self.admin_user)
        self.active_election = ActiveElectionFactory(created_by=self.admin_user)
    
    def test_admin_view_draft_election(self):
        """Test admin can view draft election details."""
        self.client.force_authenticate(user=self.admin_user)
        url = reverse('elections:election_detail', kwargs={'id': self.draft_election.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['id'], str(self.draft_election.id))
        self.assertEqual(response.data['title'], self.draft_election.title)
    
    def test_student_cannot_view_draft_election(self):
        """Test student cannot view draft election details."""
        self.client.force_authenticate(user=self.student_user)
        url = reverse('elections:election_detail', kwargs={'id': self.draft_election.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_student_can_view_active_election(self):
        """Test student can view active election details."""
        self.client.force_authenticate(user=self.student_user)
        url = reverse('elections:election_detail', kwargs={'id': self.active_election.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['id'], str(self.active_election.id))


class ElectionCreateViewTest(APITestCase):
    """Test ElectionCreateView."""
    
    def setUp(self):
        """Set up test data."""
        self.admin_user = AdminUserFactory()
        self.student_user = StudentUserFactory()
        self.url = reverse('elections:election_create')
        
        self.valid_data = {
            'title': 'New Test Election',
            'description': 'A test election for unit testing',
            'start_time': (timezone.now() + timedelta(hours=1)).isoformat(),
            'end_time': (timezone.now() + timedelta(hours=3)).isoformat(),
            'delayed_reveal': False
        }
    
    def test_unauthenticated_cannot_create(self):
        """Test unauthenticated user cannot create election."""
        response = self.client.post(self.url, self.valid_data)
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_student_cannot_create(self):
        """Test student cannot create election."""
        self.client.force_authenticate(user=self.student_user)
        response = self.client.post(self.url, self.valid_data)
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_admin_can_create(self):
        """Test admin can create election."""
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.post(self.url, self.valid_data)
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Verify election was created
        election = Election.objects.get(title='New Test Election')
        self.assertEqual(election.created_by, self.admin_user)
        self.assertEqual(election.status, ElectionStatus.DRAFT)
    
    def test_electoral_committee_can_create(self):
        """Test electoral committee member can create election."""
        electoral_user = ElectoralCommitteeUserFactory()
        self.client.force_authenticate(user=electoral_user)
        response = self.client.post(self.url, self.valid_data)
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
    
    def test_invalid_time_validation(self):
        """Test validation for invalid time ranges."""
        self.client.force_authenticate(user=self.admin_user)
        
        # End time before start time
        invalid_data = self.valid_data.copy()
        invalid_data['end_time'] = (timezone.now() + timedelta(minutes=30)).isoformat()
        
        response = self.client.post(self.url, invalid_data)
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        # Check if error is in response data or details
        if 'details' in response.data:
            self.assertIn('end_time', response.data['details'])
        else:
            self.assertIn('end_time', response.data)
    
    def test_past_start_time_validation(self):
        """Test validation for past start time."""
        self.client.force_authenticate(user=self.admin_user)
        
        invalid_data = self.valid_data.copy()
        invalid_data['start_time'] = (timezone.now() - timedelta(hours=1)).isoformat()
        
        response = self.client.post(self.url, invalid_data)
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        # Check if error is in response data or details
        if 'details' in response.data:
            self.assertIn('start_time', response.data['details'])
        else:
            self.assertIn('start_time', response.data)


class ElectionUpdateViewTest(APITestCase):
    """Test ElectionUpdateView."""
    
    def setUp(self):
        """Set up test data."""
        self.admin_user = AdminUserFactory()
        self.student_user = StudentUserFactory()
        self.other_admin = AdminUserFactory()
        
        self.election = DraftElectionFactory(created_by=self.admin_user)
        self.url = reverse('elections:election_update', kwargs={'id': self.election.id})
        
        self.update_data = {
            'title': 'Updated Election Title',
            'description': 'Updated description',
            'start_time': (timezone.now() + timedelta(hours=2)).isoformat(),
            'end_time': (timezone.now() + timedelta(hours=4)).isoformat(),
            'delayed_reveal': True
        }
    
    def test_admin_can_update_any_election(self):
        """Test admin can update any election."""
        self.client.force_authenticate(user=self.other_admin)
        response = self.client.patch(self.url, self.update_data)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify updates
        self.election.refresh_from_db()
        self.assertEqual(self.election.title, 'Updated Election Title')
    
    def test_student_cannot_update(self):
        """Test student cannot update election."""
        self.client.force_authenticate(user=self.student_user)
        response = self.client.patch(self.url, self.update_data)
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_cannot_update_started_election_times(self):
        """Test cannot update times of started election."""
        # Create election that has started
        started_election = ActiveElectionFactory(
            start_time=timezone.now() - timedelta(minutes=30),
            created_by=self.admin_user
        )
        url = reverse('elections:election_update', kwargs={'id': started_election.id})
        
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.patch(url, {
            'start_time': (timezone.now() + timedelta(hours=1)).isoformat()
        })
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class ElectionDeleteViewTest(APITestCase):
    """Test ElectionDeleteView."""
    
    def setUp(self):
        """Set up test data."""
        self.admin_user = AdminUserFactory()
        self.student_user = StudentUserFactory()
        
        self.draft_election = DraftElectionFactory(created_by=self.admin_user)
        self.active_election = ActiveElectionFactory(created_by=self.admin_user)
    
    def test_admin_can_delete_draft_election(self):
        """Test admin can delete draft election."""
        url = reverse('elections:election_delete', kwargs={'id': self.draft_election.id})
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.delete(url)
        
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Election.objects.filter(id=self.draft_election.id).exists())
    
    def test_cannot_delete_active_election(self):
        """Test cannot delete active election."""
        url = reverse('elections:election_delete', kwargs={'id': self.active_election.id})
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.delete(url)
        
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
    
    def test_student_cannot_delete(self):
        """Test student cannot delete election."""
        url = reverse('elections:election_delete', kwargs={'id': self.draft_election.id})
        self.client.force_authenticate(user=self.student_user)
        response = self.client.delete(url)
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)


class ElectionStatusViewTest(APITestCase):
    """Test ElectionStatusView."""
    
    def setUp(self):
        """Set up test data."""
        self.admin_user = AdminUserFactory()
        self.student_user = StudentUserFactory()
    
    def test_activate_draft_election(self):
        """Test activating a draft election."""
        election = DraftElectionFactory(
            start_time=timezone.now() + timedelta(hours=1),
            created_by=self.admin_user
        )
        url = reverse('elections:election_status', kwargs={'id': election.id})
        
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.patch(url, {'action': 'activate'})
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        election.refresh_from_db()
        self.assertEqual(election.status, ElectionStatus.ACTIVE)
    
    def test_cancel_election(self):
        """Test cancelling an election."""
        election = DraftElectionFactory(created_by=self.admin_user)
        url = reverse('elections:election_status', kwargs={'id': election.id})
        
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.patch(url, {'action': 'cancel'})
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        election.refresh_from_db()
        self.assertEqual(election.status, ElectionStatus.CANCELLED)
    
    def test_complete_active_election(self):
        """Test completing an active election."""
        election = ActiveElectionFactory(created_by=self.admin_user)
        url = reverse('elections:election_status', kwargs={'id': election.id})
        
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.patch(url, {'action': 'complete'})
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        election.refresh_from_db()
        self.assertEqual(election.status, ElectionStatus.COMPLETED)
    
    def test_invalid_action(self):
        """Test invalid status action."""
        election = CompletedElectionFactory(created_by=self.admin_user)
        url = reverse('elections:election_status', kwargs={'id': election.id})
        
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.patch(url, {'action': 'activate'})
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_student_cannot_change_status(self):
        """Test student cannot change election status."""
        election = DraftElectionFactory(created_by=self.admin_user)
        url = reverse('elections:election_status', kwargs={'id': election.id})
        
        self.client.force_authenticate(user=self.student_user)
        response = self.client.patch(url, {'action': 'activate'})
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)


class ElectionIntegrationTest(APITestCase):
    """Integration tests for election management workflow."""
    
    def setUp(self):
        """Set up test data."""
        self.admin_user = AdminUserFactory()
        self.student_user = StudentUserFactory()
        self.staff_user = StaffUserFactory()
        
        # Clear any existing elections for clean tests
        Election.objects.all().delete()
    
    def test_complete_election_lifecycle(self):
        """Test complete election lifecycle from creation to completion."""
        # 1. Admin creates a draft election
        self.client.force_authenticate(user=self.admin_user)
        
        create_data = {
            'title': 'Student Council Election 2024',
            'description': 'Annual student council election',
            'start_time': (timezone.now() + timedelta(hours=1)).isoformat(),
            'end_time': (timezone.now() + timedelta(hours=3)).isoformat(),
            'delayed_reveal': False
        }
        
        response = self.client.post(reverse('elections:election_create'), create_data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        election_id = response.data['id']
        
        # 2. Verify election is created as draft
        response = self.client.get(reverse('elections:election_detail', kwargs={'id': election_id}))
        self.assertEqual(response.data['status'], ElectionStatus.DRAFT)
        self.assertFalse(response.data['can_vote'])
        
        # 3. Student cannot see draft election in the list
        self.client.force_authenticate(user=self.student_user)
        response = self.client.get(reverse('elections:election_list'))
        # Should not contain our draft election ID
        election_ids = [item['id'] for item in response.data]
        self.assertNotIn(election_id, election_ids)
        
        # 4. Admin activates the election
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.patch(
            reverse('elections:election_status', kwargs={'id': election_id}),
            {'action': 'activate'}
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], ElectionStatus.ACTIVE)
        
        # 5. Now student can see the active election
        self.client.force_authenticate(user=self.student_user)
        response = self.client.get(reverse('elections:election_list'))
        # Should now contain our election ID
        election_ids = [item['id'] for item in response.data]
        self.assertIn(election_id, election_ids)
        
        # 6. Admin completes the election
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.patch(
            reverse('elections:election_status', kwargs={'id': election_id}),
            {'action': 'complete'}
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], ElectionStatus.COMPLETED)
        
        # 7. Verify completed election is still visible to students
        self.client.force_authenticate(user=self.student_user)
        response = self.client.get(reverse('elections:election_list'))
        election_ids = [item['id'] for item in response.data]
        self.assertIn(election_id, election_ids)
    
    def test_election_permission_enforcement(self):
        """Test comprehensive permission enforcement across all endpoints."""
        # Create test election
        election = DraftElectionFactory(created_by=self.admin_user)
        
        endpoints = [
            ('elections:election_create', 'POST', {}),
            ('elections:election_update', 'PATCH', {'id': election.id}),
            ('elections:election_delete', 'DELETE', {'id': election.id}),
            ('elections:election_status', 'PATCH', {'id': election.id}),
        ]
        
        # Test student access (should be denied for all management endpoints)
        self.client.force_authenticate(user=self.student_user)
        
        for url_name, method, kwargs in endpoints:
            url = reverse(url_name, kwargs=kwargs)
            
            if method == 'POST':
                response = self.client.post(url, {})
            elif method == 'PATCH':
                response = self.client.patch(url, {})
            elif method == 'DELETE':
                response = self.client.delete(url)
            
            self.assertEqual(
                response.status_code,
                status.HTTP_403_FORBIDDEN,
                f"Student should not have access to {url_name}"
            )
        
        # Test admin access (should be allowed)
        self.client.force_authenticate(user=self.admin_user)
        
        # Only test non-destructive operations for this test
        safe_endpoints = [
            ('elections:election_update', 'PATCH', {'id': election.id}, {'title': 'Updated'}),
            ('elections:election_status', 'PATCH', {'id': election.id}, {'action': 'cancel'}),
        ]
        
        for url_name, method, kwargs, data in safe_endpoints:
            url = reverse(url_name, kwargs=kwargs)
            response = self.client.patch(url, data)
            
            self.assertIn(
                response.status_code,
                [status.HTTP_200_OK, status.HTTP_201_CREATED],
                f"Admin should have access to {url_name}"
            )