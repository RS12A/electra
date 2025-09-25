"""
Analytics serializers for electra_server.

This module contains DRF serializers for analytics data formatting
and validation with proper type hints and security controls.
"""
from typing import Dict, Any, Optional
from rest_framework import serializers
from django.contrib.auth import get_user_model

from .models import AnalyticsCache, ExportVerification

User = get_user_model()


class TurnoutMetricsSerializer(serializers.Serializer):
    """Serializer for turnout metrics data."""
    
    overall_turnout = serializers.DecimalField(
        max_digits=5, 
        decimal_places=2,
        help_text='Overall turnout percentage across all elections'
    )
    
    per_election = serializers.ListField(
        child=serializers.DictField(),
        help_text='Detailed turnout data per election'
    )
    
    summary = serializers.DictField(
        help_text='Summary statistics for turnout data'
    )
    
    metadata = serializers.DictField(
        help_text='Calculation metadata including timestamps and duration'
    )


class ElectionTurnoutSerializer(serializers.Serializer):
    """Serializer for individual election turnout data."""
    
    election_id = serializers.UUIDField(help_text='Election unique identifier')
    election_title = serializers.CharField(help_text='Election title')
    status = serializers.CharField(help_text='Election status')
    eligible_voters = serializers.IntegerField(help_text='Number of eligible voters')
    votes_cast = serializers.IntegerField(help_text='Number of votes cast')
    turnout_percentage = serializers.DecimalField(
        max_digits=5, 
        decimal_places=2,
        help_text='Turnout percentage for this election'
    )
    category = serializers.CharField(help_text='Turnout category (excellent, good, fair, critical)')
    start_time = serializers.DateTimeField(
        allow_null=True,
        help_text='Election start time'
    )
    end_time = serializers.DateTimeField(
        allow_null=True,
        help_text='Election end time'
    )


class ParticipationAnalyticsSerializer(serializers.Serializer):
    """Serializer for participation analytics data."""
    
    by_user_type = serializers.DictField(
        help_text='Participation data organized by user type'
    )
    
    by_category = serializers.DictField(
        help_text='Count of elections in each participation category'
    )
    
    summary = serializers.DictField(
        help_text='Summary statistics for participation data'
    )
    
    metadata = serializers.DictField(
        help_text='Calculation metadata'
    )


class UserTypeParticipationSerializer(serializers.Serializer):
    """Serializer for user type participation data."""
    
    eligible_users = serializers.IntegerField(help_text='Number of eligible users')
    participants = serializers.IntegerField(help_text='Number of participants')
    participation_rate = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        help_text='Participation rate percentage'
    )
    category = serializers.CharField(help_text='Participation category')


class TimeSeriesAnalyticsSerializer(serializers.Serializer):
    """Serializer for time-series analytics data."""
    
    period_type = serializers.CharField(help_text='Type of time period (daily, weekly, election_period)')
    start_date = serializers.DateTimeField(help_text='Start date for the analysis')
    end_date = serializers.DateTimeField(help_text='End date for the analysis')
    data_points = serializers.ListField(
        child=serializers.DictField(),
        help_text='Time series data points'
    )
    summary = serializers.DictField(help_text='Summary statistics')
    metadata = serializers.DictField(help_text='Calculation metadata')


class TimeSeriesDataPointSerializer(serializers.Serializer):
    """Serializer for individual time series data points."""
    
    period = serializers.CharField(help_text='Period identifier (date/week)')
    vote_count = serializers.IntegerField(help_text='Number of votes in this period')
    period_start = serializers.DateTimeField(help_text='Period start time')
    period_end = serializers.DateTimeField(help_text='Period end time')


class ElectionSummarySerializer(serializers.Serializer):
    """Serializer for comprehensive election summary."""
    
    election = serializers.DictField(help_text='Election basic information')
    turnout = ElectionTurnoutSerializer(help_text='Turnout data for the election')
    participation = ParticipationAnalyticsSerializer(help_text='Participation analytics')
    time_series = TimeSeriesAnalyticsSerializer(help_text='Time series data for election period')
    generated_at = serializers.DateTimeField(help_text='When this summary was generated')


class AnalyticsExportRequestSerializer(serializers.Serializer):
    """Serializer for analytics export requests."""
    
    export_type = serializers.ChoiceField(
        choices=[('csv', 'CSV'), ('xlsx', 'Excel'), ('pdf', 'PDF')],
        help_text='Format for the export'
    )
    
    data_type = serializers.ChoiceField(
        choices=[
            ('turnout', 'Turnout Metrics'),
            ('participation', 'Participation Analytics'),
            ('time_series', 'Time Series Data'),
            ('election_summary', 'Election Summary')
        ],
        help_text='Type of analytics data to export'
    )
    
    election_id = serializers.UUIDField(
        required=False,
        allow_null=True,
        help_text='Optional election ID to filter data'
    )
    
    user_type = serializers.CharField(
        required=False,
        allow_blank=True,
        help_text='Optional user type filter for participation data'
    )
    
    period_type = serializers.ChoiceField(
        choices=[('daily', 'Daily'), ('weekly', 'Weekly'), ('election_period', 'Election Period')],
        required=False,
        default='daily',
        help_text='Time period type for time series data'
    )
    
    start_date = serializers.DateTimeField(
        required=False,
        allow_null=True,
        help_text='Start date for time series data'
    )
    
    end_date = serializers.DateTimeField(
        required=False,
        allow_null=True,
        help_text='End date for time series data'
    )
    
    include_verification = serializers.BooleanField(
        default=True,
        help_text='Include hash verification in the export'
    )
    
    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """Cross-field validation for export requests."""
        data_type = attrs.get('data_type')
        
        # Validate time series specific fields
        if data_type == 'time_series':
            start_date = attrs.get('start_date')
            end_date = attrs.get('end_date')
            
            if start_date and end_date and start_date >= end_date:
                raise serializers.ValidationError(
                    'start_date must be before end_date'
                )
        
        # Validate election summary requires election_id
        if data_type == 'election_summary' and not attrs.get('election_id'):
            raise serializers.ValidationError(
                'election_id is required for election_summary data_type'
            )
        
        return attrs


