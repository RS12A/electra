"""
URL configuration for electra_server project.
"""

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

# API URL patterns
api_v1_patterns = [
    path('auth/', include('apps.auth.urls', namespace='electra_auth')),
    path('', include('apps.core.urls', namespace='electra_core')),
]

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include((api_v1_patterns, 'api'))),
    path('api/v1/', include((api_v1_patterns, 'api_v1'))),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)

# Admin site configuration
admin.site.site_header = f"{settings.UNIVERSITY_NAME} - Electra Admin"
admin.site.site_title = "Electra Admin"
admin.site.index_title = "Election Management System"
