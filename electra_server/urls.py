"""
URL configuration for electra_server project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/health/', include('apps.health.urls')),
    path('api/auth/', include('electra_server.apps.auth.urls')),
    path('api/elections/', include('electra_server.apps.elections.urls')),
    path('api/ballots/', include('electra_server.apps.ballots.urls')),
    path('api/votes/', include('electra_server.apps.votes.urls')),
    path('api/admin/', include('electra_server.apps.admin.urls')),
    path('api/analytics/', include('electra_server.apps.analytics.urls')),
    path('', include('electra_server.apps.audit.urls')),
    path('', include('django_prometheus.urls')),  # Metrics endpoint at /metrics
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)

# Customize admin site
admin.site.site_header = 'Electra Administration'
admin.site.site_title = 'Electra Admin'
admin.site.index_title = 'Welcome to Electra Administration'