class AnalyticsExportResponseSerializer(serializers.Serializer):
    """Serializer for analytics export responses."""
    
    export_id = serializers.UUIDField(help_text='Unique identifier for this export')
    filename = serializers.CharField(help_text='Generated filename for the export')
    export_type = serializers.CharField(help_text='Export format type')
    file_size = serializers.IntegerField(help_text='Size of the exported file in bytes')
    verification_hash = serializers.CharField(help_text='Hash for verifying export integrity')
    download_url = serializers.URLField(help_text='URL to download the exported file')
    expires_at = serializers.DateTimeField(help_text='When the download link expires')
    created_at = serializers.DateTimeField(help_text='When the export was created')


class ExportVerificationSerializer(serializers.ModelSerializer):
    """Serializer for export verification records."""
    
    requested_by_name = serializers.CharField(
        source='requested_by.full_name',
        read_only=True,
        help_text='Full name of the user who requested the export'
    )
    
    class Meta:
        model = ExportVerification
        fields = [
            'id',
            'export_type',
            'content_hash',
            'verification_hash',
            'filename',
            'file_size',
            'requested_by',
            'requested_by_name',
            'request_ip',
            'created_at',
        ]
        read_only_fields = [
            'id',
            'content_hash',
            'verification_hash',
            'created_at',
        ]


class AnalyticsCacheSerializer(serializers.ModelSerializer):
    """Serializer for analytics cache entries."""
    
    election_title = serializers.CharField(
        source='election.title',
        read_only=True,
        allow_null=True,
        help_text='Title of the related election'
    )
    
    is_expired = serializers.SerializerMethodField(
        help_text='Whether this cache entry has expired'
    )
    
    class Meta:
        model = AnalyticsCache
        fields = [
            'id',
            'cache_key',
            'election',
            'election_title',
            'data',
            'data_hash',
            'calculation_duration',
            'created_at',
            'expires_at',
            'last_accessed',
            'access_count',
            'is_expired',
        ]
        read_only_fields = [
            'id',
            'data_hash',
            'created_at',
            'last_accessed',
            'access_count',
        ]
    
    def get_is_expired(self, obj: AnalyticsCache) -> bool:
        """Get whether the cache entry is expired."""
        return obj.is_expired()


class AnalyticsRequestSerializer(serializers.Serializer):
    """Base serializer for analytics requests with common parameters."""
    
    election_id = serializers.UUIDField(
        required=False,
        allow_null=True,
        help_text='Optional election ID to filter results'
    )
    
    use_cache = serializers.BooleanField(
        default=True,
        help_text='Whether to use cached results if available'
    )
    
    force_refresh = serializers.BooleanField(
        default=False,
        help_text='Force refresh of cached data'
    )


class TurnoutRequestSerializer(AnalyticsRequestSerializer):
    """Serializer for turnout metrics requests."""
    
    include_trends = serializers.BooleanField(
        default=False,
        help_text='Include trend analysis data in the response'
    )
    
    category_filter = serializers.ChoiceField(
        choices=[
            ('all', 'All Categories'),
            ('excellent', 'Excellent (>80%)'),
            ('good', 'Good (60-80%)'),
            ('fair', 'Fair (40-60%)'),
            ('critical', 'Critical (<40%)')
        ],
        default='all',
        required=False,
        help_text='Filter elections by turnout category'
    )
    
    status_filter = serializers.ChoiceField(
        choices=[
            ('all', 'All Statuses'),
            ('draft', 'Draft'),
            ('active', 'Active'),
            ('completed', 'Completed'),
            ('cancelled', 'Cancelled')
        ],
        default='all',
        required=False,
        help_text='Filter elections by status'
    )


class ParticipationRequestSerializer(AnalyticsRequestSerializer):
    """Serializer for participation analytics requests."""
    
    user_type = serializers.CharField(
        required=False,
        allow_blank=True,
        help_text='Optional user type filter (student, staff, candidate)'
    )


class TimeSeriesRequestSerializer(AnalyticsRequestSerializer):
    """Serializer for time series analytics requests."""
    
    period_type = serializers.ChoiceField(
        choices=[('daily', 'Daily'), ('weekly', 'Weekly'), ('election_period', 'Election Period')],
        default='daily',
        help_text='Type of time period for aggregation'
    )
    
    start_date = serializers.DateTimeField(
        required=False,
        allow_null=True,
        help_text='Start date for the time series'
    )
    
    end_date = serializers.DateTimeField(
        required=False,
        allow_null=True,
        help_text='End date for the time series'
    )
    
    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """Validate time series request parameters."""
        start_date = attrs.get('start_date')
        end_date = attrs.get('end_date')
        
        if start_date and end_date and start_date >= end_date:
            raise serializers.ValidationError(
                'start_date must be before end_date'
            )
        
        return attrs