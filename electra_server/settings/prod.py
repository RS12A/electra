"""
Production settings for electra_server project.
"""

from .base import *

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = False

# Production allowed hosts - must be set via environment
ALLOWED_HOSTS = env.list('DJANGO_ALLOWED_HOSTS')

# Security settings for production
SECURE_SSL_REDIRECT = env.bool('SECURE_SSL_REDIRECT', default=True)
SECURE_HSTS_SECONDS = env.int('SECURE_HSTS_SECONDS', default=31536000)  # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = env.bool('SECURE_HSTS_INCLUDE_SUBDOMAINS', default=True)
SECURE_HSTS_PRELOAD = env.bool('SECURE_HSTS_PRELOAD', default=True)
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# Session and CSRF security
SESSION_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = 'Strict'

CSRF_COOKIE_SECURE = True
CSRF_COOKIE_HTTPONLY = True
CSRF_COOKIE_SAMESITE = 'Strict'

# Content security policy headers
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_REFERRER_POLICY = 'strict-origin-when-cross-origin'

# CORS - Restrictive settings for production
CORS_ALLOW_ALL_ORIGINS = False
CORS_ALLOW_CREDENTIALS = True

# Database configuration - must use PostgreSQL in production
DATABASES = {
    'default': env.db()
}

# Ensure PostgreSQL is used
if DATABASES['default']['ENGINE'] != 'django.db.backends.postgresql':
    raise ValueError('Production must use PostgreSQL database')

# Email configuration for production
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'

# Production logging - JSON format
LOGGING['handlers']['console']['formatter'] = 'json'
LOGGING['handlers']['file']['level'] = 'WARNING'  # Only warnings and errors to file

# Cache configuration - must use Redis in production
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': env('REDIS_URL'),
        'OPTIONS': {
            'CONNECTION_POOL_KWARGS': {
                'max_connections': 20,
                'retry_on_timeout': True,
            }
        }
    }
}

# Static files for production
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Compress static files
STATICFILES_FINDERS = [
    'django.contrib.staticfiles.finders.FileSystemFinder',
    'django.contrib.staticfiles.finders.AppDirectoriesFinder',
]

# Media files configuration for production
# In production, you should use cloud storage like AWS S3
DEFAULT_FILE_STORAGE = 'django.core.files.storage.FileSystemStorage'

# Admin security
ADMIN_URL = env('ADMIN_URL', default='admin/')

# JWT settings for production - require RSA keys
if not SIMPLE_JWT.get('SIGNING_KEY') or not SIMPLE_JWT.get('VERIFYING_KEY'):
    raise ValueError('RSA keys must be configured for JWT in production')

# Additional security middleware for production
MIDDLEWARE.insert(0, 'django.middleware.security.SecurityMiddleware')

# Performance optimizations
USE_L10N = False  # Disable localization if not needed
USE_I18N = False  # Disable internationalization if not needed

# Connection pooling for database
DATABASES['default']['CONN_MAX_AGE'] = 60
DATABASES['default']['OPTIONS'] = {
    'MAX_CONNS': 20,
    'MIN_CONNS': 5,
}