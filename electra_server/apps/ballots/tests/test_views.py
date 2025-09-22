"""
Tests for ballot views and API endpoints.
"""
import json
import uuid
from datetime import timedelta
from unittest.mock import patch, mock_open

import pytest
from django.contrib.auth import get_user_model
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase
# from freezegun import freeze_time

from electra_server.apps.auth.models import UserRole
from electra_server.apps.elections.models import Election, ElectionStatus
from ..models import BallotToken, BallotTokenStatus, OfflineBallotQueue, BallotTokenUsageLog

User = get_user_model()

pytestmark = pytest.mark.django_db


class BallotTokenAPITestCase(APITestCase):
    """Base test case for ballot token API tests."""
    
    def setUp(self):
        """Set up test data."""
        # Create users
        self.student_user = User.objects.create_user(
            email='student@test.com',
            password='testpass123',
            full_name='Test Student',
            role=UserRole.STUDENT,
            matric_number='ST123456'
        )
        
        self.staff_user = User.objects.create_user(
            email='staff@test.com',
            password='testpass123',
            full_name='Test Staff',
            role=UserRole.STAFF,
            staff_id='SF123456'
        )
        
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            full_name='Test Admin',
            role=UserRole.ADMIN,
            staff_id='AD123456'
        )
        
        self.electoral_committee_user = User.objects.create_user(
            email='ec@test.com',
            password='testpass123',
            full_name='Test EC Member',
            role=UserRole.ELECTORAL_COMMITTEE,
            staff_id='EC123456'
        )
        
        # Create election
        now = timezone.now()
        self.active_election = Election.objects.create(
            title='Test Election',
            description='Test election description',
            start_time=now - timedelta(hours=1),
            end_time=now + timedelta(hours=2),
            status=ElectionStatus.ACTIVE,
            created_by=self.electoral_committee_user
        )
        
        self.future_election = Election.objects.create(
            title='Future Election',
            description='Future election description',
            start_time=now + timedelta(hours=1),
            end_time=now + timedelta(hours=3),
            status=ElectionStatus.ACTIVE,
            created_by=self.electoral_committee_user
        )


class TestBallotTokenRequestAPI(BallotTokenAPITestCase):
    """Test cases for ballot token request API."""
    
    @patch('builtins.open', mock_open(read_data=b'fake-key-data'))
    @patch('electra_server.apps.ballots.models.serialization')
    def test_student_can_request_token(self, mock_serialization):
        """Test that students can request ballot tokens."""
        # Mock the cryptography operations
        mock_private_key = mock_serialization.load_pem_private_key.return_value
        mock_private_key.sign.return_value = b'fake_signature'
        
        self.client.force_authenticate(user=self.student_user)
        
        url = reverse('ballots:request_token')
        data = {'election_id': str(self.active_election.id)}
        
        response = self.client.post(url, data, format='json')
        
        assert response.status_code == status.HTTP_201_CREATED
        assert 'id' in response.data
        assert 'token_uuid' in response.data
        assert 'signature' in response.data
        assert response.data['election_id'] == str(self.active_election.id)
        assert response.data['user_id'] == str(self.student_user.id)
        
        # Verify token was created in database
        token = BallotToken.objects.get(id=response.data['id'])
        assert token.user == self.student_user
        assert token.election == self.active_election
        assert token.status == BallotTokenStatus.ISSUED
    
    def test_admin_cannot_request_token(self):
        """Test that admin users cannot request ballot tokens."""
        self.client.force_authenticate(user=self.admin_user)
        
        url = reverse('ballots:request_token')
        data = {'election_id': str(self.active_election.id)}
        
        response = self.client.post(url, data, format='json')
        assert response.status_code == status.HTTP_403_FORBIDDEN
    
    def test_unauthenticated_cannot_request_token(self):
        """Test that unauthenticated users cannot request ballot tokens."""
        url = reverse('ballots:request_token')
        data = {'election_id': str(self.active_election.id)}
        
        response = self.client.post(url, data, format='json')
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_cannot_request_token_for_nonexistent_election(self):
        """Test that requesting token for non-existent election fails."""
        self.client.force_authenticate(user=self.student_user)
        
        url = reverse('ballots:request_token')
        data = {'election_id': str(uuid.uuid4())}
        
        response = self.client.post(url, data, format='json')
        assert response.status_code == status.HTTP_400_BAD_REQUEST
    
    @patch('builtins.open', mock_open(read_data=b'fake-key-data'))
    @patch('electra_server.apps.ballots.models.serialization')
    def test_cannot_request_duplicate_token(self, mock_serialization):
        """Test that users cannot request duplicate tokens for same election."""
        # Mock the cryptography operations
        mock_private_key = mock_serialization.load_pem_private_key.return_value
        mock_private_key.sign.return_value = b'fake_signature'
        
        # Create existing token
        BallotToken.objects.create(
            user=self.student_user,
            election=self.active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature'
        )
        
        self.client.force_authenticate(user=self.student_user)
        
        url = reverse('ballots:request_token')
        data = {'election_id': str(self.active_election.id)}
        
        response = self.client.post(url, data, format='json')
        assert response.status_code == status.HTTP_400_BAD_REQUEST


