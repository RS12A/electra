"""
URL configuration for the core app.
"""

from django.urls import path
from . import views

app_name = 'electra_core'

urlpatterns = [
    path('health/', views.health_check, name='health_check'),
    path('ping/', views.simple_health, name='simple_health'),
]