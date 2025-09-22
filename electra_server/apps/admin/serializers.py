"""
Admin API serializers for the electra voting system.

This module contains DRF serializers for admin CRUD operations on users,
elections, candidates, and ballot tokens with proper validation and
security considerations.
"""
from typing import Dict, Any, List, Optional
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.exceptions import ValidationError as DjangoValidationError

from electra_server.apps.auth.models import UserRole
from electra_server.apps.elections.models import Election, ElectionStatus
from electra_server.apps.ballots.models import BallotToken, BallotTokenStatus
from electra_server.apps.audit.utils import log_admin_action
from electra_server.apps.audit.models import AuditActionType

User = get_user_model()


class AdminUserListSerializer(serializers.ModelSerializer):
    """
    Serializer for listing users in admin APIs.
    
    Provides essential user information for listing operations
    with security-conscious field selection.
    """
    
    role_display = serializers.CharField(source='get_role_display', read_only=True)
    last_login_display = serializers.SerializerMethodField()
    date_joined_display = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = [
            'id', 'email', 'full_name', 'matric_number', 'staff_id',
            'role', 'role_display', 'is_active', 'is_staff', 
            'last_login', 'last_login_display', 'date_joined', 'date_joined_display'
        ]
        read_only_fields = ['id', 'last_login', 'date_joined']
    
    def get_last_login_display(self, obj: User) -> Optional[str]:
        """Format last login datetime for display."""
        if obj.last_login:
            return obj.last_login.strftime('%Y-%m-%d %H:%M:%S UTC')
        return 'Never'
    
    def get_date_joined_display(self, obj: User) -> str:
        """Format date joined datetime for display."""
        return obj.date_joined.strftime('%Y-%m-%d %H:%M:%S UTC')


class AdminUserDetailSerializer(serializers.ModelSerializer):
    """
    Serializer for detailed user information in admin APIs.
    
    Provides comprehensive user information for detail views
    including sensitive fields only accessible to admins.
    """
    
    role_display = serializers.CharField(source='get_role_display', read_only=True)
    last_login_display = serializers.SerializerMethodField()
    date_joined_display = serializers.SerializerMethodField()
    ballot_tokens_count = serializers.SerializerMethodField()
    created_elections_count = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = [
            'id', 'email', 'full_name', 'matric_number', 'staff_id',
            'role', 'role_display', 'is_active', 'is_staff', 'is_superuser',
            'last_login', 'last_login_display', 
            'date_joined', 'date_joined_display',
            'ballot_tokens_count', 'created_elections_count'
        ]
        read_only_fields = ['id', 'last_login', 'date_joined']
    
    def get_last_login_display(self, obj: User) -> Optional[str]:
        """Format last login datetime for display."""
        if obj.last_login:
            return obj.last_login.strftime('%Y-%m-%d %H:%M:%S UTC')
        return 'Never'
    
    def get_date_joined_display(self, obj: User) -> str:
        """Format date joined datetime for display."""
        return obj.date_joined.strftime('%Y-%m-%d %H:%M:%S UTC')
    
    def get_ballot_tokens_count(self, obj: User) -> int:
        """Get count of ballot tokens for this user."""
        return obj.ballot_tokens.count()
    
    def get_created_elections_count(self, obj: User) -> int:
        """Get count of elections created by this user."""
        return obj.created_elections.count()


class AdminUserCreateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating users through admin APIs.
    
    Handles user creation with proper validation and security checks.
    """
    
    password = serializers.CharField(write_only=True, min_length=8)
    password_confirm = serializers.CharField(write_only=True)
    
    class Meta:
        model = User
        fields = [
            'email', 'full_name', 'matric_number', 'staff_id',
            'role', 'is_active', 'is_staff', 'password', 'password_confirm'
        ]
    
    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate user creation data.
        
        Args:
            attrs: Validated attributes
            
        Returns:
            Dict[str, Any]: Validated attributes
            
        Raises:
            ValidationError: If validation fails
        """
        # Check password confirmation
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({
                'password_confirm': 'Password confirmation does not match.'
            })
        
        # Role-based validation for identification numbers
        role = attrs.get('role')
        matric_number = attrs.get('matric_number')
        staff_id = attrs.get('staff_id')
        
        if role == UserRole.STUDENT:
            if not matric_number:
                raise serializers.ValidationError({
                    'matric_number': 'Students must have a matriculation number.'
                })
            if staff_id:
                raise serializers.ValidationError({
                    'staff_id': 'Students should not have a staff ID.'
                })
        elif role in [UserRole.STAFF, UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]:
            if not staff_id:
                role_display = dict(UserRole.choices)[role]
                raise serializers.ValidationError({
                    'staff_id': f'{role_display} must have a staff ID.'
                })
            if matric_number:
                role_display = dict(UserRole.choices)[role]
                raise serializers.ValidationError({
                    'matric_number': f'{role_display} should not have a matriculation number.'
                })
        # Candidates can have either
        
        # Remove password_confirm from attrs
        attrs.pop('password_confirm', None)
        
        return attrs
    
    def create(self, validated_data: Dict[str, Any]) -> User:
        """
        Create a new user with proper password hashing.
        
        Args:
            validated_data: Validated user data
            
        Returns:
            User: Created user instance
        """
        password = validated_data.pop('password')
        user = User.objects.create_user(password=password, **validated_data)
        
        # Log user creation
        request = self.context.get('request')
        if request and request.user:
            log_admin_action(
                admin_user=request.user,
                action_type=AuditActionType.ADMIN_ACTION,
                description=f'User created: {user.email}',
                target_user=user,
                metadata={
                    'created_user_role': user.role,
                    'created_user_email': user.email,
                    'admin_user_role': request.user.role
                }
            )
        
        return user