class TestBallotTokenValidateAPI(BallotTokenAPITestCase):
    """Test cases for ballot token validation API."""
    
    @patch('builtins.open', mock_open(read_data=b'fake-key-data'))
    @patch('electra_server.apps.ballots.models.serialization')
    def test_valid_token_validation(self, mock_serialization):
        """Test validation of a valid ballot token."""
        # Mock the cryptography operations
        mock_private_key = mock_serialization.load_pem_private_key.return_value
        mock_private_key.sign.return_value = b'fake_signature'
        mock_public_key = mock_serialization.load_pem_public_key.return_value
        
        # Create a valid token
        token = BallotToken.objects.create(
            user=self.student_user,
            election=self.active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature_hex'
        )
        
        self.client.force_authenticate(user=self.student_user)
        
        url = reverse('ballots:validate_token')
        data = {
            'token_uuid': str(token.token_uuid),
            'signature': 'fake_signature_hex',
            'election_id': str(self.active_election.id)
        }
        
        response = self.client.post(url, data, format='json')
        
        assert response.status_code == status.HTTP_200_OK
        assert response.data['valid'] is True
        assert 'token' in response.data
        assert response.data['message'] == 'Token is valid for voting.'
    
    def test_invalid_token_validation(self):
        """Test validation of an invalid ballot token."""
        self.client.force_authenticate(user=self.student_user)
        
        url = reverse('ballots:validate_token')
        data = {
            'token_uuid': str(uuid.uuid4()),
            'signature': 'fake_signature',
        }
        
        response = self.client.post(url, data, format='json')
        
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert response.data['valid'] is False
        assert 'Invalid token' in response.data['message']
    
    def test_unauthenticated_cannot_validate(self):
        """Test that unauthenticated users cannot validate tokens."""
        url = reverse('ballots:validate_token')
        data = {
            'token_uuid': str(uuid.uuid4()),
            'signature': 'fake_signature',
        }
        
        response = self.client.post(url, data, format='json')
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


class TestUserBallotTokensAPI(BallotTokenAPITestCase):
    """Test cases for user ballot tokens API."""
    
    def test_user_can_list_own_tokens(self):
        """Test that users can list their own ballot tokens."""
        # Create tokens for the user
        token1 = BallotToken.objects.create(
            user=self.student_user,
            election=self.active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature_1'
        )
        
        token2 = BallotToken.objects.create(
            user=self.student_user,
            election=self.future_election,
            issued_ip='192.168.1.2',
            signature='fake_signature_2'
        )
        
        # Create token for another user (should not appear)
        BallotToken.objects.create(
            user=self.staff_user,
            election=self.active_election,
            issued_ip='192.168.1.3',
            signature='fake_signature_3'
        )
        
        self.client.force_authenticate(user=self.student_user)
        
        url = reverse('ballots:user_tokens')
        response = self.client.get(url)
        
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) == 2
        
        token_ids = [token['id'] for token in response.data]
        assert str(token1.id) in token_ids
        assert str(token2.id) in token_ids
    
    def test_unauthenticated_cannot_list_tokens(self):
        """Test that unauthenticated users cannot list tokens."""
        url = reverse('ballots:user_tokens')
        response = self.client.get(url)
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


class TestBallotTokenStatsAPI(BallotTokenAPITestCase):
    """Test cases for ballot token statistics API."""
    
    def test_admin_can_view_stats(self):
        """Test that admin users can view ballot token statistics."""
        # Create some test tokens
        BallotToken.objects.create(
            user=self.student_user,
            election=self.active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature_1'
        )
        
        used_token = BallotToken.objects.create(
            user=self.staff_user,
            election=self.active_election,
            issued_ip='192.168.1.2',
            signature='fake_signature_2'
        )
        used_token.mark_as_used()
        
        self.client.force_authenticate(user=self.admin_user)
        
        url = reverse('ballots:token_stats')
        response = self.client.get(url)
        
        assert response.status_code == status.HTTP_200_OK
        assert 'total_tokens_issued' in response.data
        assert 'active_tokens' in response.data
        assert 'used_tokens' in response.data
        assert 'by_election' in response.data
        assert 'by_status' in response.data
        
        assert response.data['total_tokens_issued'] == 2
        assert response.data['active_tokens'] == 1
        assert response.data['used_tokens'] == 1
    
    def test_electoral_committee_can_view_stats(self):
        """Test that electoral committee members can view statistics."""
        self.client.force_authenticate(user=self.electoral_committee_user)
        
        url = reverse('ballots:token_stats')
        response = self.client.get(url)
        
        assert response.status_code == status.HTTP_200_OK
    
    def test_student_cannot_view_stats(self):
        """Test that students cannot view ballot token statistics."""
        self.client.force_authenticate(user=self.student_user)
        
        url = reverse('ballots:token_stats')
        response = self.client.get(url)
        
        assert response.status_code == status.HTTP_403_FORBIDDEN


class TestOfflineBallotQueueAPI(BallotTokenAPITestCase):
    """Test cases for offline ballot queue API."""
    
    def test_user_can_list_own_offline_entries(self):
        """Test that users can list their own offline queue entries."""
        # Create token and queue entry for user
        token = BallotToken.objects.create(
            user=self.student_user,
            election=self.active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature'
        )
        
        queue_entry = OfflineBallotQueue.objects.create(
            ballot_token=token,
            encrypted_data='encrypted_vote_data'
        )
        
        # Create queue entry for another user (should not appear)
        other_token = BallotToken.objects.create(
            user=self.staff_user,
            election=self.active_election,
            issued_ip='192.168.1.2',
            signature='fake_signature_2'
        )
        
        OfflineBallotQueue.objects.create(
            ballot_token=other_token,
            encrypted_data='other_encrypted_data'
        )
        
        self.client.force_authenticate(user=self.student_user)
        
        url = reverse('ballots:offline_queue')
        response = self.client.get(url)
        
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) == 1
        assert response.data[0]['id'] == str(queue_entry.id)
    
    def test_admin_can_list_all_offline_entries(self):
        """Test that admin users can list all offline queue entries."""
        # Create tokens and queue entries
        token1 = BallotToken.objects.create(
            user=self.student_user,
            election=self.active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature_1'
        )
        
        token2 = BallotToken.objects.create(
            user=self.staff_user,
            election=self.active_election,
            issued_ip='192.168.1.2',
            signature='fake_signature_2'
        )
        
        OfflineBallotQueue.objects.create(
            ballot_token=token1,
            encrypted_data='encrypted_data_1'
        )
        
        OfflineBallotQueue.objects.create(
            ballot_token=token2,
            encrypted_data='encrypted_data_2'
        )
        
        self.client.force_authenticate(user=self.admin_user)
        
        url = reverse('ballots:offline_queue')
        response = self.client.get(url)
        
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) == 2


class TestOfflineBallotSubmissionAPI(BallotTokenAPITestCase):
    """Test cases for offline ballot submission API."""
    
    def test_valid_offline_submission(self):
        """Test submitting a valid offline ballot."""
        # Create a valid token
        submission_time = timezone.now() - timedelta(minutes=30)
        
        # with freeze_time(submission_time - timedelta(hours=1)):
        token = BallotToken.objects.create(
            user=self.student_user,
            election=self.active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature'
        )
        
        self.client.force_authenticate(user=self.student_user)
        
        url = reverse('ballots:offline_submit')
        data = {
            'ballot_token_uuid': str(token.token_uuid),
            'encrypted_vote_data': 'encrypted_offline_vote',
            'signature': 'offline_signature',
            'submission_timestamp': submission_time.isoformat()
        }
        
        response = self.client.post(url, data, format='json')
        
        assert response.status_code == status.HTTP_200_OK
        assert response.data['success'] is True
        assert 'queue_entry_id' in response.data
        
        # Verify token was marked as used
        token.refresh_from_db()
        assert token.status == BallotTokenStatus.USED
        assert token.used_at is not None
        
        # Verify queue entry was created and marked as synced
        queue_entry = OfflineBallotQueue.objects.get(ballot_token=token)
        assert queue_entry.is_synced is True
        assert queue_entry.encrypted_data == 'encrypted_offline_vote'
    
    def test_invalid_offline_submission_expired_token(self):
        """Test submitting offline ballot with expired token."""
        # Create a token that was valid in the past
        past_time = timezone.now() - timedelta(hours=2)
        
        # with freeze_time(past_time):
        token = BallotToken.objects.create(
            user=self.student_user,
            election=self.active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature'
        )
        
        self.client.force_authenticate(user=self.student_user)
        
        # Try to submit with current time (after token expiry)
        url = reverse('ballots:offline_submit')
        data = {
            'ballot_token_uuid': str(token.token_uuid),
            'encrypted_vote_data': 'encrypted_offline_vote',
            'signature': 'offline_signature',
            'submission_timestamp': timezone.now().isoformat()
        }
        
        response = self.client.post(url, data, format='json')
        
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert 'after token expiry' in str(response.data)