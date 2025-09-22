"""
Tests for ballot models.
"""
import uuid
from datetime import timedelta
from unittest.mock import patch, mock_open

import pytest
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.db import IntegrityError
from django.utils import timezone
# from freezegun import freeze_time

from electra_server.apps.elections.models import Election, ElectionStatus
from electra_server.apps.auth.models import UserRole
from ..models import BallotToken, BallotTokenStatus, OfflineBallotQueue, BallotTokenUsageLog

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
def active_election():
    """Create an active election for testing."""
    now = timezone.now()
    return Election.objects.create(
        title='Test Election',
        description='Test election description',
        start_time=now - timedelta(hours=1),
        end_time=now + timedelta(hours=2),
        status=ElectionStatus.ACTIVE,
        created_by=User.objects.create_user(
            email='creator@test.com',
            password='testpass123',
            full_name='Creator',
            role=UserRole.ELECTORAL_COMMITTEE,
            staff_id='EC123456'
        )
    )


@pytest.fixture
def future_election():
    """Create a future election for testing."""
    now = timezone.now()
    return Election.objects.create(
        title='Future Election',
        description='Future election description',
        start_time=now + timedelta(hours=1),
        end_time=now + timedelta(hours=3),
        status=ElectionStatus.ACTIVE,
        created_by=User.objects.create_user(
            email='creator2@test.com', 
            password='testpass123',
            full_name='Creator 2',
            role=UserRole.ELECTORAL_COMMITTEE,
            staff_id='EC123457'
        )
    )


class TestBallotToken:
    """Test cases for BallotToken model."""
    
    @patch('builtins.open', mock_open(read_data=b'fake-key-data'))
    @patch('electra_server.apps.ballots.models.serialization')
    def test_ballot_token_creation(self, mock_serialization, student_user, active_election):
        """Test basic ballot token creation."""
        # Mock the cryptography operations
        mock_private_key = mock_serialization.load_pem_private_key.return_value
        mock_private_key.sign.return_value = b'fake_signature'
        
        token = BallotToken.objects.create(
            user=student_user,
            election=active_election,
            issued_ip='192.168.1.1',
            issued_user_agent='Test Agent'
        )
        
        assert token.id is not None
        assert token.token_uuid is not None
        assert token.user == student_user
        assert token.election == active_election
        assert token.status == BallotTokenStatus.ISSUED
        assert token.issued_at is not None
        assert token.expires_at > token.issued_at
        
    def test_ballot_token_string_representation(self, student_user, active_election):
        """Test ballot token string representation."""
        token = BallotToken(
            user=student_user,
            election=active_election,
            issued_ip='192.168.1.1'
        )
        
        expected = f"BallotToken({token.token_uuid}) - {student_user.email} - {active_election.title}"
        assert str(token) == expected
    
    def test_unique_token_per_user_election(self, student_user, active_election):
        """Test that only one token per user per election is allowed."""
        BallotToken.objects.create(
            user=student_user,
            election=active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature'
        )
        
        with pytest.raises(IntegrityError):
            BallotToken.objects.create(
                user=student_user,
                election=active_election,
                issued_ip='192.168.1.2',
                signature='fake_signature_2'
            )
    
    def test_ballot_token_expiry_validation(self, student_user, active_election):
        """Test ballot token expiry validation."""
        past_time = timezone.now() - timedelta(hours=1)
        
        token = BallotToken(
            user=student_user,
            election=active_election,
            issued_ip='192.168.1.1',
            expires_at=past_time
        )
        
        with pytest.raises(ValidationError):
            token.clean()
    
    def test_ballot_token_is_valid_property(self, student_user, active_election):
        """Test ballot token is_valid property."""
        token = BallotToken.objects.create(
            user=student_user,
            election=active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature'
        )
        
        assert token.is_valid is True
        
        # Test expired token
        token.expires_at = timezone.now() - timedelta(minutes=1)
        token.save()
        assert token.is_valid is False
        
        # Test used token
        token.expires_at = timezone.now() + timedelta(hours=1)
        token.status = BallotTokenStatus.USED
        token.save()
        assert token.is_valid is False
    
    def test_ballot_token_mark_as_used(self, student_user, active_election):
        """Test marking ballot token as used."""
        token = BallotToken.objects.create(
            user=student_user,
            election=active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature'
        )
        
        assert token.status == BallotTokenStatus.ISSUED
        assert token.used_at is None
        
        token.mark_as_used()
        token.refresh_from_db()
        
        assert token.status == BallotTokenStatus.USED
        assert token.used_at is not None
    
    def test_ballot_token_invalidate(self, student_user, active_election):
        """Test invalidating ballot token."""
        token = BallotToken.objects.create(
            user=student_user,
            election=active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature'
        )
        
        reason = 'Security concern'
        token.invalidate(reason)
        token.refresh_from_db()
        
        assert token.status == BallotTokenStatus.INVALIDATED
        assert token.invalidated_at is not None
        assert token.offline_data.get('invalidation_reason') == reason
    
    @patch('builtins.open', mock_open(read_data=b'fake-key-data'))
    @patch('electra_server.apps.ballots.models.serialization')
    def test_get_token_data(self, mock_serialization, student_user, active_election):
        """Test get_token_data method."""
        token = BallotToken.objects.create(
            user=student_user,
            election=active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature'
        )
        
        token_data = token.get_token_data()
        
        assert 'token_uuid' in token_data
        assert 'user_id' in token_data
        assert 'election_id' in token_data
        assert 'issued_at' in token_data
        assert 'expires_at' in token_data
        
        assert token_data['token_uuid'] == str(token.token_uuid)
        assert token_data['user_id'] == str(student_user.id)
        assert token_data['election_id'] == str(active_election.id)


