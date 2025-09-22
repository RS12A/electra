"""
Audit admin configuration for electra_server.

This module contains admin interface configuration for the audit logging
system with read-only access and advanced filtering capabilities.
"""
from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe

from .models import AuditLog, AuditActionType


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    """
    Admin interface for audit logs with read-only access and filtering.
    
    Provides comprehensive view of audit entries with tamper-proof
    verification status and chain integrity information.
    """
    
    # Read-only interface - no modifications allowed
    def has_add_permission(self, request):
        return False
    
    def has_change_permission(self, request, obj=None):
        return False
    
    def has_delete_permission(self, request, obj=None):
        return False
    
    # List display configuration
    list_display = [
        'chain_position',
        'timestamp',
        'action_type_colored',
        'user_display',
        'outcome_colored',
        'target_resource',
        'verification_status',
        'ip_address',
    ]
    
    list_filter = [
        'action_type',
        'outcome',
        'timestamp',
        'user__role',
        'target_resource_type',
        'is_sealed',
    ]
    
    search_fields = [
        'action_description',
        'user__email',
        'user_identifier',
        'ip_address',
        'target_resource_id',
    ]
    
    ordering = ['-chain_position', '-timestamp']
    
    date_hierarchy = 'timestamp'
    
    # Fieldsets for detailed view
    fieldsets = [
        ('Chain Information', {
            'fields': [
                'chain_position',
                'content_hash',
                'previous_hash',
                'signature_display',
                'is_sealed',
            ]
        }),
        ('Action Details', {
            'fields': [
                'action_type',
                'action_description',
                'outcome',
                'timestamp',
            ]
        }),
        ('User Context', {
            'fields': [
                'user',
                'user_identifier',
                'session_key',
            ]
        }),
        ('Request Context', {
            'fields': [
                'ip_address',
                'user_agent',
            ]
        }),
        ('Target Resource', {
            'fields': [
                'election',
                'target_resource_type',
                'target_resource_id',
            ]
        }),
        ('Metadata', {
            'fields': [
                'metadata_display',
                'error_details',
            ],
            'classes': ['collapse']
        }),
    ]
    
    readonly_fields = [
        'chain_position',
        'content_hash', 
        'previous_hash',
        'signature_display',
        'is_sealed',
        'action_type',
        'action_description',
        'outcome',
        'timestamp',
        'user',
        'user_identifier',
        'session_key',
        'ip_address',
        'user_agent',
        'election',
        'target_resource_type',
        'target_resource_id',
        'metadata_display',
        'error_details',
    ]
    
    # Custom display methods
    def action_type_colored(self, obj):
        """Display action type with color coding."""
        color_map = {
            'user_login': 'green',
            'user_logout': 'blue', 
            'user_login_failed': 'red',
            'election_created': 'purple',
            'election_updated': 'orange',
            'token_issued': 'teal',
            'vote_cast': 'darkgreen',
            'vote_failed': 'red',
            'system_error': 'red',
        }
        
        color = color_map.get(obj.action_type, 'black')
        return format_html(
            '<span style="color: {};">{}</span>',
            color,
            obj.get_action_type_display()
        )
    action_type_colored.short_description = 'Action Type'
    action_type_colored.admin_order_field = 'action_type'
    
    def outcome_colored(self, obj):
        """Display outcome with color coding."""
        color_map = {
            'success': 'green',
            'failure': 'orange',
            'error': 'red',
            'warning': 'gold',
        }
        
        color = color_map.get(obj.outcome, 'black')
        return format_html(
            '<span style="color: {}; font-weight: bold;">{}</span>',
            color,
            obj.get_outcome_display()
        )
    outcome_colored.short_description = 'Outcome'
    outcome_colored.admin_order_field = 'outcome'
    
    def user_display(self, obj):
        """Display user information with role."""
        if obj.user:
            return f"{obj.user.email} ({obj.user.get_role_display()})"
        elif obj.user_identifier:
            return f"{obj.user_identifier} (System)"
        return "System"
    user_display.short_description = 'User'
    user_display.admin_order_field = 'user__email'
    
    def target_resource(self, obj):
        """Display target resource information."""
        if obj.target_resource_type and obj.target_resource_id:
            return f"{obj.target_resource_type}: {obj.target_resource_id[:20]}..."
        return "-"
    target_resource.short_description = 'Target Resource'
    
    def verification_status(self, obj):
        """Display chain verification status with icons."""
        try:
            is_valid = obj.verify_chain_integrity()
            signature_valid = obj.verify_signature()
            
            if is_valid and signature_valid:
                return format_html(
                    '<span style="color: green;" title="Chain and signature valid">✓ Valid</span>'
                )
            elif not signature_valid:
                return format_html(
                    '<span style="color: red;" title="Invalid signature">✗ Sig. Invalid</span>'
                )
            else:
                return format_html(
                    '<span style="color: orange;" title="Chain integrity issues">⚠ Chain Issue</span>'
                )
        except Exception:
            return format_html(
                '<span style="color: gray;" title="Verification error">? Unknown</span>'
            )
    verification_status.short_description = 'Verification'
    
    def signature_display(self, obj):
        """Display signature information in a readable format."""
        if obj.signature:
            return format_html(
                '<code title="{}...">{}</code>',
                obj.signature,
                obj.signature[:32] + '...'
            )
        return "No signature"
    signature_display.short_description = 'Digital Signature'
    
    def metadata_display(self, obj):
        """Display metadata in a formatted way."""
        if obj.metadata:
            import json
            formatted_json = json.dumps(obj.metadata, indent=2)
            return format_html('<pre>{}</pre>', formatted_json)
        return "No metadata"
    metadata_display.short_description = 'Metadata'
    
    # Custom actions
    actions = ['verify_selected_entries']
    
    def verify_selected_entries(self, request, queryset):
        """Verify integrity of selected audit entries."""
        verified_count = 0
        failed_count = 0
        
        for entry in queryset:
            try:
                if entry.verify_chain_integrity():
                    verified_count += 1
                else:
                    failed_count += 1
            except Exception:
                failed_count += 1
        
        if failed_count == 0:
            message = f"All {verified_count} selected entries passed verification."
            self.message_user(request, message)
        else:
            message = f"Verification results: {verified_count} passed, {failed_count} failed."
            self.message_user(request, message, level='WARNING')
    
    verify_selected_entries.short_description = "Verify chain integrity of selected entries"
    
    # Custom list per page
    list_per_page = 25
    list_max_show_all = 100
    
    # Additional admin configuration
    save_on_top = False
    preserve_filters = True
