"""
Audit views for electra_server.

This module contains views for the audit logging system API endpoints,
providing secure access to audit logs with proper authentication,
authorization, and tamper-proof verification capabilities.
"""
from datetime import timedelta
from typing import Dict, Any

from django.db.models import Count, Q
from django.utils import timezone
from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response
from rest_framework.request import Request

from .models import AuditLog, AuditActionType
from .permissions import AuditLogPermission
from .serializers import (
    AuditLogSerializer,
    AuditLogSummarySerializer,
    ChainVerificationSerializer,
    AuditActionTypeSerializer,
    AuditStatsSerializer,
)


class AuditLogPagination(PageNumberPagination):
    """Custom pagination for audit logs with appropriate page sizes."""
    
    page_size = 50
    page_size_query_param = 'page_size'
    max_page_size = 200


class AuditLogListView(generics.ListAPIView):
    """
    List audit log entries with filtering and pagination.
    
    Provides secure access to audit logs for administrators and electoral
    committee members with comprehensive filtering capabilities.
    
    **Authentication Required**: Admin or Electoral Committee
    **TLS Required**: Yes (enforced via middleware)
    """
    
    serializer_class = AuditLogSerializer
    permission_classes = [AuditLogPermission]
    pagination_class = AuditLogPagination
    
    def get_queryset(self):
        """Get filtered audit log queryset based on query parameters."""
        queryset = AuditLog.objects.select_related('user', 'election').order_by('-timestamp')
        
        # Filter by action type
        action_type = self.request.query_params.get('action_type')
        if action_type:
            queryset = queryset.filter(action_type=action_type)
        
        # Filter by action category
        action_category = self.request.query_params.get('action_category')
        if action_category:
            if action_category == 'authentication':
                queryset = queryset.filter(action_type__startswith='user_')
            elif action_category == 'election_management':
                queryset = queryset.filter(action_type__startswith='election_')
            elif action_category == 'ballot_tokens':
                queryset = queryset.filter(action_type__startswith='token_')
            elif action_category == 'voting':
                queryset = queryset.filter(action_type__startswith='vote_')
            elif action_category == 'system':
                queryset = queryset.filter(
                    Q(action_type='admin_action') | Q(action_type='system_error')
                )
        
        # Filter by outcome
        outcome = self.request.query_params.get('outcome')
        if outcome:
            queryset = queryset.filter(outcome=outcome)
        
        # Filter by user
        user_id = self.request.query_params.get('user_id')
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        
        # Filter by election
        election_id = self.request.query_params.get('election_id')
        if election_id:
            queryset = queryset.filter(election_id=election_id)
        
        # Filter by IP address
        ip_address = self.request.query_params.get('ip_address')
        if ip_address:
            queryset = queryset.filter(ip_address=ip_address)
        
        # Date range filtering
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        
        if start_date:
            try:
                start_date = timezone.datetime.fromisoformat(start_date.replace('Z', '+00:00'))
                queryset = queryset.filter(timestamp__gte=start_date)
            except ValueError:
                pass
        
        if end_date:
            try:
                end_date = timezone.datetime.fromisoformat(end_date.replace('Z', '+00:00'))
                queryset = queryset.filter(timestamp__lte=end_date)
            except ValueError:
                pass
        
        # Search in action description
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(action_description__icontains=search)
        
        return queryset
    
    def get_serializer_class(self):
        """Use summary serializer for list view unless detailed is requested."""
        if self.request.query_params.get('detailed') == 'true':
            return AuditLogSerializer
        return AuditLogSummarySerializer


class AuditLogDetailView(generics.RetrieveAPIView):
    """
    Retrieve detailed audit log entry.
    
    Provides full details of a specific audit log entry including
    chain verification status and signature validation.
    
    **Authentication Required**: Admin or Electoral Committee
    **TLS Required**: Yes (enforced via middleware)
    """
    
    queryset = AuditLog.objects.select_related('user', 'election')
    serializer_class = AuditLogSerializer
    permission_classes = [AuditLogPermission]


