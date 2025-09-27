"""
Base Django settings for electra_server project.
"""
import os
import sys
import uuid
import logging
from pathlib import Path
from datetime import timedelta

import environ

# Initialize environment variables
env = environ.Env(
    DEBUG=(bool, False),
    DJANGO_SECRET_KEY=(str, ''),
    DATABASE_URL=(str, ''),
)

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent.parent

# Read environment variables from .env file if it exists
env_file = BASE_DIR / '.env'
if env_file.exists():
    environ.Env.read_env(str(env_file))

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = env('DJANGO_SECRET_KEY')
if not SECRET_KEY or SECRET_KEY == 'your_KEY_goes_here':
    if not env('DEBUG', default=False):
        raise ValueError("Django secret key must be set for production")
    print("⚠️  Using default Django secret key for development")

DEBUG = env('DEBUG')

# Environment validation for production
if not DEBUG and os.getenv('SKIP_ENV_VALIDATION') != 'true':
    try:
        from .env_validation import validate_environment, check_key_files
        
        # Run comprehensive environment validation
        is_valid = validate_environment(fail_on_error=False)
        check_key_files()
        
        if not is_valid:
            print("\n❌ Production environment validation failed!")
            print("Set SKIP_ENV_VALIDATION=true to bypass (not recommended)")
            sys.exit(1)
    except ImportError:
        print("⚠️  Environment validation module not found - skipping validation")

ALLOWED_HOSTS = env.list('DJANGO_ALLOWED_HOSTS', default=['localhost', '127.0.0.1'])

# Application definition
DJANGO_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

THIRD_PARTY_APPS = [
    'rest_framework',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'corsheaders',
    'django_prometheus',
]

LOCAL_APPS = [
    'electra_server',  # Main electra_server app for management commands
    'electra_server.apps.auth',
    'electra_server.apps.elections',
    'electra_server.apps.ballots', 
    'electra_server.apps.votes',
    'electra_server.apps.audit',
    'electra_server.apps.admin',
    'electra_server.apps.analytics',
    'electra_server.apps.health',
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

MIDDLEWARE = [
    'django_prometheus.middleware.PrometheusBeforeMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'electra_server.apps.audit.middleware.SecurityEnforcementMiddleware',
    'electra_server.apps.audit.middleware.TamperDetectionMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',  
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'electra_server.middleware.RequestLoggingMiddleware',
    'electra_server.apps.audit.middleware.AuditTrailMiddleware',
    'django_prometheus.middleware.PrometheusAfterMiddleware',
]

ROOT_URLCONF = 'electra_server.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'electra_server.wsgi.application'

# Database - PostgreSQL Only
# SQLite is completely prohibited in this project
DATABASES = {
    'default': env.db(default='postgresql://postgres:postgres@localhost:5432/electra_db')
}

# Enforce PostgreSQL usage - no SQLite allowed
if DATABASES['default']['ENGINE'] != 'django.db.backends.postgresql':
    raise ValueError(
        'Only PostgreSQL is allowed as the database backend. '
        'SQLite usage is prohibited throughout the project. '
        'Please set DATABASE_URL with a PostgreSQL connection string.'
    )

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
        'OPTIONS': {
            'min_length': 8,
        }
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Password hashing - Use Argon2
PASSWORD_HASHERS = [
    'django.contrib.auth.hashers.Argon2PasswordHasher',
    'django.contrib.auth.hashers.PBKDF2PasswordHasher',
    'django.contrib.auth.hashers.PBKDF2SHA1PasswordHasher',
    'django.contrib.auth.hashers.BCryptSHA256PasswordHasher',
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Monitoring and observability configuration
PROMETHEUS_EXPORT_MIGRATIONS = False

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# OpenTelemetry settings
OTEL_SERVICE_NAME = env('OTEL_SERVICE_NAME', default='electra-django')
OTEL_RESOURCE_ATTRIBUTES = env('OTEL_RESOURCE_ATTRIBUTES', default='service.name=electra-django,service.version=1.0.0')
OTEL_EXPORTER_JAEGER_AGENT_HOST = env('OTEL_EXPORTER_JAEGER_AGENT_HOST', default='jaeger')
OTEL_EXPORTER_JAEGER_AGENT_PORT = env.int('OTEL_EXPORTER_JAEGER_AGENT_PORT', default=14268)
OTEL_EXPORTER_JAEGER_ENDPOINT = env('OTEL_EXPORTER_JAEGER_ENDPOINT', default='http://jaeger:14268/api/traces')

# Custom metrics configuration
ELECTRA_METRICS_ENABLED = env.bool('ELECTRA_METRICS_ENABLED', default=True)
ELECTRA_METRICS_PREFIX = env('ELECTRA_METRICS_PREFIX', default='electra')

# Sentry configuration for error tracking (optional)
SENTRY_DSN = env('SENTRY_DSN', default='your_KEY_goes_here')
if SENTRY_DSN and SENTRY_DSN != 'your_KEY_goes_here':
    try:
        import sentry_sdk
        from sentry_sdk.integrations.django import DjangoIntegration
        from sentry_sdk.integrations.logging import LoggingIntegration
        
        sentry_logging = LoggingIntegration(
            level=logging.INFO,        # Capture info and above as breadcrumbs
            event_level=logging.ERROR  # Send errors as events
        )
        
        sentry_sdk.init(
            dsn=SENTRY_DSN,
            integrations=[
                DjangoIntegration(
                    transaction_style='url',
                    middleware_spans=True,
                    signals_spans=True,
                    cache_spans=True,
                ),
                sentry_logging,
            ],
            traces_sample_rate=0.1,  # 10% sampling rate for performance monitoring
            send_default_pii=False,  # Don't send personally identifiable information
            environment=env('DJANGO_ENV', default='development'),
            release=env('RELEASE_VERSION', default='1.0.0'),
        )
        print("✅ Sentry error tracking initialized")
    except ImportError:
        print("⚠️  Sentry SDK not installed - error tracking disabled")
else:
    print("⚠️  Sentry DSN not configured - error tracking disabled")

# Django REST Framework
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'EXCEPTION_HANDLER': 'electra_server.exceptions.custom_exception_handler',
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle'
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/hour',
        'user': '1000/hour',
        'admin_api': '100/hour',
        'admin_api_sensitive': '30/hour'
    }
}

# Simple JWT
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=env.int('JWT_ACCESS_TOKEN_LIFETIME', default=15)),
    'REFRESH_TOKEN_LIFETIME': timedelta(seconds=env.int('JWT_REFRESH_TOKEN_LIFETIME', default=604800)),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,
    'ALGORITHM': 'HS256',  # Use HS256 for testing
    'SIGNING_KEY': SECRET_KEY,  # Use Django secret key for testing
    'VERIFYING_KEY': None,
    'AUDIENCE': None,
    'ISSUER': None,
    'JWK_URL': None,
    'LEEWAY': 0,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'AUTH_HEADER_NAME': 'HTTP_AUTHORIZATION',
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
    'USER_AUTHENTICATION_RULE': 'rest_framework_simplejwt.authentication.default_user_authentication_rule',
    'AUTH_TOKEN_CLASSES': ('rest_framework_simplejwt.tokens.AccessToken',),
    'TOKEN_TYPE_CLAIM': 'token_type',
    'JTI_CLAIM': 'jti',
    'SLIDING_TOKEN_REFRESH_EXP_CLAIM': 'refresh_exp',
    'SLIDING_TOKEN_LIFETIME': timedelta(minutes=5),
    'SLIDING_TOKEN_REFRESH_LIFETIME': timedelta(days=1),
}

