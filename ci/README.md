# Electra CI/CD Documentation

This document describes the CI/CD workflows, how to run them locally, manage secrets, and perform emergency procedures.

## Workflow Overview

The Electra project uses three main GitHub Actions workflows:

### 1. CI Workflow (`.github/workflows/ci.yml`)

**Triggers:**
- Push to `main` and `develop` branches
- Pull requests to `main` and `develop` branches

**Jobs:**
- **django-ci**: Python backend testing (matrix: Python 3.10, 3.11)
- **flutter-ci**: Flutter frontend testing and build
- **docker-security**: Docker image building and security scanning
- **migration-checks**: Database migration safety validation
- **integration-test**: End-to-end health checks

**What it does:**
- Installs dependencies and runs linting (flake8, black, isort)
- Executes pytest with coverage reporting
- Validates Django migrations and settings
- Builds and tests Flutter application
- Creates Docker images and scans for vulnerabilities
- Uploads test results and coverage reports

### 2. CD Workflow (`.github/workflows/cd.yml`)

**Triggers:**
- Manual dispatch with environment selection (staging/production)

**Jobs:**
- **pre-deploy-validation**: Parameter validation and approval checks
- **build-and-push**: Docker image building and registry push  
- **database-operations**: Backup creation and migration execution
- **deploy-application**: Blue/Green Kubernetes deployment
- **health-checks**: Post-deployment verification
- **traffic-switch**: Traffic routing to new version

**What it does:**
- Validates deployment parameters and branch requirements
- Builds and pushes production Docker images
- Creates database backups before deployment
- Deploys applications using Blue/Green strategy
- Runs health checks and smoke tests
- Switches traffic to new deployment
- Creates GitHub releases (production only)

### 3. Security Scan Workflow (`.github/workflows/security-scan.yml`)

**Triggers:**
- Weekly schedule (Sundays at 2 AM UTC)
- Pull requests affecting dependencies
- Manual dispatch

**Jobs:**
- **python-security-scan**: Dependency vulnerability scanning
- **flutter-security-scan**: Flutter/Dart security analysis
- **secret-scanning**: Repository secret detection
- **owasp-dependency-check**: OWASP vulnerability assessment
- **codeql-analysis**: Static code analysis
- **docker-security-scan**: Container image security scanning

**What it does:**
- Scans Python dependencies for known vulnerabilities
- Analyzes Flutter packages for security issues
- Detects potential secrets in code history
- Performs OWASP dependency checks
- Runs CodeQL static analysis
- Scans Docker images for vulnerabilities
- Uploads findings to GitHub Security tab

## Running Workflows Locally

### Using Act (GitHub Actions Local Runner)

1. **Install Act:**
```bash
# Using curl
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Using Homebrew (macOS)
brew install act

# Using Chocolatey (Windows)
choco install act-cli
```

2. **Create `.actrc` configuration:**
```bash
# .actrc
-P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest
-P ubuntu-22.04=ghcr.io/catthehacker/ubuntu:act-22.04
-P ubuntu-20.04=ghcr.io/catthehacker/ubuntu:act-20.04
```

3. **Create secrets file for local testing:**
```bash
# .secrets
DJANGO_SECRET_KEY=local-test-secret-key
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/electra_test
GITHUB_TOKEN=your_github_token_here
DOCKER_REGISTRY_TOKEN=your_registry_token_here
```

4. **Run workflows locally:**
```bash
# Run CI workflow
act push --secret-file .secrets

# Run specific job
act push --secret-file .secrets --job django-ci

# Run with specific event
act pull_request --secret-file .secrets

# Run security scan
act schedule --secret-file .secrets
```

### Using Docker Compose for Local Testing

1. **Start local environment:**
```bash
# Start services
docker-compose up -d

# Run Django tests
docker-compose exec web python -m pytest

# Run Flutter tests
cd electra_flutter && flutter test

# Run linting
docker-compose exec web flake8 .
docker-compose exec web black --check .
```

2. **Local CI simulation script:**
```bash
#!/bin/bash
# scripts/local_ci.sh

set -e

echo "🚀 Running local CI simulation"

# Backend tests
echo "🐍 Running Python tests..."
docker-compose exec -T web python -m pytest --cov=apps --cov-report=term

# Frontend tests  
echo "📱 Running Flutter tests..."
cd electra_flutter
flutter test
cd ..

# Linting
echo "🔍 Running linting..."
docker-compose exec -T web flake8 .
docker-compose exec -T web black --check .
docker-compose exec -T web isort --check-only .

# Security checks
echo "🔒 Running security checks..."
docker-compose exec -T web bandit -r . -x ./venv,./node_modules

echo "✅ Local CI simulation completed"
```

