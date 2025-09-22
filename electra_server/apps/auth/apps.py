"""
Authentication app configuration for electra_server.
"""
from django.apps import AppConfig


class AuthConfig(AppConfig):
    """Configuration for the auth app."""
    
    default_auto_field: str = 'django.db.models.BigAutoField'
    name: str = 'electra_server.apps.auth'
    label: str = 'electra_auth'  # Unique label to avoid conflict with django.contrib.auth
    verbose_name: str = 'Authentication'
    
    def ready(self) -> None:
        """Import signals when the app is ready."""
        # Import any signals here if needed
        pass