# Environment Setup Guide

This guide provides comprehensive instructions for setting up and managing environment variables for the Electra secure digital voting system.

## Table of Contents

- [Quick Start](#quick-start)
- [Environment Variables Reference](#environment-variables-reference)
- [Security Keys Management](#security-keys-management)
- [Environment Validation](#environment-validation)
- [Deployment Environments](#deployment-environments)
- [Troubleshooting](#troubleshooting)

## Quick Start

### 1. Copy Environment Template

```bash
cp .env.example .env
```

### 2. Generate RSA Keys for JWT

```bash
# Generate 4096-bit RSA keys (recommended for production)
python scripts/generate_rsa_keys.py --key-size 4096

# Or use the Makefile
make generate-keys
```

### 3. Configure Required Variables

Edit `.env` and set these critical variables:

```bash
# Core Django Settings
DJANGO_SECRET_KEY=your_production_django_secret_key_here
DJANGO_ALLOWED_HOSTS=yourdomain.com,api.yourdomain.com

# Database
DATABASE_URL=postgresql://username:password@hostname:5432/database_name

# JWT & Security
JWT_SECRET_KEY=your_jwt_signing_key_here

# Email Configuration
EMAIL_HOST=smtp.yourmailprovider.com
EMAIL_HOST_USER=your_smtp_username
EMAIL_HOST_PASSWORD=your_smtp_password

# Redis Cache
REDIS_URL=redis://username:password@hostname:6379/0
```

### 4. Validate Configuration

```bash
# Validate all environment variables
python scripts/validate_environment.py

# Or validate specific environment file
python scripts/validate_environment.py --env-file .env.production
```

## Environment Variables Reference

### Core Django Configuration

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `DJANGO_SECRET_KEY` | ✅ | Django cryptographic signing key | `your_production_secret_key_here` |
| `DJANGO_DEBUG` | ✅ | Debug mode (False for production) | `False` |
| `DJANGO_ALLOWED_HOSTS` | ✅ | Comma-separated allowed hosts | `yourdomain.com,api.yourdomain.com` |
| `DJANGO_ENV` | ⚪ | Environment name | `production` |

### Database Configuration

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `DATABASE_URL` | ✅ | PostgreSQL connection string | `postgresql://user:pass@host:5432/db` |

### Authentication & Security

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `JWT_SECRET_KEY` | ✅ | JWT signing secret | `your_jwt_secret_key_here` |
| `JWT_ACCESS_TOKEN_LIFETIME` | ⚪ | Access token lifetime (seconds) | `900` (15 minutes) |
| `JWT_REFRESH_TOKEN_LIFETIME` | ⚪ | Refresh token lifetime (seconds) | `604800` (7 days) |
| `RSA_PRIVATE_KEY_PATH` | ✅ | Path to RSA private key | `keys/private_key.pem` |
| `RSA_PUBLIC_KEY_PATH` | ✅ | Path to RSA public key | `keys/public_key.pem` |

### Email Configuration

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `EMAIL_HOST` | ✅ | SMTP server hostname | `smtp.gmail.com` |
| `EMAIL_PORT` | ⚪ | SMTP server port | `587` |
| `EMAIL_HOST_USER` | ✅ | SMTP username | `your_email@gmail.com` |
| `EMAIL_HOST_PASSWORD` | ✅ | SMTP password or app password | `your_app_password` |
| `EMAIL_USE_TLS` | ⚪ | Use TLS encryption | `True` |
| `DEFAULT_FROM_EMAIL` | ⚪ | Default sender email | `noreply@yourdomain.com` |

### Security Checklist

Before deploying to production, ensure:

- [ ] All placeholder values (`your_KEY_goes_here`) are replaced
- [ ] RSA keys are generated and secured (600 permissions)
- [ ] Django secret key is unique and secure
- [ ] Database credentials are strong
- [ ] SSL redirect is enabled (`SECURE_SSL_REDIRECT=True`)
- [ ] Debug mode is disabled (`DJANGO_DEBUG=False`)
- [ ] Environment validation passes without errors
- [ ] Backup encryption key is configured
- [ ] Monitoring (Sentry, Slack) is configured
- [ ] Email configuration is tested

## Security Keys Management

### RSA Keys for JWT Signing

#### Generation

```bash
# Generate 4096-bit keys (recommended for production)
python scripts/generate_rsa_keys.py --key-size 4096

# Generate with custom output directory
python scripts/generate_rsa_keys.py --output-dir /secure/keys/

# Force overwrite existing keys
python scripts/generate_rsa_keys.py --force
```

#### Key Rotation Schedule

- **Development:** As needed
- **Staging:** Monthly (for testing rotation procedures)
- **Production:** Every 6-12 months or when compromised

#### Key Rotation Procedure

1. **Generate new keys:**
   ```bash
   python scripts/generate_rsa_keys.py --output-dir keys/new/
   ```

2. **Update environment variables:**
   ```bash
   RSA_PRIVATE_KEY_PATH=keys/new/private_key.pem
   RSA_PUBLIC_KEY_PATH=keys/new/public_key.pem
   ```

3. **Deploy and restart services:**
   ```bash
   # Docker deployment
   docker-compose down
   docker-compose up -d
   
   # Kubernetes deployment
   kubectl rollout restart deployment/electra-web
   ```

4. **Verify JWT tokens work and remove old keys after verification**

## Environment Validation

### Automatic Validation

The system automatically validates environment variables on startup in production mode.

### Manual Validation

```bash
# Validate current environment
python scripts/validate_environment.py

# Validate specific environment file
python scripts/validate_environment.py --env-file .env.production

# Strict mode (fail on warnings)
python scripts/validate_environment.py --strict
```

## Support

For additional support:
- Review the main [README.md](../README.md)
- Check [security.md](../security.md) for security guidelines
- Contact the development team