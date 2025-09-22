"""
Election serializers for electra_server.

This module contains DRF serializers for Election model CRUD operations
with proper validation and security controls.
"""
from typing import Dict, Any
from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework import serializers

from .models import Election, ElectionStatus

User = get_user_model()


class ElectionListSerializer(serializers.ModelSerializer):
    """Serializer for listing elections (minimal fields for performance)."""
    
    created_by_name = serializers.CharField(
        source='created_by.full_name',
        read_only=True
    )
    
    is_active = serializers.BooleanField(read_only=True)
    can_vote = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = Election
        fields = [
            'id',
            'title',
            'status',
            'start_time',
            'end_time',
            'created_by_name',
            'is_active',
            'can_vote',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class ElectionDetailSerializer(serializers.ModelSerializer):
    """Serializer for detailed election view with all fields."""
    
    created_by_name = serializers.CharField(
        source='created_by.full_name',
        read_only=True
    )
    
    created_by_role = serializers.CharField(
        source='created_by.role',
        read_only=True
    )
    
    # Status properties
    is_active = serializers.BooleanField(read_only=True)
    can_vote = serializers.BooleanField(read_only=True)
    has_started = serializers.BooleanField(read_only=True)
    has_ended = serializers.BooleanField(read_only=True)
    is_voting_period = serializers.BooleanField(read_only=True)
    
    # Action availability
    can_be_activated = serializers.SerializerMethodField()
    can_be_cancelled = serializers.SerializerMethodField()
    
    class Meta:
        model = Election
        fields = [
            'id',
            'title',
            'description',
            'start_time',
            'end_time',
            'status',
            'delayed_reveal',
            'created_by',
            'created_by_name',
            'created_by_role',
            'created_at',
            'updated_at',
            'is_active',
            'can_vote',
            'has_started',
            'has_ended',
            'is_voting_period',
            'can_be_activated',
            'can_be_cancelled',
        ]
        read_only_fields = [
            'id',
            'created_by',
            'created_at',
            'updated_at',
        ]
    
    def get_can_be_activated(self, obj: Election) -> bool:
        """Get whether the election can be activated."""
        return obj.can_be_activated()
    
    def get_can_be_cancelled(self, obj: Election) -> bool:
        """Get whether the election can be cancelled."""
        return obj.can_be_cancelled()


class ElectionCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating new elections."""
    
    class Meta:
        model = Election
        fields = [
            'title',
            'description',
            'start_time',
            'end_time',
            'delayed_reveal',
        ]
    
    def validate_start_time(self, value):
        """Validate start time is in the future."""
        if value <= timezone.now():
            raise serializers.ValidationError(
                "Start time must be in the future."
            )
        return value
    
    def validate_end_time(self, value):
        """Validate end time."""
        # Basic validation - more detailed validation in validate()
        if value <= timezone.now():
            raise serializers.ValidationError(
                "End time must be in the future."
            )
        return value
    
    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """Cross-field validation."""
        start_time = attrs.get('start_time')
        end_time = attrs.get('end_time')
        
        if start_time and end_time:
            if start_time >= end_time:
                raise serializers.ValidationError({
                    'end_time': 'End time must be after start time.'
                })
            
            # Ensure minimum election duration (e.g., 1 hour)
            min_duration = timezone.timedelta(hours=1)
            if end_time - start_time < min_duration:
                raise serializers.ValidationError({
                    'end_time': 'Election must run for at least 1 hour.'
                })
        
        return attrs
    
    def create(self, validated_data: Dict[str, Any]) -> Election:
        """Create election with current user as creator."""
        user = self.context['request'].user
        validated_data['created_by'] = user
        return super().create(validated_data)


class ElectionUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating existing elections."""
    
    class Meta:
        model = Election
        fields = [
            'title',
            'description',
            'start_time',
            'end_time',
            'delayed_reveal',
        ]
    
    def validate_start_time(self, value):
        """Validate start time based on election status."""
        election = self.instance
        
        # If election has started, don't allow changing start time
        if election and election.has_started:
            if value != election.start_time:
                raise serializers.ValidationError(
                    "Cannot change start time of an election that has started."
                )
        
        # For elections that haven't started, ensure future time
        elif value <= timezone.now():
            raise serializers.ValidationError(
                "Start time must be in the future."
            )
        
        return value
    
    def validate_end_time(self, value):
        """Validate end time based on election status."""
        election = self.instance
        
        # If election has ended, don't allow changing end time
        if election and election.has_ended:
            if value != election.end_time:
                raise serializers.ValidationError(
                    "Cannot change end time of an election that has ended."
                )
        
        # Ensure future time
        elif value <= timezone.now():
            raise serializers.ValidationError(
                "End time must be in the future."
            )
        
        return value
    
    def validate(self, attrs: Dict[str, Any]) -> Dict[str, Any]:
        """Cross-field validation for updates."""
        election = self.instance
        
        start_time = attrs.get('start_time', election.start_time)
        end_time = attrs.get('end_time', election.end_time)
        
        if start_time >= end_time:
            raise serializers.ValidationError({
                'end_time': 'End time must be after start time.'
            })
        
        # Ensure minimum election duration
        min_duration = timezone.timedelta(hours=1)
        if end_time - start_time < min_duration:
            raise serializers.ValidationError({
                'end_time': 'Election must run for at least 1 hour.'
            })
        
        # Don't allow changes to active elections during voting period
        if election.status == ElectionStatus.ACTIVE and election.is_voting_period:
            # Only allow delayed_reveal changes during active voting
            allowed_fields = {'delayed_reveal'}
            changed_fields = set(attrs.keys()) - allowed_fields
            if changed_fields:
                raise serializers.ValidationError(
                    "Cannot modify election details while voting is in progress. "
                    f"Attempted to change: {', '.join(changed_fields)}"
                )
        
        return attrs


class ElectionStatusSerializer(serializers.Serializer):
    """Serializer for election status changes."""
    
    action = serializers.ChoiceField(
        choices=['activate', 'cancel', 'complete'],
        help_text='Action to perform on the election'
    )
    
    def validate_action(self, value):
        """Validate the action can be performed on the election."""
        election = self.instance
        
        if value == 'activate' and not election.can_be_activated():
            raise serializers.ValidationError(
                "Election cannot be activated. It must be in draft status and "
                "have a future start time."
            )
        elif value == 'cancel' and not election.can_be_cancelled():
            raise serializers.ValidationError(
                "Election cannot be cancelled. It must be in draft or active status."
            )
        elif value == 'complete':
            if election.status != ElectionStatus.ACTIVE:
                raise serializers.ValidationError(
                    "Only active elections can be marked as completed."
                )
        
        return value