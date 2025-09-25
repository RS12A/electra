"""
Elections admin configuration.

Django admin interface for election management.
"""
from django.contrib import admin
from django.urls import reverse
from django.utils.html import format_html
from django.utils.safestring import mark_safe

from .models import Election, ElectionStatus


@admin.register(Election)
class ElectionAdmin(admin.ModelAdmin):
    """Admin configuration for Election model."""
    
    list_display = [
        'title',
        'status',
        'status_badge',
        'voting_period',
        'created_by_name',
        'created_at',
        'is_active',
    ]
    
    list_filter = [
        'status',
        # 'created_by__role',  # Temporarily disabled for testing
        'delayed_reveal',
        'created_at',
        'start_time',
    ]
    
    search_fields = [
        'title',
        'description',
        'created_by__full_name',
        'created_by__email',
    ]
    
    readonly_fields = [
        'id',
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
    
    fieldsets = (
        ('Basic Information', {
            'fields': (
                'id',
                'title',
                'description',
                'created_by',
            )
        }),
        ('Schedule', {
            'fields': (
                'start_time',
                'end_time',
            )
        }),
        ('Status & Configuration', {
            'fields': (
                'status',
                'delayed_reveal',
            )
        }),
        ('Status Properties', {
            'fields': (
                'is_active',
                'can_vote',
                'has_started',
                'has_ended',
                'is_voting_period',
                'can_be_activated',
                'can_be_cancelled',
            ),
            'classes': ['collapse'],
        }),
        ('Audit Trail', {
            'fields': (
                'created_at',
                'updated_at',
            ),
            'classes': ['collapse'],
        }),
    )
    
    ordering = ['-created_at']
    date_hierarchy = 'created_at'
    
    def status_badge(self, obj):
        """Display status with color-coded badge."""
        colors = {
            ElectionStatus.DRAFT: 'gray',
            ElectionStatus.ACTIVE: 'green',
            ElectionStatus.COMPLETED: 'blue',
            ElectionStatus.CANCELLED: 'red',
        }
        color = colors.get(obj.status, 'gray')
        return format_html(
            '<span style="color: {}; font-weight: bold;">{}</span>',
            color,
            obj.get_status_display()
        )
    status_badge.short_description = 'Status Badge'
    
    def voting_period(self, obj):
        """Display voting period information."""
        return f"{obj.start_time.strftime('%Y-%m-%d %H:%M')} - {obj.end_time.strftime('%Y-%m-%d %H:%M')}"
    voting_period.short_description = 'Voting Period'
    
    def created_by_name(self, obj):
        """Display creator name with link."""
        url = reverse('admin:electra_auth_user_change', args=[obj.created_by.id])
        return format_html(
            '<a href="{}">{}</a>',
            url,
            obj.created_by.full_name
        )
    created_by_name.short_description = 'Created By'
    
    def get_queryset(self, request):
        """Optimize queryset with select_related."""
        qs = super().get_queryset(request)
        return qs.select_related('created_by')
    
    def has_delete_permission(self, request, obj=None):
        """Allow deletion only for draft elections."""
        if obj and obj.status != ElectionStatus.DRAFT:
            return False
        return super().has_delete_permission(request, obj)
    
    def get_readonly_fields(self, request, obj=None):
        """Make certain fields readonly based on election status."""
        readonly_fields = list(self.readonly_fields)
        
        if obj:  # Editing existing election
            # Don't allow changing creator
            readonly_fields.append('created_by')
            
            # If election has started, don't allow changing start time
            if obj.has_started:
                readonly_fields.append('start_time')
            
            # If election has ended, don't allow changing end time
            if obj.has_ended:
                readonly_fields.append('end_time')
            
            # If election is active and voting is in progress, limit changes
            if obj.status == ElectionStatus.ACTIVE and obj.is_voting_period:
                readonly_fields.extend(['title', 'description'])
        
        return readonly_fields