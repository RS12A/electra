"""
Election views for electra_server.

This module contains DRF views for election management with proper
role-based access control and security features.
"""
import logging
from typing import Any, Dict
from django.contrib.auth import get_user_model
from django.db.models import QuerySet
from django.utils import timezone
from rest_framework import generics, status, permissions
from rest_framework.decorators import action
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet

from .models import Election, ElectionStatus
from .permissions import (
    CanManageElections,
    CanViewElections,
    ElectionManagementPermission,
    IsElectionCreatorOrManager
)
from .serializers import (
    ElectionListSerializer,
    ElectionDetailSerializer,
    ElectionCreateSerializer,
    ElectionUpdateSerializer,
    ElectionStatusSerializer
)

User = get_user_model()
logger = logging.getLogger('electra_server')


class ElectionListView(generics.ListAPIView):
    """
    List elections.
    
    GET /api/elections/
    
    Returns different elections based on user role:
    - Election managers: All elections (including drafts)
    - Regular users: Only non-draft elections
    """
    
    serializer_class = ElectionListSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self) -> QuerySet[Election]:
        """Get elections based on user role."""
        user = self.request.user
        
        # Election managers can see all elections
        if user.role in ['admin', 'electoral_committee']:
            return Election.objects.select_related('created_by').all()
        
        # Regular users can only see non-draft elections
        return Election.objects.select_related('created_by').exclude(
            status=ElectionStatus.DRAFT
        )
    
    def list(self, request: Request, *args, **kwargs) -> Response:
        """List elections with logging."""
        logger.info(
            'User accessed elections list',
            extra={
                'user_id': request.user.id,
                'user_role': request.user.role,
                'endpoint': 'elections_list'
            }
        )
        return super().list(request, *args, **kwargs)


class ElectionDetailView(generics.RetrieveAPIView):
    """
    Retrieve election details.
    
    GET /api/elections/<id>/
    """
    
    serializer_class = ElectionDetailSerializer
    permission_classes = [ElectionManagementPermission]
    lookup_field = 'id'
    
    def get_queryset(self) -> QuerySet[Election]:
        """Get elections based on user permissions."""
        return Election.objects.select_related('created_by').all()


class ElectionCreateView(generics.CreateAPIView):
    """
    Create new election.
    
    POST /api/elections/create/
    """
    
    serializer_class = ElectionCreateSerializer
    permission_classes = [CanManageElections]
    
    def perform_create(self, serializer) -> None:
        """Create election with current user as creator."""
        election = serializer.save()
        
        logger.info(
            'New election created',
            extra={
                'user_id': self.request.user.id,
                'user_role': self.request.user.role,
                'election_id': election.id,
                'election_title': election.title,
                'endpoint': 'election_create'
            }
        )
    
    def create(self, request, *args, **kwargs):
        """Create election and return detailed response."""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        # Return detailed election data instead of just create serializer data
        election = serializer.instance
        response_serializer = ElectionDetailSerializer(election)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class ElectionUpdateView(generics.UpdateAPIView):
    """
    Update existing election.
    
    PUT/PATCH /api/elections/<id>/update/
    """
    
    serializer_class = ElectionUpdateSerializer
    permission_classes = [CanManageElections]
    lookup_field = 'id'
    
    def get_queryset(self) -> QuerySet[Election]:
        """Get elections that can be updated."""
        return Election.objects.all()
    
    def perform_update(self, serializer) -> None:
        """Update election with logging."""
        election = serializer.save()
        
        logger.info(
            'Election updated',
            extra={
                'user_id': self.request.user.id,
                'user_role': self.request.user.role,
                'election_id': election.id,
                'election_title': election.title,
                'endpoint': 'election_update'
            }
        )


class ElectionDeleteView(generics.DestroyAPIView):
    """
    Delete election.
    
    DELETE /api/elections/<id>/delete/
    """
    
    permission_classes = [CanManageElections]
    lookup_field = 'id'
    
    def get_queryset(self) -> QuerySet[Election]:
        """Get elections that can be deleted."""
        # Only allow deleting draft elections
        return Election.objects.filter(status=ElectionStatus.DRAFT)
    
    def perform_destroy(self, instance: Election) -> None:
        """Delete election with validation and logging."""
        if instance.status != ElectionStatus.DRAFT:
            raise ValueError("Only draft elections can be deleted")
        
        logger.warning(
            'Election deleted',
            extra={
                'user_id': self.request.user.id,
                'user_role': self.request.user.role,
                'election_id': instance.id,
                'election_title': instance.title,
                'endpoint': 'election_delete'
            }
        )
        
        super().perform_destroy(instance)


