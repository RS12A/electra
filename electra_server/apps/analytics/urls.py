"""
URL configuration for analytics app.

This module defines the URL patterns for analytics API endpoints
with proper routing and security enforcement.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import AnalyticsViewSet, AnalyticsExportView, ExportVerificationView

# Create router for ViewSet
router = DefaultRouter()
router.register(r'', AnalyticsViewSet, basename='analytics')

app_name = 'analytics'

urlpatterns = [
    # Analytics data endpoints (via ViewSet)
    path('', include(router.urls)),
    
    # Export endpoint
    path('export/', AnalyticsExportView.as_view(), name='export'),
    
    # Verification endpoint
    path('verify/<str:verification_hash>/', ExportVerificationView.as_view(), name='verify'),
]