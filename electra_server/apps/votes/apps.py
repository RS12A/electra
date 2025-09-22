"""
Votes app configuration for electra_server.
"""
from django.apps import AppConfig


class VotesConfig(AppConfig):
    """Configuration for the votes app."""

    default_auto_field = "django.db.models.BigAutoField"
    name = "electra_server.apps.votes"
    verbose_name = "Vote Casting"
