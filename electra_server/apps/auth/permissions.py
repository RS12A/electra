"""
Custom permissions for the authentication system.

This module contains role-based permissions for the electra voting system,
ensuring proper access control based on user roles.
"""
from typing import Any, Optional
from rest_framework import permissions
from rest_framework.request import Request
from rest_framework.views import View

from .models import User, UserRole


class IsAuthenticated(permissions.BasePermission):
    """
    Enhanced authentication permission with additional checks.
    """
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if user is authenticated and active.
        
        Args:
            request: HTTP request
            view: View being accessed
            
        Returns:
            bool: Whether user has permission
        """
        return (
            request.user and 
            request.user.is_authenticated and 
            request.user.is_active
        )


class IsOwnerOrReadOnly(permissions.BasePermission):
    """
    Permission that allows owners of an object to edit it.
    """
    
    def has_object_permission(self, request: Request, view: View, obj: Any) -> bool:
        """
        Check if user can access the object.
        
        Args:
            request: HTTP request
            view: View being accessed
            obj: Object being accessed
            
        Returns:
            bool: Whether user has permission
        """
        # Read permissions for any request
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Write permissions only to owner
        return obj == request.user


class RoleBasedPermission(permissions.BasePermission):
    """
    Base class for role-based permissions.
    """
    
    allowed_roles = []  # Override in subclasses
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if user has required role.
        
        Args:
            request: HTTP request
            view: View being accessed
            
        Returns:
            bool: Whether user has permission
        """
        if not request.user or not request.user.is_authenticated:
            return False
        
        if not request.user.is_active:
            return False
        
        return request.user.role in self.allowed_roles


class IsStudent(RoleBasedPermission):
    """
    Permission that allows only students.
    """
    
    allowed_roles = [UserRole.STUDENT]


class IsStaff(RoleBasedPermission):
    """
    Permission that allows only staff members.
    """
    
    allowed_roles = [UserRole.STAFF]


class IsCandidate(RoleBasedPermission):
    """
    Permission that allows only candidates.
    """
    
    allowed_roles = [UserRole.CANDIDATE]


class IsAdmin(RoleBasedPermission):
    """
    Permission that allows only administrators.
    """
    
    allowed_roles = [UserRole.ADMIN]


class IsElectoralCommittee(RoleBasedPermission):
    """
    Permission that allows only electoral committee members.
    """
    
    allowed_roles = [UserRole.ELECTORAL_COMMITTEE]


class IsElectionManager(RoleBasedPermission):
    """
    Permission that allows users who can manage elections.
    
    This includes administrators and electoral committee members.
    """
    
    allowed_roles = [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]


class IsStaffOrAdmin(RoleBasedPermission):
    """
    Permission that allows staff and administrators.
    """
    
    allowed_roles = [UserRole.STAFF, UserRole.ADMIN]


class IsAdminOrElectoralCommittee(RoleBasedPermission):
    """
    Permission that allows administrators and electoral committee.
    """
    
    allowed_roles = [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]


class CanVote(permissions.BasePermission):
    """
    Permission that checks if user can vote.
    
    Students and staff can vote. Admins and electoral committee
    typically cannot vote to maintain neutrality.
    """
    
    voting_roles = [UserRole.STUDENT, UserRole.STAFF, UserRole.CANDIDATE]
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if user can vote.
        
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


class CanRunForElection(permissions.BasePermission):
    """
    Permission that checks if user can run for election.
    
    Typically students and staff can be candidates, but admins
    and electoral committee members cannot for neutrality.
    """
    
    candidate_roles = [UserRole.STUDENT, UserRole.STAFF]
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if user can run for election.
        
        Args:
            request: HTTP request
            view: View being accessed
            
        Returns:
            bool: Whether user can be a candidate
        """
        if not request.user or not request.user.is_authenticated:
            return False
        
        if not request.user.is_active:
            return False
        
        return request.user.role in self.candidate_roles


class IsSuperUser(permissions.BasePermission):
    """
    Permission that allows only Django superusers.
    """
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if user is a superuser.
        
        Args:
            request: HTTP request
            view: View being accessed
            
        Returns:
            bool: Whether user is superuser
        """
        return (
            request.user and 
            request.user.is_authenticated and 
            request.user.is_active and 
            request.user.is_superuser
        )


