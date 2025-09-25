"""
Django admin configuration for the admin API module.

This module provides Django admin interface integration for admin API
models and utilities. The admin API module uses REST API endpoints 
for administration functionality rather than Django's built-in admin interface.
"""
from django.contrib import admin

# No models to register in this module as it provides API interfaces
# Admin functionality is handled through the REST API endpoints in views.py