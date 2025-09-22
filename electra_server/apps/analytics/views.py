"""
Analytics views for the electra voting system.

This module contains API views for analytics data access and export
with comprehensive security and caching support.
"""
import hashlib
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, Optional

from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.http import HttpResponse
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import action
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.viewsets import ViewSet

from electra_server.apps.audit.utils import log_user_action
from electra_server.apps.audit.models import AuditActionType

from .calculations import (
    calculate_turnout_metrics,
    calculate_participation_analytics,
    calculate_time_series_analytics,
    get_election_summary
)
from .export_utils import AnalyticsExporter, create_download_response
from .models import AnalyticsCache, ExportVerification
from .permissions import AnalyticsPermission, AnalyticsExportPermission
from .serializers import (
    TurnoutMetricsSerializer,
    ParticipationAnalyticsSerializer,
    TimeSeriesAnalyticsSerializer,
    ElectionSummarySerializer,
    AnalyticsExportRequestSerializer,
    AnalyticsExportResponseSerializer,
    TurnoutRequestSerializer,
    ParticipationRequestSerializer,
    TimeSeriesRequestSerializer
)

User = get_user_model()
logger = logging.getLogger('electra_server.analytics')


class AnalyticsViewSet(ViewSet):
    """
    ViewSet for analytics data access with caching and security.
    
    Provides comprehensive analytics endpoints for turnout metrics,
    participation analytics, and time-series data.
    """
    
    permission_classes = [AnalyticsPermission]
    
    def _get_client_ip(self, request: Request) -> str:
        """Extract client IP address from request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR', 'unknown')
        return ip
    
    def _get_cache_key(self, prefix: str, params: Dict[str, Any]) -> str:
        """Generate cache key for analytics data."""
        # Create deterministic cache key from parameters
        param_string = ','.join(f"{k}:{v}" for k, v in sorted(params.items()) if v is not None)
        cache_hash = hashlib.md5(param_string.encode()).hexdigest()
        return f"analytics_{prefix}_{cache_hash}"
    
    def _get_cached_data(
        self,
        cache_key: str,
        calculation_func,
        calculation_args: tuple = (),
        calculation_kwargs: Dict[str, Any] = None,
        cache_timeout: int = 3600  # 1 hour default
    ) -> Dict[str, Any]:
        """
        Get data from cache or calculate and cache it.
        
        Args:
            cache_key: Cache key for the data
            calculation_func: Function to calculate data if not cached
            calculation_args: Arguments for calculation function
            calculation_kwargs: Keyword arguments for calculation function
            cache_timeout: Cache timeout in seconds
            
        Returns:
            Dict containing the analytics data
        """
        if calculation_kwargs is None:
            calculation_kwargs = {}
        
        # Try to get from Django cache first (fast)
        cached_data = cache.get(cache_key)
        if cached_data:
            logger.info(f"Analytics data retrieved from Django cache: {cache_key}")
            return cached_data
        
        # Try to get from database cache
        try:
            cache_entry = AnalyticsCache.objects.get(
                cache_key=cache_key,
                expires_at__gt=timezone.now()
            )
            
            # Verify data integrity
            if cache_entry.verify_integrity():
                cache_entry.mark_accessed()
                # Store in Django cache for faster access
                cache.set(cache_key, cache_entry.data, cache_timeout)
                logger.info(f"Analytics data retrieved from database cache: {cache_key}")
                return cache_entry.data
            else:
                logger.warning(f"Cache integrity verification failed for: {cache_key}")
                cache_entry.delete()
        
        except AnalyticsCache.DoesNotExist:
            pass
        
        # Calculate fresh data
        logger.info(f"Calculating fresh analytics data: {cache_key}")
        start_time = timezone.now()
        
        try:
            data = calculation_func(*calculation_args, **calculation_kwargs)
            
            calculation_duration = (timezone.now() - start_time).total_seconds()
            
            # Cache in database
            expires_at = timezone.now() + timedelta(seconds=cache_timeout)
            
            # Extract election from kwargs if present
            election_id = calculation_kwargs.get('election_id')
            election = None
            if election_id:
                from electra_server.apps.elections.models import Election
                try:
                    election = Election.objects.get(id=election_id)
                except Election.DoesNotExist:
                    pass
            
            AnalyticsCache.objects.create(
                cache_key=cache_key,
                election=election,
                data=data,
                calculation_duration=calculation_duration,
                expires_at=expires_at
            )
            
            # Cache in Django cache
            cache.set(cache_key, data, cache_timeout)
            
            logger.info(f"Analytics data calculated and cached in {calculation_duration:.2f}s: {cache_key}")
            
            return data
            
        except Exception as e:
            logger.error(f"Error calculating analytics data: {str(e)}", exc_info=True)
            raise
    
    @action(detail=False, methods=['get', 'post'], url_path='turnout')
    def turnout_metrics(self, request: Request) -> Response:
        """
        Get turnout metrics for elections.
        
        Query parameters:
        - election_id: Optional UUID to filter by specific election
        - use_cache: Boolean to enable/disable caching (default: true)
        - force_refresh: Boolean to force cache refresh (default: false)
        """
        # Parse request parameters
        if request.method == 'POST':
            serializer = TurnoutRequestSerializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            params = serializer.validated_data
        else:
            params = {
                'election_id': request.query_params.get('election_id'),
                'use_cache': request.query_params.get('use_cache', 'true').lower() == 'true',
                'force_refresh': request.query_params.get('force_refresh', 'false').lower() == 'true'
            }
        
        election_id = params.get('election_id')
        use_cache = params.get('use_cache', True)
        force_refresh = params.get('force_refresh', False)
        
        # Log access
        log_user_action(
            user=request.user,
            action_type=AuditActionType.ADMIN_ACTION,
            description=f'Turnout metrics accessed - election: {election_id or "all"}',
            outcome='success',
            metadata={
                'endpoint': 'turnout_metrics',
                'election_id': election_id,
                'use_cache': use_cache,
                'force_refresh': force_refresh,
                'ip_address': self._get_client_ip(request),
            }
        )
        
        try:
            if use_cache and not force_refresh:
                # Use caching
                cache_key = self._get_cache_key('turnout', {'election_id': election_id})
                data = self._get_cached_data(
                    cache_key=cache_key,
                    calculation_func=calculate_turnout_metrics,
                    calculation_kwargs={'election_id': election_id}
                )
            else:
                # Calculate fresh data
                data = calculate_turnout_metrics(election_id=election_id)
            
            # Serialize and return
            serializer = TurnoutMetricsSerializer(data)
            return Response(serializer.data, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Error in turnout_metrics endpoint: {str(e)}", exc_info=True)
            
            # Log error
            log_user_action(
                user=request.user,
                action_type=AuditActionType.ADMIN_ACTION,
                description=f'Turnout metrics access failed - election: {election_id or "all"}',
                outcome='error',
                metadata={
                    'endpoint': 'turnout_metrics',
                    'error': str(e),
                    'ip_address': self._get_client_ip(request),
                }
            )
            
            return Response(
                {'error': 'Failed to calculate turnout metrics'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['get', 'post'], url_path='participation')
    def participation_analytics(self, request: Request) -> Response:
        """
        Get participation analytics by category and user type.
        
        Query parameters:
        - election_id: Optional UUID to filter by specific election
        - user_type: Optional user type filter (student, staff, etc.)
        - use_cache: Boolean to enable/disable caching (default: true)
        - force_refresh: Boolean to force cache refresh (default: false)
        """
        # Parse request parameters
        if request.method == 'POST':
            serializer = ParticipationRequestSerializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            params = serializer.validated_data
        else:
            params = {
                'election_id': request.query_params.get('election_id'),
                'user_type': request.query_params.get('user_type'),
                'use_cache': request.query_params.get('use_cache', 'true').lower() == 'true',
                'force_refresh': request.query_params.get('force_refresh', 'false').lower() == 'true'
            }
        
        election_id = params.get('election_id')
        user_type = params.get('user_type')
        use_cache = params.get('use_cache', True)
        force_refresh = params.get('force_refresh', False)
        
        # Log access
        log_user_action(
            user=request.user,
            action_type=AuditActionType.ADMIN_ACTION,
            description=f'Participation analytics accessed - election: {election_id or "all"}, user_type: {user_type or "all"}',
            outcome='success',
            metadata={
                'endpoint': 'participation_analytics',
                'election_id': election_id,
                'user_type': user_type,
                'use_cache': use_cache,
                'force_refresh': force_refresh,
                'ip_address': self._get_client_ip(request),
            }
        )
        
        try:
            if use_cache and not force_refresh:
                # Use caching
                cache_key = self._get_cache_key('participation', {
                    'election_id': election_id,
                    'user_type': user_type
                })
                data = self._get_cached_data(
                    cache_key=cache_key,
                    calculation_func=calculate_participation_analytics,
                    calculation_kwargs={
                        'election_id': election_id,
                        'user_type': user_type
                    }
                )
            else:
                # Calculate fresh data
                data = calculate_participation_analytics(
                    election_id=election_id,
                    user_type=user_type
                )
            
            # Serialize and return
            serializer = ParticipationAnalyticsSerializer(data)
            return Response(serializer.data, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Error in participation_analytics endpoint: {str(e)}", exc_info=True)
            
            # Log error
            log_user_action(
                user=request.user,
                action_type=AuditActionType.ADMIN_ACTION,
                description=f'Participation analytics access failed - election: {election_id or "all"}',
                outcome='error',
                metadata={
                    'endpoint': 'participation_analytics',
                    'error': str(e),
                    'ip_address': self._get_client_ip(request),
                }
            )
            
            return Response(
                {'error': 'Failed to calculate participation analytics'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['get', 'post'], url_path='time-series')
    def time_series_analytics(self, request: Request) -> Response:
        """
        Get time-series analytics for voter participation.
        
        Query parameters:
        - period_type: Type of period (daily, weekly, election_period)
        - start_date: Optional start date (ISO format)
        - end_date: Optional end date (ISO format)
        - election_id: Optional election ID for election_period type
        - use_cache: Boolean to enable/disable caching (default: true)
        - force_refresh: Boolean to force cache refresh (default: false)
        """
        # Parse request parameters
        if request.method == 'POST':
            serializer = TimeSeriesRequestSerializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            params = serializer.validated_data
        else:
            params = {
                'period_type': request.query_params.get('period_type', 'daily'),
                'start_date': request.query_params.get('start_date'),
                'end_date': request.query_params.get('end_date'),
                'election_id': request.query_params.get('election_id'),
                'use_cache': request.query_params.get('use_cache', 'true').lower() == 'true',
                'force_refresh': request.query_params.get('force_refresh', 'false').lower() == 'true'
            }
            
            # Parse date strings if provided
            for date_field in ['start_date', 'end_date']:
                if params[date_field]:
                    try:
                        params[date_field] = datetime.fromisoformat(params[date_field].replace('Z', '+00:00'))
                    except ValueError:
                        return Response(
                            {'error': f'Invalid {date_field} format. Use ISO 8601 format.'},
                            status=status.HTTP_400_BAD_REQUEST
                        )
        
        period_type = params.get('period_type', 'daily')
        start_date = params.get('start_date')
        end_date = params.get('end_date')
        election_id = params.get('election_id')
        use_cache = params.get('use_cache', True)
        force_refresh = params.get('force_refresh', False)
        
        # Log access
        log_user_action(
            user=request.user,
            action_type=AuditActionType.ADMIN_ACTION,
            description=f'Time series analytics accessed - period: {period_type}, election: {election_id or "all"}',
            outcome='success',
            metadata={
                'endpoint': 'time_series_analytics',
                'period_type': period_type,
                'election_id': election_id,
                'use_cache': use_cache,
                'force_refresh': force_refresh,
                'ip_address': self._get_client_ip(request),
            }
        )
        
        try:
            if use_cache and not force_refresh:
                # Use caching
                cache_key = self._get_cache_key('time_series', {
                    'period_type': period_type,
                    'start_date': start_date.isoformat() if start_date else None,
                    'end_date': end_date.isoformat() if end_date else None,
                    'election_id': election_id
                })
                data = self._get_cached_data(
                    cache_key=cache_key,
                    calculation_func=calculate_time_series_analytics,
                    calculation_kwargs={
                        'period_type': period_type,
                        'start_date': start_date,
                        'end_date': end_date,
                        'election_id': election_id
                    }
                )
            else:
                # Calculate fresh data
                data = calculate_time_series_analytics(
                    period_type=period_type,
                    start_date=start_date,
                    end_date=end_date,
                    election_id=election_id
                )
            
            # Serialize and return
            serializer = TimeSeriesAnalyticsSerializer(data)
            return Response(serializer.data, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Error in time_series_analytics endpoint: {str(e)}", exc_info=True)
            
            # Log error
            log_user_action(
                user=request.user,
                action_type=AuditActionType.ADMIN_ACTION,
                description=f'Time series analytics access failed - period: {period_type}',
                outcome='error',
                metadata={
                    'endpoint': 'time_series_analytics',
                    'error': str(e),
                    'ip_address': self._get_client_ip(request),
                }
            )
            
            return Response(
                {'error': 'Failed to calculate time series analytics'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['get'], url_path='election-summary/(?P<election_id>[^/.]+)')
    def election_summary(self, request: Request, election_id: str) -> Response:
        """
        Get comprehensive summary for a specific election.
        
        Args:
            election_id: UUID of the election to analyze
        """
        use_cache = request.query_params.get('use_cache', 'true').lower() == 'true'
        force_refresh = request.query_params.get('force_refresh', 'false').lower() == 'true'
        
        # Log access
        log_user_action(
            user=request.user,
            action_type=AuditActionType.ADMIN_ACTION,
            description=f'Election summary accessed - election: {election_id}',
            outcome='success',
            metadata={
                'endpoint': 'election_summary',
                'election_id': election_id,
                'use_cache': use_cache,
                'force_refresh': force_refresh,
                'ip_address': self._get_client_ip(request),
            }
        )
        
        try:
            if use_cache and not force_refresh:
                # Use caching
                cache_key = self._get_cache_key('election_summary', {'election_id': election_id})
                data = self._get_cached_data(
                    cache_key=cache_key,
                    calculation_func=get_election_summary,
                    calculation_args=(election_id,)
                )
            else:
                # Calculate fresh data
                data = get_election_summary(election_id)
            
            # Serialize and return
            serializer = ElectionSummarySerializer(data)
            return Response(serializer.data, status=status.HTTP_200_OK)
            
        except ValueError as e:
            # Election not found
            return Response(
                {'error': str(e)},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f"Error in election_summary endpoint: {str(e)}", exc_info=True)
            
            # Log error
            log_user_action(
                user=request.user,
                action_type=AuditActionType.ADMIN_ACTION,
                description=f'Election summary access failed - election: {election_id}',
                outcome='error',
                metadata={
                    'endpoint': 'election_summary',
                    'error': str(e),
                    'ip_address': self._get_client_ip(request),
                }
            )
            
            return Response(
                {'error': 'Failed to generate election summary'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class AnalyticsExportView(APIView):
    """
    View for exporting analytics data in various formats.
    
    Supports CSV, XLSX, and PDF exports with hash verification.
    """
    
    permission_classes = [AnalyticsExportPermission]
    
    def _get_client_ip(self, request: Request) -> str:
        """Extract client IP address from request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR', 'unknown')
        return ip
    
    def post(self, request: Request) -> Response:
        """
        Export analytics data in the specified format.
        
        Request body should contain:
        - export_type: Format (csv, xlsx, pdf)
        - data_type: Type of data (turnout, participation, time_series, election_summary)
        - Various optional filters based on data_type
        """
        # Validate request
        serializer = AnalyticsExportRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        export_params = serializer.validated_data
        export_type = export_params['export_type']
        data_type = export_params['data_type']
        
        # Log export request
        log_user_action(
            user=request.user,
            action_type=AuditActionType.ADMIN_ACTION,
            description=f'Analytics export requested - type: {export_type}, data: {data_type}',
            outcome='initiated',
            metadata={
                'endpoint': 'analytics_export',
                'export_type': export_type,
                'data_type': data_type,
                'export_params': export_params,
                'ip_address': self._get_client_ip(request),
            }
        )
        
        try:
            # Get analytics data based on type
            if data_type == 'turnout':
                data = calculate_turnout_metrics(
                    election_id=export_params.get('election_id')
                )
                filename_base = f"turnout_metrics"
                
            elif data_type == 'participation':
                data = calculate_participation_analytics(
                    election_id=export_params.get('election_id'),
                    user_type=export_params.get('user_type')
                )
                filename_base = f"participation_analytics"
                
            elif data_type == 'time_series':
                data = calculate_time_series_analytics(
                    period_type=export_params.get('period_type', 'daily'),
                    start_date=export_params.get('start_date'),
                    end_date=export_params.get('end_date'),
                    election_id=export_params.get('election_id')
                )
                filename_base = f"time_series_{export_params.get('period_type', 'daily')}"
                
            elif data_type == 'election_summary':
                election_id = export_params['election_id']  # Required for this type
                data = get_election_summary(election_id)
                filename_base = f"election_summary_{election_id}"
                
            else:
                return Response(
                    {'error': f'Unsupported data type: {data_type}'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Create exporter and export data
            exporter = AnalyticsExporter(
                user=request.user,
                request_ip=self._get_client_ip(request)
            )
            
            exported_data, verification = exporter.export_data(
                data=data,
                export_type=export_type,
                filename=filename_base,
                export_params=export_params
            )
            
            # Log successful export
            log_user_action(
                user=request.user,
                action_type=AuditActionType.ADMIN_ACTION,
                description=f'Analytics export completed - {verification.filename}',
                outcome='success',
                metadata={
                    'endpoint': 'analytics_export',
                    'export_id': str(verification.id),
                    'filename': verification.filename,
                    'file_size': verification.file_size,
                    'verification_hash': verification.verification_hash,
                    'ip_address': self._get_client_ip(request),
                }
            )
            
            # Determine content type
            content_types = {
                'csv': 'text/csv',
                'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                'pdf': 'application/pdf'
            }
            
            content_type = content_types.get(export_type, 'application/octet-stream')
            
            # Return file download response
            response = create_download_response(
                content=exported_data,
                filename=verification.filename,
                content_type=content_type
            )
            
            # Add verification headers
            response['X-Export-Verification-Hash'] = verification.verification_hash
            response['X-Export-ID'] = str(verification.id)
            response['X-Content-Hash'] = verification.content_hash
            
            return response
            
        except ValueError as e:
            # Data validation error
            log_user_action(
                user=request.user,
                action_type=AuditActionType.ADMIN_ACTION,
                description=f'Analytics export failed - validation error: {str(e)}',
                outcome='error',
                metadata={
                    'endpoint': 'analytics_export',
                    'error': str(e),
                    'export_params': export_params,
                    'ip_address': self._get_client_ip(request),
                }
            )
            
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        except Exception as e:
            logger.error(f"Error in analytics export: {str(e)}", exc_info=True)
            
            # Log error
            log_user_action(
                user=request.user,
                action_type=AuditActionType.ADMIN_ACTION,
                description=f'Analytics export failed - system error: {str(e)}',
                outcome='error',
                metadata={
                    'endpoint': 'analytics_export',
                    'error': str(e),
                    'export_params': export_params,
                    'ip_address': self._get_client_ip(request),
                }
            )
            
            return Response(
                {'error': 'Failed to export analytics data'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ExportVerificationView(APIView):
    """
    View for verifying exported analytics data.
    
    Allows users to verify the integrity of previously exported files.
    """
    
    permission_classes = [AnalyticsPermission]
    
    def get(self, request: Request, verification_hash: str) -> Response:
        """
        Get verification details for an export.
        
        Args:
            verification_hash: Hash to verify
        """
        try:
            verification = ExportVerification.objects.get(
                verification_hash=verification_hash
            )
            
            # Check if user can access this verification
            # (either the user who created it, or admin/electoral committee)
            if (verification.requested_by != request.user and 
                not request.user.role in ['admin', 'electoral_committee']):
                return Response(
                    {'error': 'Access denied to this verification record'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Log verification check
            log_user_action(
                user=request.user,
                action_type=AuditActionType.ADMIN_ACTION,
                description=f'Export verification checked - {verification.filename}',
                outcome='success',
                metadata={
                    'endpoint': 'export_verification',
                    'verification_hash': verification_hash,
                    'export_id': str(verification.id),
                    'original_requester': verification.requested_by.id,
                }
            )
            
            # Return verification details
            response_data = {
                'verification_hash': verification.verification_hash,
                'content_hash': verification.content_hash,
                'filename': verification.filename,
                'export_type': verification.export_type,
                'file_size': verification.file_size,
                'created_at': verification.created_at.isoformat(),
                'requested_by': verification.requested_by.full_name,
                'export_params': verification.export_params,
                'verified': True,
                'message': 'Export verification successful - file integrity confirmed'
            }
            
            return Response(response_data, status=status.HTTP_200_OK)
            
        except ExportVerification.DoesNotExist:
            # Log failed verification
            log_user_action(
                user=request.user,
                action_type=AuditActionType.ADMIN_ACTION,
                description=f'Export verification failed - hash not found: {verification_hash}',
                outcome='error',
                metadata={
                    'endpoint': 'export_verification',
                    'verification_hash': verification_hash,
                }
            )
            
            return Response(
                {
                    'verified': False,
                    'error': 'Verification hash not found',
                    'message': 'This export could not be verified'
                },
                status=status.HTTP_404_NOT_FOUND
            )
            
        except Exception as e:
            logger.error(f"Error in export verification: {str(e)}", exc_info=True)
            
            return Response(
                {
                    'verified': False,
                    'error': 'Verification system error',
                    'message': 'Unable to complete verification'
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )