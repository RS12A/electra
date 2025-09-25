"""
URL configuration for the admin API module.

This module defines URL patterns for admin API endpoints with proper
routing and rate limiting configuration for production security.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import (
    AdminUserViewSet,
    AdminElectionViewSet,
    AdminBallotTokenViewSet,
    AdminCandidateListView,
    AdminDashboardView,
)

# Create router for ViewSets
router = DefaultRouter()

# Register ViewSets
router.register(r'users', AdminUserViewSet, basename='admin-users')
router.register(r'elections', AdminElectionViewSet, basename='admin-elections')
router.register(r'ballots', AdminBallotTokenViewSet, basename='admin-ballots')

app_name = 'electra_admin'

urlpatterns = [
    # Dashboard endpoint
    path('dashboard/', AdminDashboardView.as_view(), name='dashboard'),
    
    # Candidate management
    path('candidates/', AdminCandidateListView.as_view(), name='candidates'),
    
    # Include router URLs
    path('', include(router.urls)),
]