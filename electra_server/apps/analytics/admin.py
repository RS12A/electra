"""
Admin configuration for analytics models.

This module provides Django admin interface for analytics data,
including cache management and export verification.
"""
from django.contrib import admin
from django.utils.html import format_html
from django.utils import timezone
from .models import AnalyticsCache, ExportVerification


@admin.register(AnalyticsCache)
class AnalyticsCacheAdmin(admin.ModelAdmin):
    """Admin configuration for AnalyticsCache model."""
    
    list_display = [
        'cache_key',
        'election_title',
        'created_at',
        'expires_at',
        'is_expired_badge',
        'access_count',
        'calculation_duration',
    ]
    
    list_filter = [
        'created_at',
        'expires_at',
        'election',
    ]
    
    search_fields = [
        'cache_key',
        'election__title',
        'election__description',
    ]
    
    readonly_fields = [
        'id',
        'data_hash',
        'created_at',
        'last_accessed',
        'access_count',
        'is_expired_badge',
        'data_preview',
    ]
    
    fieldsets = (
        ('Basic Information', {
            'fields': (
                'id',
                'cache_key',
                'election',
            )
        }),
        ('Cache Data', {
            'fields': (
                'data_preview',
                'data_hash',
                'calculation_duration',
            )
        }),
        ('Expiration & Access', {
            'fields': (
                'expires_at',
                'is_expired_badge',
                'last_accessed',
                'access_count',
            )
        }),
        ('Timestamps', {
            'fields': (
                'created_at',
            ),
            'classes': ['collapse'],
        }),
    )
    
    ordering = ['-created_at']
    date_hierarchy = 'created_at'
    
    def election_title(self, obj):
        """Display election title or 'Global' if no election."""
        return obj.election.title if obj.election else 'Global Analytics'
    election_title.short_description = 'Election'
    
    def is_expired_badge(self, obj):
        """Display expiration status with color-coded badge."""
        if obj.is_expired():
            return format_html(
                '<span style="color: red; font-weight: bold;">Expired</span>'
            )
        else:
            return format_html(
                '<span style="color: green; font-weight: bold;">Valid</span>'
            )
    is_expired_badge.short_description = 'Status'
    
    def data_preview(self, obj):
        """Display a preview of the cached data."""
        if not obj.data:
            return 'No data'
        
        # Show basic structure
        data_keys = list(obj.data.keys()) if isinstance(obj.data, dict) else ['Raw data']
        return f"Keys: {', '.join(data_keys[:5])}"
    data_preview.short_description = 'Data Preview'
    
    actions = ['cleanup_expired_cache', 'force_refresh_cache']
    
    def cleanup_expired_cache(self, request, queryset):
        """Action to cleanup expired cache entries."""
        expired_count = 0
        for cache_entry in queryset:
            if cache_entry.is_expired():
                cache_entry.delete()
                expired_count += 1
        
        self.message_user(
            request,
            f"Cleaned up {expired_count} expired cache entries."
        )
    cleanup_expired_cache.short_description = "Cleanup expired cache entries"
    
    def force_refresh_cache(self, request, queryset):
        """Action to mark cache entries for refresh (by deleting them)."""
        count = queryset.count()
        queryset.delete()
        
        self.message_user(
            request,
            f"Marked {count} cache entries for refresh."
        )
    force_refresh_cache.short_description = "Force refresh selected cache entries"


@admin.register(ExportVerification)
class ExportVerificationAdmin(admin.ModelAdmin):
    """Admin configuration for ExportVerification model."""
    
    list_display = [
        'filename',
        'export_type',
        'requested_by_name',
        'file_size_formatted',
        'created_at',
        'request_ip',
        'verification_status',
    ]
    
    list_filter = [
        'export_type',
        'created_at',
        'requested_by__role',
    ]
    
    search_fields = [
        'filename',
        'requested_by__full_name',
        'requested_by__email',
        'verification_hash',
        'content_hash',
    ]
    
    readonly_fields = [
        'id',
        'content_hash',
        'verification_hash',
        'file_size_formatted',
        'created_at',
        'export_params_formatted',
    ]
    
    fieldsets = (
        ('Export Information', {
            'fields': (
                'id',
                'filename',
                'export_type',
                'file_size_formatted',
            )
        }),
        ('Verification', {
            'fields': (
                'content_hash',
                'verification_hash',
            )
        }),
        ('Request Details', {
            'fields': (
                'requested_by',
                'request_ip',
                'export_params_formatted',
            )
        }),
        ('Timestamps', {
            'fields': (
                'created_at',
            ),
            'classes': ['collapse'],
        }),
    )
    
    ordering = ['-created_at']
    date_hierarchy = 'created_at'
    
    def requested_by_name(self, obj):
        """Display the name of the user who requested the export."""
        return obj.requested_by.full_name
    requested_by_name.short_description = 'Requested By'
    
    def file_size_formatted(self, obj):
        """Display file size in human-readable format."""
        size = obj.file_size
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size < 1024.0:
                return f"{size:.1f} {unit}"
            size /= 1024.0
        return f"{size:.1f} TB"
    file_size_formatted.short_description = 'File Size'
    
    def verification_status(self, obj):
        """Display verification status badge."""
        return format_html(
            '<span style="color: green; font-weight: bold;">Verified</span>'
        )
    verification_status.short_description = 'Status'
    
    def export_params_formatted(self, obj):
        """Display export parameters in a readable format."""
        if not obj.export_params:
            return 'No parameters'
        
        params = []
        for key, value in obj.export_params.items():
            if value is not None and value != '':
                params.append(f"{key}: {value}")
        
        return '; '.join(params) if params else 'Default parameters'
    export_params_formatted.short_description = 'Export Parameters'
    
    def has_add_permission(self, request):
        """Disable adding export verifications through admin."""
        return False
    
    def has_change_permission(self, request, obj=None):
        """Disable changing export verifications through admin."""
        return False
    
    def has_delete_permission(self, request, obj=None):
        """Allow deletion for cleanup purposes."""
        return request.user.is_superuser