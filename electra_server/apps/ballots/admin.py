"""
Admin interface for ballot models.

This module configures Django admin interface for ballot token management,
providing electoral committee and admin users with tools to monitor and
manage ballot tokens, offline queues, and usage logs.
"""
from django.contrib import admin
from django.db import models
from django.http import HttpRequest
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe

from .models import BallotToken, BallotTokenStatus, OfflineBallotQueue, BallotTokenUsageLog


@admin.register(BallotToken)
class BallotTokenAdmin(admin.ModelAdmin):
    """
    Admin interface for BallotToken model.
    
    Provides comprehensive management of ballot tokens including
    filtering, search, and security monitoring capabilities.
    """
    
    list_display = [
        'token_uuid_short', 'user_email', 'election_title', 'status',
        'is_valid_display', 'issued_at', 'expires_at', 'issued_ip'
    ]
    
    list_filter = [
        'status', 'issued_at', 'expires_at', 'election__status',
        # 'user__role'  # Temporarily disabled for testing
    ]
    
    search_fields = [
        'token_uuid', 'user__email', 'user__full_name',
        'election__title', 'issued_ip'
    ]
    
    readonly_fields = [
        'id', 'token_uuid', 'signature', 'issued_at', 'used_at',
        'invalidated_at', 'is_valid_display', 'token_data_display'
    ]
    
    fieldsets = (
        ('Token Information', {
            'fields': ('id', 'token_uuid', 'status', 'signature')
        }),
        ('Relationships', {
            'fields': ('user', 'election')
        }),
        ('Timestamps', {
            'fields': ('issued_at', 'expires_at', 'used_at', 'invalidated_at'),
            'classes': ('collapse',)
        }),
        ('Security & Audit', {
            'fields': ('issued_ip', 'issued_user_agent'),
            'classes': ('collapse',)
        }),
        ('Offline Support', {
            'fields': ('offline_data',),
            'classes': ('collapse',)
        }),
        ('Validation', {
            'fields': ('is_valid_display', 'token_data_display'),
            'classes': ('collapse',)
        })
    )
    
    # Security: Only allow electoral committee and admin to access
    def has_module_permission(self, request: HttpRequest) -> bool:
        """Check if user can access ballot token admin."""
        if not request.user.is_authenticated:
            return False
        return request.user.role in ['admin', 'electoral_committee']
    
    def has_view_permission(self, request: HttpRequest, obj=None) -> bool:
        """Check if user can view ballot tokens."""
        return self.has_module_permission(request)
    
    def has_add_permission(self, request: HttpRequest) -> bool:
        """Prevent adding tokens through admin (should use API)."""
        return False
    
    def has_change_permission(self, request: HttpRequest, obj=None) -> bool:
        """Allow limited changes for electoral committee."""
        if not self.has_module_permission(request):
            return False
        # Only allow invalidation
        return True
    
    def has_delete_permission(self, request: HttpRequest, obj=None) -> bool:
        """Prevent deletion of ballot tokens for audit trail."""
        return False
    
    # Custom display methods
    def token_uuid_short(self, obj: BallotToken) -> str:
        """Display shortened token UUID."""
        return str(obj.token_uuid)[:8] + '...'
    token_uuid_short.short_description = 'Token UUID'
    
    def user_email(self, obj: BallotToken) -> str:
        """Display user email with link to user admin."""
        url = reverse('admin:electra_auth_user_change', args=[obj.user.id])
        return format_html('<a href="{}">{}</a>', url, obj.user.email)
    user_email.short_description = 'User'
    user_email.admin_order_field = 'user__email'
    
    def election_title(self, obj: BallotToken) -> str:
        """Display election title with link to election admin."""
        url = reverse('admin:elections_election_change', args=[obj.election.id])
        return format_html('<a href="{}">{}</a>', url, obj.election.title)
    election_title.short_description = 'Election'
    election_title.admin_order_field = 'election__title'
    
    def is_valid_display(self, obj: BallotToken) -> str:
        """Display token validity status with color coding."""
        if obj.is_valid:
            return format_html(
                '<span style="color: green; font-weight: bold;">✓ Valid</span>'
            )
        elif obj.is_expired:
            return format_html(
                '<span style="color: orange; font-weight: bold;">⏰ Expired</span>'
            )
        elif obj.status == BallotTokenStatus.USED:
            return format_html(
                '<span style="color: blue; font-weight: bold;">✓ Used</span>'
            )
        elif obj.status == BallotTokenStatus.INVALIDATED:
            return format_html(
                '<span style="color: red; font-weight: bold;">✗ Invalid</span>'
            )
        else:
            return format_html(
                '<span style="color: gray; font-weight: bold;">? Unknown</span>'
            )
    is_valid_display.short_description = 'Status'
    
    def token_data_display(self, obj: BallotToken) -> str:
        """Display token data in formatted JSON."""
        import json
        token_data = obj.get_token_data()
        return format_html(
            '<pre style="font-size: 12px;">{}</pre>',
            json.dumps(token_data, indent=2)
        )
    token_data_display.short_description = 'Token Data'
    
    # Custom actions
    actions = ['invalidate_tokens']
    
    def invalidate_tokens(self, request: HttpRequest, queryset):
        """Custom action to invalidate selected tokens."""
        count = 0
        for token in queryset.filter(status=BallotTokenStatus.ISSUED):
            token.invalidate(reason=f'Invalidated by admin: {request.user.email}')
            count += 1
        
        self.message_user(
            request,
            f'Successfully invalidated {count} ballot tokens.'
        )
    invalidate_tokens.short_description = 'Invalidate selected tokens'