# Load RSA keys for JWT
RSA_PRIVATE_KEY_PATH = env('RSA_PRIVATE_KEY_PATH', default='keys/private_key.pem')
RSA_PUBLIC_KEY_PATH = env('RSA_PUBLIC_KEY_PATH', default='keys/public_key.pem')

try:
    private_key_path = BASE_DIR / RSA_PRIVATE_KEY_PATH
    public_key_path = BASE_DIR / RSA_PUBLIC_KEY_PATH
    
    if private_key_path.exists():
        with open(private_key_path, 'r') as f:
            SIMPLE_JWT['SIGNING_KEY'] = f.read()
    
    if public_key_path.exists():
        with open(public_key_path, 'r') as f:
            SIMPLE_JWT['VERIFYING_KEY'] = f.read()
except Exception as e:
    # In development, we'll generate keys if they don't exist
    pass

# CORS settings
CORS_ALLOWED_ORIGINS = env.list('CORS_ALLOWED_ORIGINS', default=[
    'http://localhost:3000',
    'http://127.0.0.1:3000',
])

CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_ALL_ORIGINS = DEBUG  # Only in development

# Session configuration
SESSION_COOKIE_SECURE = not DEBUG
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = 'Lax'
SESSION_COOKIE_AGE = 3600  # 1 hour

# CSRF configuration
CSRF_COOKIE_SECURE = not DEBUG
CSRF_COOKIE_HTTPONLY = True
CSRF_COOKIE_SAMESITE = 'Lax'
CSRF_TRUSTED_ORIGINS = env.list('CSRF_TRUSTED_ORIGINS', default=CORS_ALLOWED_ORIGINS)

# Security headers
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'

# Email configuration
# Email configuration with SMTP settings
EMAIL_BACKEND = env('EMAIL_BACKEND', default='django.core.mail.backends.smtp.EmailBackend')

# Support both EMAIL_* and SMTP_* variable names for flexibility
EMAIL_HOST = env('SMTP_HOST', default=env('EMAIL_HOST', default='smtp.gmail.com'))
EMAIL_PORT = env.int('SMTP_PORT', default=env.int('EMAIL_PORT', default=587))
EMAIL_USE_TLS = env.bool('EMAIL_USE_TLS', default=True)
EMAIL_HOST_USER = env('SMTP_USER', default=env('EMAIL_HOST_USER', default=''))
EMAIL_HOST_PASSWORD = env('SMTP_PASS', default=env('EMAIL_HOST_PASSWORD', default=''))
DEFAULT_FROM_EMAIL = env('DEFAULT_FROM_EMAIL', default='noreply@electra.com')

# Use mock backend for testing
if 'test' in sys.argv or env.bool('USE_MOCK_EMAIL', default=False):
    EMAIL_BACKEND = 'django.core.mail.backends.locmem.EmailBackend'

# Logging configuration
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'json': {
            '()': 'electra_server.logging.JsonFormatter',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': BASE_DIR / 'logs' / 'django.log',
            'formatter': 'json',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose' if DEBUG else 'json',
        },
    },
    'root': {
        'handlers': ['console', 'file'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
            'propagate': False,
        },
        'electra_server': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}

# Ensure logs directory exists
os.makedirs(BASE_DIR / 'logs', exist_ok=True)

# Cache configuration - Redis Only
# Local memory cache is prohibited in this project
redis_url = env('REDIS_URL', default='redis://localhost:6379/0')
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': redis_url,
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'CONNECTION_POOL_KWARGS': {
                'max_connections': 20,
                'retry_on_timeout': True,
            },
            'COMPRESSOR': 'django_redis.compressors.zlib.ZlibCompressor',
            'SERIALIZER': 'django_redis.serializers.json.JSONSerializer',
            'IGNORE_EXCEPTIONS': True,  # Don't fail silently in production
        },
        'KEY_PREFIX': 'electra',
        'VERSION': 1,
    }
}

# Session backend - use Redis for session storage
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'default'

# Custom user model
AUTH_USER_MODEL = 'electra_auth.User'