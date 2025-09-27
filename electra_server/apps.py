"""
Django app configuration for electra_server.
"""
from django.apps import AppConfig


class ElectraServerConfig(AppConfig):
    """Configuration for the electra_server app."""
    
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'electra_server'
    verbose_name = 'Electra Server'
    
    def ready(self):
        """Initialize the app when ready."""
        pass