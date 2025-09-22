"""
Elections URL configuration.

URL patterns for election management endpoints.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import (
    ElectionListView,
    ElectionDetailView,
    ElectionCreateView,
    ElectionUpdateView,
    ElectionDeleteView,
    ElectionStatusView,
    ElectionViewSet
)

app_name = 'elections'

# Router for ViewSet (alternative approach)
router = DefaultRouter()
router.register(r'', ElectionViewSet, basename='election')

# Function-based URL patterns (primary approach for requirements)
urlpatterns = [
    # List and detail views
    path('', ElectionListView.as_view(), name='election_list'),
    path('<uuid:id>/', ElectionDetailView.as_view(), name='election_detail'),
    
    # Management endpoints
    path('create/', ElectionCreateView.as_view(), name='election_create'),
    path('<uuid:id>/update/', ElectionUpdateView.as_view(), name='election_update'),
    path('<uuid:id>/delete/', ElectionDeleteView.as_view(), name='election_delete'),
    path('<uuid:id>/status/', ElectionStatusView.as_view(), name='election_status'),
    
    # Alternative: ViewSet-based URLs (uncomment to use instead of function-based)
    # path('', include(router.urls)),
]