"""
Ballot permissions for electra_server.

This module contains custom permissions for ballot token operations
based on user roles and election state.
"""
from typing import Any

from django.contrib.auth import get_user_model
from rest_framework import permissions
from rest_framework.request import Request
from rest_framework.views import View

from electra_server.apps.auth.models import UserRole
from electra_server.apps.elections.models import Election
from .models import BallotToken

User = get_user_model()


class CanRequestBallotTokens(permissions.BasePermission):
    """
    Permission that checks if user can request ballot tokens.
    
    Only eligible voters (students, staff, candidates) can request tokens.
    Electoral committee members and admins cannot vote to maintain neutrality.
    """
    
    voting_roles = [UserRole.STUDENT, UserRole.STAFF, UserRole.CANDIDATE]
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if user can request ballot tokens.
        
        Args:
            request: HTTP request
            view: View being accessed
            
        Returns:
            bool: Whether user can request tokens
        """
        if not request.user or not request.user.is_authenticated:
            return False
        
        if not request.user.is_active:
            return False
        
        return request.user.role in self.voting_roles


class CanValidateBallotTokens(permissions.BasePermission):
    """
    Permission that checks if user can validate ballot tokens.
    
    Validation is typically needed for voting applications or
    election management systems.
    """
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if user can validate ballot tokens.
        
        Args:
            request: HTTP request
            view: View being accessed
            
        Returns:
            bool: Whether user can validate tokens
        """
        if not request.user or not request.user.is_authenticated:
            return False
        
        if not request.user.is_active:
            return False
        
        # All authenticated users can validate tokens for voting
        return True


class CanManageBallotTokens(permissions.BasePermission):
    """
    Permission that checks if user can manage ballot tokens.
    
    Only electoral committee members and admins can manage tokens
    for security and audit purposes.
    """
    
    management_roles = [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if user can manage ballot tokens.
        
        Args:
            request: HTTP request
            view: View being accessed
            
        Returns:
            bool: Whether user can manage tokens
        """
        if not request.user or not request.user.is_authenticated:
            return False
        
        if not request.user.is_active:
            return False
        
        return request.user.role in self.management_roles


class CanViewBallotTokenStats(permissions.BasePermission):
    """
    Permission that checks if user can view ballot token statistics.
    
    Electoral committee members and admins can view aggregated statistics
    for election management and monitoring.
    """
    
    stats_roles = [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if user can view ballot token statistics.
        
        Args:
            request: HTTP request
            view: View being accessed
            
        Returns:
            bool: Whether user can view statistics
        """
        if not request.user or not request.user.is_authenticated:
            return False
        
        if not request.user.is_active:
            return False
        
        return request.user.role in self.stats_roles


class IsBallotTokenOwner(permissions.BasePermission):
    """
    Permission that checks if user owns the ballot token.
    
    Users can only access their own ballot tokens.
    """
    
    def has_object_permission(self, request: Request, view: View, obj: BallotToken) -> bool:
        """
        Check if user owns the ballot token.
        
        Args:
            request: HTTP request
            view: View being accessed
            obj: BallotToken object
            
        Returns:
            bool: Whether user owns the token
        """
        if not request.user or not request.user.is_authenticated:
            return False
        
        return obj.user == request.user


class CanAccessOfflineQueue(permissions.BasePermission):
    """
    Permission that checks if user can access offline ballot queue.
    
    Users can access their own offline queue entries, while
    electoral committee and admins can manage the queue.
    """
    
    management_roles = [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if user can access offline queue.
        
        Args:
            request: HTTP request
            view: View being accessed
            
        Returns:
            bool: Whether user can access offline queue
        """
        if not request.user or not request.user.is_authenticated:
            return False
        
        if not request.user.is_active:
            return False
        
        return True
    
    def has_object_permission(self, request: Request, view: View, obj: Any) -> bool:
        """
        Check if user can access specific offline queue entry.
        
        Args:
            request: HTTP request
            view: View being accessed
            obj: Queue entry object
            
        Returns:
            bool: Whether user can access the entry
        """
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Management roles can access all entries
        if request.user.role in self.management_roles:
            return True
        
        # Users can only access their own entries
        return obj.ballot_token.user == request.user


class ElectionVotingPermission(permissions.BasePermission):
    """
    Permission that validates election voting eligibility.
    
    Checks if user is eligible to vote in the specified election
    and if the election is currently accepting votes.
    """
    
    voting_roles = [UserRole.STUDENT, UserRole.STAFF, UserRole.CANDIDATE]
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if user can participate in voting.
        
        Args:
            request: HTTP request
            view: View being accessed
            
        Returns:
            bool: Whether user can vote
        """
        if not request.user or not request.user.is_authenticated:
            return False
        
        if not request.user.is_active:
            return False
        
        return request.user.role in self.voting_roles
    
    def has_object_permission(self, request: Request, view: View, obj: Election) -> bool:
        """
        Check if user can vote in specific election.
        
        Args:
            request: HTTP request
            view: View being accessed
            obj: Election object
            
        Returns:
            bool: Whether user can vote in the election
        """
        if not self.has_permission(request, view):
            return False
        
        # Check if election allows voting
        if not obj.can_vote:
            return False
        
        return True


def can_request_ballot_token(user, election) -> bool:
    """
    Utility function to check if user can request a ballot token.
    
    Args:
        user: User instance
        election: Election instance
        
    Returns:
        bool: Whether user can request a token
    """
    if not user or not user.is_authenticated or not user.is_active:
        return False
    
    if user.role not in [UserRole.STUDENT, UserRole.STAFF, UserRole.CANDIDATE]:
        return False
    
    if not election or not election.can_vote:
        return False
    
    # Check if user already has a valid token
    existing_token = BallotToken.objects.filter(
        user=user,
        election=election,
        status='issued'
    ).first()
    
    if existing_token and existing_token.is_valid:
        return False
    
    return True


def can_validate_ballot_token(user) -> bool:
    """
    Utility function to check if user can validate ballot tokens.
    
    Args:
        user: User instance
        
    Returns:
        bool: Whether user can validate tokens
    """
    if not user or not user.is_authenticated or not user.is_active:
        return False
    
    return True


def can_manage_ballot_tokens(user) -> bool:
    """
    Utility function to check if user can manage ballot tokens.
    
    Args:
        user: User instance
        
    Returns:
        bool: Whether user can manage tokens
    """
    if not user or not user.is_authenticated or not user.is_active:
        return False
    
    return user.role in [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]


def can_view_ballot_stats(user) -> bool:
    """
    Utility function to check if user can view ballot statistics.
    
    Args:
        user: User instance
        
    Returns:
        bool: Whether user can view statistics
    """
    if not user or not user.is_authenticated or not user.is_active:
        return False
    
    return user.role in [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]