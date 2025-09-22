"""
Django production settings for electra_server project.
All security features enabled for production deployment.
"""

from .base import *

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = False

# Production security settings
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_HSTS_SECONDS = 31536000  # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_SSL_REDIRECT = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# Session security
SESSION_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = 'Strict'
SESSION_COOKIE_AGE = 3600  # 1 hour for production

# CSRF security
CSRF_COOKIE_SECURE = True
CSRF_COOKIE_HTTPONLY = True
CSRF_COOKIE_SAMESITE = 'Strict'

# Frame options
X_FRAME_OPTIONS = 'DENY'

# Content Security Policy
SECURE_REFERRER_POLICY = 'strict-origin-when-cross-origin'

# Production allowed hosts must be explicitly set
ALLOWED_HOSTS = env.list('ALLOWED_HOSTS', default=[])

# Production CORS settings - must be explicitly configured
CORS_ALLOW_ALL_ORIGINS = False
CORS_ALLOWED_ORIGINS = env.list('CORS_ALLOWED_ORIGINS', default=[])
CORS_ALLOW_CREDENTIALS = True

# Production database connection pooling and SSL
DATABASES['default'].update({
    'CONN_MAX_AGE': 600,
    'OPTIONS': {
        'sslmode': 'require',
    },
})

# Production caching with Redis (if available)
if env('REDIS_URL', default=None):
    CACHES = {
        'default': {
            'BACKEND': 'django_redis.cache.RedisCache',
            'LOCATION': env('REDIS_URL'),
            'OPTIONS': {
                'CLIENT_CLASS': 'django_redis.client.DefaultClient',
                'CONNECTION_POOL_KWARGS': {
                    'ssl_cert_reqs': None,
                },
            },
            'KEY_PREFIX': 'electra',
            'VERSION': 1,
        }
    }
else:
    # Fallback to database cache
    CACHES = {
        'default': {
            'BACKEND': 'django.core.cache.backends.db.DatabaseCache',
            'LOCATION': 'electra_cache_table',
        }
    }

# Production logging - structured JSON logs
LOGGING['handlers']['file'].update({
    'filename': '/var/log/electra/electra_server.log',
    'level': 'INFO',
})

# Remove console handler in production
LOGGING['handlers'].pop('console', None)
LOGGING['root']['handlers'] = ['file']
LOGGING['loggers']['django']['handlers'] = ['file']
LOGGING['loggers']['electra_server']['handlers'] = ['file']
LOGGING['loggers']['apps']['handlers'] = ['file']

# Production email settings
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_TIMEOUT = 10
EMAIL_USE_SSL = env.bool('EMAIL_USE_SSL', default=False)
EMAIL_USE_TLS = env.bool('EMAIL_USE_TLS', default=True)

# File upload security
FILE_UPLOAD_PERMISSIONS = 0o644
FILE_UPLOAD_DIRECTORY_PERMISSIONS = 0o755
FILE_UPLOAD_MAX_MEMORY_SIZE = 2621440  # 2.5 MB
DATA_UPLOAD_MAX_MEMORY_SIZE = 2621440  # 2.5 MB

# Production JWT settings - shorter lifetime for security
SIMPLE_JWT.update({
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=15),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
})

# Strict throttling for production
REST_FRAMEWORK['DEFAULT_THROTTLE_RATES'] = {
    'anon': '100/hour',
    'user': '1000/hour',
    'login': '5/minute',
    'register': '3/hour',
}

# Production static files handling
STATICFILES_STORAGE = 'django.contrib.staticfiles.storage.StaticFilesStorage'
STATIC_ROOT = env('STATIC_ROOT', default=str(BASE_DIR / 'staticfiles'))

# Media files for production
MEDIA_ROOT = env('MEDIA_ROOT', default=str(BASE_DIR / 'media'))

# AWS S3 configuration (if using cloud storage)
if env('AWS_STORAGE_BUCKET_NAME', default=None):
    # AWS S3 Configuration
    AWS_ACCESS_KEY_ID = env('AWS_ACCESS_KEY_ID')
    AWS_SECRET_ACCESS_KEY = env('AWS_SECRET_ACCESS_KEY')
    AWS_STORAGE_BUCKET_NAME = env('AWS_STORAGE_BUCKET_NAME')
    AWS_S3_REGION_NAME = env('AWS_S3_REGION_NAME', default='us-east-1')
    AWS_S3_CUSTOM_DOMAIN = env('AWS_S3_CUSTOM_DOMAIN', default=None)
    AWS_DEFAULT_ACL = 'private'
    AWS_S3_OBJECT_PARAMETERS = {
        'CacheControl': 'max-age=86400',
    }
    AWS_S3_FILE_OVERWRITE = False
    AWS_QUERYSTRING_AUTH = True
    AWS_QUERYSTRING_EXPIRE = 3600  # 1 hour
    
    # Use S3 for static and media files
    DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
    STATICFILES_STORAGE = 'storages.backends.s3boto3.S3StaticStorage'

# Monitoring and health checks
HEALTH_CHECK = {
    'DISK_USAGE_MAX': 90,  # Fail if disk usage > 90%
    'MEMORY_MIN': 100,     # Fail if available memory < 100MB
}

# Production middleware additions
MIDDLEWARE.insert(1, 'whitenoise.middleware.WhiteNoiseMiddleware')

# Admin security
ADMIN_URL = env('ADMIN_URL', default='admin/')

# Secure headers
SECURE_CROSS_ORIGIN_OPENER_POLICY = 'same-origin'

print("🏭 Django production server configured")
print(f"🔒 HTTPS enforced: {SECURE_SSL_REDIRECT}")
print(f"🛡️  HSTS enabled: {SECURE_HSTS_SECONDS}s")
print(f"🔐 Secure cookies: {SESSION_COOKIE_SECURE}")