"""
Django admin configuration for authentication models.

This module provides a comprehensive admin interface for managing users,
login attempts, and password reset OTPs with proper filtering and search.
"""
from typing import List, Tuple, Optional, Any
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.forms import UserChangeForm, UserCreationForm
from django.core.exceptions import ValidationError
from django.db import models
from django.forms import ModelForm
from django.utils.html import format_html
from django.utils import timezone

from .models import User, UserRole, PasswordResetOTP, LoginAttempt


class CustomUserCreationForm(UserCreationForm):
    """
    Custom user creation form for Django admin.
    """
    
    class Meta:
        model = User
        fields = ('email', 'full_name', 'role', 'matric_number', 'staff_id')
    
    def clean(self):
        """Validate form data."""
        cleaned_data = super().clean()
        role = cleaned_data.get('role')
        matric_number = cleaned_data.get('matric_number')
        staff_id = cleaned_data.get('staff_id')
        
        # Role-based validation
        if role == UserRole.STUDENT:
            if not matric_number:
                raise ValidationError('Students must have a matriculation number.')
            if staff_id:
                cleaned_data['staff_id'] = None  # Clear staff_id for students
        elif role in [UserRole.STAFF, UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]:
            if not staff_id:
                raise ValidationError(f'{role.title()} must have a staff ID.')
            if matric_number:
                cleaned_data['matric_number'] = None  # Clear matric_number for staff
        
        return cleaned_data


class CustomUserChangeForm(UserChangeForm):
    """
    Custom user change form for Django admin.
    """
    
    class Meta:
        model = User
        fields = '__all__'


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """
    Admin interface for User model.
    """
    
    form = CustomUserChangeForm
    add_form = CustomUserCreationForm
    
    # List display
    list_display = (
        'email', 'full_name', 'role', 'get_identifier', 
        'is_active', 'is_staff', 'date_joined', 'last_login'
    )
    
    list_filter = (
        'role', 'is_active', 'is_staff', 'is_superuser', 'date_joined'
    )
    
    search_fields = (
        'email', 'full_name', 'matric_number', 'staff_id'
    )
    
    ordering = ('-date_joined',)
    
    # Fieldsets for viewing/editing
    fieldsets = (
        ('Personal Information', {
            'fields': ('email', 'full_name', 'role')
        }),
        ('Identification', {
            'fields': ('matric_number', 'staff_id'),
            'description': 'Students should have matric_number, staff should have staff_id'
        }),
        ('Permissions', {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions'),
            'classes': ('collapse',)
        }),
        ('Important dates', {
            'fields': ('last_login', 'date_joined', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    # Fieldsets for adding new user
    add_fieldsets = (
        ('Required Information', {
            'classes': ('wide',),
            'fields': ('email', 'password1', 'password2', 'full_name', 'role')
        }),
        ('Identification', {
            'classes': ('wide',),
            'fields': ('matric_number', 'staff_id'),
            'description': 'Provide either matric_number (for students) or staff_id (for staff/admin)'
        }),
        ('Permissions', {
            'classes': ('wide', 'collapse'),
            'fields': ('is_active', 'is_staff', 'is_superuser')
        }),
    )
    
    readonly_fields = ('id', 'created_at', 'updated_at', 'last_login', 'date_joined')
    
    filter_horizontal = ('groups', 'user_permissions')
    
    # Custom display methods
    def get_identifier(self, obj: User) -> str:
        """Get user identifier based on role."""
        if obj.role == UserRole.STUDENT:
            return obj.matric_number or 'No Matric Number'
        else:
            return obj.staff_id or 'No Staff ID'
    
    get_identifier.short_description = 'Identifier'
    get_identifier.admin_order_field = 'matric_number'
    
    def get_queryset(self, request):
        """Optimize queryset."""
        return super().get_queryset(request).select_related()
    
    def save_model(self, request, obj, form, change):
        """Custom save logic."""
        # Log admin changes
        if change:
            import logging
            logger = logging.getLogger(__name__)
            logger.info(f"User {obj.email} updated by admin {request.user.email}")
        
        super().save_model(request, obj, form, change)
    
    # Custom actions
    def make_active(self, request, queryset):
        """Activate selected users."""
        count = queryset.update(is_active=True)
        self.message_user(request, f'{count} users were successfully activated.')
    
    make_active.short_description = "Activate selected users"
    
    def make_inactive(self, request, queryset):
        """Deactivate selected users."""
        count = queryset.update(is_active=False)
        self.message_user(request, f'{count} users were successfully deactivated.')
    
    make_inactive.short_description = "Deactivate selected users"
    
    actions = ['make_active', 'make_inactive']


@admin.register(PasswordResetOTP)
class PasswordResetOTPAdmin(admin.ModelAdmin):
    """
    Admin interface for PasswordResetOTP model.
    """
    
    list_display = (
        'user_email', 'user_name', 'otp_code', 'status',
        'created_at', 'expires_at', 'ip_address'
    )
    
    list_filter = (
        'is_used', 'created_at', 'expires_at'
    )
    
    search_fields = (
        'user__email', 'user__full_name', 'otp_code', 'ip_address'
    )
    
    readonly_fields = (
        'id', 'user', 'otp_code', 'created_at', 'expires_at',
        'ip_address', 'status_display'
    )
    
    ordering = ('-created_at',)
    
    # Custom display methods
    def user_email(self, obj: PasswordResetOTP) -> str:
        """Get user email."""
        return obj.user.email
    
    user_email.short_description = 'User Email'
    user_email.admin_order_field = 'user__email'
    
    def user_name(self, obj: PasswordResetOTP) -> str:
        """Get user name."""
        return obj.user.full_name
    
    user_name.short_description = 'User Name'
    user_name.admin_order_field = 'user__full_name'
    
    def status(self, obj: PasswordResetOTP) -> str:
        """Get OTP status with color."""
        if obj.is_used:
            return format_html('<span style="color: green;">Used</span>')
        elif obj.is_expired():
            return format_html('<span style="color: red;">Expired</span>')
        else:
            return format_html('<span style="color: orange;">Active</span>')
    
    status.short_description = 'Status'
    
    def status_display(self, obj: PasswordResetOTP) -> str:
        """Status for readonly field."""
        if obj.is_used:
            return 'Used'
        elif obj.is_expired():
            return 'Expired'
        else:
            return 'Active'
    
    status_display.short_description = 'Status'
    
    def has_add_permission(self, request):
        """Don't allow manual creation of OTPs."""
        return False
    
    def has_change_permission(self, request, obj=None):
        """Don't allow editing of OTPs."""
        return False
    
    # Custom actions
    def cleanup_expired(self, request, queryset):
        """Clean up expired/used OTPs."""
        count = PasswordResetOTP.objects.cleanup_expired()
        self.message_user(request, f'{count} expired/used OTPs were cleaned up.')
    
    cleanup_expired.short_description = "Clean up expired/used OTPs"
    
    actions = ['cleanup_expired']


@admin.register(LoginAttempt)
class LoginAttemptAdmin(admin.ModelAdmin):
    """
    Admin interface for LoginAttempt model.
    """
    
    list_display = (
        'email', 'user_name', 'success_display', 'failure_reason',
        'ip_address', 'timestamp'
    )
    
    list_filter = (
        'success', 'timestamp', 'failure_reason'
    )
    
    search_fields = (
        'email', 'user__full_name', 'ip_address', 'user_agent'
    )
    
    readonly_fields = (
        'id', 'email', 'user', 'ip_address', 'user_agent',
        'success', 'failure_reason', 'timestamp'
    )
    
    ordering = ('-timestamp',)
    
    date_hierarchy = 'timestamp'
    
    # Custom display methods
    def user_name(self, obj: LoginAttempt) -> str:
        """Get user name if available."""
        return obj.user.full_name if obj.user else 'Unknown User'
    
    user_name.short_description = 'User Name'
    user_name.admin_order_field = 'user__full_name'
    
    def success_display(self, obj: LoginAttempt) -> str:
        """Display success status with color."""
        if obj.success:
            return format_html('<span style="color: green;">✓ Success</span>')
        else:
            return format_html('<span style="color: red;">✗ Failed</span>')
    
    success_display.short_description = 'Status'
    success_display.admin_order_field = 'success'
    
    def has_add_permission(self, request):
        """Don't allow manual creation of login attempts."""
        return False
    
    def has_change_permission(self, request, obj=None):
        """Don't allow editing of login attempts."""
        return False
    
    # Custom actions
    def cleanup_old_attempts(self, request, queryset):
        """Clean up old login attempts."""
        count = LoginAttempt.objects.cleanup_old_attempts()
        self.message_user(request, f'{count} old login attempts were cleaned up.')
    
    cleanup_old_attempts.short_description = "Clean up old login attempts (30+ days)"
    
    actions = ['cleanup_old_attempts']


# Admin site customizations
admin.site.site_header = 'Electra Administration'
admin.site.site_title = 'Electra Admin'
admin.site.index_title = 'Welcome to Electra Administration'