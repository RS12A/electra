"""
URL configuration for the authentication app.

This module defines all the URL patterns for authentication endpoints
including registration, login, logout, password recovery, and profile management.
"""
from django.urls import path, include
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    UserRegistrationView,
    UserLoginView,
    UserLogoutView,
    UserProfileView,
    PasswordResetRequestView,
    PasswordResetConfirmView,
    ChangePasswordView,
    UserListView,
    UserDetailView,
    LoginHistoryView,
    auth_status,
    user_stats,
)

app_name = 'auth'

urlpatterns = [
    # Authentication endpoints
    path('register/', UserRegistrationView.as_view(), name='register'),
    path('login/', UserLoginView.as_view(), name='login'),
    path('logout/', UserLogoutView.as_view(), name='logout'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('status/', auth_status, name='auth_status'),
    
    # Profile management
    path('profile/', UserProfileView.as_view(), name='profile'),
    path('change-password/', ChangePasswordView.as_view(), name='change_password'),
    path('login-history/', LoginHistoryView.as_view(), name='login_history'),
    
    # Password recovery - Updated to match requirements
    path('password-reset/', PasswordResetRequestView.as_view(), name='password_reset'),
    path('password-reset-confirm/', PasswordResetConfirmView.as_view(), name='password_reset_confirm'),
    
    # User management (admin/electoral committee only)
    path('users/', UserListView.as_view(), name='user_list'),
    path('users/<uuid:id>/', UserDetailView.as_view(), name='user_detail'),
    path('stats/', user_stats, name='user_stats'),
]