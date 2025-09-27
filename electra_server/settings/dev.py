# Development settings for electra_server project.
# All database operations must use PostgreSQL - SQLite is prohibited.
"""

from .base import *

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

# Development-specific allowed hosts
ALLOWED_HOSTS = ['localhost', '127.0.0.1', '0.0.0.0', '*']

# Development database - PostgreSQL ONLY
# SQLite usage is completely prohibited, even in development
# Override database settings with DATABASE_URL in .env for custom configuration
if not env('DATABASE_URL', default=''):
    # Default development PostgreSQL database
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': 'electra_dev',
            'USER': 'postgres',
            'PASSWORD': 'postgres',
            'HOST': 'localhost',
            'PORT': '5432',
            'CONN_MAX_AGE': 60,
            'OPTIONS': {
                'connect_timeout': 10,
            },
        }
    }

# Email backend for development (console output)
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'

# CORS - Allow all origins in development
CORS_ALLOW_ALL_ORIGINS = True

# Disable security features for development
SESSION_COOKIE_SECURE = False
CSRF_COOKIE_SECURE = False
SECURE_SSL_REDIRECT = False
SECURE_HSTS_SECONDS = 0

# Development logging - more verbose
LOGGING['handlers']['console']['level'] = 'DEBUG'
LOGGING['root']['level'] = 'DEBUG'
LOGGING['loggers']['django']['level'] = 'DEBUG'
LOGGING['loggers']['electra_server']['level'] = 'DEBUG'

# Add django-extensions if available (for development tools)
try:
    import django_extensions
    INSTALLED_APPS.append('django_extensions')
except ImportError:
    pass

# Static files in development
STATICFILES_DIRS = [
    BASE_DIR / 'static',
]

# Development Redis configuration - use default Redis cache from base
# Ensure Redis is always used, never local memory cache