"""
Analytics calculation utilities for the electra voting system.

This module contains functions for calculating voter participation,
turnout metrics, and time-series analytics.
"""
import logging
from datetime import datetime, timedelta
from decimal import Decimal, ROUND_HALF_UP
from typing import Dict, Any, List, Optional, Union
from django.contrib.auth import get_user_model
from django.db.models import Count, Q, Case, When, Value, CharField
from django.db.models.functions import TruncDay, TruncWeek
from django.utils import timezone

from electra_server.apps.auth.models import UserRole
from electra_server.apps.elections.models import Election, ElectionStatus
from electra_server.apps.ballots.models import BallotToken, BallotTokenStatus
from electra_server.apps.votes.models import Vote, VoteStatus

User = get_user_model()
logger = logging.getLogger('electra_server.analytics')


class ParticipationCategory:
    """Constants for participation categories."""
    EXCELLENT = 'excellent'  # >80%
    GOOD = 'good'           # 60-80%
    FAIR = 'fair'           # 40-60%
    CRITICAL = 'critical'   # <40%


def calculate_turnout_metrics(election_id: Optional[str] = None) -> Dict[str, Any]:
    """
    Calculate turnout metrics for elections.
    
    Args:
        election_id: Optional election ID. If None, calculates for all elections.
        
    Returns:
        Dict containing turnout metrics
    """
    logger.info(f"Calculating turnout metrics for election: {election_id or 'all'}")
    
    start_time = timezone.now()
    
    try:
        # Base querysets
        if election_id:
            elections = Election.objects.filter(id=election_id)
        else:
            elections = Election.objects.all()
        
        # Initialize results
        results = {
            'overall_turnout': Decimal('0.00'),
            'per_election': [],
            'summary': {
                'total_elections': 0,
                'active_elections': 0,
                'completed_elections': 0,
                'total_eligible_voters': 0,
                'total_votes_cast': 0,
            }
        }
        
        total_eligible = 0
        total_votes = 0
        
        for election in elections:
            # Get eligible voters for this election
            eligible_voters = User.objects.filter(
                Q(role=UserRole.STUDENT) | Q(role=UserRole.STAFF)
            ).filter(is_active=True).count()
            
            # Get votes cast for this election
            votes_cast = Vote.objects.filter(
                election=election,
                status=VoteStatus.CAST
            ).count()
            
            # Calculate turnout percentage
            turnout_percentage = Decimal('0.00')
            if eligible_voters > 0:
                turnout_percentage = (Decimal(votes_cast) / Decimal(eligible_voters) * 100).quantize(
                    Decimal('0.01'), rounding=ROUND_HALF_UP
                )
            
            # Categorize turnout
            category = _categorize_turnout(turnout_percentage)
            
            election_data = {
                'election_id': str(election.id),
                'election_title': election.title,
                'status': election.status,
                'eligible_voters': eligible_voters,
                'votes_cast': votes_cast,
                'turnout_percentage': float(turnout_percentage),
                'category': category,
                'start_time': election.start_time.isoformat() if election.start_time else None,
                'end_time': election.end_time.isoformat() if election.end_time else None,
            }
            
            results['per_election'].append(election_data)
            
            # Add to totals
            total_eligible += eligible_voters
            total_votes += votes_cast
            
            # Update summary counts
            results['summary']['total_elections'] += 1
            if election.status == ElectionStatus.ACTIVE:
                results['summary']['active_elections'] += 1
            elif election.status == ElectionStatus.COMPLETED:
                results['summary']['completed_elections'] += 1
        
        # Calculate overall turnout
        if total_eligible > 0:
            results['overall_turnout'] = float(
                (Decimal(total_votes) / Decimal(total_eligible) * 100).quantize(
                    Decimal('0.01'), rounding=ROUND_HALF_UP
                )
            )
        
        results['summary']['total_eligible_voters'] = total_eligible
        results['summary']['total_votes_cast'] = total_votes
        
        # Add calculation metadata
        end_time = timezone.now()
        results['metadata'] = {
            'calculated_at': end_time.isoformat(),
            'calculation_duration': (end_time - start_time).total_seconds(),
            'data_source': 'real_time',
        }
        
        logger.info(f"Turnout calculation completed in {results['metadata']['calculation_duration']:.2f}s")
        
        return results
        
    except Exception as e:
        logger.error(f"Error calculating turnout metrics: {str(e)}", exc_info=True)
        raise