class TestOfflineBallotQueue:
    """Test cases for OfflineBallotQueue model."""
    
    def test_offline_queue_creation(self, student_user, active_election):
        """Test offline ballot queue entry creation."""
        token = BallotToken.objects.create(
            user=student_user,
            election=active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature'
        )
        
        queue_entry = OfflineBallotQueue.objects.create(
            ballot_token=token,
            encrypted_data='encrypted_vote_data'
        )
        
        assert queue_entry.id is not None
        assert queue_entry.ballot_token == token
        assert queue_entry.encrypted_data == 'encrypted_vote_data'
        assert queue_entry.is_synced is False
        assert queue_entry.created_at is not None
        assert queue_entry.sync_attempts == 0
    
    def test_offline_queue_string_representation(self, student_user, active_election):
        """Test offline queue string representation."""
        token = BallotToken.objects.create(
            user=student_user,
            election=active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature'
        )
        
        queue_entry = OfflineBallotQueue(
            ballot_token=token,
            encrypted_data='test_data'
        )
        
        expected = f"OfflineQueue({token.token_uuid}) - Pending"
        assert str(queue_entry) == expected
    
    def test_mark_as_synced(self, student_user, active_election):
        """Test marking offline queue entry as synced."""
        token = BallotToken.objects.create(
            user=student_user,
            election=active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature'
        )
        
        queue_entry = OfflineBallotQueue.objects.create(
            ballot_token=token,
            encrypted_data='encrypted_vote_data'
        )
        
        assert queue_entry.is_synced is False
        assert queue_entry.synced_at is None
        
        queue_entry.mark_as_synced()
        queue_entry.refresh_from_db()
        
        assert queue_entry.is_synced is True
        assert queue_entry.synced_at is not None
    
    def test_record_sync_error(self, student_user, active_election):
        """Test recording sync error."""
        token = BallotToken.objects.create(
            user=student_user,
            election=active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature'
        )
        
        queue_entry = OfflineBallotQueue.objects.create(
            ballot_token=token,
            encrypted_data='encrypted_vote_data'
        )
        
        error_message = 'Network connection failed'
        queue_entry.record_sync_error(error_message)
        queue_entry.refresh_from_db()
        
        assert queue_entry.sync_attempts == 1
        assert queue_entry.last_sync_error == error_message


class TestBallotTokenUsageLog:
    """Test cases for BallotTokenUsageLog model."""
    
    def test_usage_log_creation(self, student_user, active_election):
        """Test ballot token usage log creation."""
        token = BallotToken.objects.create(
            user=student_user,
            election=active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature'
        )
        
        log_entry = BallotTokenUsageLog.objects.create(
            ballot_token=token,
            action='issued',
            ip_address='192.168.1.1',
            user_agent='Test Agent',
            metadata={'test': 'data'}
        )
        
        assert log_entry.id is not None
        assert log_entry.ballot_token == token
        assert log_entry.action == 'issued'
        assert log_entry.ip_address == '192.168.1.1'
        assert log_entry.user_agent == 'Test Agent'
        assert log_entry.metadata == {'test': 'data'}
        assert log_entry.timestamp is not None
    
    def test_usage_log_string_representation(self, student_user, active_election):
        """Test usage log string representation."""
        token = BallotToken.objects.create(
            user=student_user,
            election=active_election,
            issued_ip='192.168.1.1',
            signature='fake_signature'
        )
        
        log_entry = BallotTokenUsageLog(
            ballot_token=token,
            action='validated',
            ip_address='192.168.1.2'
        )
        
        expected_start = f"UsageLog({token.token_uuid}) - validated"
        assert str(log_entry).startswith(expected_start)