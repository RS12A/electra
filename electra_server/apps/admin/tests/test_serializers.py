"""
Unit tests for admin API serializers.

This module contains comprehensive tests for admin API serializers
to ensure proper validation, serialization, and security.
"""
import pytest
from datetime import datetime, timedelta
from unittest.mock import Mock, patch
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework.request import Request
from rest_framework.test import APIRequestFactory

from electra_server.apps.auth.models import UserRole
from electra_server.apps.elections.models import Election, ElectionStatus
from electra_server.apps.ballots.models import BallotToken, BallotTokenStatus
from electra_server.apps.admin.serializers import (
    AdminUserListSerializer,
    AdminUserDetailSerializer,
    AdminUserCreateSerializer,
    AdminUserUpdateSerializer,
    AdminElectionListSerializer,
    AdminElectionDetailSerializer,
    AdminElectionCreateUpdateSerializer,
    AdminBallotTokenListSerializer,
    AdminBallotTokenDetailSerializer,
    AdminBallotTokenRevokeSerializer,
)

User = get_user_model()


@pytest.mark.django_db
class AdminUserSerializerTest(TestCase):
    """Test cases for admin user serializers."""
    
    def setUp(self):
        """Set up test data."""
        self.factory = APIRequestFactory()
        
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            full_name='Admin User',
            staff_id='ADMIN001',
            role=UserRole.ADMIN,
            is_active=True
        )
        
        self.test_user = User.objects.create_user(
            email='test@test.com',
            password='testpass123',
            full_name='Test User',
            staff_id='TEST001',
            role=UserRole.STAFF,
            is_active=True
        )
    
    def test_user_list_serializer(self):
        """Test AdminUserListSerializer serialization."""
        serializer = AdminUserListSerializer(self.test_user)
        data = serializer.data
        
        self.assertEqual(data['email'], self.test_user.email)
        self.assertEqual(data['full_name'], self.test_user.full_name)
        self.assertEqual(data['role'], self.test_user.role)
        self.assertEqual(data['role_display'], self.test_user.get_role_display())
        self.assertIn('last_login_display', data)
        self.assertIn('date_joined_display', data)
    
    def test_user_detail_serializer(self):
        """Test AdminUserDetailSerializer serialization."""
        serializer = AdminUserDetailSerializer(self.test_user)
        data = serializer.data
        
        self.assertEqual(data['email'], self.test_user.email)
        self.assertEqual(data['ballot_tokens_count'], self.test_user.ballot_tokens.count())
        self.assertEqual(data['created_elections_count'], self.test_user.created_elections.count())
    
    def test_user_create_serializer_valid_student(self):
        """Test AdminUserCreateSerializer with valid student data."""
        data = {
            'email': 'student@test.com',
            'full_name': 'Student User',
            'matric_number': 'ST001',
            'role': UserRole.STUDENT,
            'password': 'testpass123',
            'password_confirm': 'testpass123',
            'is_active': True
        }
        
        request = self.factory.post('/api/admin/users/')
        request.user = self.admin_user
        
        serializer = AdminUserCreateSerializer(data=data, context={'request': request})
        self.assertTrue(serializer.is_valid())
        
        user = serializer.save()
        self.assertEqual(user.email, data['email'])
        self.assertEqual(user.matric_number, data['matric_number'])
        self.assertIsNone(user.staff_id)
    
    def test_user_create_serializer_valid_staff(self):
        """Test AdminUserCreateSerializer with valid staff data."""
        data = {
            'email': 'staff2@test.com',
            'full_name': 'Staff User',
            'staff_id': 'STAFF002',
            'role': UserRole.STAFF,
            'password': 'testpass123',
            'password_confirm': 'testpass123',
            'is_active': True
        }
        
        request = self.factory.post('/api/admin/users/')
        request.user = self.admin_user
        
        serializer = AdminUserCreateSerializer(data=data, context={'request': request})
        self.assertTrue(serializer.is_valid())
        
        user = serializer.save()
        self.assertEqual(user.staff_id, data['staff_id'])
        self.assertIsNone(user.matric_number)
    
    def test_user_create_serializer_password_mismatch(self):
        """Test AdminUserCreateSerializer with password mismatch."""
        data = {
            'email': 'test@test.com',
            'full_name': 'Test User',
            'staff_id': 'TEST002',
            'role': UserRole.STAFF,
            'password': 'testpass123',
            'password_confirm': 'differentpass',
            'is_active': True
        }
        
        serializer = AdminUserCreateSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('password_confirm', serializer.errors)
    
    def test_user_create_serializer_student_without_matric(self):
        """Test AdminUserCreateSerializer student without matric number."""
        data = {
            'email': 'student@test.com',
            'full_name': 'Student User',
            'role': UserRole.STUDENT,
            'password': 'testpass123',
            'password_confirm': 'testpass123',
            'is_active': True
        }
        
        serializer = AdminUserCreateSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('matric_number', serializer.errors)
    
    def test_user_create_serializer_staff_without_staff_id(self):
        """Test AdminUserCreateSerializer staff without staff ID."""
        data = {
            'email': 'staff@test.com',
            'full_name': 'Staff User',
            'role': UserRole.STAFF,
            'password': 'testpass123',
            'password_confirm': 'testpass123',
            'is_active': True
        }
        
        serializer = AdminUserCreateSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('staff_id', serializer.errors)
    
    def test_user_update_serializer(self):
        """Test AdminUserUpdateSerializer."""
        data = {
            'full_name': 'Updated Name',
            'is_active': False
        }
        
        request = self.factory.patch('/api/admin/users/1/')
        request.user = self.admin_user
        
        serializer = AdminUserUpdateSerializer(
            instance=self.test_user,
            data=data,
            partial=True,
            context={'request': request}
        )
        self.assertTrue(serializer.is_valid())
        
        updated_user = serializer.save()
        self.assertEqual(updated_user.full_name, data['full_name'])
        self.assertEqual(updated_user.is_active, data['is_active'])


