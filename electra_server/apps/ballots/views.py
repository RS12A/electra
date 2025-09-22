"""
Ballot views for electra_server.

This module contains all API views for ballot token operations including
issuance, validation, offline queue management, and statistics.
"""
import logging
from datetime import timedelta
from typing import Dict, Any

from django.contrib.auth import get_user_model
from django.db import transaction
from django.db.models import Count, Q, QuerySet
from django.utils import timezone
from rest_framework import generics, status, views
from rest_framework.request import Request
from rest_framework.response import Response

from electra_server.apps.elections.models import Election
from .models import (
    BallotToken, BallotTokenStatus, OfflineBallotQueue, 
    BallotTokenUsageLog
)
from .permissions import (
    CanRequestBallotTokens, CanValidateBallotTokens, 
    CanManageBallotTokens, CanViewBallotTokenStats,
    IsBallotTokenOwner, CanAccessOfflineQueue
)
from .serializers import (
    BallotTokenRequestSerializer, BallotTokenResponseSerializer,
    BallotTokenValidationSerializer, BallotTokenValidationResponseSerializer,
    OfflineBallotQueueSerializer, OfflineBallotSubmissionSerializer,
    BallotTokenUsageLogSerializer, BallotTokenStatsSerializer
)

User = get_user_model()
logger = logging.getLogger(__name__)


class BallotTokenRequestView(generics.CreateAPIView):
    """
    Request a ballot token for an election.
    
    POST /api/ballots/request-token/
    
    Generates and returns a cryptographically signed ballot token
    for the specified election. Each user can only have one valid
    token per election.
    """
    
    serializer_class = BallotTokenRequestSerializer
    permission_classes = [CanRequestBallotTokens]
    
    def create(self, request: Request, *args, **kwargs) -> Response:
        """
        Create a new ballot token.
        
        Args:
            request: HTTP request containing election_id
            
        Returns:
            Response: Ballot token details with signature
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        election_id = serializer.validated_data['election_id']
        election = Election.objects.get(id=election_id)
        
        # Get client IP and user agent for security logging
        ip_address = self.get_client_ip(request)
        user_agent = request.META.get('HTTP_USER_AGENT', '')
        
        try:
            with transaction.atomic():
                # Create the ballot token
                ballot_token = BallotToken(
                    user=request.user,
                    election=election,
                    issued_ip=ip_address,
                    issued_user_agent=user_agent,
                )
                
                # Generate and set signature
                ballot_token.signature = ballot_token.create_signature()
                ballot_token.save()
                
                # Log the token issuance
                self.log_token_action(
                    ballot_token, 'issued', ip_address, user_agent,
                    {'election_title': election.title}
                )
                
                # Create response
                response_serializer = BallotTokenResponseSerializer(ballot_token)
                
                logger.info(
                    'Ballot token issued',
                    extra={
                        'user_id': request.user.id,
                        'user_role': request.user.role,
                        'election_id': election.id,
                        'token_id': ballot_token.id,
                        'ip_address': ip_address,
                        'endpoint': 'ballot_token_request'
                    }
                )
                
                return Response(
                    response_serializer.data,
                    status=status.HTTP_201_CREATED
                )
                
        except Exception as e:
            logger.error(
                'Ballot token issuance failed',
                extra={
                    'user_id': request.user.id,
                    'election_id': election_id,
                    'error': str(e),
                    'ip_address': ip_address,
                    'endpoint': 'ballot_token_request'
                },
                exc_info=True
            )
            return Response(
                {'error': 'Token issuance failed. Please try again.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def get_client_ip(self, request: Request) -> str:
        """Get client IP address from request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip
    
    def log_token_action(
        self, token: BallotToken, action: str, ip: str, 
        user_agent: str, metadata: Dict[str, Any] = None
    ) -> None:
        """Log ballot token action for audit trail."""
        BallotTokenUsageLog.objects.create(
            ballot_token=token,
            action=action,
            ip_address=ip,
            user_agent=user_agent,
            metadata=metadata or {}
        )


class BallotTokenValidateView(views.APIView):
    """
    Validate a ballot token.
    
    POST /api/ballots/validate-token/
    
    Validates the RSA signature and status of a ballot token
    before allowing it to be used for voting.
    """
    
    permission_classes = [CanValidateBallotTokens]
    
    def post(self, request: Request, *args, **kwargs) -> Response:
        """
        Validate a ballot token.
        
        Args:
            request: HTTP request containing token_uuid and signature
            
        Returns:
            Response: Validation result with token details if valid
        """
        serializer = BallotTokenValidationSerializer(
            data=request.data,
            context={'request': request}
        )
        
        if serializer.is_valid():
            token = serializer.validated_data['token']
            
            # Log validation attempt
            ip_address = self.get_client_ip(request)
            user_agent = request.META.get('HTTP_USER_AGENT', '')
            
            self.log_token_action(
                token, 'validated', ip_address, user_agent,
                {'validator_user_id': str(request.user.id)}
            )
            
            response_data = {
                'valid': True,
                'token': BallotTokenResponseSerializer(token).data,
                'message': 'Token is valid for voting.'
            }
            
            logger.info(
                'Ballot token validated successfully',
                extra={
                    'validator_user_id': request.user.id,
                    'token_owner_id': token.user.id,
                    'token_id': token.id,
                    'election_id': token.election.id,
                    'ip_address': ip_address,
                    'endpoint': 'ballot_token_validate'
                }
            )
            
            return Response(
                response_data,
                status=status.HTTP_200_OK
            )
        else:
            # Invalid token
            error_message = next(iter(serializer.errors.values()))[0]
            
            logger.warning(
                'Ballot token validation failed',
                extra={
                    'validator_user_id': request.user.id,
                    'error': error_message,
                    'request_data': request.data,
                    'ip_address': self.get_client_ip(request),
                    'endpoint': 'ballot_token_validate'
                }
            )
            
            response_data = {
                'valid': False,
                'message': error_message
            }
            
            return Response(
                response_data,
                status=status.HTTP_400_BAD_REQUEST
            )
    
    def get_client_ip(self, request: Request) -> str:
        """Get client IP address from request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip
    
    def log_token_action(
        self, token: BallotToken, action: str, ip: str, 
        user_agent: str, metadata: Dict[str, Any] = None
    ) -> None:
        """Log ballot token action for audit trail."""
        BallotTokenUsageLog.objects.create(
            ballot_token=token,
            action=action,
            ip_address=ip,
            user_agent=user_agent,
            metadata=metadata or {}
        )


class UserBallotTokensView(generics.ListAPIView):
    """
    List user's ballot tokens.
    
    GET /api/ballots/my-tokens/
    
    Returns all ballot tokens belonging to the authenticated user.
    """
    
    serializer_class = BallotTokenResponseSerializer
    permission_classes = [CanRequestBallotTokens]
    
    def get_queryset(self) -> QuerySet[BallotToken]:
        """Get ballot tokens for the authenticated user."""
        return BallotToken.objects.filter(
            user=self.request.user
        ).select_related('election').order_by('-issued_at')


class BallotTokenDetailView(generics.RetrieveAPIView):
    """
    Retrieve specific ballot token details.
    
    GET /api/ballots/tokens/<uuid:token_id>/
    
    Returns detailed information about a specific ballot token.
    Only token owners and managers can access token details.
    """
    
    serializer_class = BallotTokenResponseSerializer
    permission_classes = [IsBallotTokenOwner | CanManageBallotTokens]
    lookup_field = 'id'
    
    def get_queryset(self) -> QuerySet[BallotToken]:
        """Get ballot tokens based on user permissions."""
        if hasattr(self.request.user, 'role') and self.request.user.role in [
            'admin', 'electoral_committee'
        ]:
            return BallotToken.objects.select_related('user', 'election').all()
        else:
            return BallotToken.objects.filter(
                user=self.request.user
            ).select_related('election')


class OfflineBallotQueueView(generics.ListCreateAPIView):
    """
    Manage offline ballot queue.
    
    GET /api/ballots/offline-queue/ - List offline queue entries
    POST /api/ballots/offline-queue/ - Add entry to offline queue
    
    Handles offline voting scenarios where tokens and votes
    need to be queued for later synchronization.
    """
    
    serializer_class = OfflineBallotQueueSerializer
    permission_classes = [CanAccessOfflineQueue]
    
    def get_queryset(self) -> QuerySet[OfflineBallotQueue]:
        """Get offline queue entries based on user permissions."""
        if hasattr(self.request.user, 'role') and self.request.user.role in [
            'admin', 'electoral_committee'
        ]:
            return OfflineBallotQueue.objects.select_related(
                'ballot_token__user', 'ballot_token__election'
            ).all()
        else:
            return OfflineBallotQueue.objects.filter(
                ballot_token__user=self.request.user
            ).select_related('ballot_token__election')


class OfflineBallotSubmissionView(views.APIView):
    """
    Submit offline ballot votes.
    
    POST /api/ballots/offline-submit/
    
    Processes votes that were cast offline and synchronizes
    them back to the server when connectivity is restored.
    """
    
    permission_classes = [CanAccessOfflineQueue]
    
    def post(self, request: Request, *args, **kwargs) -> Response:
        """
        Submit offline ballot vote.
        
        Args:
            request: HTTP request with offline vote data
            
        Returns:
            Response: Submission result
        """
        serializer = OfflineBallotSubmissionSerializer(
            data=request.data,
            context={'request': request}
        )
        
        if not serializer.is_valid():
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            with transaction.atomic():
                token = serializer.validated_data['token']
                encrypted_vote_data = serializer.validated_data['encrypted_vote_data']
                submission_timestamp = serializer.validated_data['submission_timestamp']
                
                # Mark token as used
                token.mark_as_used()
                
                # Create offline queue entry if it doesn't exist
                queue_entry, created = OfflineBallotQueue.objects.get_or_create(
                    ballot_token=token,
                    defaults={
                        'encrypted_data': encrypted_vote_data,
                    }
                )
                
                if not created:
                    # Update existing entry
                    queue_entry.encrypted_data = encrypted_vote_data
                    queue_entry.save(update_fields=['encrypted_data'])
                
                # Mark as synced since we're processing it now
                queue_entry.mark_as_synced()
                
                # Log the submission
                ip_address = self.get_client_ip(request)
                user_agent = request.META.get('HTTP_USER_AGENT', '')
                
                BallotTokenUsageLog.objects.create(
                    ballot_token=token,
                    action='offline_submission',
                    ip_address=ip_address,
                    user_agent=user_agent,
                    metadata={
                        'submission_timestamp': submission_timestamp.isoformat(),
                        'queue_entry_id': str(queue_entry.id)
                    }
                )
                
                logger.info(
                    'Offline ballot submitted successfully',
                    extra={
                        'user_id': token.user.id,
                        'token_id': token.id,
                        'election_id': token.election.id,
                        'submission_timestamp': submission_timestamp.isoformat(),
                        'ip_address': ip_address,
                        'endpoint': 'offline_ballot_submission'
                    }
                )
                
                return Response(
                    {
                        'success': True,
                        'message': 'Offline ballot submitted successfully.',
                        'queue_entry_id': queue_entry.id
                    },
                    status=status.HTTP_200_OK
                )
                
        except Exception as e:
            logger.error(
                'Offline ballot submission failed',
                extra={
                    'user_id': request.user.id,
                    'error': str(e),
                    'request_data': request.data,
                    'ip_address': self.get_client_ip(request),
                    'endpoint': 'offline_ballot_submission'
                },
                exc_info=True
            )
            
            return Response(
                {'error': 'Offline ballot submission failed.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def get_client_ip(self, request: Request) -> str:
        """Get client IP address from request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip


