"""
Audit serializers for electra_server.

This module contains serializers for the audit logging system, providing
secure API access to audit logs with proper data validation and filtering.
"""
from typing import Dict, Any

from rest_framework import serializers
from django.contrib.auth import get_user_model

from .models import AuditLog, AuditActionType

User = get_user_model()


class AuditLogSerializer(serializers.ModelSerializer):
    """
    Serializer for audit log entries with secure field access.
    
    Provides read-only access to audit logs for administrators and
    electoral committee members with sensitive data appropriately filtered.
    """
    
    # User information (sanitized)
    user_email = serializers.CharField(
        source='user.email', 
        read_only=True,
        help_text='Email of user who performed the action'
    )
    
    user_role = serializers.CharField(
        source='user.role',
        read_only=True, 
        help_text='Role of user who performed the action'
    )
    
    # Election context
    election_title = serializers.CharField(
        source='election.title',
        read_only=True,
        help_text='Title of associated election'
    )
    
    election_status = serializers.CharField(
        source='election.status',
        read_only=True,
        help_text='Status of associated election'
    )
    
    # Display fields
    action_type_display = serializers.CharField(
        source='get_action_type_display',
        read_only=True,
        help_text='Human-readable action type'
    )
    
    outcome_display = serializers.CharField(
        source='get_outcome_display', 
        read_only=True,
        help_text='Human-readable outcome'
    )
    
    # Chain verification status
    is_chain_valid = serializers.SerializerMethodField(
        help_text='Whether this entry passes chain integrity verification'
    )
    
    is_signature_valid = serializers.SerializerMethodField(
        help_text='Whether the RSA signature is valid'
    )
    
    class Meta:
        model = AuditLog
        fields = [
            'id',
            'action_type',
            'action_type_display',
            'action_description',
            'user_email',
            'user_role',
            'user_identifier',
            'ip_address',
            'target_resource_type',
            'target_resource_id',
            'outcome',
            'outcome_display',
            'metadata',
            'error_details',
            'timestamp',
            'chain_position',
            'election_title',
            'election_status',
            'is_chain_valid',
            'is_signature_valid',
        ]
        read_only_fields = [
            'id',
            'action_type',
            'action_type_display', 
            'action_description',
            'user_email',
            'user_role',
            'user_identifier',
            'ip_address',
            'target_resource_type',
            'target_resource_id',
            'outcome',
            'outcome_display',
            'metadata',
            'error_details', 
            'timestamp',
            'chain_position',
            'election_title',
            'election_status',
            'is_chain_valid',
            'is_signature_valid',
        ]
    
    def get_is_chain_valid(self, obj: AuditLog) -> bool:
        """Check if the audit entry passes chain integrity verification."""
        try:
            return obj.verify_chain_integrity()
        except Exception:
            return False
    
    def get_is_signature_valid(self, obj: AuditLog) -> bool:
        """Check if the RSA signature is valid."""
        try:
            return obj.verify_signature()
        except Exception:
            return False


class AuditLogSummarySerializer(serializers.ModelSerializer):
    """
    Summary serializer for audit log entries with minimal data.
    
    Used for listing views where full detail is not required.
    """
    
    user_identifier = serializers.CharField(read_only=True)
    action_type_display = serializers.CharField(
        source='get_action_type_display',
        read_only=True
    )
    outcome_display = serializers.CharField(
        source='get_outcome_display',
        read_only=True
    )
    
    class Meta:
        model = AuditLog
        fields = [
            'id',
            'action_type',
            'action_type_display',
            'user_identifier',
            'outcome',
            'outcome_display', 
            'timestamp',
            'chain_position',
        ]
        read_only_fields = [
            'id',
            'action_type',
            'action_type_display',
            'user_identifier', 
            'outcome',
            'outcome_display',
            'timestamp',
            'chain_position',
        ]


class ChainVerificationSerializer(serializers.Serializer):
    """
    Serializer for audit log chain verification results.
    
    Provides detailed information about the integrity of the audit chain.
    """
    
    is_valid = serializers.BooleanField(
        read_only=True,
        help_text='Whether the entire audit chain is valid'
    )
    
    total_entries = serializers.IntegerField(
        read_only=True,
        help_text='Total number of audit entries in the chain'
    )
    
    verified_entries = serializers.IntegerField(
        read_only=True,
        help_text='Number of entries that passed verification'
    )
    
    failed_entries = serializers.ListField(
        child=serializers.DictField(),
        read_only=True,
        help_text='List of entries that failed verification'
    )
    
    chain_breaks = serializers.ListField(
        child=serializers.IntegerField(),
        read_only=True,
        help_text='Chain positions where hash chain is broken'
    )
    
    signature_failures = serializers.ListField(
        child=serializers.IntegerField(),
        read_only=True,
        help_text='Chain positions where RSA signature verification failed'
    )
    
    verification_timestamp = serializers.DateTimeField(
        read_only=True,
        help_text='When the verification was performed'
    )
    
    verified_by = serializers.CharField(
        read_only=True,
        help_text='User who requested the verification'
    )


class AuditActionTypeSerializer(serializers.Serializer):
    """
    Serializer for audit action types.
    
    Provides information about available audit action types for filtering.
    """
    
    value = serializers.CharField(
        read_only=True,
        help_text='Action type value'
    )
    
    label = serializers.CharField(
        read_only=True,
        help_text='Human-readable action type label'
    )
    
    category = serializers.SerializerMethodField(
        help_text='Category of the action type'
    )
    
    def get_category(self, obj) -> str:
        """Determine the category of the action type."""
        value = obj[0] if isinstance(obj, tuple) else obj
        
        if value.startswith('user_'):
            return 'authentication'
        elif value.startswith('election_'):
            return 'election_management'
        elif value.startswith('token_'):
            return 'ballot_tokens'
        elif value.startswith('vote_'):
            return 'voting'
        else:
            return 'system'


class AuditStatsSerializer(serializers.Serializer):
    """
    Serializer for audit statistics and metrics.
    
    Provides summary statistics about audit log activity.
    """
    
    total_entries = serializers.IntegerField(
        read_only=True,
        help_text='Total number of audit entries'
    )
    
    entries_last_24h = serializers.IntegerField(
        read_only=True,
        help_text='Audit entries in the last 24 hours'
    )
    
    entries_last_7d = serializers.IntegerField(
        read_only=True,
        help_text='Audit entries in the last 7 days'
    )
    
    action_type_breakdown = serializers.DictField(
        read_only=True,
        help_text='Breakdown of entries by action type'
    )
    
    outcome_breakdown = serializers.DictField(
        read_only=True,
        help_text='Breakdown of entries by outcome'
    )
    
    user_activity = serializers.DictField(
        read_only=True,
        help_text='Top user activity (anonymized for privacy)'
    )
    
    chain_integrity = serializers.DictField(
        read_only=True,
        help_text='Chain integrity status summary'
    )