@api_view(['POST'])
@permission_classes([AuditLogPermission])
def verify_audit_chain(request: Request) -> Response:
    """
    Verify the integrity of the audit log chain.
    
    Performs comprehensive verification of the blockchain-style audit chain,
    checking hash chaining, RSA signatures, and overall integrity.
    
    **Authentication Required**: Admin or Electoral Committee
    **TLS Required**: Yes (enforced via middleware)
    
    **Request Parameters**:
    - start_position (optional): Starting chain position for verification
    - end_position (optional): Ending chain position for verification
    - quick_verify (optional): Perform quick verification (default: false)
    
    **Returns**:
    - Chain verification results with detailed integrity information
    """
    start_position = request.data.get('start_position')
    end_position = request.data.get('end_position')
    quick_verify = request.data.get('quick_verify', False)
    
    try:
        if quick_verify:
            # Quick verification of recent entries only
            recent_entries = AuditLog.objects.filter(
                timestamp__gte=timezone.now() - timedelta(hours=24)
            ).order_by('chain_position')
            
            verification_results = {
                'is_valid': True,
                'total_entries': recent_entries.count(),
                'verified_entries': 0,
                'failed_entries': [],
                'chain_breaks': [],
                'signature_failures': [],
            }
            
            for entry in recent_entries:
                if entry.verify_chain_integrity():
                    verification_results['verified_entries'] += 1
                else:
                    verification_results['is_valid'] = False
                    verification_results['failed_entries'].append({
                        'id': str(entry.id),
                        'chain_position': entry.chain_position,
                        'action_type': entry.action_type,
                        'timestamp': entry.timestamp.isoformat(),
                    })
        else:
            # Full chain verification
            verification_results = AuditLog.verify_chain_integrity_full()
        
        # Add verification metadata
        verification_results.update({
            'verification_timestamp': timezone.now(),
            'verified_by': request.user.email if request.user.is_authenticated else 'Anonymous',
        })
        
        # Log this verification action
        AuditLog.create_audit_entry(
            action_type=AuditActionType.ADMIN_ACTION,
            action_description=f"Audit chain verification performed ({'quick' if quick_verify else 'full'})",
            user=request.user if request.user.is_authenticated else None,
            ip_address=get_client_ip(request),
            user_agent=request.META.get('HTTP_USER_AGENT', ''),
            session_key=request.session.session_key or '',
            outcome='success',
            metadata={
                'verification_type': 'quick' if quick_verify else 'full',
                'start_position': start_position,
                'end_position': end_position,
                'results_summary': {
                    'is_valid': verification_results['is_valid'],
                    'total_entries': verification_results['total_entries'],
                    'verified_entries': verification_results['verified_entries'],
                }
            }
        )
        
        serializer = ChainVerificationSerializer(verification_results)
        return Response(serializer.data, status=status.HTTP_200_OK)
        
    except Exception as e:
        # Log verification failure
        AuditLog.create_audit_entry(
            action_type=AuditActionType.SYSTEM_ERROR,
            action_description="Audit chain verification failed",
            user=request.user if request.user.is_authenticated else None,
            ip_address=get_client_ip(request),
            user_agent=request.META.get('HTTP_USER_AGENT', ''),
            session_key=request.session.session_key or '',
            outcome='error',
            error_details=str(e),
            metadata={
                'verification_type': 'quick' if quick_verify else 'full',
                'start_position': start_position,
                'end_position': end_position,
            }
        )
        
        return Response(
            {
                'error': 'Chain verification failed',
                'detail': str(e)
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([AuditLogPermission])
def audit_action_types(request: Request) -> Response:
    """
    Get available audit action types.
    
    Returns list of available action types for filtering and reference.
    
    **Authentication Required**: Admin or Electoral Committee
    **TLS Required**: Yes (enforced via middleware)
    """
    action_types = [
        {
            'value': choice[0],
            'label': choice[1],
        }
        for choice in AuditActionType.choices
    ]
    
    serializer = AuditActionTypeSerializer(action_types, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([AuditLogPermission])
def audit_stats(request: Request) -> Response:
    """
    Get audit log statistics and metrics.
    
    Provides summary statistics about audit activity for monitoring
    and reporting purposes.
    
    **Authentication Required**: Admin or Electoral Committee
    **TLS Required**: Yes (enforced via middleware)
    """
    now = timezone.now()
    
    try:
        # Basic counts
        total_entries = AuditLog.objects.count()
        entries_24h = AuditLog.objects.filter(
            timestamp__gte=now - timedelta(days=1)
        ).count()
        entries_7d = AuditLog.objects.filter(
            timestamp__gte=now - timedelta(days=7)
        ).count()
        
        # Action type breakdown
        action_type_breakdown = dict(
            AuditLog.objects.values('action_type').annotate(
                count=Count('id')
            ).values_list('action_type', 'count')
        )
        
        # Outcome breakdown
        outcome_breakdown = dict(
            AuditLog.objects.values('outcome').annotate(
                count=Count('id')
            ).values_list('outcome', 'count')
        )
        
        # User activity (anonymized)
        user_activity = {}
        recent_user_activity = AuditLog.objects.filter(
            timestamp__gte=now - timedelta(days=7),
            user__isnull=False
        ).values('user__role').annotate(
            count=Count('id')
        ).order_by('-count')[:10]
        
        for activity in recent_user_activity:
            role = activity['user__role']
            count = activity['count']
            user_activity[f"{role}_users"] = count
        
        # Chain integrity summary
        chain_integrity = {
            'last_verified': None,
            'status': 'unknown',
            'total_chain_length': AuditLog.objects.order_by('-chain_position').first().chain_position if AuditLog.objects.exists() else 0,
        }
        
        stats = {
            'total_entries': total_entries,
            'entries_last_24h': entries_24h,
            'entries_last_7d': entries_7d,
            'action_type_breakdown': action_type_breakdown,
            'outcome_breakdown': outcome_breakdown,
            'user_activity': user_activity,
            'chain_integrity': chain_integrity,
        }
        
        # Log stats access
        AuditLog.create_audit_entry(
            action_type=AuditActionType.ADMIN_ACTION,
            action_description="Audit statistics accessed",
            user=request.user if request.user.is_authenticated else None,
            ip_address=get_client_ip(request),
            user_agent=request.META.get('HTTP_USER_AGENT', ''),
            session_key=request.session.session_key or '',
            outcome='success',
            metadata={
                'stats_summary': {
                    'total_entries': total_entries,
                    'entries_last_24h': entries_24h,
                }
            }
        )
        
        serializer = AuditStatsSerializer(stats)
        return Response(serializer.data)
        
    except Exception as e:
        # Log stats access failure
        AuditLog.create_audit_entry(
            action_type=AuditActionType.SYSTEM_ERROR,
            action_description="Audit statistics access failed",
            user=request.user if request.user.is_authenticated else None,
            ip_address=get_client_ip(request),
            user_agent=request.META.get('HTTP_USER_AGENT', ''),
            session_key=request.session.session_key or '',
            outcome='error',
            error_details=str(e)
        )
        
        return Response(
            {
                'error': 'Failed to retrieve audit statistics',
                'detail': str(e)
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


def get_client_ip(request: Request) -> str:
    """
    Extract client IP address from request.
    
    Handles various proxy configurations commonly used in production.
    """
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0].strip()
    else:
        ip = request.META.get('REMOTE_ADDR', '')
    return ip
