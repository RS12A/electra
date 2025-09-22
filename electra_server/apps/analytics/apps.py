"""
Analytics app configuration for electra_server.

This app provides comprehensive analytics and reporting functionality
for voter participation and turnout metrics.
"""
from django.apps import AppConfig


class AnalyticsConfig(AppConfig):
    """Analytics app configuration."""
    
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'electra_server.apps.analytics'
    verbose_name = 'Analytics'
    
    def ready(self) -> None:
        """Initialize app when Django starts."""
        # Import signals if needed
        pass