@pytest.mark.django_db
class AdminElectionSerializerTest(TestCase):
    """Test cases for admin election serializers."""
    
    def setUp(self):
        """Set up test data."""
        self.factory = APIRequestFactory()
        
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            full_name='Admin User',
            staff_id='ADMIN001',
            role=UserRole.ADMIN,
            is_active=True
        )
        
        self.election = Election.objects.create(
            title='Test Election',
            description='A test election',
            start_time=timezone.now() + timedelta(days=1),
            end_time=timezone.now() + timedelta(days=2),
            created_by=self.admin_user
        )
    
    def test_election_list_serializer(self):
        """Test AdminElectionListSerializer serialization."""
        serializer = AdminElectionListSerializer(self.election)
        data = serializer.data
        
        self.assertEqual(data['title'], self.election.title)
        self.assertEqual(data['status'], self.election.status)
        self.assertEqual(data['created_by_email'], self.admin_user.email)
        self.assertIn('start_time_display', data)
        self.assertIn('end_time_display', data)
    
    def test_election_detail_serializer(self):
        """Test AdminElectionDetailSerializer serialization."""
        serializer = AdminElectionDetailSerializer(self.election)
        data = serializer.data
        
        self.assertEqual(data['title'], self.election.title)
        self.assertIn('created_by_details', data)
        self.assertEqual(data['ballot_tokens_count'], self.election.ballot_tokens.count())
    
    def test_election_create_serializer_valid(self):
        """Test AdminElectionCreateUpdateSerializer with valid data."""
        data = {
            'title': 'New Election',
            'description': 'A new test election',
            'start_time': timezone.now() + timedelta(days=1),
            'end_time': timezone.now() + timedelta(days=2),
            'delayed_reveal': True
        }
        
        request = self.factory.post('/api/admin/elections/')
        request.user = self.admin_user
        
        serializer = AdminElectionCreateUpdateSerializer(data=data, context={'request': request})
        self.assertTrue(serializer.is_valid())
        
        election = serializer.save()
        self.assertEqual(election.title, data['title'])
        self.assertEqual(election.created_by, self.admin_user)
    
    def test_election_create_serializer_end_before_start(self):
        """Test AdminElectionCreateUpdateSerializer with end time before start."""
        data = {
            'title': 'Invalid Election',
            'description': 'An election with invalid times',
            'start_time': timezone.now() + timedelta(days=2),
            'end_time': timezone.now() + timedelta(days=1),
            'delayed_reveal': False
        }
        
        serializer = AdminElectionCreateUpdateSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('end_time', serializer.errors)
    
    def test_election_create_serializer_start_in_past(self):
        """Test AdminElectionCreateUpdateSerializer with start time in past."""
        data = {
            'title': 'Past Election',
            'description': 'An election starting in the past',
            'start_time': timezone.now() - timedelta(days=1),
            'end_time': timezone.now() + timedelta(days=1),
            'delayed_reveal': False
        }
        
        serializer = AdminElectionCreateUpdateSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('start_time', serializer.errors)


@pytest.mark.django_db
class AdminBallotTokenSerializerTest(TestCase):
    """Test cases for admin ballot token serializers."""
    
    def setUp(self):
        """Set up test data."""
        self.factory = APIRequestFactory()
        
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
        
        self.election = Election.objects.create(
            title='Test Election',
            description='A test election',
            start_time=timezone.now() + timedelta(days=1),
            end_time=timezone.now() + timedelta(days=2),
            created_by=self.admin_user
        )
        
        # Create a ballot token manually (normally done through ballot API)
        self.ballot_token = BallotToken.objects.create(
            user=self.test_user,
            election=self.election,
            expires_at=timezone.now() + timedelta(hours=24),
            signature='test_signature',
            issued_ip='127.0.0.1',
            issued_user_agent='Test Agent'
        )
    
    def test_ballot_token_list_serializer(self):
        """Test AdminBallotTokenListSerializer serialization."""
        serializer = AdminBallotTokenListSerializer(self.ballot_token)
        data = serializer.data
        
        self.assertEqual(data['user_email'], self.test_user.email)
        self.assertEqual(data['election_title'], self.election.title)
        self.assertEqual(data['status'], BallotTokenStatus.ISSUED)
        self.assertIn('issued_at_display', data)
        self.assertIn('expires_at_display', data)
    
    def test_ballot_token_detail_serializer(self):
        """Test AdminBallotTokenDetailSerializer serialization."""
        serializer = AdminBallotTokenDetailSerializer(self.ballot_token)
        data = serializer.data
        
        self.assertEqual(data['user_email'], self.test_user.email)
        self.assertIn('user_details', data)
        self.assertIn('election_details', data)
        self.assertIn('offline_data', data)
    
    def test_ballot_token_revoke_serializer_valid(self):
        """Test AdminBallotTokenRevokeSerializer with valid data."""
        data = {
            'reason': 'Token compromised due to security breach'
        }
        
        request = self.factory.post('/api/admin/ballots/revoke/')
        request.user = self.admin_user
        
        serializer = AdminBallotTokenRevokeSerializer(data=data, context={'request': request})
        self.assertTrue(serializer.is_valid())
        
        revoked_token = serializer.save(self.ballot_token)
        self.assertEqual(revoked_token.status, BallotTokenStatus.INVALIDATED)
        self.assertIsNotNone(revoked_token.invalidated_at)
    
    def test_ballot_token_revoke_serializer_empty_reason(self):
        """Test AdminBallotTokenRevokeSerializer with empty reason."""
        data = {
            'reason': ''
        }
        
        serializer = AdminBallotTokenRevokeSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('reason', serializer.errors)
    
    def test_ballot_token_revoke_serializer_already_used(self):
        """Test AdminBallotTokenRevokeSerializer with already used token."""
        # Mark token as used
        self.ballot_token.mark_as_used()
        
        data = {
            'reason': 'Test revocation'
        }
        
        serializer = AdminBallotTokenRevokeSerializer(data=data)
        serializer.is_valid(raise_exception=True)
        
        with self.assertRaises(Exception):
            serializer.save(self.ballot_token)


@pytest.mark.unit
class SerializerSecurityTest(TestCase):
    """Test security aspects of admin serializers."""
    
    def test_password_not_exposed_in_serialization(self):
        """Test that passwords are never exposed in serialization."""
        user = Mock()
        user.email = 'test@test.com'
        user.full_name = 'Test User'
        user.role = UserRole.STAFF
        user.get_role_display = Mock(return_value='Staff')
        user.is_active = True
        user.last_login = None
        user.date_joined = timezone.now()
        user.matric_number = None
        user.staff_id = 'STAFF001'
        user.is_staff = False
        user.is_superuser = False
        user.ballot_tokens = Mock()
        user.ballot_tokens.count = Mock(return_value=0)
        user.created_elections = Mock()
        user.created_elections.count = Mock(return_value=0)
        
        # Test all user serializers
        serializers = [
            AdminUserListSerializer,
            AdminUserDetailSerializer,
        ]
        
        for serializer_class in serializers:
            serializer = serializer_class(user)
            data = serializer.data
            
            # Ensure password field is not in serialized data
            self.assertNotIn('password', data)
            self.assertNotIn('password_confirm', data)
    
    def test_sensitive_ballot_data_handling(self):
        """Test that sensitive ballot token data is handled appropriately."""
        ballot_token = Mock()
        ballot_token.id = 'test-id'
        ballot_token.token_uuid = 'test-uuid'
        ballot_token.status = BallotTokenStatus.ISSUED
        ballot_token.get_status_display = Mock(return_value='Issued')
        ballot_token.user = Mock()
        ballot_token.user.email = 'test@test.com'
        ballot_token.user.full_name = 'Test User'
        ballot_token.election = Mock()
        ballot_token.election.title = 'Test Election'
        ballot_token.issued_at = timezone.now()
        ballot_token.expires_at = timezone.now() + timedelta(hours=24)
        ballot_token.used_at = None
        ballot_token.invalidated_at = None
        ballot_token.is_valid = True
        ballot_token.is_expired = False
        ballot_token.issued_ip = '127.0.0.1'
        
        serializer = AdminBallotTokenListSerializer(ballot_token)
        data = serializer.data
        
        # Should include IP for admin purposes but not other sensitive data
        self.assertIn('issued_ip', data)
        # Token UUID should be included for admin identification
        self.assertIn('token_uuid', data)
        
        # Should not include cryptographic signature in list view
        self.assertNotIn('signature', data)