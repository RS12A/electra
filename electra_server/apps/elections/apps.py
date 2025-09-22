"""
Elections app configuration.
"""
from django.apps import AppConfig


class ElectionsConfig(AppConfig):
    """Configuration for the elections app."""
    
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'electra_server.apps.elections'
    verbose_name = 'Elections'