## Managing Secrets

### GitHub Secrets Setup

#### Repository Secrets (Required)

```bash
# Core Application Secrets
DJANGO_SECRET_KEY="your_production_django_secret_key_here"
DATABASE_URL="postgresql://user:pass@host:5432/electra_prod"
JWT_SECRET_KEY="your_jwt_signing_key_here"

# Docker Registry
DOCKER_REGISTRY_USER="your_registry_username"
DOCKER_REGISTRY_TOKEN="your_registry_token_or_password"
GITHUB_TOKEN="automatically_provided_by_github"

# Database Backup
BACKUP_ENCRYPTION_KEY="your_backup_encryption_key_here"

# AWS Credentials (if using AWS)
AWS_ACCESS_KEY_ID="your_aws_access_key"
AWS_SECRET_ACCESS_KEY="your_aws_secret_key"
AWS_REGION="us-west-2"

# Kubernetes Configuration
KUBECONFIG="base64_encoded_kubeconfig_content"

# Notification Webhooks
SLACK_WEBHOOK_URL="https://hooks.slack.com/your/webhook/url"

# Security Scanning
SNYK_TOKEN="your_snyk_token_for_vulnerability_scanning"
```

#### Environment Secrets (Staging/Production)

Create environment-specific secrets in GitHub:

**Settings → Environments → [Environment Name] → Add Secret**

```bash
# Staging Environment
DATABASE_URL="postgresql://user:pass@staging-db:5432/electra_staging"
DJANGO_ALLOWED_HOSTS="staging.electra.example.com"

# Production Environment  
DATABASE_URL="postgresql://user:pass@prod-db:5432/electra_prod"
DJANGO_ALLOWED_HOSTS="electra.example.com"
```

### Environment Variables Template

Create `.env.example` for development:

```bash
# .env.example - Copy to .env and update values

# Django Configuration
DJANGO_SECRET_KEY=your_KEY_goes_here
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1

# Database
DATABASE_URL=postgresql://postgres:your_KEY_goes_here@localhost:5432/electra_db

# JWT Configuration
JWT_SECRET_KEY=your_KEY_goes_here
JWT_ACCESS_TOKEN_LIFETIME=900
JWT_REFRESH_TOKEN_LIFETIME=604800

# RSA Keys
RSA_PRIVATE_KEY_PATH=keys/private_key.pem
RSA_PUBLIC_KEY_PATH=keys/public_key.pem

# Email Configuration
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your_KEY_goes_here
EMAIL_HOST_PASSWORD=your_KEY_goes_here

# Redis
REDIS_URL=redis://localhost:6379/0

# AWS S3 (if using)
AWS_ACCESS_KEY_ID=your_KEY_goes_here
AWS_SECRET_ACCESS_KEY=your_KEY_goes_here
AWS_STORAGE_BUCKET_NAME=your_KEY_goes_here

# Backup Configuration
BACKUP_ENCRYPTION_KEY=your_KEY_goes_here
```

### Secret Rotation

Regular secret rotation schedule:

1. **Database passwords**: Quarterly
2. **JWT signing keys**: Annually  
3. **API keys**: As needed or when compromised
4. **Backup encryption keys**: Annually
5. **Registry tokens**: Annually

**Rotation Process:**
1. Generate new secret value
2. Update in secret management system
3. Update GitHub secrets
4. Deploy applications with new secrets
5. Verify functionality
6. Revoke old secrets

## Emergency Procedures

### Rollback Deployment

#### Automatic Rollback (if enabled)
```bash
# Rollback is automatic if health checks fail
# Monitor workflow logs for rollback status
```

#### Manual Rollback
```bash
# Option 1: Use GitHub Actions
# Go to Actions → CD Workflow → Run workflow
# Select: Action = "rollback", Target Version = "v1.0.0"

# Option 2: Direct Kubernetes rollback
kubectl rollout undo deployment/electra-web -n electra-production

# Option 3: Use deployment script
./scripts/deploy_k8s.sh --action rollback --target-version v1.0.0 --environment production
```

### Database Recovery

