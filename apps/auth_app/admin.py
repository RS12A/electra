"""
Admin configuration for auth app.
"""
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, LoginAttempt


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    """Admin configuration for custom User model."""
    
    list_display = [
        'username', 'email', 'matric_staff_id', 'first_name', 'last_name',
        'is_staff_member', 'email_verified', 'is_active', 'date_joined'
    ]
    list_filter = [
        'is_active', 'is_staff', 'is_superuser', 'is_staff_member', 
        'email_verified', 'date_joined'
    ]
    search_fields = ['username', 'email', 'matric_staff_id', 'first_name', 'last_name']
    ordering = ['-date_joined']
    
    # Fieldsets for the user form
    fieldsets = UserAdmin.fieldsets + (
        ('Additional Info', {
            'fields': (
                'matric_staff_id', 'phone_number', 'date_of_birth', 
                'is_staff_member', 'email_verified', 'email_verification_token',
                'last_login_ip'
            )
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    # Fields for adding a user
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Required Info', {
            'fields': ('email', 'first_name', 'last_name', 'matric_staff_id')
        }),
        ('Optional Info', {
            'fields': ('phone_number', 'date_of_birth', 'is_staff_member')
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at', 'last_login', 'date_joined']


@admin.register(LoginAttempt)
class LoginAttemptAdmin(admin.ModelAdmin):
    """Admin configuration for LoginAttempt model."""
    
    list_display = ['email', 'ip_address', 'success', 'timestamp', 'failure_reason']
    list_filter = ['success', 'timestamp']
    search_fields = ['email', 'ip_address']
    ordering = ['-timestamp']
    readonly_fields = ['email', 'ip_address', 'user_agent', 'success', 'timestamp', 'failure_reason']
    
    def has_add_permission(self, request):
        """Disable adding login attempts through admin."""
        return False
    
    def has_change_permission(self, request, obj=None):
        """Make login attempts read-only."""
        return False
