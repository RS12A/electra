"""
Test settings for electra_server project.
"""
import os

# Skip environment validation in tests
os.environ['SKIP_ENV_VALIDATION'] = 'true'

from .base import *

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

# Test-specific allowed hosts
ALLOWED_HOSTS = ['localhost', '127.0.0.1', '0.0.0.0', '*', 'testserver']

# Use in-memory SQLite database for tests
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': ':memory:',
    }
}

# Disable migrations for faster tests
class DisableMigrations:
    def __contains__(self, item):
        return True
    
    def __getitem__(self, item):
        return None

MIGRATION_MODULES = DisableMigrations()

# Email backend for testing (in-memory)
EMAIL_BACKEND = 'django.core.mail.backends.locmem.EmailBackend'

# CORS - Allow all origins in testing
CORS_ALLOW_ALL_ORIGINS = True

# Disable security features for testing
SESSION_COOKIE_SECURE = False
CSRF_COOKIE_SECURE = False
SECURE_SSL_REDIRECT = False
SECURE_HSTS_SECONDS = 0

# Test logging - minimal output
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'level': 'ERROR',
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'ERROR',
    },
}

# Test cache (use local memory)
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'test-cache',
    }
}

# Disable password hashers for faster tests
PASSWORD_HASHERS = [
    'django.contrib.auth.hashers.MD5PasswordHasher',
]

# Disable any external services
CELERY_TASK_ALWAYS_EAGER = True
CELERY_TASK_EAGER_PROPAGATES = True

# Use simple JWT settings for testing
SIMPLE_JWT.update({
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),
    'SIGNING_KEY': 'test-secret-key-for-testing-only-do-not-use-in-production',
    'VERIFYING_KEY': None,
    'ALGORITHM': 'HS256',
})

# Skip environment validation in tests
SKIP_ENV_VALIDATION = True

# Test-specific middleware (remove some middleware that might interfere with tests)
MIDDLEWARE = [m for m in MIDDLEWARE if 'audit.middleware' not in m]

# Disable audit logging in tests for faster execution
AUDIT_LOGGING_ENABLED = False