class ElectionStatusView(generics.UpdateAPIView):
    """
    Update election status (activate, cancel, complete).
    
    PATCH /api/elections/<id>/status/
    """
    
    serializer_class = ElectionStatusSerializer
    permission_classes = [CanManageElections]
    lookup_field = 'id'
    
    def get_queryset(self) -> QuerySet[Election]:
        """Get all elections for status updates."""
        return Election.objects.all()
    
    def update(self, request: Request, *args, **kwargs) -> Response:
        """Update election status based on action."""
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data)
        serializer.is_valid(raise_exception=True)
        
        action = serializer.validated_data['action']
        old_status = instance.status
        
        try:
            if action == 'activate':
                instance.activate()
            elif action == 'cancel':
                instance.cancel()
            elif action == 'complete':
                instance.complete()
            
            logger.info(
                f'Election status changed via {action} action',
                extra={
                    'user_id': request.user.id,
                    'user_role': request.user.role,
                    'election_id': instance.id,
                    'election_title': instance.title,
                    'old_status': old_status,
                    'new_status': instance.status,
                    'action': action,
                    'endpoint': 'election_status'
                }
            )
            
            # Return updated election data
            response_serializer = ElectionDetailSerializer(instance)
            return Response(response_serializer.data)
            
        except ValueError as e:
            logger.warning(
                f'Failed to change election status via {action} action',
                extra={
                    'user_id': request.user.id,
                    'user_role': request.user.role,
                    'election_id': instance.id,
                    'election_title': instance.title,
                    'error': str(e),
                    'action': action,
                    'endpoint': 'election_status'
                }
            )
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )


class ElectionViewSet(ModelViewSet):
    """
    Complete CRUD ViewSet for elections.
    
    This provides all the standard REST operations:
    - GET /api/elections/ - List elections
    - POST /api/elections/ - Create election
    - GET /api/elections/<id>/ - Retrieve election
    - PUT/PATCH /api/elections/<id>/ - Update election
    - DELETE /api/elections/<id>/ - Delete election
    """
    
    permission_classes = [ElectionManagementPermission]
    lookup_field = 'id'
    
    def get_queryset(self) -> QuerySet[Election]:
        """Get elections based on user role and action."""
        user = self.request.user
        
        # For delete actions, only allow draft elections
        if self.action == 'destroy':
            return Election.objects.filter(status=ElectionStatus.DRAFT)
        
        # Election managers can see all elections
        if user.role in ['admin', 'electoral_committee']:
            return Election.objects.select_related('created_by').all()
        
        # Regular users can only see non-draft elections
        return Election.objects.select_related('created_by').exclude(
            status=ElectionStatus.DRAFT
        )
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action."""
        if self.action == 'list':
            return ElectionListSerializer
        elif self.action == 'create':
            return ElectionCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return ElectionUpdateSerializer
        else:
            return ElectionDetailSerializer
    
    def perform_create(self, serializer) -> None:
        """Create election with current user as creator."""
        election = serializer.save()
        
        logger.info(
            'Election created via ViewSet',
            extra={
                'user_id': self.request.user.id,
                'user_role': self.request.user.role,
                'election_id': election.id,
                'election_title': election.title
            }
        )
    
    def perform_update(self, serializer) -> None:
        """Update election with logging."""
        election = serializer.save()
        
        logger.info(
            'Election updated via ViewSet',
            extra={
                'user_id': self.request.user.id,
                'user_role': self.request.user.role,
                'election_id': election.id,
                'election_title': election.title
            }
        )
    
    def perform_destroy(self, instance: Election) -> None:
        """Delete election with validation."""
        if instance.status != ElectionStatus.DRAFT:
            raise ValueError("Only draft elections can be deleted")
        
        logger.warning(
            'Election deleted via ViewSet',
            extra={
                'user_id': self.request.user.id,
                'user_role': self.request.user.role,
                'election_id': instance.id,
                'election_title': instance.title
            }
        )
        
        super().perform_destroy(instance)
    
    @action(detail=True, methods=['patch'], permission_classes=[CanManageElections])
    def status(self, request: Request, id: str = None) -> Response:
        """
        Change election status.
        
        PATCH /api/elections/<id>/status/
        """
        election = self.get_object()
        serializer = ElectionStatusSerializer(election, data=request.data)
        serializer.is_valid(raise_exception=True)
        
        action_name = serializer.validated_data['action']
        old_status = election.status
        
        try:
            if action_name == 'activate':
                election.activate()
            elif action_name == 'cancel':
                election.cancel()
            elif action_name == 'complete':
                election.complete()
            
            logger.info(
                f'Election status changed via ViewSet {action_name} action',
                extra={
                    'user_id': request.user.id,
                    'user_role': request.user.role,
                    'election_id': election.id,
                    'election_title': election.title,
                    'old_status': old_status,
                    'new_status': election.status,
                    'action': action_name
                }
            )
            
            # Return updated election data
            response_serializer = self.get_serializer(election)
            return Response(response_serializer.data)
            
        except ValueError as e:
            logger.warning(
                f'Failed to change election status via ViewSet {action_name} action',
                extra={
                    'user_id': request.user.id,
                    'user_role': request.user.role,
                    'election_id': election.id,
                    'election_title': election.title,
                    'error': str(e),
                    'action': action_name
                }
            )
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )