"""
Django app configuration for notifications.
"""
from django.apps import AppConfig


class NotificationsConfig(AppConfig):
    """Configuration for the notifications app."""
    
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'electra_server.apps.notifications'
    label = 'notifications'
    verbose_name = 'Notifications'
    
    def ready(self):
        """Perform any necessary setup when the app is ready."""
        # Import signals if any
        # from . import signals
        pass