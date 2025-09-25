"""
Production settings for electra_server project.
"""

from .base import *

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = False

# Production allowed hosts - must be set via environment
ALLOWED_HOSTS = env.list('DJANGO_ALLOWED_HOSTS')
if not ALLOWED_HOSTS:
    raise ValueError("DJANGO_ALLOWED_HOSTS must be set for production")

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

# Validate database URL format
database_url = env('DATABASE_URL', default='')
if not database_url or database_url == 'your_KEY_goes_here':
    raise ValueError('DATABASE_URL must be set for production')

# Email configuration for production
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'

# Validate email configuration
email_host = env('EMAIL_HOST', default='')
email_user = env('EMAIL_HOST_USER', default='')
email_password = env('EMAIL_HOST_PASSWORD', default='')

if not email_host or email_host == 'your_KEY_goes_here':
    raise ValueError('EMAIL_HOST must be set for production')
if not email_user or email_user == 'your_KEY_goes_here':
    raise ValueError('EMAIL_HOST_USER must be set for production')
if not email_password or email_password == 'your_KEY_goes_here':
    raise ValueError('EMAIL_HOST_PASSWORD must be set for production')

# Production logging - JSON format
LOGGING['handlers']['console']['formatter'] = 'json'
LOGGING['handlers']['file']['level'] = 'WARNING'  # Only warnings and errors to file

# Cache configuration - must use Redis in production
redis_url = env('REDIS_URL', default='')
if not redis_url or redis_url == 'your_KEY_goes_here':
    raise ValueError('REDIS_URL must be set for production caching')

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': redis_url,
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
rsa_private_key_path = env('RSA_PRIVATE_KEY_PATH', default='')
rsa_public_key_path = env('RSA_PUBLIC_KEY_PATH', default='')

if not rsa_private_key_path or not rsa_public_key_path:
    raise ValueError('RSA key paths must be set for production JWT signing')

if not os.path.exists(rsa_private_key_path):
    raise ValueError(f'RSA private key file not found: {rsa_private_key_path}')

if not os.path.exists(rsa_public_key_path):
    raise ValueError(f'RSA public key file not found: {rsa_public_key_path}')

# Load RSA keys for JWT
try:
    with open(rsa_private_key_path, 'r') as f:
        SIMPLE_JWT['SIGNING_KEY'] = f.read()
    with open(rsa_public_key_path, 'r') as f:
        SIMPLE_JWT['VERIFYING_KEY'] = f.read()
    SIMPLE_JWT['ALGORITHM'] = 'RS256'
    print("✅ RSA keys loaded successfully for JWT signing")
except Exception as e:
    raise ValueError(f'Failed to load RSA keys: {e}')

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

# Sentry configuration for error tracking
sentry_dsn = env('SENTRY_DSN', default='')
if sentry_dsn and sentry_dsn != 'your_KEY_goes_here':
    try:
        import sentry_sdk
        from sentry_sdk.integrations.django import DjangoIntegration
        from sentry_sdk.integrations.logging import LoggingIntegration
        
        sentry_sdk.init(
            dsn=sentry_dsn,
            integrations=[
                DjangoIntegration(
                    transaction_style='url',
                    middleware_spans=True,
                    signals_spans=False,
                ),
                LoggingIntegration(
                    level=logging.INFO,
                    event_level=logging.ERROR
                ),
            ],
            traces_sample_rate=0.1,
            send_default_pii=False,
            environment=env('SENTRY_ENVIRONMENT', default='production'),
            release=env('RELEASE_VERSION', default='1.0.0'),
        )
        print("✅ Sentry error tracking initialized")
    except ImportError:
        print("⚠️  Sentry SDK not installed - error tracking disabled")
else:
    print("⚠️  Sentry DSN not configured - error tracking disabled")