class IsOwner(permissions.BasePermission):
    """
    Permission that allows only the owner of an object.
    """
    
    def has_object_permission(self, request: Request, view: View, obj: Any) -> bool:
        """
        Check if user owns the object.
        
        Args:
            request: HTTP request
            view: View being accessed
            obj: Object being accessed
            
        Returns:
            bool: Whether user owns the object
        """
        # For User objects, check if it's the same user
        if isinstance(obj, User):
            return obj == request.user
        
        # For objects with a user field
        if hasattr(obj, 'user'):
            return obj.user == request.user
        
        # For objects with an owner field
        if hasattr(obj, 'owner'):
            return obj.owner == request.user
        
        return False


class ReadOnlyPermission(permissions.BasePermission):
    """
    Permission that allows only read operations.
    """
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if request is read-only.
        
        Args:
            request: HTTP request
            view: View being accessed
            
        Returns:
            bool: Whether request is read-only
        """
        return request.method in permissions.SAFE_METHODS


class ConditionalPermission(permissions.BasePermission):
    """
    Permission that checks multiple conditions.
    
    This is a utility permission class that can combine multiple
    permission checks with AND/OR logic.
    """
    
    def __init__(self, *permissions_classes, logic='AND'):
        """
        Initialize conditional permission.
        
        Args:
            *permissions_classes: Permission classes to check
            logic: 'AND' or 'OR' logic (default: 'AND')
        """
        self.permissions_classes = permissions_classes
        self.logic = logic.upper()
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check permissions based on logic.
        
        Args:
            request: HTTP request
            view: View being accessed
            
        Returns:
            bool: Whether user has permission
        """
        results = []
        
        for permission_class in self.permissions_classes:
            permission = permission_class()
            result = permission.has_permission(request, view)
            results.append(result)
        
        if self.logic == 'AND':
            return all(results)
        elif self.logic == 'OR':
            return any(results)
        else:
            raise ValueError("Logic must be 'AND' or 'OR'")
    
    def has_object_permission(self, request: Request, view: View, obj: Any) -> bool:
        """
        Check object permissions based on logic.
        
        Args:
            request: HTTP request
            view: View being accessed
            obj: Object being accessed
            
        Returns:
            bool: Whether user has permission
        """
        results = []
        
        for permission_class in self.permissions_classes:
            permission = permission_class()
            if hasattr(permission, 'has_object_permission'):
                result = permission.has_object_permission(request, view, obj)
            else:
                result = permission.has_permission(request, view)
            results.append(result)
        
        if self.logic == 'AND':
            return all(results)
        elif self.logic == 'OR':
            return any(results)
        else:
            raise ValueError("Logic must be 'AND' or 'OR'")


# Common permission combinations
IsAuthenticatedOwner = lambda: ConditionalPermission(IsAuthenticated, IsOwner)
IsElectionManagerOrReadOnly = lambda: ConditionalPermission(IsElectionManager, ReadOnlyPermission, logic='OR')
IsOwnerOrElectionManager = lambda: ConditionalPermission(IsOwner, IsElectionManager, logic='OR')


def has_role(user: Optional[User], *roles: str) -> bool:
    """
    Utility function to check if user has any of the specified roles.
    
    Args:
        user: User instance to check
        *roles: Roles to check for
        
    Returns:
        bool: Whether user has any of the roles
    """
    if not user or not user.is_authenticated:
        return False
    
    return user.role in roles


def can_manage_elections(user: Optional[User]) -> bool:
    """
    Utility function to check if user can manage elections.
    
    Args:
        user: User instance to check
        
    Returns:
        bool: Whether user can manage elections
    """
    if not user or not user.is_authenticated:
        return False
    
    return user.can_manage_elections()


def can_vote(user: Optional[User]) -> bool:
    """
    Utility function to check if user can vote.
    
    Args:
        user: User instance to check
        
    Returns:
        bool: Whether user can vote
    """
    return has_role(user, UserRole.STUDENT, UserRole.STAFF, UserRole.CANDIDATE)


def can_be_candidate(user: Optional[User]) -> bool:
    """
    Utility function to check if user can be a candidate.
    
    Args:
        user: User instance to check
        
    Returns:
        bool: Whether user can be a candidate
    """
    return has_role(user, UserRole.STUDENT, UserRole.STAFF)