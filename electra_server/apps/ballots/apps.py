"""
Django app configuration for ballots app.
"""
from django.apps import AppConfig


class BallotsConfig(AppConfig):
    """Configuration for the ballots app."""
    
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'electra_server.apps.ballots'
    verbose_name = 'Ballots'

    def ready(self) -> None:
        """Initialize app when Django starts."""
        # Import signal handlers if needed
        pass