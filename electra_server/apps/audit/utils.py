"""
Audit integration utilities for electra_server.

This module provides convenient functions for integrating audit logging
throughout the electra system without creating circular dependencies.
"""
from typing import Optional, Dict, Any, Union
from django.contrib.auth import get_user_model
from django.http import HttpRequest
from rest_framework.request import Request

User = get_user_model()


def log_user_action(
    action_type: str,
    description: str,
    request: Optional[Union[HttpRequest, Request]] = None,
    user: Optional[User] = None,
    outcome: str = 'success',
    election=None,
    target_resource_type: str = '',
    target_resource_id: str = '',
    metadata: Optional[Dict[str, Any]] = None,
    error_details: str = '',
) -> None:
    """
    Log a user action to the audit trail.
    
    This function provides a convenient way for other modules to create
    audit log entries without directly importing audit models.
    
    Args:
        action_type: Type of action from AuditActionType choices
        description: Detailed description of the action
        request: HTTP request object (for extracting IP, user agent, etc.)
        user: User who performed the action
        outcome: Outcome of the action ('success', 'failure', 'error', 'warning')
        election: Election context if applicable
        target_resource_type: Type of resource being acted upon
        target_resource_id: ID of the target resource
        metadata: Additional contextual data
        error_details: Error details if action failed
    """
    try:
        # Import here to avoid circular imports
        from .models import AuditLog
        
        # Extract request information if available
        ip_address = ''
        user_agent = ''
        session_key = ''
        
        if request:
            # Handle both Django HttpRequest and DRF Request
            if hasattr(request, 'META'):
                # Extract IP address
                x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
                if x_forwarded_for:
                    ip_address = x_forwarded_for.split(',')[0].strip()
                else:
                    ip_address = request.META.get('REMOTE_ADDR', '')
                
                # Extract user agent
                user_agent = request.META.get('HTTP_USER_AGENT', '')
            
            # Extract session key
            if hasattr(request, 'session') and hasattr(request.session, 'session_key'):
                session_key = request.session.session_key or ''
            
            # Extract user if not provided
            if not user and hasattr(request, 'user') and request.user.is_authenticated:
                user = request.user
        
        # Create audit entry
        AuditLog.create_audit_entry(
            action_type=action_type,
            action_description=description,
            user=user,
            ip_address=ip_address if ip_address else None,
            user_agent=user_agent,
            session_key=session_key,
            election=election,
            target_resource_type=target_resource_type,
            target_resource_id=target_resource_id,
            outcome=outcome,
            metadata=metadata or {},
            error_details=error_details,
        )
    except Exception as e:
        # Don't let audit logging failures break the main application
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Failed to create audit log entry: {e}")


def log_authentication_event(
    action_type: str,
    user: Optional[User],
    request: Optional[Union[HttpRequest, Request]] = None,
    outcome: str = 'success',
    error_details: str = '',
    metadata: Optional[Dict[str, Any]] = None,
) -> None:
    """
    Log authentication-related events.
    
    Args:
        action_type: Type of authentication action
        user: User involved in the authentication event
        request: HTTP request object
        outcome: Outcome of the authentication attempt
        error_details: Details of authentication failure
        metadata: Additional authentication context
    """
    user_identifier = ''
    if user:
        user_identifier = user.email
    elif request and hasattr(request, 'data'):
        # Try to extract email from failed login attempt
        user_identifier = request.data.get('email', '')
    
    description = f"Authentication event: {action_type}"
    if user_identifier:
        description += f" for {user_identifier}"
    
    log_user_action(
        action_type=action_type,
        description=description,
        request=request,
        user=user,
        outcome=outcome,
        target_resource_type='User',
        target_resource_id=str(user.id) if user else '',
        metadata=metadata,
        error_details=error_details,
    )


def log_election_event(
    action_type: str,
    election,
    user: Optional[User] = None,
    request: Optional[Union[HttpRequest, Request]] = None,
    outcome: str = 'success',
    metadata: Optional[Dict[str, Any]] = None,
    error_details: str = '',
) -> None:
    """
    Log election management events.
    
    Args:
        action_type: Type of election action
        election: Election object being acted upon
        user: User who performed the action
        request: HTTP request object
        outcome: Outcome of the action
        metadata: Additional context about the election action
        error_details: Error details if action failed
    """
    description = f"Election {action_type}: {election.title}"
    if hasattr(election, 'status'):
        description += f" (Status: {election.status})"
    
    log_user_action(
        action_type=action_type,
        description=description,
        request=request,
        user=user,
        outcome=outcome,
        election=election,
        target_resource_type='Election',
        target_resource_id=str(election.id),
        metadata=metadata,
        error_details=error_details,
    )


def log_token_event(
    action_type: str,
    token,
    user: Optional[User] = None,
    request: Optional[Union[HttpRequest, Request]] = None,
    outcome: str = 'success',
    metadata: Optional[Dict[str, Any]] = None,
    error_details: str = '',
) -> None:
    """
    Log ballot token events.
    
    Args:
        action_type: Type of token action
        token: Ballot token object being acted upon
        user: User who performed the action
        request: HTTP request object
        outcome: Outcome of the action
        metadata: Additional context about the token action
        error_details: Error details if action failed
    """
    description = f"Ballot token {action_type}"
    if hasattr(token, 'election'):
        description += f" for election: {token.election.title}"
    
    election = getattr(token, 'election', None)
    
    log_user_action(
        action_type=action_type,
        description=description,
        request=request,
        user=user,
        outcome=outcome,
        election=election,
        target_resource_type='BallotToken',
        target_resource_id=str(token.id),
        metadata=metadata,
        error_details=error_details,
    )


def log_vote_event(
    action_type: str,
    vote=None,
    election=None,
    user: Optional[User] = None,
    request: Optional[Union[HttpRequest, Request]] = None,
    outcome: str = 'success',
    metadata: Optional[Dict[str, Any]] = None,
    error_details: str = '',
) -> None:
    """
    Log vote casting events.
    
    Args:
        action_type: Type of vote action
        vote: Vote object being acted upon (optional for failed votes)
        election: Election context if vote object not available
        user: User who performed the action
        request: HTTP request object
        outcome: Outcome of the action
        metadata: Additional context about the vote action
        error_details: Error details if action failed
    """
    description = f"Vote {action_type}"
    
    # Use election from vote if available, otherwise use provided election
    if vote and hasattr(vote, 'election'):
        election = vote.election
    
    if election:
        description += f" in election: {election.title}"
    
    # Don't include user in vote logging to maintain ballot secrecy
    # The audit trail shows voting activity but not who voted for what
    target_id = str(vote.id) if vote else ''
    
    log_user_action(
        action_type=action_type,
        description=description,
        request=request,
        user=None,  # Maintain ballot secrecy
        outcome=outcome,
        election=election,
        target_resource_type='Vote',
        target_resource_id=target_id,
        metadata=metadata,
        error_details=error_details,
    )


def log_system_event(
    action_type: str,
    description: str,
    outcome: str = 'success',
    metadata: Optional[Dict[str, Any]] = None,
    error_details: str = '',
) -> None:
    """
    Log system-level events (no user context).
    
    Args:
        action_type: Type of system action
        description: Detailed description of the system event
        outcome: Outcome of the system action
        metadata: Additional context about the system event
        error_details: Error details if action failed
    """
    log_user_action(
        action_type=action_type,
        description=description,
        request=None,
        user=None,
        outcome=outcome,
        target_resource_type='System',
        target_resource_id='',
        metadata=metadata,
        error_details=error_details,
    )


def log_admin_action(
    admin_user: User,
    action_type: str,
    description: str,
    target_user: Optional[User] = None,
    target_election = None,
    outcome: str = 'success',
    metadata: Optional[Dict[str, Any]] = None,
    error_details: str = '',
) -> None:
    """
    Log administrative actions performed through admin APIs.
    
    This function provides a specialized logging interface for admin actions
    with proper context and targeting information.
    
    Args:
        admin_user: User performing the administrative action
        action_type: Type of action from AuditActionType choices
        description: Detailed description of the administrative action
        target_user: User being acted upon (if applicable)
        target_election: Election being acted upon (if applicable)
        outcome: Outcome of the action ('success', 'failure', 'error', 'warning')
        metadata: Additional contextual data
        error_details: Error details if action failed
    """
    # Prepare metadata with admin context
    admin_metadata = {
        'admin_user_id': str(admin_user.id),
        'admin_user_email': admin_user.email,
        'admin_user_role': admin_user.role,
        'is_admin_action': True,
    }
    
    if metadata:
        admin_metadata.update(metadata)
    
    # Determine target resource information
    target_resource_type = ''
    target_resource_id = ''
    
    if target_user:
        target_resource_type = 'User'
        target_resource_id = str(target_user.id)
        admin_metadata['target_user_id'] = str(target_user.id)
        admin_metadata['target_user_email'] = target_user.email
    
    if target_election:
        if target_resource_type:
            target_resource_type = 'Multiple'
        else:
            target_resource_type = 'Election'
            target_resource_id = str(target_election.id)
        admin_metadata['target_election_id'] = str(target_election.id)
        admin_metadata['target_election_title'] = target_election.title
    
    # Log the admin action
    log_user_action(
        action_type=action_type,
        description=f'[ADMIN] {description}',
        request=None,
        user=admin_user,
        outcome=outcome,
        election=target_election,
        target_resource_type=target_resource_type,
        target_resource_id=target_resource_id,
        metadata=admin_metadata,
        error_details=error_details,
    )