def calculate_participation_analytics(
    election_id: Optional[str] = None,
    user_type: Optional[str] = None
) -> Dict[str, Any]:
    """
    Calculate detailed participation analytics by category and user type.
    
    Args:
        election_id: Optional election ID to filter by
        user_type: Optional user type to filter by (student, staff, etc.)
        
    Returns:
        Dict containing participation analytics
    """
    logger.info(f"Calculating participation analytics for election: {election_id or 'all'}, user_type: {user_type or 'all'}")
    
    start_time = timezone.now()
    
    try:
        # Base filters
        election_filter = Q()
        if election_id:
            election_filter = Q(election_id=election_id)
        
        user_filter = Q(is_active=True)
        if user_type:
            user_filter &= Q(role=user_type)
        
        # Get participation by user role
        user_roles = [UserRole.STUDENT, UserRole.STAFF, UserRole.CANDIDATE]
        
        results = {
            'by_user_type': {},
            'by_category': {
                ParticipationCategory.EXCELLENT: 0,
                ParticipationCategory.GOOD: 0,
                ParticipationCategory.FAIR: 0,
                ParticipationCategory.CRITICAL: 0,
            },
            'summary': {
                'total_eligible_users': 0,
                'total_participants': 0,
                'overall_participation_rate': 0.0,
            }
        }
        
        for role in user_roles:
            # Skip if filtering by specific user type and this isn't it
            if user_type and role != user_type:
                continue
            
            # Get eligible users for this role
            eligible_users = User.objects.filter(
                user_filter & Q(role=role)
            ).count()
            
            # Get participants for this role
            participants_query = Vote.objects.filter(
                election_filter,
                status=VoteStatus.CAST
            ).values('election__ballots__user').filter(
                election__ballots__user__role=role,
                election__ballots__user__is_active=True
            ).distinct().count()
            
            # Calculate participation rate
            participation_rate = Decimal('0.00')
            if eligible_users > 0:
                participation_rate = (Decimal(participants_query) / Decimal(eligible_users) * 100).quantize(
                    Decimal('0.01'), rounding=ROUND_HALF_UP
                )
            
            # Categorize participation
            category = _categorize_turnout(participation_rate)
            
            role_data = {
                'eligible_users': eligible_users,
                'participants': participants_query,
                'participation_rate': float(participation_rate),
                'category': category,
            }
            
            results['by_user_type'][role] = role_data
            
            # Update category counts
            results['by_category'][category] += 1
            
            # Update summary
            results['summary']['total_eligible_users'] += eligible_users
            results['summary']['total_participants'] += participants_query
        
        # Calculate overall participation rate
        if results['summary']['total_eligible_users'] > 0:
            overall_rate = (
                Decimal(results['summary']['total_participants']) / 
                Decimal(results['summary']['total_eligible_users']) * 100
            ).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
            results['summary']['overall_participation_rate'] = float(overall_rate)
        
        # Add metadata
        end_time = timezone.now()
        results['metadata'] = {
            'calculated_at': end_time.isoformat(),
            'calculation_duration': (end_time - start_time).total_seconds(),
            'filters': {
                'election_id': election_id,
                'user_type': user_type,
            }
        }
        
        logger.info(f"Participation calculation completed in {results['metadata']['calculation_duration']:.2f}s")
        
        return results
        
    except Exception as e:
        logger.error(f"Error calculating participation analytics: {str(e)}", exc_info=True)
        raise