class AdminUserUpdateSerializer(serializers.ModelSerializer):
    """
    Serializer for updating users through admin APIs.
    
    Handles user updates with proper validation and audit logging.
    """
    
    class Meta:
        model = User
        fields = [
            'email', 'full_name', 'matric_number', 'staff_id',
            'role', 'is_active', 'is_staff'
        ]
    
    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate user update data.
        
        Args:
            attrs: Validated attributes
            
        Returns:
            Dict[str, Any]: Validated attributes
        """
        # Role-based validation if role is being changed
        role = attrs.get('role')
        if role:
            matric_number = attrs.get('matric_number', self.instance.matric_number)
            staff_id = attrs.get('staff_id', self.instance.staff_id)
            
            if role == UserRole.STUDENT:
                if not matric_number:
                    raise serializers.ValidationError({
                        'matric_number': 'Students must have a matriculation number.'
                    })
            elif role in [UserRole.STAFF, UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]:
                if not staff_id:
                    raise serializers.ValidationError({
                        'staff_id': f'{role.label} must have a staff ID.'
                    })
        
        return attrs
    
    def update(self, instance: User, validated_data: Dict[str, Any]) -> User:
        """
        Update user with audit logging.
        
        Args:
            instance: User instance to update
            validated_data: Validated update data
            
        Returns:
            User: Updated user instance
        """
        # Track changes for audit log
        changes = {}
        for field, new_value in validated_data.items():
            old_value = getattr(instance, field)
            if old_value != new_value:
                changes[field] = {'old': str(old_value), 'new': str(new_value)}
        
        # Update the instance
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Log user update
        request = self.context.get('request')
        if request and request.user and changes:
            log_admin_action(
                admin_user=request.user,
                action_type=AuditActionType.ADMIN_ACTION,
                description=f'User updated: {instance.email}',
                target_user=instance,
                metadata={
                    'changes': changes,
                    'updated_user_role': instance.role,
                    'admin_user_role': request.user.role
                }
            )
        
        return instance


class AdminElectionListSerializer(serializers.ModelSerializer):
    """
    Serializer for listing elections in admin APIs.
    
    Provides essential election information for listing operations.
    """
    
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    created_by_email = serializers.CharField(source='created_by.email', read_only=True)
    created_by_name = serializers.CharField(source='created_by.full_name', read_only=True)
    created_at_display = serializers.SerializerMethodField()
    start_time_display = serializers.SerializerMethodField()
    end_time_display = serializers.SerializerMethodField()
    is_active = serializers.ReadOnlyField()
    can_vote = serializers.ReadOnlyField()
    
    class Meta:
        model = Election
        fields = [
            'id', 'title', 'description', 'status', 'status_display',
            'start_time', 'start_time_display', 'end_time', 'end_time_display',
            'created_by', 'created_by_email', 'created_by_name',
            'created_at', 'created_at_display', 'updated_at',
            'is_active', 'can_vote', 'delayed_reveal'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_created_at_display(self, obj: Election) -> str:
        """Format created at datetime for display."""
        return obj.created_at.strftime('%Y-%m-%d %H:%M:%S UTC')
    
    def get_start_time_display(self, obj: Election) -> str:
        """Format start time datetime for display."""
        return obj.start_time.strftime('%Y-%m-%d %H:%M:%S UTC')
    
    def get_end_time_display(self, obj: Election) -> str:
        """Format end time datetime for display."""
        return obj.end_time.strftime('%Y-%m-%d %H:%M:%S UTC')


class AdminElectionDetailSerializer(serializers.ModelSerializer):
    """
    Serializer for detailed election information in admin APIs.
    
    Provides comprehensive election information including statistics.
    """
    
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    created_by_details = AdminUserListSerializer(source='created_by', read_only=True)
    created_at_display = serializers.SerializerMethodField()
    start_time_display = serializers.SerializerMethodField()
    end_time_display = serializers.SerializerMethodField()
    ballot_tokens_count = serializers.SerializerMethodField()
    votes_count = serializers.SerializerMethodField()
    candidates_count = serializers.SerializerMethodField()
    is_active = serializers.ReadOnlyField()
    can_vote = serializers.ReadOnlyField()
    has_started = serializers.ReadOnlyField()
    has_ended = serializers.ReadOnlyField()
    
    class Meta:
        model = Election
        fields = [
            'id', 'title', 'description', 'status', 'status_display',
            'start_time', 'start_time_display', 'end_time', 'end_time_display',
            'created_by', 'created_by_details',
            'created_at', 'created_at_display', 'updated_at',
            'delayed_reveal', 'is_active', 'can_vote', 'has_started', 'has_ended',
            'ballot_tokens_count', 'votes_count', 'candidates_count'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_created_at_display(self, obj: Election) -> str:
        """Format created at datetime for display."""
        return obj.created_at.strftime('%Y-%m-%d %H:%M:%S UTC')
    
    def get_start_time_display(self, obj: Election) -> str:
        """Format start time datetime for display."""
        return obj.start_time.strftime('%Y-%m-%d %H:%M:%S UTC')
    
    def get_end_time_display(self, obj: Election) -> str:
        """Format end time datetime for display."""
        return obj.end_time.strftime('%Y-%m-%d %H:%M:%S UTC')
    
    def get_ballot_tokens_count(self, obj: Election) -> int:
        """Get count of ballot tokens for this election."""
        return obj.ballot_tokens.count()
    
    def get_votes_count(self, obj: Election) -> int:
        """Get count of votes cast in this election."""
        return obj.votes.count() if hasattr(obj, 'votes') else 0
    
    def get_candidates_count(self, obj: Election) -> int:
        """Get count of candidates in this election."""
        return obj.candidates.count() if hasattr(obj, 'candidates') else 0


class AdminElectionCreateUpdateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating/updating elections through admin APIs.
    
    Handles election creation and updates with proper validation.
    """
    
    class Meta:
        model = Election
        fields = [
            'title', 'description', 'start_time', 'end_time', 'delayed_reveal'
        ]
    
    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate election data.
        
        Args:
            attrs: Validated attributes
            
        Returns:
            Dict[str, Any]: Validated attributes
            
        Raises:
            ValidationError: If validation fails
        """
        start_time = attrs.get('start_time')
        end_time = attrs.get('end_time')
        
        if start_time and end_time:
            if start_time >= end_time:
                raise serializers.ValidationError({
                    'end_time': 'End time must be after start time.'
                })
            
            # For new elections, ensure start time is in the future
            if not self.instance and start_time <= timezone.now():
                raise serializers.ValidationError({
                    'start_time': 'Start time must be in the future for new elections.'
                })
        
        return attrs
    
    def create(self, validated_data: Dict[str, Any]) -> Election:
        """
        Create a new election with proper audit logging.
        
        Args:
            validated_data: Validated election data
            
        Returns:
            Election: Created election instance
        """
        # Set created_by from request user
        request = self.context.get('request')
        if request and request.user:
            validated_data['created_by'] = request.user
        
        election = Election.objects.create(**validated_data)
        
        # Log election creation
        if request and request.user:
            log_admin_action(
                admin_user=request.user,
                action_type=AuditActionType.ELECTION_CREATED,
                description=f'Election created: {election.title}',
                target_election=election,
                metadata={
                    'election_title': election.title,
                    'start_time': election.start_time.isoformat(),
                    'end_time': election.end_time.isoformat(),
                    'admin_user_role': request.user.role
                }
            )
        
        return election
    
    def update(self, instance: Election, validated_data: Dict[str, Any]) -> Election:
        """
        Update election with audit logging.
        
        Args:
            instance: Election instance to update
            validated_data: Validated update data
            
        Returns:
            Election: Updated election instance
        """
        # Track changes for audit log
        changes = {}
        for field, new_value in validated_data.items():
            old_value = getattr(instance, field)
            if old_value != new_value:
                if isinstance(old_value, timezone.datetime):
                    changes[field] = {'old': old_value.isoformat(), 'new': new_value.isoformat()}
                else:
                    changes[field] = {'old': str(old_value), 'new': str(new_value)}
        
        # Update the instance
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Log election update
        request = self.context.get('request')
        if request and request.user and changes:
            log_admin_action(
                admin_user=request.user,
                action_type=AuditActionType.ELECTION_UPDATED,
                description=f'Election updated: {instance.title}',
                target_election=instance,
                metadata={
                    'changes': changes,
                    'admin_user_role': request.user.role
                }
            )
        
        return instance


class AdminBallotTokenListSerializer(serializers.ModelSerializer):
    """
    Serializer for listing ballot tokens in admin APIs.
    
    Provides essential ballot token information for listing operations.
    """
    
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    user_email = serializers.CharField(source='user.email', read_only=True)
    user_name = serializers.CharField(source='user.full_name', read_only=True)
    election_title = serializers.CharField(source='election.title', read_only=True)
    issued_at_display = serializers.SerializerMethodField()
    expires_at_display = serializers.SerializerMethodField()
    is_valid = serializers.ReadOnlyField()
    is_expired = serializers.ReadOnlyField()
    
    class Meta:
        model = BallotToken
        fields = [
            'id', 'token_uuid', 'status', 'status_display',
            'user', 'user_email', 'user_name',
            'election', 'election_title',
            'issued_at', 'issued_at_display',
            'expires_at', 'expires_at_display',
            'used_at', 'invalidated_at',
            'is_valid', 'is_expired', 'issued_ip'
        ]
        read_only_fields = ['id', 'token_uuid', 'issued_at', 'used_at', 'invalidated_at']
    
    def get_issued_at_display(self, obj: BallotToken) -> str:
        """Format issued at datetime for display."""
        return obj.issued_at.strftime('%Y-%m-%d %H:%M:%S UTC')
    
    def get_expires_at_display(self, obj: BallotToken) -> str:
        """Format expires at datetime for display."""
        return obj.expires_at.strftime('%Y-%m-%d %H:%M:%S UTC')


class AdminBallotTokenDetailSerializer(serializers.ModelSerializer):
    """
    Serializer for detailed ballot token information in admin APIs.
    
    Provides comprehensive ballot token information including metadata.
    """
    
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    user_details = AdminUserListSerializer(source='user', read_only=True)
    election_details = AdminElectionListSerializer(source='election', read_only=True)
    issued_at_display = serializers.SerializerMethodField()
    expires_at_display = serializers.SerializerMethodField()
    used_at_display = serializers.SerializerMethodField()
    invalidated_at_display = serializers.SerializerMethodField()
    is_valid = serializers.ReadOnlyField()
    is_expired = serializers.ReadOnlyField()
    
    class Meta:
        model = BallotToken
        fields = [
            'id', 'token_uuid', 'status', 'status_display',
            'user', 'user_details', 'election', 'election_details',
            'issued_at', 'issued_at_display',
            'expires_at', 'expires_at_display',
            'used_at', 'used_at_display',
            'invalidated_at', 'invalidated_at_display',
            'is_valid', 'is_expired',
            'issued_ip', 'issued_user_agent', 'offline_data'
        ]
        read_only_fields = [
            'id', 'token_uuid', 'issued_at', 'used_at', 'invalidated_at',
            'issued_ip', 'issued_user_agent'
        ]
    
    def get_issued_at_display(self, obj: BallotToken) -> str:
        """Format issued at datetime for display."""
        return obj.issued_at.strftime('%Y-%m-%d %H:%M:%S UTC')
    
    def get_expires_at_display(self, obj: BallotToken) -> str:
        """Format expires at datetime for display."""
        return obj.expires_at.strftime('%Y-%m-%d %H:%M:%S UTC')
    
    def get_used_at_display(self, obj: BallotToken) -> Optional[str]:
        """Format used at datetime for display."""
        if obj.used_at:
            return obj.used_at.strftime('%Y-%m-%d %H:%M:%S UTC')
        return None
    
    def get_invalidated_at_display(self, obj: BallotToken) -> Optional[str]:
        """Format invalidated at datetime for display."""
        if obj.invalidated_at:
            return obj.invalidated_at.strftime('%Y-%m-%d %H:%M:%S UTC')
        return None


class AdminBallotTokenRevokeSerializer(serializers.Serializer):
    """
    Serializer for revoking ballot tokens through admin APIs.
    
    Handles ballot token revocation with proper validation and logging.
    """
    
    reason = serializers.CharField(
        max_length=500,
        required=True,
        help_text='Reason for revoking the ballot token'
    )
    
    def validate_reason(self, value: str) -> str:
        """
        Validate revocation reason.
        
        Args:
            value: Revocation reason
            
        Returns:
            str: Validated reason
        """
        if not value or value.strip() == '':
            raise serializers.ValidationError('Revocation reason is required.')
        
        return value.strip()
    
    def save(self, ballot_token: BallotToken) -> BallotToken:
        """
        Revoke the ballot token with audit logging.
        
        Args:
            ballot_token: Ballot token to revoke
            
        Returns:
            BallotToken: Revoked ballot token
        """
        reason = self.validated_data['reason']
        
        # Check if token can be revoked
        if ballot_token.status in [BallotTokenStatus.USED, BallotTokenStatus.INVALIDATED]:
            raise serializers.ValidationError(
                f'Cannot revoke token with status: {ballot_token.get_status_display()}'
            )
        
        # Invalidate the token
        ballot_token.invalidate(reason=reason)
        
        # Log revocation
        request = self.context.get('request')
        if request and request.user:
            log_admin_action(
                admin_user=request.user,
                action_type=AuditActionType.TOKEN_INVALIDATED,
                description=f'Ballot token revoked: {ballot_token.token_uuid}',
                target_user=ballot_token.user,
                target_election=ballot_token.election,
                metadata={
                    'token_id': str(ballot_token.id),
                    'token_uuid': str(ballot_token.token_uuid),
                    'revocation_reason': reason,
                    'user_email': ballot_token.user.email,
                    'election_title': ballot_token.election.title,
                    'admin_user_role': request.user.role
                }
            )
        
        return ballot_token