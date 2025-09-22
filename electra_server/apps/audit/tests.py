"""
Tests for the audit logging system in electra_server.

This module contains comprehensive unit and integration tests for the
audit logging functionality, including chain integrity verification,
RSA signature validation, and API endpoint testing.
"""
import json
import uuid
from datetime import timedelta
from unittest.mock import patch, Mock

from django.test import TestCase, override_settings
from django.utils import timezone
from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase, APIClient
from rest_framework import status

from electra_server.apps.elections.models import Election, ElectionStatus
from electra_server.apps.audit.models import AuditLog, AuditActionType
from electra_server.apps.audit.utils import (
    log_user_action,
    log_authentication_event,
    log_election_event,
)

User = get_user_model()


class AuditLogModelTest(TestCase):
    """Test cases for the AuditLog model."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.user = User.objects.create_user(
            email='test@example.com',
            full_name='Test User',
            role='admin',
            staff_id='ADMIN001',
            password='testpass123'
        )
        
        self.election = Election.objects.create(
            title='Test Election',
            description='Test election description',
            start_time=timezone.now() + timedelta(days=1),
            end_time=timezone.now() + timedelta(days=2),
            status=ElectionStatus.DRAFT,
            created_by=self.user
        )
    
    def test_audit_log_creation(self):
        """Test basic audit log entry creation."""
        entry = AuditLog.create_audit_entry(
            action_type=AuditActionType.USER_LOGIN,
            action_description='User logged in successfully',
            user=self.user,
            ip_address='192.168.1.1',
            user_agent='Test Browser',
            outcome='success'
        )
        
        self.assertIsNotNone(entry.id)
        self.assertEqual(entry.action_type, AuditActionType.USER_LOGIN)
        self.assertEqual(entry.user, self.user)
        self.assertEqual(entry.chain_position, 1)
        self.assertTrue(entry.is_sealed)
        self.assertNotEqual(entry.content_hash, '')
        self.assertNotEqual(entry.signature, '')
    
    def test_chain_integrity_single_entry(self):
        """Test chain integrity verification for single entry."""
        entry = AuditLog.create_audit_entry(
            action_type=AuditActionType.USER_LOGIN,
            action_description='First entry',
            user=self.user,
            ip_address='192.168.1.1'
        )
        
        self.assertTrue(entry.verify_chain_integrity())
        self.assertEqual(entry.previous_hash, '')  # First entry has empty previous hash
    
    def test_chain_integrity_multiple_entries(self):
        """Test chain integrity verification for multiple entries."""
        # Create first entry
        entry1 = AuditLog.create_audit_entry(
            action_type=AuditActionType.USER_LOGIN,
            action_description='First entry',
            user=self.user,
            ip_address='192.168.1.1'
        )
        
        # Create second entry
        entry2 = AuditLog.create_audit_entry(
            action_type=AuditActionType.ELECTION_CREATED,
            action_description='Second entry',
            user=self.user,
            ip_address='192.168.1.1',
            election=self.election
        )
        
        # Verify both entries
        self.assertTrue(entry1.verify_chain_integrity())
        self.assertTrue(entry2.verify_chain_integrity())
        
        # Verify chain linkage
        self.assertEqual(entry2.previous_hash, entry1.content_hash)
        self.assertEqual(entry2.chain_position, entry1.chain_position + 1)
    
    @patch('electra_server.apps.audit.models.AuditLog._load_private_key')
    def test_rsa_signature_creation(self, mock_load_key):
        """Test RSA signature creation and verification."""
        # Mock the private key loading
        mock_private_key = Mock()
        mock_private_key.sign.return_value = b'mock_signature_bytes'
        mock_load_key.return_value = mock_private_key
        
        entry = AuditLog.create_audit_entry(
            action_type=AuditActionType.USER_LOGIN,
            action_description='Test entry',
            user=self.user,
            ip_address='192.168.1.1'
        )
        
        # Verify signature was created
        self.assertNotEqual(entry.signature, '')
        mock_private_key.sign.assert_called_once()
    
    def test_immutability_enforcement(self):
        """Test that sealed entries cannot be modified."""
        entry = AuditLog.create_audit_entry(
            action_type=AuditActionType.USER_LOGIN,
            action_description='Test entry',
            user=self.user,
            ip_address='192.168.1.1'
        )
        
        # Attempt to modify sealed entry should raise ValidationError
        with self.assertRaises(Exception):
            entry.action_description = 'Modified description'
            entry.save()
    
    def test_chain_verification_full(self):
        """Test full chain integrity verification."""
        # Create multiple entries
        entries = []
        for i in range(5):
            entry = AuditLog.create_audit_entry(
                action_type=AuditActionType.USER_LOGIN,
                action_description=f'Entry {i+1}',
                user=self.user,
                ip_address='192.168.1.1'
            )
            entries.append(entry)
        
        # Verify full chain
        verification_result = AuditLog.verify_chain_integrity_full()
        
        self.assertTrue(verification_result['is_valid'])
        self.assertEqual(verification_result['total_entries'], 5)
        self.assertEqual(verification_result['verified_entries'], 5)
        self.assertEqual(len(verification_result['failed_entries']), 0)
    
    def test_user_identifier_preservation(self):
        """Test that user identifier is preserved for audit trail."""
        entry = AuditLog.create_audit_entry(
            action_type=AuditActionType.USER_LOGIN,
            action_description='User login',
            user=self.user,
            ip_address='192.168.1.1'
        )
        
        self.assertEqual(entry.user_identifier, self.user.email)
        
        # Test with no user (system action)
        system_entry = AuditLog.create_audit_entry(
            action_type=AuditActionType.SYSTEM_ERROR,
            action_description='System error',
            ip_address='127.0.0.1'
        )
        
        self.assertEqual(system_entry.user_identifier, '')
    
    def test_metadata_serialization(self):
        """Test that metadata is properly serialized and stored."""
        metadata = {
            'request_path': '/api/auth/login/',
            'method': 'POST',
            'response_time': 150,
            'additional_info': {
                'browser': 'Chrome',
                'version': '91.0'
            }
        }
        
        entry = AuditLog.create_audit_entry(
            action_type=AuditActionType.USER_LOGIN,
            action_description='Login with metadata',
            user=self.user,
            ip_address='192.168.1.1',
            metadata=metadata
        )
        
        self.assertEqual(entry.metadata, metadata)
        self.assertEqual(entry.metadata['additional_info']['browser'], 'Chrome')


class AuditUtilsTest(TestCase):
    """Test cases for audit utility functions."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.user = User.objects.create_user(
            email='test@example.com',
            full_name='Test User',
            role='admin',
            staff_id='ADMIN001',
            password='testpass123'
        )
        
        self.election = Election.objects.create(
            title='Test Election',
            description='Test election description',
            start_time=timezone.now() + timedelta(days=1),
            end_time=timezone.now() + timedelta(days=2),
            status=ElectionStatus.DRAFT,
            created_by=self.user
        )
    
    def test_log_user_action(self):
        """Test logging user actions via utility function."""
        log_user_action(
            action_type=AuditActionType.USER_LOGIN,
            description='User login test',
            user=self.user,
            ip_address='192.168.1.1',
            outcome='success'
        )
        
        entry = AuditLog.objects.get(action_type=AuditActionType.USER_LOGIN)
        self.assertEqual(entry.action_description, 'User login test')
        self.assertEqual(entry.user, self.user)
    
    def test_log_authentication_event(self):
        """Test logging authentication events."""
        log_authentication_event(
            action_type=AuditActionType.USER_LOGIN_FAILED,
            user=None,  # Failed login, no user object
            outcome='failure',
            error_details='Invalid credentials',
            metadata={'attempted_email': 'fake@example.com'}
        )
        
        entry = AuditLog.objects.get(action_type=AuditActionType.USER_LOGIN_FAILED)
        self.assertEqual(entry.outcome, 'failure')
        self.assertEqual(entry.error_details, 'Invalid credentials')
    
    def test_log_election_event(self):
        """Test logging election management events."""
        log_election_event(
            action_type=AuditActionType.ELECTION_CREATED,
            election=self.election,
            user=self.user,
            outcome='success'
        )
        
        entry = AuditLog.objects.get(action_type=AuditActionType.ELECTION_CREATED)
        self.assertEqual(entry.election, self.election)
        self.assertEqual(entry.target_resource_type, 'Election')
        self.assertEqual(entry.target_resource_id, str(self.election.id))


class AuditAPITest(APITestCase):
    """Test cases for audit API endpoints."""
    
    def setUp(self):
        """Set up test fixtures."""
        # Create admin user
        self.admin_user = User.objects.create_user(
            email='admin@example.com',
            full_name='Admin User',
            role='admin',
            staff_id='ADMIN001',
            password='testpass123'
        )
        
        # Create regular user
        self.regular_user = User.objects.create_user(
            email='user@example.com',
            full_name='Regular User',
            role='student',
            matric_number='STU001',
            password='testpass123'
        )
        
        # Create electoral committee user
        self.committee_user = User.objects.create_user(
            email='committee@example.com',
            full_name='Committee User',
            role='electoral_committee',
            staff_id='COMM001',
            password='testpass123'
        )
        
        # Create election
        self.election = Election.objects.create(
            title='Test Election',
            description='Test election description',
            start_time=timezone.now() + timedelta(days=1),
            end_time=timezone.now() + timedelta(days=2),
            status=ElectionStatus.DRAFT,
            created_by=self.admin_user
        )
        
        # Create some audit entries
        self.create_test_audit_entries()
        
        self.client = APIClient()
    
    def create_test_audit_entries(self):
        """Create test audit entries."""
        entries_data = [
            (AuditActionType.USER_LOGIN, 'Admin login', self.admin_user),
            (AuditActionType.ELECTION_CREATED, 'Election created', self.admin_user),
            (AuditActionType.USER_LOGIN, 'Committee login', self.committee_user),
            (AuditActionType.TOKEN_ISSUED, 'Token issued', self.admin_user),
            (AuditActionType.VOTE_CAST, 'Vote cast', None),  # Anonymous vote
        ]
        
        for action_type, description, user in entries_data:
            AuditLog.create_audit_entry(
                action_type=action_type,
                action_description=description,
                user=user,
                ip_address='192.168.1.1',
                election=self.election if 'election' in description.lower() else None
            )
    
    def test_audit_logs_list_admin_access(self):
        """Test that admin users can access audit logs."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.get('/api/audit/logs/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('results', response.data)
        self.assertGreaterEqual(len(response.data['results']), 5)
    
    def test_audit_logs_list_committee_access(self):
        """Test that electoral committee users can access audit logs."""
        self.client.force_authenticate(user=self.committee_user)
        
        response = self.client.get('/api/audit/logs/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('results', response.data)
    
    def test_audit_logs_list_regular_user_denied(self):
        """Test that regular users cannot access audit logs."""
        self.client.force_authenticate(user=self.regular_user)
        
        response = self.client.get('/api/audit/logs/')
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_audit_logs_list_unauthenticated_denied(self):
        """Test that unauthenticated users cannot access audit logs."""
        response = self.client.get('/api/audit/logs/')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_audit_logs_filtering(self):
        """Test audit logs filtering capabilities."""
        self.client.force_authenticate(user=self.admin_user)
        
        # Test filtering by action type
        response = self.client.get('/api/audit/logs/?action_type=user_login')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify all results match filter
        for result in response.data['results']:
            self.assertEqual(result['action_type'], 'user_login')
        
        # Test filtering by outcome
        response = self.client.get('/api/audit/logs/?outcome=success')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Test filtering by election
        response = self.client.get(f'/api/audit/logs/?election_id={self.election.id}')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    def test_audit_log_detail(self):
        """Test retrieving detailed audit log entry."""
        self.client.force_authenticate(user=self.admin_user)
        
        # Get first audit entry
        entry = AuditLog.objects.first()
        
        response = self.client.get(f'/api/audit/logs/{entry.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['id'], str(entry.id))
        self.assertEqual(response.data['action_type'], entry.action_type)
        
        # Verify chain verification fields are included
        self.assertIn('is_chain_valid', response.data)
        self.assertIn('is_signature_valid', response.data)
    
    def test_verify_audit_chain(self):
        """Test audit chain verification endpoint."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.post('/api/audit/verify/', {
            'quick_verify': True
        })
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('is_valid', response.data)
        self.assertIn('total_entries', response.data)
        self.assertIn('verified_entries', response.data)
        self.assertIn('verification_timestamp', response.data)
    
    def test_verify_audit_chain_regular_user_denied(self):
        """Test that regular users cannot verify audit chain."""
        self.client.force_authenticate(user=self.regular_user)
        
        response = self.client.post('/api/audit/verify/', {
            'quick_verify': True
        })
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_audit_action_types(self):
        """Test audit action types endpoint."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.get('/api/audit/action-types/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsInstance(response.data, list)
        self.assertGreater(len(response.data), 0)
        
        # Verify structure
        first_action = response.data[0]
        self.assertIn('value', first_action)
        self.assertIn('label', first_action)
        self.assertIn('category', first_action)
    
    def test_audit_stats(self):
        """Test audit statistics endpoint."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.get('/api/audit/stats/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('total_entries', response.data)
        self.assertIn('entries_last_24h', response.data)
        self.assertIn('entries_last_7d', response.data)
        self.assertIn('action_type_breakdown', response.data)
        self.assertIn('outcome_breakdown', response.data)
    
    def test_audit_logs_pagination(self):
        """Test audit logs pagination."""
        self.client.force_authenticate(user=self.admin_user)
        
        # Test with small page size
        response = self.client.get('/api/audit/logs/?page_size=2&page=1')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('next', response.data)
        self.assertIn('previous', response.data)
        self.assertLessEqual(len(response.data['results']), 2)


class AuditPermissionsTest(TestCase):
    """Test cases for audit permissions."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.admin_user = User.objects.create_user(
            email='admin@example.com',
            full_name='Admin User',
            role='admin',
            staff_id='ADMIN001',
            password='testpass123'
        )
        
        self.committee_user = User.objects.create_user(
            email='committee@example.com',
            full_name='Committee User',
            role='electoral_committee',
            staff_id='COMM001',
            password='testpass123'
        )
        
        self.regular_user = User.objects.create_user(
            email='user@example.com',
            full_name='Regular User',
            role='student',
            matric_number='STU001',
            password='testpass123'
        )
    
    def test_audit_permission_admin(self):
        """Test audit permissions for admin users."""
        from electra_server.apps.audit.permissions import AuditLogPermission
        
        permission = AuditLogPermission()
        
        # Mock request
        request = Mock()
        request.user = self.admin_user
        request.method = 'GET'
        request.path = '/api/audit/logs/'
        request.META = {'HTTP_USER_AGENT': 'Test Browser'}
        request.session = Mock()
        request.session.session_key = 'test_session'
        
        self.assertTrue(permission.has_permission(request, Mock()))
    
    def test_audit_permission_committee(self):
        """Test audit permissions for electoral committee users."""
        from electra_server.apps.audit.permissions import AuditLogPermission
        
        permission = AuditLogPermission()
        
        # Mock request
        request = Mock()
        request.user = self.committee_user
        request.method = 'GET'
        request.path = '/api/audit/logs/'
        request.META = {'HTTP_USER_AGENT': 'Test Browser'}
        request.session = Mock()
        request.session.session_key = 'test_session'
        
        self.assertTrue(permission.has_permission(request, Mock()))
    
    def test_audit_permission_regular_user(self):
        """Test audit permissions for regular users."""
        from electra_server.apps.audit.permissions import AuditLogPermission
        
        permission = AuditLogPermission()
        
        # Mock request
        request = Mock()
        request.user = self.regular_user
        request.method = 'GET'
        request.path = '/api/audit/logs/'
        request.META = {'HTTP_USER_AGENT': 'Test Browser'}
        request.session = Mock()
        request.session.session_key = 'test_session'
        
        self.assertFalse(permission.has_permission(request, Mock()))