#### Restore from Backup
```bash
# List available backups
./scripts/db_restore.sh --list-backups --environment production

# Restore latest backup
./scripts/db_restore.sh --latest production --no-confirmation

# Restore specific backup
./scripts/db_restore.sh /var/backups/electra/backup_file.sql.gz.enc
```

#### Point-in-Time Recovery
```bash
# AWS RDS Point-in-Time Recovery
aws rds restore-db-instance-to-point-in-time \
  --db-instance-identifier electra-prod-recovery \
  --source-db-instance-identifier electra-prod \
  --restore-time 2023-10-15T10:30:00Z
```

### Security Incident Response

#### Suspected Secret Leak
1. **Immediate Actions:**
   ```bash
   # Rotate all potentially compromised secrets
   # Revoke API keys and tokens
   # Reset database passwords
   ```

2. **Investigation:**
   ```bash
   # Run secret scan
   act schedule --secret-file .secrets --job secret-scanning
   
   # Check access logs
   kubectl logs -l app=electra-web --since=24h | grep "suspicious_pattern"
   ```

3. **Containment:**
   ```bash
   # Scale down affected deployments
   kubectl scale deployment electra-web --replicas=0
   
   # Block suspicious IPs
   kubectl patch service electra-web -p '{"spec":{"type":"ClusterIP"}}'
   ```

#### Service Outage
1. **Assessment:**
   ```bash
   # Check service health
   kubectl get pods -n electra-production
   kubectl describe deployment electra-web -n electra-production
   
   # Check external dependencies
   curl -f https://api.external-service.com/health
   ```

2. **Quick Fixes:**
   ```bash
   # Restart pods
   kubectl rollout restart deployment/electra-web -n electra-production
   
   # Scale up replicas
   kubectl scale deployment electra-web --replicas=5 -n electra-production
   
   # Check resource limits
   kubectl top pods -n electra-production
   ```

### Monitoring and Alerting

#### Health Check Commands
```bash
# Application health
curl -f https://electra.example.com/api/health/

# Database connectivity
kubectl exec -it deployment/electra-web -- python manage.py dbshell -c "SELECT 1;"

# Redis connectivity  
kubectl exec -it deployment/electra-web -- python manage.py shell -c "from django.core.cache import cache; cache.get('test')"
```

#### Log Analysis
```bash
# Application logs
kubectl logs -f deployment/electra-web -n electra-production

# Filter error logs
kubectl logs deployment/electra-web -n electra-production | grep ERROR

# Database query logs
kubectl logs deployment/electra-web -n electra-production | grep "slow query"
```

## Troubleshooting

### Common CI/CD Issues

#### Build Failures
```bash
# Check workflow logs in GitHub Actions
# Common issues:
# - Missing dependencies in requirements.txt
# - Test failures due to environment differences  
# - Docker build context issues
# - Secret configuration problems
```

#### Deployment Failures
```bash
# Check Kubernetes events
kubectl get events -n electra-production --sort-by='.lastTimestamp'

# Check pod status
kubectl describe pod <pod-name> -n electra-production

# Check ingress configuration
kubectl describe ingress electra-ingress -n electra-production
```

#### Security Scan Issues
```bash
# Update dependency versions
pip-audit --fix

# Exclude false positives
# Add to .bandit configuration
# Update security scan configuration
```

### Performance Issues

#### Database Performance
```bash
# Check slow queries
kubectl exec -it deployment/electra-web -- python manage.py shell
>>> from django.db import connection
>>> print(connection.queries)

# Database metrics
kubectl exec -it deployment/electra-web -- python manage.py dbshell -c "SELECT * FROM pg_stat_activity;"
```

#### Application Performance
```bash
# Check resource usage
kubectl top pods -n electra-production

# Memory profiling
kubectl exec -it deployment/electra-web -- python -m memory_profiler manage.py runserver
```

## Best Practices

### Code Quality
- Always run linting before committing
- Write tests for new features
- Keep test coverage above 80%
- Use type hints in Python code
- Follow Flutter/Dart style guidelines

### Security
- Never commit secrets to repository
- Regularly update dependencies
- Monitor security scan results
- Use least-privilege access principles
- Enable branch protection rules

### Deployment
- Always test in staging first
- Use feature flags for gradual rollouts
- Monitor metrics after deployment
- Keep deployment scripts idempotent
- Document all manual intervention steps

## Support Contacts

- **Platform Team**: platform@example.com
- **Security Team**: security@example.com  
- **On-call Rotation**: oncall@example.com
- **Slack Channels**: #electra-alerts, #platform-support