@admin.register(OfflineBallotQueue)
class OfflineBallotQueueAdmin(admin.ModelAdmin):
    """
    Admin interface for OfflineBallotQueue model.
    
    Provides management of offline voting queue entries and
    synchronization monitoring.
    """
    
    list_display = [
        'ballot_token_short', 'user_email', 'election_title',
        'is_synced', 'sync_attempts', 'created_at', 'synced_at'
    ]
    
    list_filter = [
        'is_synced', 'created_at', 'synced_at', 'sync_attempts',
        'ballot_token__election__title'
    ]
    
    search_fields = [
        'ballot_token__token_uuid', 'ballot_token__user__email',
        'ballot_token__election__title'
    ]
    
    readonly_fields = [
        'id', 'ballot_token', 'created_at', 'synced_at',
        'encrypted_data_preview'
    ]
    
    fieldsets = (
        ('Queue Entry', {
            'fields': ('id', 'ballot_token', 'is_synced')
        }),
        ('Sync Information', {
            'fields': ('sync_attempts', 'last_sync_error', 'created_at', 'synced_at')
        }),
        ('Encrypted Data', {
            'fields': ('encrypted_data_preview',),
            'classes': ('collapse',)
        })
    )
    
    def has_module_permission(self, request: HttpRequest) -> bool:
        """Check if user can access offline queue admin."""
        if not request.user.is_authenticated:
            return False
        return request.user.role in ['admin', 'electoral_committee']
    
    def has_view_permission(self, request: HttpRequest, obj=None) -> bool:
        """Check if user can view offline queue."""
        return self.has_module_permission(request)
    
    def has_add_permission(self, request: HttpRequest) -> bool:
        """Prevent adding queue entries through admin."""
        return False
    
    def has_change_permission(self, request: HttpRequest, obj=None) -> bool:
        """Allow limited changes for sync management."""
        return self.has_module_permission(request)
    
    def has_delete_permission(self, request: HttpRequest, obj=None) -> bool:
        """Allow deletion of synced entries only."""
        return self.has_module_permission(request)
    
    # Custom display methods
    def ballot_token_short(self, obj: OfflineBallotQueue) -> str:
        """Display shortened ballot token UUID."""
        return str(obj.ballot_token.token_uuid)[:8] + '...'
    ballot_token_short.short_description = 'Token UUID'
    
    def user_email(self, obj: OfflineBallotQueue) -> str:
        """Display user email."""
        return obj.ballot_token.user.email
    user_email.short_description = 'User'
    user_email.admin_order_field = 'ballot_token__user__email'
    
    def election_title(self, obj: OfflineBallotQueue) -> str:
        """Display election title."""
        return obj.ballot_token.election.title
    election_title.short_description = 'Election'
    election_title.admin_order_field = 'ballot_token__election__title'
    
    def encrypted_data_preview(self, obj: OfflineBallotQueue) -> str:
        """Display preview of encrypted data."""
        if len(obj.encrypted_data) > 200:
            preview = obj.encrypted_data[:200] + '...'
        else:
            preview = obj.encrypted_data
        return format_html('<pre style="font-size: 12px;">{}</pre>', preview)
    encrypted_data_preview.short_description = 'Encrypted Data Preview'