class BallotTokenStatsView(views.APIView):
    """
    Get ballot token statistics.
    
    GET /api/ballots/stats/
    
    Returns aggregated statistics about ballot token issuance,
    usage, and offline queue status. Only available to
    electoral committee and admin users.
    """
    
    permission_classes = [CanViewBallotTokenStats]
    
    def get(self, request: Request, *args, **kwargs) -> Response:
        """
        Get ballot token statistics.
        
        Args:
            request: HTTP request
            
        Returns:
            Response: Token statistics
        """
        # Get overall statistics
        token_stats = BallotToken.objects.aggregate(
            total_issued=Count('id'),
            active_tokens=Count('id', filter=Q(status=BallotTokenStatus.ISSUED)),
            used_tokens=Count('id', filter=Q(status=BallotTokenStatus.USED)),
            expired_tokens=Count('id', filter=Q(status=BallotTokenStatus.EXPIRED)),
            invalidated_tokens=Count('id', filter=Q(status=BallotTokenStatus.INVALIDATED))
        )
        
        # Get offline queue statistics
        queue_stats = OfflineBallotQueue.objects.aggregate(
            total_entries=Count('id'),
            pending_sync=Count('id', filter=Q(is_synced=False))
        )
        
        # Get statistics by election
        by_election = {}
        election_stats = BallotToken.objects.values(
            'election__id', 'election__title'
        ).annotate(
            total_tokens=Count('id'),
            active_tokens=Count('id', filter=Q(status=BallotTokenStatus.ISSUED)),
            used_tokens=Count('id', filter=Q(status=BallotTokenStatus.USED))
        )
        
        for stat in election_stats:
            by_election[str(stat['election__id'])] = {
                'election_title': stat['election__title'],
                'total_tokens': stat['total_tokens'],
                'active_tokens': stat['active_tokens'],
                'used_tokens': stat['used_tokens']
            }
        
        # Get statistics by status
        by_status = {
            BallotTokenStatus.ISSUED: token_stats['active_tokens'],
            BallotTokenStatus.USED: token_stats['used_tokens'],
            BallotTokenStatus.EXPIRED: token_stats['expired_tokens'],
            BallotTokenStatus.INVALIDATED: token_stats['invalidated_tokens']
        }
        
        stats_data = {
            'total_tokens_issued': token_stats['total_issued'],
            'active_tokens': token_stats['active_tokens'],
            'used_tokens': token_stats['used_tokens'],
            'expired_tokens': token_stats['expired_tokens'],
            'invalidated_tokens': token_stats['invalidated_tokens'],
            'offline_queue_entries': queue_stats['total_entries'],
            'pending_sync_entries': queue_stats['pending_sync'],
            'by_election': by_election,
            'by_status': by_status
        }
        
        serializer = BallotTokenStatsSerializer(stats_data)
        
        logger.info(
            'Ballot token statistics accessed',
            extra={
                'user_id': request.user.id,
                'user_role': request.user.role,
                'ip_address': self.get_client_ip(request),
                'endpoint': 'ballot_token_stats'
            }
        )
        
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    def get_client_ip(self, request: Request) -> str:
        """Get client IP address from request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip


class BallotTokenUsageLogView(generics.ListAPIView):
    """
    List ballot token usage logs.
    
    GET /api/ballots/usage-logs/
    
    Returns audit trail of ballot token operations.
    Only available to electoral committee and admin users.
    """
    
    serializer_class = BallotTokenUsageLogSerializer
    permission_classes = [CanManageBallotTokens]
    
    def get_queryset(self) -> QuerySet[BallotTokenUsageLog]:
        """Get usage logs with filtering options."""
        queryset = BallotTokenUsageLog.objects.select_related(
            'ballot_token__user', 'ballot_token__election'
        ).order_by('-timestamp')
        
        # Filter by token if specified
        token_id = self.request.query_params.get('token_id')
        if token_id:
            queryset = queryset.filter(ballot_token__id=token_id)
        
        # Filter by election if specified
        election_id = self.request.query_params.get('election_id')
        if election_id:
            queryset = queryset.filter(ballot_token__election__id=election_id)
        
        # Filter by action if specified
        action = self.request.query_params.get('action')
        if action:
            queryset = queryset.filter(action=action)
        
        # Filter by date range if specified
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        
        if start_date:
            queryset = queryset.filter(timestamp__gte=start_date)
        if end_date:
            queryset = queryset.filter(timestamp__lte=end_date)
        
        return queryset