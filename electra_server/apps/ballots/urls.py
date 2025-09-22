"""
URL patterns for ballot endpoints.
"""
from django.urls import path

from .views import (
    BallotTokenRequestView,
    BallotTokenValidateView, 
    UserBallotTokensView,
    BallotTokenDetailView,
    OfflineBallotQueueView,
    OfflineBallotSubmissionView,
    BallotTokenStatsView,
    BallotTokenUsageLogView,
)

app_name = 'ballots'

urlpatterns = [
    # Token management endpoints
    path('request-token/', BallotTokenRequestView.as_view(), name='request_token'),
    path('validate-token/', BallotTokenValidateView.as_view(), name='validate_token'),
    
    # User token endpoints
    path('my-tokens/', UserBallotTokensView.as_view(), name='user_tokens'),
    path('tokens/<uuid:id>/', BallotTokenDetailView.as_view(), name='token_detail'),
    
    # Offline support endpoints
    path('offline-queue/', OfflineBallotQueueView.as_view(), name='offline_queue'),
    path('offline-submit/', OfflineBallotSubmissionView.as_view(), name='offline_submit'),
    
    # Management and monitoring endpoints
    path('stats/', BallotTokenStatsView.as_view(), name='token_stats'),
    path('usage-logs/', BallotTokenUsageLogView.as_view(), name='usage_logs'),
]