@admin.register(BallotTokenUsageLog)
class BallotTokenUsageLogAdmin(admin.ModelAdmin):
    """
    Admin interface for BallotTokenUsageLog model.
    
    Provides audit trail viewing and filtering capabilities
    for ballot token operations.
    """
    
    list_display = [
        'timestamp', 'ballot_token_short', 'user_email', 'action',
        'ip_address', 'user_agent_short'
    ]
    
    list_filter = [
        'action', 'timestamp', 'ballot_token__election__title',
        'ballot_token__status'
    ]
    
    search_fields = [
        'ballot_token__token_uuid', 'ballot_token__user__email',
        'action', 'ip_address', 'user_agent'
    ]
    
    readonly_fields = [
        'id', 'ballot_token', 'action', 'ip_address',
        'user_agent', 'metadata', 'timestamp', 'metadata_display'
    ]
    
    fieldsets = (
        ('Log Entry', {
            'fields': ('id', 'ballot_token', 'action', 'timestamp')
        }),
        ('Client Information', {
            'fields': ('ip_address', 'user_agent')
        }),
        ('Additional Data', {
            'fields': ('metadata_display',),
            'classes': ('collapse',)
        })
    )
    
    def has_module_permission(self, request: HttpRequest) -> bool:
        """Check if user can access usage log admin."""
        if not request.user.is_authenticated:
            return False
        return request.user.role in ['admin', 'electoral_committee']
    
    def has_view_permission(self, request: HttpRequest, obj=None) -> bool:
        """Check if user can view usage logs."""
        return self.has_module_permission(request)
    
    def has_add_permission(self, request: HttpRequest) -> bool:
        """Prevent adding log entries through admin."""
        return False
    
    def has_change_permission(self, request: HttpRequest, obj=None) -> bool:
        """Prevent changing log entries."""
        return False
    
    def has_delete_permission(self, request: HttpRequest, obj=None) -> bool:
        """Prevent deletion of log entries for audit trail."""
        return False
    
    # Custom display methods
    def ballot_token_short(self, obj: BallotTokenUsageLog) -> str:
        """Display shortened ballot token UUID."""
        return str(obj.ballot_token.token_uuid)[:8] + '...'
    ballot_token_short.short_description = 'Token UUID'
    
    def user_email(self, obj: BallotTokenUsageLog) -> str:
        """Display user email."""
        return obj.ballot_token.user.email
    user_email.short_description = 'User'
    user_email.admin_order_field = 'ballot_token__user__email'
    
    def user_agent_short(self, obj: BallotTokenUsageLog) -> str:
        """Display shortened user agent."""
        if len(obj.user_agent) > 50:
            return obj.user_agent[:50] + '...'
        return obj.user_agent
    user_agent_short.short_description = 'User Agent'
    
    def metadata_display(self, obj: BallotTokenUsageLog) -> str:
        """Display metadata in formatted JSON."""
        import json
        if obj.metadata:
            return format_html(
                '<pre style="font-size: 12px;">{}</pre>',
                json.dumps(obj.metadata, indent=2)
            )
        return 'No metadata'
    metadata_display.short_description = 'Metadata'