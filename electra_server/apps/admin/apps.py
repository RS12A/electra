"""
Django application configuration for the admin API module.
"""
from django.apps import AppConfig


class AdminConfig(AppConfig):
    """Configuration class for the admin API application."""
    
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'electra_server.apps.admin'
    label = 'electra_admin'
    verbose_name = 'Admin API'
    
    def ready(self) -> None:
        """Perform any necessary setup when the app is ready."""
        # Import signals if any
        # from . import signals
        pass