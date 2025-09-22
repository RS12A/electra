"""
Elections permissions for electra_server.

This module contains custom permissions for election management
based on user roles and election state.
"""
from typing import Any
from django.contrib.auth import get_user_model
from rest_framework import permissions
from rest_framework.request import Request
from rest_framework.views import View

from electra_server.apps.auth.models import UserRole
from .models import Election

User = get_user_model()


class CanManageElections(permissions.BasePermission):
    """
    Permission that allows only users who can manage elections.
    
    This includes administrators and electoral committee members.
    """
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if user can manage elections.
        
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
        
        return request.user.role in [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]


class CanViewElections(permissions.BasePermission):
    """
    Permission that allows viewing elections.
    
    All authenticated users can view elections, but only election managers
    can see draft elections.
    """
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check if user can view elections.
        
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
        
        return True
    
    def has_object_permission(self, request: Request, view: View, obj: Election) -> bool:
        """
        Check if user can view specific election.
        
        Args:
            request: HTTP request
            view: View being accessed
            obj: Election object
            
        Returns:
            bool: Whether user has permission
        """
        # Election managers can view all elections
        if request.user.role in [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]:
            return True
        
        # Regular users can only view non-draft elections
        return obj.status != 'draft'


class CanVoteInElections(permissions.BasePermission):
    """
    Permission that checks if user can vote in elections.
    
    Students, staff, and candidates can vote. Admins and electoral committee
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


class IsElectionCreatorOrManager(permissions.BasePermission):
    """
    Permission that allows election creators or election managers to modify elections.
    """
    
    def has_object_permission(self, request: Request, view: View, obj: Election) -> bool:
        """
        Check if user can modify specific election.
        
        Args:
            request: HTTP request
            view: View being accessed
            obj: Election object
            
        Returns:
            bool: Whether user has permission
        """
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Election managers can modify all elections
        if request.user.role in [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]:
            return True
        
        # Users can only modify elections they created
        return obj.created_by == request.user


class ElectionManagementPermission(permissions.BasePermission):
    """
    Comprehensive permission class for election management endpoints.
    
    Combines multiple permission checks based on the request method and action.
    """
    
    def has_permission(self, request: Request, view: View) -> bool:
        """
        Check permission based on request method.
        
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
        
        # GET requests - viewing elections
        if request.method in permissions.SAFE_METHODS:
            return True  # All authenticated users can view
        
        # POST, PUT, PATCH, DELETE - managing elections
        return request.user.role in [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]
    
    def has_object_permission(self, request: Request, view: View, obj: Election) -> bool:
        """
        Check object-level permissions.
        
        Args:
            request: HTTP request
            view: View being accessed
            obj: Election object
            
        Returns:
            bool: Whether user has permission
        """
        # GET requests - viewing specific election
        if request.method in permissions.SAFE_METHODS:
            # Election managers can view all elections
            if request.user.role in [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]:
                return True
            
            # Regular users can only view non-draft elections
            return obj.status != 'draft'
        
        # POST, PUT, PATCH, DELETE - modifying elections
        # Only election managers can modify elections
        return request.user.role in [UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]