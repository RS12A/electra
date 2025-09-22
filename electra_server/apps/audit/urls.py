"""
Audit URL configuration for electra_server.

This module defines URL patterns for the audit logging system API endpoints.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter

from . import views

app_name = 'audit'

# API URL patterns
api_urlpatterns = [
    # Audit log endpoints
    path('logs/', views.AuditLogListView.as_view(), name='audit-logs-list'),
    path('logs/<uuid:pk>/', views.AuditLogDetailView.as_view(), name='audit-log-detail'),
    
    # Chain verification endpoint
    path('verify/', views.verify_audit_chain, name='audit-verify-chain'),
    
    # Metadata endpoints
    path('action-types/', views.audit_action_types, name='audit-action-types'),
    path('stats/', views.audit_stats, name='audit-stats'),
]

urlpatterns = [
    # Include API endpoints under /api/audit/
    path('api/audit/', include(api_urlpatterns)),
]