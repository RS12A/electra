"""
Test settings for electra_server project.
All tests must use PostgreSQL - SQLite is completely prohibited.
"""
import os

# Skip environment validation in tests
os.environ['SKIP_ENV_VALIDATION'] = 'true'

from .base import *

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

# Test-specific allowed hosts
ALLOWED_HOSTS = ['localhost', '127.0.0.1', '0.0.0.0', '*', 'testserver']

# Test database - PostgreSQL ONLY
# SQLite usage is prohibited even for testing
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'electra_test',
        'USER': 'postgres', 
        'PASSWORD': 'postgres',
        'HOST': 'localhost',
        'PORT': '5432',
        'TEST': {
            'NAME': 'test_electra_test',
        },
        'OPTIONS': {
            'connect_timeout': 10,
        },
    }
}

# Override with custom test database URL if provided
test_database_url = env('TEST_DATABASE_URL', default='')
if test_database_url:
    DATABASES = {'default': env.db('TEST_DATABASE_URL')}

# Ensure we're using PostgreSQL for tests
if DATABASES['default']['ENGINE'] != 'django.db.backends.postgresql':
    raise ValueError(
        'Tests must use PostgreSQL database. SQLite is prohibited. '
        'Please set TEST_DATABASE_URL with a PostgreSQL connection string.'
    )

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

# Test Redis cache - use separate Redis database for testing
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': env('REDIS_URL', default='redis://localhost:6379/1'),  # Use database 1 for tests
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'CONNECTION_POOL_KWARGS': {
                'max_connections': 10,
                'retry_on_timeout': True,
            },
            'IGNORE_EXCEPTIONS': True,
        },
        'KEY_PREFIX': 'electra_test',
    }
}

# Use Redis-backed sessions for testing
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'default'

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