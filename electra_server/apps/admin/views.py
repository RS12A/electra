"""
Admin API views for the electra voting system.

This module contains DRF views for admin CRUD operations on users, elections,
candidates, and ballot tokens with comprehensive role-based access control,
rate limiting, and audit logging.
"""
import logging
from typing import Any, Dict, Type
from django.contrib.auth import get_user_model
from django.db.models import QuerySet, Q
from django.http import Http404
from django.utils import timezone
from rest_framework import generics, status, permissions
from rest_framework.decorators import action
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet
from rest_framework.throttling import UserRateThrottle

from electra_server.apps.auth.models import UserRole
from electra_server.apps.elections.models import Election, ElectionStatus
from electra_server.apps.ballots.models import BallotToken, BallotTokenStatus
from electra_server.apps.audit.utils import log_admin_action
from electra_server.apps.audit.models import AuditActionType

from .permissions import (
    AdminPermission,
    UserManagementPermission,
    ElectionManagementPermission,
    BallotTokenManagementPermission
)
from .serializers import (
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
logger = logging.getLogger('electra_server.admin')


class AdminRateThrottle(UserRateThrottle):
    """Custom rate throttle for admin APIs."""
    scope = 'admin_api'
    rate = '100/hour'  # Conservative rate limit for admin operations


class SensitiveAdminRateThrottle(UserRateThrottle):
    """More restrictive rate throttle for sensitive admin operations."""
    scope = 'admin_api_sensitive'
    rate = '30/hour'  # Very restrictive for sensitive operations


class AdminUserViewSet(ModelViewSet):
    """
    ViewSet for admin user management operations.
    
    Provides CRUD operations for users with proper role-based access control,
    comprehensive audit logging, and rate limiting for security.
    """
    
    queryset = User.objects.all().order_by('-date_joined')
    permission_classes = [UserManagementPermission]
    throttle_classes = [AdminRateThrottle]
    lookup_field = 'id'
    
    def get_serializer_class(self) -> Type:
        """
        Return appropriate serializer based on action.
        
        Returns:
            Type: Serializer class
        """
        if self.action == 'list':
            return AdminUserListSerializer
        elif self.action == 'retrieve':
            return AdminUserDetailSerializer
        elif self.action == 'create':
            return AdminUserCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return AdminUserUpdateSerializer
        return AdminUserListSerializer
    
    def get_queryset(self) -> QuerySet[User]:
        """
        Get users based on filters and permissions.
        
        Returns:
            QuerySet[User]: Filtered user queryset
        """
        queryset = super().get_queryset()
        
        # Filter by role if provided
        role = self.request.query_params.get('role')
        if role:
            queryset = queryset.filter(role=role)
        
        # Filter by active status
        is_active = self.request.query_params.get('is_active')
        if is_active is not None:
            is_active = is_active.lower() in ['true', '1', 'yes']
            queryset = queryset.filter(is_active=is_active)
        
        # Search functionality
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(email__icontains=search) |
                Q(full_name__icontains=search) |
                Q(matric_number__icontains=search) |
                Q(staff_id__icontains=search)
            )
        
        return queryset
    
    def perform_create(self, serializer) -> None:
        """
        Create user with audit logging.
        
        Args:
            serializer: User creation serializer
        """
        user = serializer.save()
        
        # Log user creation
        log_admin_action(
            admin_user=self.request.user,
            action_type=AuditActionType.ADMIN_ACTION,
            description=f'User created via admin API: {user.email}',
            target_user=user,
            metadata={
                'created_user_id': str(user.id),
                'created_user_email': user.email,
                'created_user_role': user.role,
                'admin_user_role': self.request.user.role,
                'endpoint': self.request.path,
                'method': self.request.method
            }
        )
        
        logger.info(
            f'User created via admin API: {user.email}',
            extra={
                'admin_user': self.request.user.email,
                'created_user': user.email,
                'created_user_role': user.role
            }
        )
    
    def perform_update(self, serializer) -> None:
        """
        Update user with audit logging.
        
        Args:
            serializer: User update serializer
        """
        user = serializer.save()
        
        logger.info(
            f'User updated via admin API: {user.email}',
            extra={
                'admin_user': self.request.user.email,
                'updated_user': user.email
            }
        )
    
    def perform_destroy(self, instance: User) -> None:
        """
        Delete user with audit logging and validation.
        
        Args:
            instance: User instance to delete
        """
        # Prevent deletion of own account
        if instance.id == self.request.user.id:
            from rest_framework.exceptions import ValidationError
            raise ValidationError('Cannot delete your own account.')
        
        # Prevent deletion of other admin users unless user is admin
        if instance.role == UserRole.ADMIN and self.request.user.role != UserRole.ADMIN:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('Only admins can delete admin users.')
        
        # Log user deletion before deleting
        log_admin_action(
            admin_user=self.request.user,
            action_type=AuditActionType.ADMIN_ACTION,
            description=f'User deleted via admin API: {instance.email}',
            target_user=instance,
            metadata={
                'deleted_user_id': str(instance.id),
                'deleted_user_email': instance.email,
                'deleted_user_role': instance.role,
                'admin_user_role': self.request.user.role,
                'endpoint': self.request.path,
                'method': self.request.method
            }
        )
        
        logger.warning(
            f'User deleted via admin API: {instance.email}',
            extra={
                'admin_user': self.request.user.email,
                'deleted_user': instance.email,
                'deleted_user_role': instance.role
            }
        )
        
        super().perform_destroy(instance)
    
    @action(detail=True, methods=['post'], throttle_classes=[SensitiveAdminRateThrottle])
    def activate(self, request: Request, id: str = None) -> Response:
        """
        Activate a user account.
        
        Args:
            request: HTTP request
            id: User ID
            
        Returns:
            Response: API response
        """
        user = self.get_object()
        
        if user.is_active:
            return Response(
                {'detail': 'User is already active.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user.is_active = True
        user.save(update_fields=['is_active'])
        
        # Log activation
        log_admin_action(
            admin_user=request.user,
            action_type=AuditActionType.ADMIN_ACTION,
            description=f'User activated: {user.email}',
            target_user=user,
            metadata={
                'activated_user_id': str(user.id),
                'activated_user_email': user.email,
                'admin_user_role': request.user.role
            }
        )
        
        return Response({'detail': 'User activated successfully.'})
    
    @action(detail=True, methods=['post'], throttle_classes=[SensitiveAdminRateThrottle])
    def deactivate(self, request: Request, id: str = None) -> Response:
        """
        Deactivate a user account.
        
        Args:
            request: HTTP request
            id: User ID
            
        Returns:
            Response: API response
        """
        user = self.get_object()
        
        # Prevent deactivation of own account
        if user.id == request.user.id:
            return Response(
                {'detail': 'Cannot deactivate your own account.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if not user.is_active:
            return Response(
                {'detail': 'User is already inactive.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user.is_active = False
        user.save(update_fields=['is_active'])
        
        # Log deactivation
        log_admin_action(
            admin_user=request.user,
            action_type=AuditActionType.ADMIN_ACTION,
            description=f'User deactivated: {user.email}',
            target_user=user,
            metadata={
                'deactivated_user_id': str(user.id),
                'deactivated_user_email': user.email,
                'admin_user_role': request.user.role
            }
        )
        
        return Response({'detail': 'User deactivated successfully.'})


class AdminElectionViewSet(ModelViewSet):
    """
    ViewSet for admin election management operations.
    
    Provides CRUD operations for elections with proper access control,
    election lifecycle management, and comprehensive audit logging.
    """
    
    queryset = Election.objects.all().select_related('created_by').order_by('-created_at')
    permission_classes = [ElectionManagementPermission]
    throttle_classes = [AdminRateThrottle]
    lookup_field = 'id'
    
    def get_serializer_class(self) -> Type:
        """
        Return appropriate serializer based on action.
        
        Returns:
            Type: Serializer class
        """
        if self.action == 'list':
            return AdminElectionListSerializer
        elif self.action == 'retrieve':
            return AdminElectionDetailSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return AdminElectionCreateUpdateSerializer
        return AdminElectionListSerializer
    
    def get_queryset(self) -> QuerySet[Election]:
        """
        Get elections based on filters.
        
        Returns:
            QuerySet[Election]: Filtered election queryset
        """
        queryset = super().get_queryset()
        
        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        # Filter by creator
        created_by = self.request.query_params.get('created_by')
        if created_by:
            queryset = queryset.filter(created_by_id=created_by)
        
        # Search functionality
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) |
                Q(description__icontains=search)
            )
        
        return queryset
    
    def perform_destroy(self, instance: Election) -> None:
        """
        Delete election with validation and audit logging.
        
        Args:
            instance: Election instance to delete
        """
        # Prevent deletion of active elections
        if instance.status == ElectionStatus.ACTIVE:
            from rest_framework.exceptions import ValidationError
            raise ValidationError('Cannot delete an active election.')
        
        # Log election deletion before deleting
        log_admin_action(
            admin_user=self.request.user,
            action_type=AuditActionType.ADMIN_ACTION,
            description=f'Election deleted via admin API: {instance.title}',
            target_election=instance,
            metadata={
                'deleted_election_id': str(instance.id),
                'deleted_election_title': instance.title,
                'deleted_election_status': instance.status,
                'admin_user_role': self.request.user.role
            }
        )
        
        logger.warning(
            f'Election deleted via admin API: {instance.title}',
            extra={
                'admin_user': self.request.user.email,
                'deleted_election': instance.title
            }
        )
        
        super().perform_destroy(instance)
    
    @action(detail=True, methods=['post'], throttle_classes=[SensitiveAdminRateThrottle])
    def activate(self, request: Request, id: str = None) -> Response:
        """
        Activate an election.
        
        Args:
            request: HTTP request
            id: Election ID
            
        Returns:
            Response: API response
        """
        election = self.get_object()
        
        try:
            election.activate()
            
            # Log activation
            log_admin_action(
                admin_user=request.user,
                action_type=AuditActionType.ELECTION_ACTIVATED,
                description=f'Election activated: {election.title}',
                target_election=election,
                metadata={
                    'election_id': str(election.id),
                    'election_title': election.title,
                    'admin_user_role': request.user.role,
                    'start_time': election.start_time.isoformat(),
                    'end_time': election.end_time.isoformat()
                }
            )
            
            return Response({'detail': 'Election activated successfully.'})
        
        except Exception as e:
            return Response(
                {'detail': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
    
    @action(detail=True, methods=['post'], throttle_classes=[SensitiveAdminRateThrottle])
    def close(self, request: Request, id: str = None) -> Response:
        """
        Close (complete) an election.
        
        Args:
            request: HTTP request
            id: Election ID
            
        Returns:
            Response: API response
        """
        election = self.get_object()
        
        try:
            election.complete()
            
            # Log closure
            log_admin_action(
                admin_user=request.user,
                action_type=AuditActionType.ELECTION_COMPLETED,
                description=f'Election closed: {election.title}',
                target_election=election,
                metadata={
                    'election_id': str(election.id),
                    'election_title': election.title,
                    'admin_user_role': request.user.role,
                    'closed_at': timezone.now().isoformat()
                }
            )
            
            return Response({'detail': 'Election closed successfully.'})
        
        except Exception as e:
            return Response(
                {'detail': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
    
    @action(detail=True, methods=['post'], throttle_classes=[SensitiveAdminRateThrottle])
    def cancel(self, request: Request, id: str = None) -> Response:
        """
        Cancel an election.
        
        Args:
            request: HTTP request
            id: Election ID
            
        Returns:
            Response: API response
        """
        election = self.get_object()
        
        try:
            election.cancel()
            
            # Log cancellation
            log_admin_action(
                admin_user=request.user,
                action_type=AuditActionType.ELECTION_CANCELLED,
                description=f'Election cancelled: {election.title}',
                target_election=election,
                metadata={
                    'election_id': str(election.id),
                    'election_title': election.title,
                    'admin_user_role': request.user.role,
                    'cancelled_at': timezone.now().isoformat()
                }
            )
            
            return Response({'detail': 'Election cancelled successfully.'})
        
        except Exception as e:
            return Response(
                {'detail': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )


class AdminBallotTokenViewSet(ModelViewSet):
    """
    ViewSet for admin ballot token management operations.
    
    Provides view and revocation operations for ballot tokens with
    comprehensive security and audit logging.
    """
    
    queryset = BallotToken.objects.all().select_related('user', 'election').order_by('-issued_at')
    permission_classes = [BallotTokenManagementPermission]
    throttle_classes = [AdminRateThrottle]
    lookup_field = 'id'
    http_method_names = ['get', 'post', 'delete']  # No PUT/PATCH for security
    
    def get_serializer_class(self) -> Type:
        """
        Return appropriate serializer based on action.
        
        Returns:
            Type: Serializer class
        """
        if self.action == 'list':
            return AdminBallotTokenListSerializer
        elif self.action == 'retrieve':
            return AdminBallotTokenDetailSerializer
        elif self.action == 'revoke':
            return AdminBallotTokenRevokeSerializer
        return AdminBallotTokenListSerializer
    
    def get_queryset(self) -> QuerySet[BallotToken]:
        """
        Get ballot tokens based on filters.
        
        Returns:
            QuerySet[BallotToken]: Filtered ballot token queryset
        """
        queryset = super().get_queryset()
        
        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        # Filter by election
        election_id = self.request.query_params.get('election')
        if election_id:
            queryset = queryset.filter(election_id=election_id)
        
        # Filter by user
        user_id = self.request.query_params.get('user')
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        
        # Filter by valid status
        is_valid = self.request.query_params.get('is_valid')
        if is_valid is not None:
            is_valid = is_valid.lower() in ['true', '1', 'yes']
            if is_valid:
                queryset = queryset.filter(
                    status=BallotTokenStatus.ISSUED,
                    expires_at__gt=timezone.now()
                )
            else:
                queryset = queryset.exclude(
                    status=BallotTokenStatus.ISSUED,
                    expires_at__gt=timezone.now()
                )
        
        # Search functionality
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(user__email__icontains=search) |
                Q(user__full_name__icontains=search) |
                Q(election__title__icontains=search) |
                Q(token_uuid__icontains=search)
            )
        
        return queryset
    
    def create(self, request: Request, *args, **kwargs) -> Response:
        """
        Prevent creation of ballot tokens through admin API.
        
        Ballot tokens should only be created through the proper ballot API.
        """
        return Response(
            {'detail': 'Ballot tokens cannot be created through admin API. Use the ballot API instead.'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    def update(self, request: Request, *args, **kwargs) -> Response:
        """
        Prevent update of ballot tokens through admin API.
        
        Ballot tokens should not be modified after creation for security.
        """
        return Response(
            {'detail': 'Ballot tokens cannot be modified through admin API.'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    def destroy(self, request: Request, *args, **kwargs) -> Response:
        """
        Prevent deletion of ballot tokens through admin API.
        
        Ballot tokens should not be deleted for audit trail integrity.
        """
        return Response(
            {'detail': 'Ballot tokens cannot be deleted. Use revoke action instead.'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    @action(detail=True, methods=['post'], throttle_classes=[SensitiveAdminRateThrottle])
    def revoke(self, request: Request, id: str = None) -> Response:
        """
        Revoke a ballot token.
        
        Args:
            request: HTTP request
            id: Ballot token ID
            
        Returns:
            Response: API response
        """
        ballot_token = self.get_object()
        
        serializer = AdminBallotTokenRevokeSerializer(
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        
        try:
            revoked_token = serializer.save(ballot_token)
            
            logger.warning(
                f'Ballot token revoked via admin API: {revoked_token.token_uuid}',
                extra={
                    'admin_user': request.user.email,
                    'token_id': str(revoked_token.id),
                    'user': revoked_token.user.email,
                    'election': revoked_token.election.title
                }
            )
            
            return Response({
                'detail': 'Ballot token revoked successfully.',
                'token_id': str(revoked_token.id),
                'revoked_at': revoked_token.invalidated_at.isoformat() if revoked_token.invalidated_at else None
            })
        
        except Exception as e:
            return Response(
                {'detail': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )


class AdminCandidateListView(generics.ListAPIView):
    """
    View for listing candidates in admin APIs.
    
    Lists users with candidate role, providing admin capabilities
    to manage candidate information and election participation.
    """
    
    permission_classes = [AdminPermission]
    throttle_classes = [AdminRateThrottle]
    serializer_class = AdminUserListSerializer
    
    def get_queryset(self) -> QuerySet[User]:
        """Get queryset of users with candidate role."""
        return User.objects.filter(role=UserRole.CANDIDATE).select_related()
    
    def list(self, request: Request, *args, **kwargs) -> Response:
        """
        List candidates for elections.
        
        Returns paginated list of users with candidate role.
        """
        queryset = self.get_queryset()
        
        # Apply search filter if provided
        search = request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(full_name__icontains=search) |
                Q(email__icontains=search) |
                Q(matric_number__icontains=search)
            )
        
        # Apply pagination
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            result = self.get_paginated_response(serializer.data)
        else:
            serializer = self.get_serializer(queryset, many=True)
            result = Response(serializer.data)
        
        # Log the action
        log_admin_action(
            user=request.user,
            action=AuditActionType.LIST_CANDIDATES,
            target_model='User',
            details={
                'candidate_count': queryset.count(),
                'search_query': search,
            }
        )
        
        return result


class AdminDashboardView(generics.GenericAPIView):
    """
    View for admin dashboard statistics and overview.
    
    Provides key metrics and statistics for administrative oversight.
    """
    
    permission_classes = [AdminPermission]
    throttle_classes = [AdminRateThrottle]
    
    def get(self, request: Request) -> Response:
        """
        Get admin dashboard statistics.
        
        Args:
            request: HTTP request
            
        Returns:
            Response: Dashboard statistics
        """
        try:
            # User statistics
            total_users = User.objects.count()
            active_users = User.objects.filter(is_active=True).count()
            users_by_role = {}
            for role in UserRole:
                users_by_role[role.value] = User.objects.filter(role=role.value).count()
            
            # Election statistics
            total_elections = Election.objects.count()
            elections_by_status = {}
            for status_choice in ElectionStatus:
                elections_by_status[status_choice.value] = Election.objects.filter(status=status_choice.value).count()
            
            # Ballot token statistics
            total_tokens = BallotToken.objects.count()
            tokens_by_status = {}
            for status_choice in BallotTokenStatus:
                tokens_by_status[status_choice.value] = BallotToken.objects.filter(status=status_choice.value).count()
            
            # Recent activity counts
            recent_users = User.objects.filter(
                date_joined__gte=timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
            ).count()
            recent_elections = Election.objects.filter(
                created_at__gte=timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
            ).count()
            recent_tokens = BallotToken.objects.filter(
                issued_at__gte=timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
            ).count()
            
            dashboard_data = {
                'users': {
                    'total': total_users,
                    'active': active_users,
                    'inactive': total_users - active_users,
                    'by_role': users_by_role,
                    'created_today': recent_users
                },
                'elections': {
                    'total': total_elections,
                    'by_status': elections_by_status,
                    'created_today': recent_elections
                },
                'ballot_tokens': {
                    'total': total_tokens,
                    'by_status': tokens_by_status,
                    'issued_today': recent_tokens
                },
                'system': {
                    'current_time': timezone.now().isoformat(),
                    'admin_user': {
                        'email': request.user.email,
                        'role': request.user.role
                    }
                }
            }
            
            # Log dashboard access
            log_admin_action(
                admin_user=request.user,
                action_type=AuditActionType.ADMIN_ACTION,
                description='Admin dashboard accessed',
                metadata={
                    'endpoint': request.path,
                    'admin_user_role': request.user.role
                }
            )
            
            return Response(dashboard_data)
        
        except Exception as e:
            logger.error(
                f'Error generating admin dashboard: {str(e)}',
                extra={'admin_user': request.user.email},
                exc_info=True
            )
            
            return Response(
                {'detail': 'Error generating dashboard statistics.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )