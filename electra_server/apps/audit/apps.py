"""
Audit app configuration for electra_server.

This module contains the Django app configuration for the audit logging system.
"""
from django.apps import AppConfig


class AuditConfig(AppConfig):
    """Configuration for the audit logging app."""
    
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'electra_server.apps.audit'
    verbose_name = 'Audit Logging'
    
    def ready(self):
        """Initialize app when Django starts."""
        # Import signal handlers or other initialization code here
        pass
