"""
Votes URL configuration for electra_server.

This module contains URL patterns for vote casting, verification,
and management endpoints.
"""
from django.urls import path

from . import views

# API URL patterns
urlpatterns = [
    # Vote casting endpoint
    path("cast/", views.VoteCastView.as_view(), name="vote-cast"),
    # Vote verification endpoint
    path("verify/", views.VoteVerifyView.as_view(), name="vote-verify"),
    # Vote status endpoint
    path(
        "status/<uuid:vote_token>/", views.VoteStatusView.as_view(), name="vote-status"
    ),
    # Offline vote management
    path(
        "offline-queue/",
        views.OfflineVoteQueueView.as_view(),
        name="offline-vote-queue",
    ),
    path(
        "offline-submit/",
        views.OfflineVoteSubmissionView.as_view(),
        name="offline-vote-submit",
    ),
    # Audit logs (admin only)
    path("audit-logs/", views.VoteAuditLogView.as_view(), name="vote-audit-logs"),
]

app_name = "votes"
