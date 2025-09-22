"""
Unit tests for analytics calculations.

This module tests the core calculation functions for analytics
data including turnout, participation, and time-series metrics.
"""
import uuid
from datetime import datetime, timedelta
from decimal import Decimal
from unittest.mock import patch, MagicMock

import pytest
from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone

from electra_server.apps.auth.models import UserRole
from electra_server.apps.elections.models import Election, ElectionStatus
from electra_server.apps.votes.models import Vote, VoteStatus
from electra_server.apps.analytics.calculations import (
    calculate_turnout_metrics,
    calculate_participation_analytics,
    calculate_time_series_analytics,
    get_election_summary,
    _categorize_turnout,
    ParticipationCategory
)

User = get_user_model()


@pytest.mark.unit
class TestAnalyticsCalculations(TestCase):
    """Test cases for analytics calculation functions."""
    
    def setUp(self):
        """Set up test data."""
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
        
        # Create test students
        self.students = []
        for i in range(10):
            student = User.objects.create_user(
                email=f'student{i}@test.com',
                password='testpass123',
                full_name=f'Student {i}',
                role=UserRole.STUDENT,
                matric_number=f'STU{i:03d}'
            )
            self.students.append(student)
        
        # Create test staff
        self.staff_users = []
        for i in range(5):
            staff = User.objects.create_user(
                email=f'staff{i}@test.com',
                password='testpass123',
                full_name=f'Staff {i}',
                role=UserRole.STAFF,
                staff_id=f'STF{i:03d}'
            )
            self.staff_users.append(staff)
        
        # Create test election
        self.election = Election.objects.create(
            title='Test Election',
            description='Test election for analytics',
            start_time=timezone.now() - timedelta(days=7),
            end_time=timezone.now() + timedelta(days=7),
            status=ElectionStatus.ACTIVE,
            created_by=self.admin_user
        )
        
        # Create another completed election
        self.completed_election = Election.objects.create(
            title='Completed Election',
            description='Completed election for testing',
            start_time=timezone.now() - timedelta(days=14),
            end_time=timezone.now() - timedelta(days=7),
            status=ElectionStatus.COMPLETED,
            created_by=self.admin_user
        )
    
    def test_categorize_turnout(self):
        """Test turnout categorization function."""
        # Test excellent category (>= 80%)
        self.assertEqual(_categorize_turnout(Decimal('85.0')), ParticipationCategory.EXCELLENT)
        self.assertEqual(_categorize_turnout(Decimal('80.0')), ParticipationCategory.EXCELLENT)
        
        # Test good category (60-79%)
        self.assertEqual(_categorize_turnout(Decimal('75.0')), ParticipationCategory.GOOD)
        self.assertEqual(_categorize_turnout(Decimal('60.0')), ParticipationCategory.GOOD)
        
        # Test fair category (40-59%)
        self.assertEqual(_categorize_turnout(Decimal('55.0')), ParticipationCategory.FAIR)
        self.assertEqual(_categorize_turnout(Decimal('40.0')), ParticipationCategory.FAIR)
        
        # Test critical category (< 40%)
        self.assertEqual(_categorize_turnout(Decimal('25.0')), ParticipationCategory.CRITICAL)
        self.assertEqual(_categorize_turnout(Decimal('0.0')), ParticipationCategory.CRITICAL)
    
    @patch('electra_server.apps.analytics.calculations.Vote.objects')
    def test_calculate_turnout_metrics_all_elections(self, mock_vote_objects):
        """Test turnout calculation for all elections."""
        # Mock vote counts
        mock_vote_objects.filter.return_value.count.return_value = 8  # 8 votes total
        
        result = calculate_turnout_metrics()
        
        # Verify structure
        self.assertIn('overall_turnout', result)
        self.assertIn('per_election', result)
        self.assertIn('summary', result)
        self.assertIn('metadata', result)
        
        # Verify per-election data structure
        self.assertEqual(len(result['per_election']), 2)  # Two elections created
        
        for election_data in result['per_election']:
            self.assertIn('election_id', election_data)
            self.assertIn('election_title', election_data)
            self.assertIn('status', election_data)
            self.assertIn('eligible_voters', election_data)
            self.assertIn('votes_cast', election_data)
            self.assertIn('turnout_percentage', election_data)
            self.assertIn('category', election_data)
        
        # Verify summary data
        summary = result['summary']
        self.assertIn('total_elections', summary)
        self.assertIn('active_elections', summary)
        self.assertIn('completed_elections', summary)
        self.assertEqual(summary['total_elections'], 2)
        self.assertEqual(summary['active_elections'], 1)
        self.assertEqual(summary['completed_elections'], 1)
    
    @patch('electra_server.apps.analytics.calculations.Vote.objects')
    def test_calculate_turnout_metrics_specific_election(self, mock_vote_objects):
        """Test turnout calculation for a specific election."""
        # Mock vote counts
        mock_vote_objects.filter.return_value.count.return_value = 5
        
        result = calculate_turnout_metrics(election_id=str(self.election.id))
        
        # Should only have one election in results
        self.assertEqual(len(result['per_election']), 1)
        
        election_data = result['per_election'][0]
        self.assertEqual(election_data['election_id'], str(self.election.id))
        self.assertEqual(election_data['election_title'], self.election.title)
    
    @patch('electra_server.apps.analytics.calculations.Vote.objects')
    def test_calculate_participation_analytics(self, mock_vote_objects):
        """Test participation analytics calculation."""
        # Mock vote queries
        mock_vote_objects.filter.return_value.values.return_value.filter.return_value.distinct.return_value.count.return_value = 3
        
        result = calculate_participation_analytics()
        
        # Verify structure
        self.assertIn('by_user_type', result)
        self.assertIn('by_category', result)
        self.assertIn('summary', result)
        self.assertIn('metadata', result)
        
        # Verify user type data
        by_user_type = result['by_user_type']
        for role in [UserRole.STUDENT, UserRole.STAFF, UserRole.CANDIDATE]:
            if role in by_user_type:
                role_data = by_user_type[role]
                self.assertIn('eligible_users', role_data)
                self.assertIn('participants', role_data)
                self.assertIn('participation_rate', role_data)
                self.assertIn('category', role_data)
        
        # Verify category counts
        by_category = result['by_category']
        for category in [ParticipationCategory.EXCELLENT, ParticipationCategory.GOOD, 
                        ParticipationCategory.FAIR, ParticipationCategory.CRITICAL]:
            self.assertIn(category, by_category)
            self.assertIsInstance(by_category[category], int)
    
    @patch('electra_server.apps.analytics.calculations.Vote.objects')
    def test_calculate_time_series_analytics_daily(self, mock_vote_objects):
        """Test daily time series analytics calculation."""
        # Mock time series data
        mock_vote_data = [
            {'period': timezone.now().date(), 'vote_count': 5},
            {'period': timezone.now().date() - timedelta(days=1), 'vote_count': 3},
        ]
        mock_vote_objects.filter.return_value.annotate.return_value.values.return_value.annotate.return_value.order_by.return_value = mock_vote_data
        
        result = calculate_time_series_analytics(period_type='daily')
        
        # Verify structure
        self.assertIn('period_type', result)
        self.assertIn('start_date', result)
        self.assertIn('end_date', result)
        self.assertIn('data_points', result)
        self.assertIn('summary', result)
        self.assertIn('metadata', result)
        
        self.assertEqual(result['period_type'], 'daily')
        
        # Verify data points structure
        for point in result['data_points']:
            self.assertIn('period', point)
            self.assertIn('vote_count', point)
            self.assertIn('period_start', point)
            self.assertIn('period_end', point)
        
        # Verify summary
        summary = result['summary']
        self.assertIn('total_votes', summary)
        self.assertIn('average_daily_votes', summary)
    
    def test_get_election_summary(self):
        """Test election summary generation."""
        with patch('electra_server.apps.analytics.calculations.calculate_turnout_metrics') as mock_turnout, \
             patch('electra_server.apps.analytics.calculations.calculate_participation_analytics') as mock_participation, \
             patch('electra_server.apps.analytics.calculations.calculate_time_series_analytics') as mock_time_series:
            
            # Mock return values
            mock_turnout.return_value = {'per_election': [{'turnout_percentage': 75.0}]}
            mock_participation.return_value = {'summary': {'total_participants': 50}}
            mock_time_series.return_value = {'data_points': []}
            
            result = get_election_summary(str(self.election.id))
            
            # Verify structure
            self.assertIn('election', result)
            self.assertIn('turnout', result)
            self.assertIn('participation', result)
            self.assertIn('time_series', result)
            self.assertIn('generated_at', result)
            
            # Verify election data
            election_data = result['election']
            self.assertEqual(election_data['id'], str(self.election.id))
            self.assertEqual(election_data['title'], self.election.title)
            self.assertEqual(election_data['status'], self.election.status)
            
            # Verify function calls
            mock_turnout.assert_called_once_with(str(self.election.id))
            mock_participation.assert_called_once_with(str(self.election.id))
            mock_time_series.assert_called_once_with(
                period_type='election_period',
                election_id=str(self.election.id)
            )
    
    def test_get_election_summary_nonexistent(self):
        """Test election summary for non-existent election."""
        nonexistent_id = str(uuid.uuid4())
        
        with self.assertRaises(ValueError) as context:
            get_election_summary(nonexistent_id)
        
        self.assertIn('not found', str(context.exception))
    
    @patch('electra_server.apps.analytics.calculations.Vote.objects')
    def test_calculate_turnout_with_zero_eligible_voters(self, mock_vote_objects):
        """Test turnout calculation when there are no eligible voters."""
        # Delete all users except admin
        User.objects.filter(role__in=[UserRole.STUDENT, UserRole.STAFF]).delete()
        
        mock_vote_objects.filter.return_value.count.return_value = 0
        
        result = calculate_turnout_metrics()
        
        # Should handle zero eligible voters gracefully
        self.assertEqual(result['overall_turnout'], 0.0)
        self.assertEqual(result['summary']['total_eligible_voters'], 0)
        self.assertEqual(result['summary']['total_votes_cast'], 0)
    
    @patch('electra_server.apps.analytics.calculations.Vote.objects')
    def test_calculate_participation_with_filters(self, mock_vote_objects):
        """Test participation calculation with user type filter."""
        mock_vote_objects.filter.return_value.values.return_value.filter.return_value.distinct.return_value.count.return_value = 2
        
        result = calculate_participation_analytics(
            election_id=str(self.election.id),
            user_type=UserRole.STUDENT
        )
        
        # Should only include student data when filtered
        by_user_type = result['by_user_type']
        self.assertEqual(len(by_user_type), 1)  # Only student role
        self.assertIn(UserRole.STUDENT, by_user_type)
        
        # Verify metadata includes filters
        metadata = result['metadata']
        self.assertEqual(metadata['filters']['election_id'], str(self.election.id))
        self.assertEqual(metadata['filters']['user_type'], UserRole.STUDENT)
    
    def test_time_series_analytics_validation(self):
        """Test time series analytics input validation."""
        # Test with end date before start date
        start_date = timezone.now()
        end_date = start_date - timedelta(days=1)
        
        with patch('electra_server.apps.analytics.calculations.Vote.objects.filter') as mock_filter:
            mock_filter.return_value.annotate.return_value.values.return_value.annotate.return_value.order_by.return_value = []
            
            # Should handle invalid date range gracefully
            result = calculate_time_series_analytics(
                period_type='daily',
                start_date=start_date,
                end_date=end_date
            )
            
            # Should still return valid structure even with invalid dates
            self.assertIn('data_points', result)
            self.assertIn('summary', result)
    
    @patch('electra_server.apps.analytics.calculations.logger')
    def test_calculation_error_handling(self, mock_logger):
        """Test error handling in calculation functions."""
        # Test database error handling
        with patch('electra_server.apps.analytics.calculations.User.objects.filter') as mock_filter:
            mock_filter.side_effect = Exception("Database error")
            
            with self.assertRaises(Exception):
                calculate_turnout_metrics()
            
            # Verify error was logged
            mock_logger.error.assert_called()
    
    def test_calculation_performance_metadata(self):
        """Test that calculation metadata includes performance data."""
        with patch('electra_server.apps.analytics.calculations.Vote.objects.filter') as mock_filter:
            mock_filter.return_value.count.return_value = 0
            
            result = calculate_turnout_metrics()
            
            # Verify metadata includes timing
            metadata = result['metadata']
            self.assertIn('calculated_at', metadata)
            self.assertIn('calculation_duration', metadata)
            self.assertIn('data_source', metadata)
            self.assertIsInstance(metadata['calculation_duration'], float)
            self.assertEqual(metadata['data_source'], 'real_time')
    
    @patch('electra_server.apps.analytics.calculations.Vote.objects')
    def test_time_series_election_period_mode(self, mock_vote_objects):
        """Test time series analytics in election period mode."""
        # Mock election period votes
        mock_vote_data = [
            {'day': self.election.start_time.date(), 'vote_count': 10},
            {'day': self.election.start_time.date() + timedelta(days=1), 'vote_count': 15},
        ]
        mock_vote_objects.filter.return_value.extra.return_value.values.return_value.annotate.return_value.order_by.return_value = mock_vote_data
        
        result = calculate_time_series_analytics(
            period_type='election_period',
            election_id=str(self.election.id)
        )
        
        self.assertEqual(result['period_type'], 'election_period')
        self.assertEqual(len(result['data_points']), 2)
        self.assertEqual(result['summary']['total_votes'], 25)  # 10 + 15