def calculate_time_series_analytics(
    period_type: str = 'daily',
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    election_id: Optional[str] = None
) -> Dict[str, Any]:
    """
    Calculate time-series analytics for voter participation.
    
    Args:
        period_type: Type of period ('daily', 'weekly', 'election_period')
        start_date: Optional start date filter
        end_date: Optional end date filter
        election_id: Optional election ID filter
        
    Returns:
        Dict containing time-series data
    """
    logger.info(f"Calculating time-series analytics: {period_type}, election: {election_id or 'all'}")
    
    start_time = timezone.now()
    
    try:
        # Set default date range if not provided
        if not end_date:
            end_date = timezone.now()
        if not start_date:
            if period_type == 'daily':
                start_date = end_date - timedelta(days=30)
            elif period_type == 'weekly':
                start_date = end_date - timedelta(weeks=12)
            else:
                start_date = end_date - timedelta(days=365)
        
        # Base filters
        filters = Q(submitted_at__gte=start_date, submitted_at__lte=end_date)
        if election_id:
            filters &= Q(election_id=election_id)
        
        # Choose aggregation function based on period type
        if period_type == 'daily':
            trunc_func = TruncDay
            date_format = '%Y-%m-%d'
        elif period_type == 'weekly':
            trunc_func = TruncWeek
            date_format = '%Y-W%U'
        else:  # election_period
            # For election periods, we'll group by election
            trunc_func = None
            date_format = '%Y-%m-%d'
        
        results = {
            'period_type': period_type,
            'start_date': start_date.isoformat(),
            'end_date': end_date.isoformat(),
            'data_points': [],
            'summary': {
                'total_votes': 0,
                'peak_voting_day': None,
                'average_daily_votes': 0.0,
            }
        }
        
        if period_type == 'election_period' and election_id:
            # Special handling for election period
            election = Election.objects.get(id=election_id)
            
            # Get votes by day during election period
            election_start = election.start_time.date() if election.start_time else start_date.date()
            election_end = election.end_time.date() if election.end_time else end_date.date()
            
            votes_by_day = Vote.objects.filter(
                election=election,
                status=VoteStatus.CAST,
                submitted_at__date__gte=election_start,
                submitted_at__date__lte=election_end
            ).extra(
                select={'day': 'date(submitted_at)'}
            ).values('day').annotate(
                vote_count=Count('id')
            ).order_by('day')
            
            for vote_data in votes_by_day:
                results['data_points'].append({
                    'period': vote_data['day'].strftime(date_format),
                    'vote_count': vote_data['vote_count'],
                    'period_start': vote_data['day'].isoformat(),
                    'period_end': vote_data['day'].isoformat(),
                })
                results['summary']['total_votes'] += vote_data['vote_count']
        
        else:
            # Regular time-series aggregation
            votes_by_period = Vote.objects.filter(filters, status=VoteStatus.CAST).annotate(
                period=trunc_func('submitted_at')
            ).values('period').annotate(
                vote_count=Count('id')
            ).order_by('period')
            
            for vote_data in votes_by_period:
                period_date = vote_data['period']
                
                results['data_points'].append({
                    'period': period_date.strftime(date_format),
                    'vote_count': vote_data['vote_count'],
                    'period_start': period_date.isoformat(),
                    'period_end': period_date.isoformat(),
                })
                results['summary']['total_votes'] += vote_data['vote_count']
        
        # Calculate summary statistics
        if results['data_points']:
            # Find peak voting period
            peak_data = max(results['data_points'], key=lambda x: x['vote_count'])
            results['summary']['peak_voting_day'] = {
                'period': peak_data['period'],
                'vote_count': peak_data['vote_count']
            }
            
            # Calculate average
            if period_type == 'daily':
                total_days = (end_date - start_date).days + 1
                results['summary']['average_daily_votes'] = round(
                    results['summary']['total_votes'] / max(total_days, 1), 2
                )
        
        # Add metadata
        end_time = timezone.now()
        results['metadata'] = {
            'calculated_at': end_time.isoformat(),
            'calculation_duration': (end_time - start_time).total_seconds(),
            'data_points_count': len(results['data_points']),
        }
        
        logger.info(f"Time-series calculation completed in {results['metadata']['calculation_duration']:.2f}s")
        
        return results
        
    except Exception as e:
        logger.error(f"Error calculating time-series analytics: {str(e)}", exc_info=True)
        raise


def _categorize_turnout(percentage: Decimal) -> str:
    """
    Categorize turnout percentage into performance categories.
    
    Args:
        percentage: Turnout percentage as Decimal
        
    Returns:
        str: Category name
    """
    if percentage >= 80:
        return ParticipationCategory.EXCELLENT
    elif percentage >= 60:
        return ParticipationCategory.GOOD
    elif percentage >= 40:
        return ParticipationCategory.FAIR
    else:
        return ParticipationCategory.CRITICAL


def get_election_summary(election_id: str) -> Dict[str, Any]:
    """
    Get comprehensive summary for a specific election.
    
    Args:
        election_id: Election ID to analyze
        
    Returns:
        Dict containing election summary
    """
    logger.info(f"Generating election summary for: {election_id}")
    
    try:
        election = Election.objects.get(id=election_id)
        
        # Get basic metrics
        turnout_data = calculate_turnout_metrics(election_id)
        participation_data = calculate_participation_analytics(election_id)
        
        # Get time series for election period
        time_series_data = calculate_time_series_analytics(
            period_type='election_period',
            election_id=election_id
        )
        
        summary = {
            'election': {
                'id': str(election.id),
                'title': election.title,
                'description': election.description,
                'status': election.status,
                'start_time': election.start_time.isoformat() if election.start_time else None,
                'end_time': election.end_time.isoformat() if election.end_time else None,
                'created_at': election.created_at.isoformat(),
            },
            'turnout': turnout_data['per_election'][0] if turnout_data['per_election'] else {},
            'participation': participation_data,
            'time_series': time_series_data,
            'generated_at': timezone.now().isoformat(),
        }
        
        return summary
        
    except Election.DoesNotExist:
        logger.error(f"Election not found: {election_id}")
        raise ValueError(f"Election with ID {election_id} not found")
    except Exception as e:
        logger.error(f"Error generating election summary: {str(e)}", exc_info=True)
        raise