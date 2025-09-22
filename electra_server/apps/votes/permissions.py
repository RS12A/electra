"""
Votes permissions for electra_server.

This module contains permission classes for vote casting, verification,
and management in the electra voting system.
"""
from django.contrib.auth import get_user_model
from rest_framework import permissions
from rest_framework.request import Request
from rest_framework.views import View

from electra_server.apps.auth.models import UserRole
from electra_server.apps.elections.models import Election
from .models import Vote, OfflineVoteQueue

User = get_user_model()


class CanCastVotes(permissions.BasePermission):
    """
    Permission that allows users to cast votes.

    Users must be authenticated, active, and have a valid role
    for voting (student, staff, candidate).
    """

    voting_roles = [UserRole.STUDENT, UserRole.STAFF, UserRole.CANDIDATE]

    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if user can cast votes.

        Args:
            request: HTTP request
            view: View being accessed

        Returns:
            bool: Whether user can cast votes
        """
        if not request.user or not request.user.is_authenticated:
            return False

        if not request.user.is_active:
            return False

        # Check user role
        if not hasattr(request.user, "role"):
            return False

        return request.user.role in self.voting_roles


class CanVerifyVotes(permissions.BasePermission):
    """
    Permission that allows users to verify votes.

    Allows users to verify their own votes using the anonymous vote token,
    and administrators/electoral committee to verify any vote.
    """

    admin_roles = [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]

    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if user can verify votes.

        Args:
            request: HTTP request
            view: View being accessed

        Returns:
            bool: Whether user can verify votes
        """
        if not request.user or not request.user.is_authenticated:
            return False

        if not request.user.is_active:
            return False

        # All authenticated users can verify votes (with restrictions)
        return True

    def has_object_permission(self, request: Request, view: View, obj: Vote) -> bool:
        """
        Check if user can verify specific vote.

        Args:
            request: HTTP request
            view: View being accessed
            obj: Vote object

        Returns:
            bool: Whether user can verify the vote
        """
        # Admin roles can verify any vote
        if hasattr(request.user, "role") and request.user.role in self.admin_roles:
            return True

        # For regular users, they need to provide the correct vote token
        # This is handled in the view logic, not here
        return True


class CanManageOfflineVotes(permissions.BasePermission):
    """
    Permission that allows users to manage offline votes.

    Users can manage their own offline votes, while administrators
    can manage any offline votes.
    """

    admin_roles = [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]

    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if user can manage offline votes.

        Args:
            request: HTTP request
            view: View being accessed

        Returns:
            bool: Whether user can manage offline votes
        """
        if not request.user or not request.user.is_authenticated:
            return False

        if not request.user.is_active:
            return False

        return True

    def has_object_permission(
        self, request: Request, view: View, obj: OfflineVoteQueue
    ) -> bool:
        """
        Check if user can manage specific offline vote.

        Args:
            request: HTTP request
            view: View being accessed
            obj: OfflineVoteQueue object

        Returns:
            bool: Whether user can manage the offline vote
        """
        # Admin roles can manage any offline vote
        if hasattr(request.user, "role") and request.user.role in self.admin_roles:
            return True

        # Users can only manage their own offline votes
        return obj.ballot_token.user == request.user


class CanViewAuditLogs(permissions.BasePermission):
    """
    Permission that allows viewing vote audit logs.

    Only administrators and electoral committee members can view audit logs.
    """

    admin_roles = [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]

    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if user can view audit logs.

        Args:
            request: HTTP request
            view: View being accessed

        Returns:
            bool: Whether user can view audit logs
        """
        if not request.user or not request.user.is_authenticated:
            return False

        if not request.user.is_active:
            return False

        # Check user role
        if not hasattr(request.user, "role"):
            return False

        return request.user.role in self.admin_roles


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

        # Check user role
        if not hasattr(request.user, "role"):
            return False

        return request.user.role in self.voting_roles

    def has_object_permission(
        self, request: Request, view: View, obj: Election
    ) -> bool:
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


# Utility functions for permission checking


def can_cast_vote_for_election(user: User, election: Election) -> bool:
    """
    Utility function to check if user can cast a vote for an election.

    Args:
        user: User instance
        election: Election instance

    Returns:
        bool: Whether user can cast a vote
    """
    if not user or not user.is_authenticated or not user.is_active:
        return False

    if not hasattr(user, "role"):
        return False

    # Check role
    voting_roles = [UserRole.STUDENT, UserRole.STAFF, UserRole.CANDIDATE]
    if user.role not in voting_roles:
        return False

    # Check election status
    if not election or not election.can_vote:
        return False

    return True


def can_verify_vote_with_token(user: User, vote_token: str) -> bool:
    """
    Utility function to check if user can verify a vote with token.

    Args:
        user: User instance
        vote_token: Vote token string

    Returns:
        bool: Whether user can verify the vote
    """
    if not user or not user.is_authenticated or not user.is_active:
        return False

    # Admin roles can verify any vote
    admin_roles = [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]
    if hasattr(user, "role") and user.role in admin_roles:
        return True

    # Regular users need to have cast the vote (checked via token matching)
    return True


def can_manage_offline_vote_queue(user: User) -> bool:
    """
    Utility function to check if user can manage offline vote queue.

    Args:
        user: User instance

    Returns:
        bool: Whether user can manage offline votes
    """
    if not user or not user.is_authenticated or not user.is_active:
        return False

    # All authenticated users can manage their own offline votes
    return True


def can_view_vote_statistics(user: User) -> bool:
    """
    Utility function to check if user can view vote statistics.

    Args:
        user: User instance

    Returns:
        bool: Whether user can view vote statistics
    """
    if not user or not user.is_authenticated or not user.is_active:
        return False

    # Only admin roles can view vote statistics
    admin_roles = [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]
    if not hasattr(user, "role") or user.role not in admin_roles:
        return False

    return True
