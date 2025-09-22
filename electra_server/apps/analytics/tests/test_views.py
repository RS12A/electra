"""
Integration tests for analytics API views.

This module tests the analytics API endpoints including authentication,
permissions, caching, and export functionality.
"""
import json
import uuid
from datetime import timedelta
from unittest.mock import patch, MagicMock

import pytest
from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from electra_server.apps.auth.models import UserRole
from electra_server.apps.elections.models import Election, ElectionStatus
from electra_server.apps.analytics.models import AnalyticsCache, ExportVerification

User = get_user_model()


@pytest.mark.integration
class TestAnalyticsAPIViews(TestCase):
    """Test cases for analytics API views."""
    
    def setUp(self):
        """Set up test data and client."""
        self.client = APIClient()
        
        # Create test users
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            full_name='Admin User',
            role=UserRole.ADMIN,
            staff_id='ADMIN001'
        )
        
        self.electoral_committee_user = User.objects.create_user(
            email='committee@test.com',
            password='testpass123',
            full_name='Committee User',
            role=UserRole.ELECTORAL_COMMITTEE,
            staff_id='EC001'
        )
        
        self.student_user = User.objects.create_user(
            email='student@test.com',
            password='testpass123',
            full_name='Student User',
            role=UserRole.STUDENT,
            matric_number='STU001'
        )
        
        # Create test election
        self.election = Election.objects.create(
            title='Test Election',
            description='Test election for analytics',
            start_time=timezone.now() - timedelta(days=7),
            end_time=timezone.now() + timedelta(days=7),
            status=ElectionStatus.ACTIVE,
            created_by=self.admin_user
        )
        
        # Base URLs
        self.turnout_url = reverse('analytics:analytics-turnout-metrics')
        self.participation_url = reverse('analytics:analytics-participation-analytics')
        self.time_series_url = reverse('analytics:analytics-time-series-analytics')
        self.export_url = reverse('analytics:export')
    
    def test_turnout_metrics_admin_access(self):
        """Test turnout metrics endpoint with admin access."""
        self.client.force_authenticate(user=self.admin_user)
        
        with patch('electra_server.apps.analytics.views.calculate_turnout_metrics') as mock_calculate:
            mock_calculate.return_value = {
                'overall_turnout': 75.0,
                'per_election': [],
                'summary': {'total_elections': 1},
                'metadata': {'calculated_at': timezone.now().isoformat()}
            }
            
            response = self.client.get(self.turnout_url)
            
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            self.assertIn('overall_turnout', response.data)
            self.assertIn('per_election', response.data)
            self.assertIn('summary', response.data)
            self.assertIn('metadata', response.data)
            
            # Verify calculation was called
            mock_calculate.assert_called_once_with(election_id=None)
    
    def test_turnout_metrics_electoral_committee_access(self):
        """Test turnout metrics endpoint with electoral committee access."""
        self.client.force_authenticate(user=self.electoral_committee_user)
        
        with patch('electra_server.apps.analytics.views.calculate_turnout_metrics') as mock_calculate:
            mock_calculate.return_value = {
                'overall_turnout': 75.0,
                'per_election': [],
                'summary': {},
                'metadata': {}
            }
            
            response = self.client.get(self.turnout_url)
            
            self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    def test_turnout_metrics_student_access_denied(self):
        """Test turnout metrics endpoint denies student access."""
        self.client.force_authenticate(user=self.student_user)
        
        response = self.client.get(self.turnout_url)
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_turnout_metrics_unauthenticated_access_denied(self):
        """Test turnout metrics endpoint denies unauthenticated access."""
        response = self.client.get(self.turnout_url)
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_turnout_metrics_with_election_filter(self):
        """Test turnout metrics with election filter."""
        self.client.force_authenticate(user=self.admin_user)
        
        with patch('electra_server.apps.analytics.views.calculate_turnout_metrics') as mock_calculate:
            mock_calculate.return_value = {
                'overall_turnout': 75.0,
                'per_election': [],
                'summary': {},
                'metadata': {}
            }
            
            response = self.client.get(self.turnout_url, {'election_id': str(self.election.id)})
            
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            
            # Verify calculation was called with election_id
            mock_calculate.assert_called_once_with(election_id=str(self.election.id))
    
    def test_turnout_metrics_post_request(self):
        """Test turnout metrics endpoint with POST request."""
        self.client.force_authenticate(user=self.admin_user)
        
        with patch('electra_server.apps.analytics.views.calculate_turnout_metrics') as mock_calculate:
            mock_calculate.return_value = {
                'overall_turnout': 75.0,
                'per_election': [],
                'summary': {},
                'metadata': {}
            }
            
            data = {
                'election_id': str(self.election.id),
                'use_cache': False,
                'force_refresh': True
            }
            
            response = self.client.post(self.turnout_url, data)
            
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            
            # Verify calculation was called with correct parameters
            mock_calculate.assert_called_once_with(election_id=str(self.election.id))
    
    def test_participation_analytics_with_user_type_filter(self):
        """Test participation analytics with user type filter."""
        self.client.force_authenticate(user=self.admin_user)
        
        with patch('electra_server.apps.analytics.views.calculate_participation_analytics') as mock_calculate:
            mock_calculate.return_value = {
                'by_user_type': {},
                'by_category': {},
                'summary': {},
                'metadata': {}
            }
            
            response = self.client.get(self.participation_url, {
                'election_id': str(self.election.id),
                'user_type': 'student'
            })
            
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            
            # Verify calculation was called with filters
            mock_calculate.assert_called_once_with(
                election_id=str(self.election.id),
                user_type='student'
            )
    
    def test_time_series_analytics_daily(self):
        """Test time series analytics with daily period."""
        self.client.force_authenticate(user=self.admin_user)
        
        with patch('electra_server.apps.analytics.views.calculate_time_series_analytics') as mock_calculate:
            mock_calculate.return_value = {
                'period_type': 'daily',
                'start_date': timezone.now().isoformat(),
                'end_date': timezone.now().isoformat(),
                'data_points': [],
                'summary': {},
                'metadata': {}
            }
            
            response = self.client.get(self.time_series_url, {
                'period_type': 'daily',
                'election_id': str(self.election.id)
            })
            
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            
            # Verify response structure
            self.assertIn('period_type', response.data)
            self.assertIn('data_points', response.data)
            self.assertEqual(response.data['period_type'], 'daily')
    
    def test_time_series_analytics_with_date_range(self):
        """Test time series analytics with custom date range."""
        self.client.force_authenticate(user=self.admin_user)
        
        start_date = timezone.now() - timedelta(days=30)
        end_date = timezone.now()
        
        with patch('electra_server.apps.analytics.views.calculate_time_series_analytics') as mock_calculate:
            mock_calculate.return_value = {
                'period_type': 'daily',
                'start_date': start_date.isoformat(),
                'end_date': end_date.isoformat(),
                'data_points': [],
                'summary': {},
                'metadata': {}
            }
            
            response = self.client.get(self.time_series_url, {
                'period_type': 'daily',
                'start_date': start_date.isoformat(),
                'end_date': end_date.isoformat()
            })
            
            self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    def test_time_series_analytics_invalid_date_format(self):
        """Test time series analytics with invalid date format."""
        self.client.force_authenticate(user=self.admin_user)
        
        response = self.client.get(self.time_series_url, {
            'start_date': 'invalid-date-format'
        })
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)
    
    def test_election_summary_endpoint(self):
        """Test election summary endpoint."""
        self.client.force_authenticate(user=self.admin_user)
        
        with patch('electra_server.apps.analytics.views.get_election_summary') as mock_summary:
            mock_summary.return_value = {
                'election': {'id': str(self.election.id), 'title': 'Test Election'},
                'turnout': {},
                'participation': {},
                'time_series': {},
                'generated_at': timezone.now().isoformat()
            }
            
            url = reverse('analytics:analytics-election-summary', args=[str(self.election.id)])
            response = self.client.get(url)
            
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            self.assertIn('election', response.data)
            self.assertIn('turnout', response.data)
            self.assertIn('participation', response.data)
            self.assertIn('time_series', response.data)
            
            # Verify function was called with correct ID
            mock_summary.assert_called_once_with(str(self.election.id))
    
    def test_election_summary_nonexistent_election(self):
        """Test election summary for non-existent election."""
        self.client.force_authenticate(user=self.admin_user)
        
        with patch('electra_server.apps.analytics.views.get_election_summary') as mock_summary:
            mock_summary.side_effect = ValueError("Election not found")
            
            nonexistent_id = str(uuid.uuid4())
            url = reverse('analytics:analytics-election-summary', args=[nonexistent_id])
            response = self.client.get(url)
            
            self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
            self.assertIn('error', response.data)
    
    @patch('electra_server.apps.analytics.views.AnalyticsExporter')
    def test_analytics_export_csv(self, mock_exporter_class):
        """Test analytics export in CSV format."""
        self.client.force_authenticate(user=self.admin_user)
        
        # Mock exporter
        mock_exporter = MagicMock()
        mock_exporter_class.return_value = mock_exporter
        
        # Mock export data
        mock_content = b"CSV content here"
        mock_verification = MagicMock()
        mock_verification.id = uuid.uuid4()
        mock_verification.filename = "turnout_metrics_20231201_120000.csv"
        mock_verification.verification_hash = "abc123"
        mock_verification.content_hash = "def456"
        mock_verification.file_size = len(mock_content)
        
        mock_exporter.export_data.return_value = (mock_content, mock_verification)
        
        # Mock calculation
        with patch('electra_server.apps.analytics.views.calculate_turnout_metrics') as mock_calculate:
            mock_calculate.return_value = {'overall_turnout': 75.0}
            
            data = {
                'export_type': 'csv',
                'data_type': 'turnout',
                'include_verification': True
            }
            
            response = self.client.post(self.export_url, data)
            
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            self.assertEqual(response['Content-Type'], 'text/csv')
            self.assertIn('attachment', response['Content-Disposition'])
            self.assertIn('turnout_metrics', response['Content-Disposition'])
            
            # Verify verification headers
            self.assertEqual(response['X-Export-Verification-Hash'], mock_verification.verification_hash)
            self.assertEqual(response['X-Export-ID'], str(mock_verification.id))
            self.assertEqual(response['X-Content-Hash'], mock_verification.content_hash)
    
    @patch('electra_server.apps.analytics.views.AnalyticsExporter')
    def test_analytics_export_xlsx(self, mock_exporter_class):
        """Test analytics export in XLSX format."""
        self.client.force_authenticate(user=self.admin_user)
        
        # Mock exporter
        mock_exporter = MagicMock()
        mock_exporter_class.return_value = mock_exporter
        
        mock_content = b"XLSX content here"
        mock_verification = MagicMock()
        mock_verification.id = uuid.uuid4()
        mock_verification.filename = "participation_analytics_20231201_120000.xlsx"
        mock_verification.verification_hash = "xyz789"
        mock_verification.content_hash = "abc123"
        
        mock_exporter.export_data.return_value = (mock_content, mock_verification)
        
        # Mock calculation
        with patch('electra_server.apps.analytics.views.calculate_participation_analytics') as mock_calculate:
            mock_calculate.return_value = {'by_user_type': {}}
            
            data = {
                'export_type': 'xlsx',
                'data_type': 'participation',
                'election_id': str(self.election.id)
            }
            
            response = self.client.post(self.export_url, data)
            
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            self.assertEqual(response['Content-Type'], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    
    @patch('electra_server.apps.analytics.views.AnalyticsExporter')
    def test_analytics_export_pdf(self, mock_exporter_class):
        """Test analytics export in PDF format."""
        self.client.force_authenticate(user=self.admin_user)
        
        # Mock exporter
        mock_exporter = MagicMock()
        mock_exporter_class.return_value = mock_exporter
        
        mock_content = b"PDF content here"
        mock_verification = MagicMock()
        mock_verification.id = uuid.uuid4()
        mock_verification.filename = "time_series_daily_20231201_120000.pdf"
        mock_verification.verification_hash = "pdf123"
        mock_verification.content_hash = "pdf456"
        
        mock_exporter.export_data.return_value = (mock_content, mock_verification)
        
        # Mock calculation
        with patch('electra_server.apps.analytics.views.calculate_time_series_analytics') as mock_calculate:
            mock_calculate.return_value = {'data_points': []}
            
            data = {
                'export_type': 'pdf',
                'data_type': 'time_series',
                'period_type': 'daily'
            }
            
            response = self.client.post(self.export_url, data)
            
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            self.assertEqual(response['Content-Type'], 'application/pdf')
    
    def test_analytics_export_invalid_type(self):
        """Test analytics export with invalid export type."""
        self.client.force_authenticate(user=self.admin_user)
        
        data = {
            'export_type': 'invalid_type',
            'data_type': 'turnout'
        }
        
        response = self.client.post(self.export_url, data)
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_analytics_export_election_summary_without_election_id(self):
        """Test analytics export for election summary without election_id."""
        self.client.force_authenticate(user=self.admin_user)
        
        data = {
            'export_type': 'csv',
            'data_type': 'election_summary'
            # Missing election_id
        }
        
        response = self.client.post(self.export_url, data)
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_analytics_export_student_access_denied(self):
        """Test analytics export denies student access."""
        self.client.force_authenticate(user=self.student_user)
        
        data = {
            'export_type': 'csv',
            'data_type': 'turnout'
        }
        
        response = self.client.post(self.export_url, data)
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_export_verification_endpoint(self):
        """Test export verification endpoint."""
        self.client.force_authenticate(user=self.admin_user)
        
        # Create test verification record
        verification = ExportVerification.objects.create(
            export_type='csv',
            content_hash='abc123',
            filename='test_export.csv',
            file_size=1000,
            export_params={'data_type': 'turnout'},
            requested_by=self.admin_user,
            request_ip='127.0.0.1'
        )
        
        url = reverse('analytics:verify', args=[verification.verification_hash])
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['verified'])
        self.assertEqual(response.data['verification_hash'], verification.verification_hash)
        self.assertEqual(response.data['content_hash'], verification.content_hash)
        self.assertEqual(response.data['filename'], verification.filename)
    
    def test_export_verification_nonexistent_hash(self):
        """Test export verification with non-existent hash."""
        self.client.force_authenticate(user=self.admin_user)
        
        nonexistent_hash = 'nonexistent123'
        url = reverse('analytics:verify', args=[nonexistent_hash])
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertFalse(response.data['verified'])
        self.assertIn('not found', response.data['error'])
    
    def test_export_verification_access_control(self):
        """Test export verification access control."""
        self.client.force_authenticate(user=self.student_user)
        
        # Create verification for admin user
        verification = ExportVerification.objects.create(
            export_type='csv',
            content_hash='abc123',
            filename='test_export.csv',
            file_size=1000,
            export_params={'data_type': 'turnout'},
            requested_by=self.admin_user,
            request_ip='127.0.0.1'
        )
        
        url = reverse('analytics:verify', args=[verification.verification_hash])
        response = self.client.get(url)
        
        # Student should not be able to access admin's verification
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    @patch('electra_server.apps.analytics.views.AnalyticsCache.objects')
    def test_caching_functionality(self, mock_cache_objects):
        """Test analytics caching functionality."""
        self.client.force_authenticate(user=self.admin_user)
        
        # Mock cache hit
        mock_cache_entry = MagicMock()
        mock_cache_entry.data = {'overall_turnout': 75.0, 'per_election': []}
        mock_cache_entry.verify_integrity.return_value = True
        
        mock_cache_objects.get.return_value = mock_cache_entry
        
        response = self.client.get(self.turnout_url, {'use_cache': 'true'})
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify cache was checked
        mock_cache_objects.get.assert_called_once()
        mock_cache_entry.mark_accessed.assert_called_once()
    
    def test_force_refresh_bypasses_cache(self):
        """Test force refresh bypasses cache."""
        self.client.force_authenticate(user=self.admin_user)
        
        with patch('electra_server.apps.analytics.views.calculate_turnout_metrics') as mock_calculate:
            mock_calculate.return_value = {
                'overall_turnout': 75.0,
                'per_election': [],
                'summary': {},
                'metadata': {}
            }
            
            response = self.client.get(self.turnout_url, {
                'use_cache': 'true',
                'force_refresh': 'true'
            })
            
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            
            # Calculation should be called directly, not from cache
            mock_calculate.assert_called_once()
    
    def test_calculation_error_handling(self):
        """Test error handling in calculation functions."""
        self.client.force_authenticate(user=self.admin_user)
        
        with patch('electra_server.apps.analytics.views.calculate_turnout_metrics') as mock_calculate:
            mock_calculate.side_effect = Exception("Database error")
            
            response = self.client.get(self.turnout_url)
            
            self.assertEqual(response.status_code, status.HTTP_500_INTERNAL_SERVER_ERROR)
            self.assertIn('error', response.data)
    
    def test_audit_logging(self):
        """Test that API access is properly logged for audit."""
        self.client.force_authenticate(user=self.admin_user)
        
        with patch('electra_server.apps.analytics.views.log_user_action') as mock_log:
            with patch('electra_server.apps.analytics.views.calculate_turnout_metrics') as mock_calculate:
                mock_calculate.return_value = {
                    'overall_turnout': 75.0,
                    'per_election': [],
                    'summary': {},
                    'metadata': {}
                }
                
                response = self.client.get(self.turnout_url)
                
                self.assertEqual(response.status_code, status.HTTP_200_OK)
                
                # Verify audit logging was called
                mock_log.assert_called()
                
                # Check the log call
                call_args = mock_log.call_args
                self.assertEqual(call_args[1]['user'], self.admin_user)
                self.assertIn('Turnout metrics accessed', call_args[1]['description'])
                self.assertEqual(call_args[1]['outcome'], 'success')