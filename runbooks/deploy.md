# Electra Deployment Runbook

This runbook provides step-by-step procedures for deploying the Electra secure digital voting system to staging and production environments.

## Prerequisites

### Required Access
- [ ] GitHub repository write access
- [ ] Kubernetes cluster access (kubectl configured)
- [ ] Docker registry push permissions
- [ ] Database access for migrations
- [ ] Secrets management access

### Required Tools
```bash
# Verify tools are installed
kubectl version --client
docker --version
helm version
terraform --version
```

### Environment Verification
```bash
# Check Kubernetes connectivity
kubectl get nodes
kubectl get namespaces

# Verify current context
kubectl config current-context

# Check available resources
kubectl top nodes
```

## Pre-Deployment Checklist

### Code Readiness
- [ ] All tests passing in CI
- [ ] Code reviewed and approved
- [ ] Security scans completed
- [ ] Documentation updated
- [ ] Version tag created (`git tag v1.0.0`)

### Environment Readiness
- [ ] Infrastructure provisioned (Terraform applied)
- [ ] Secrets configured in environment
- [ ] Database migrations reviewed
- [ ] Monitoring dashboards accessible
- [ ] Backup systems operational

### Team Coordination
- [ ] Deployment window scheduled
- [ ] Stakeholders notified
- [ ] Rollback plan reviewed
- [ ] On-call engineer identified

## Staging Deployment

### 1. Prepare for Deployment

```bash
# Switch to staging context
kubectl config use-context electra-staging

# Verify current state
kubectl get pods -n electra-staging
kubectl get deployments -n electra-staging

# Check current version
kubectl get deployment electra-web -n electra-staging -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### 2. Create Pre-Deployment Backup

```bash
# Create database backup
./scripts/db_backup.sh staging v1.0.0 --verify

# Verify backup created
ls -la /var/backups/electra/electra_staging_*

# Test backup integrity
./scripts/db_restore.sh --verify-only /path/to/backup.sql.gz.enc
```

### 3. Execute Deployment

**Option A: Using GitHub Actions (Recommended)**

1. Go to GitHub Actions → CD Workflow
2. Click "Run workflow"
3. Configure parameters:
   - Environment: `staging`
   - Version tag: `v1.0.0`
   - Maintenance mode: `true`
   - Rollback enabled: `true`
4. Click "Run workflow"
5. Monitor progress in Actions tab

**Option B: Using Deployment Script**

```bash
# Build and push images
./scripts/build_images.sh --target production --version v1.0.0 --push

# Deploy to Kubernetes
./scripts/deploy_k8s.sh \
  --image ghcr.io/rs12a/electra:v1.0.0 \
  --version v1.0.0 \
  --environment staging \
  --namespace electra-staging
```

### 4. Verify Deployment

```bash
# Check deployment status
kubectl rollout status deployment/electra-web -n electra-staging

# Verify pods are running
kubectl get pods -n electra-staging -l app=electra

# Check logs for errors
kubectl logs -l app=electra -n electra-staging --since=5m

# Test health endpoints
curl -f https://staging.electra.example.com/api/health/
```

### 5. Run Smoke Tests

```bash
# Basic functionality test
curl -X POST https://staging.electra.example.com/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}' || echo "Endpoint accessible"

# Database connectivity test
kubectl exec -it deployment/electra-web -n electra-staging -- \
  python manage.py shell -c "from django.db import connection; connection.ensure_connection(); print('DB Connected')"

# Cache connectivity test
kubectl exec -it deployment/electra-web -n electra-staging -- \
  python manage.py shell -c "from django.core.cache import cache; cache.set('test', 'ok'); print(cache.get('test'))"
```

### 6. Switch Traffic (Blue/Green)

```bash
# Switch traffic to new version
./scripts/deploy_k8s.sh \
  --action switch-traffic \
  --version v1.0.0 \
  --namespace electra-staging

# Verify traffic switch
curl -H "Cache-Control: no-cache" https://staging.electra.example.com/api/health/
```

### 7. Post-Deployment Verification

```bash
# Monitor application metrics
kubectl top pods -n electra-staging

# Check error rates
kubectl logs -l app=electra -n electra-staging --since=10m | grep ERROR | wc -l

# Verify key functionality
# (Add specific business logic tests here)
```

## Production Deployment

### 1. Pre-Production Checks

```bash
# Verify staging deployment successful
kubectl get deployment electra-web -n electra-staging

# Check staging health
curl -f https://staging.electra.example.com/api/health/

# Review staging logs for errors
kubectl logs -l app=electra -n electra-staging --since=1h | grep -i error
```

### 2. Production Deployment Window

**Maintenance Window Protocol:**
1. **15 minutes before**: Send maintenance notification
2. **5 minutes before**: Enable maintenance mode
3. **Start time**: Begin deployment
4. **End time**: Complete verification and restore service

```bash
# Send notification (customize for your system)
echo "🚧 Maintenance window starting in 15 minutes" | slack-notify

# Enable maintenance mode
kubectl patch ingress electra-ingress -n electra-production \
  -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/default-backend":"maintenance-service"}}}'
```

### 3. Production Deployment Steps

**CRITICAL: Production requires manual approval**

1. **GitHub Actions Deployment:**
   - Go to GitHub Actions → CD Workflow
   - Click "Run workflow"
   - Configure:
     - Environment: `production`
     - Version tag: `v1.0.0`
     - Maintenance mode: `true`
     - Rollback enabled: `true`
   - **Wait for approval** (protected environment)
   - Approve deployment when ready

2. **Monitor Deployment Progress:**
```bash
# Watch deployment in real-time
kubectl get pods -n electra-production -w

# Monitor logs
kubectl logs -f deployment/electra-web -n electra-production
```

### 4. Database Migration Validation

```bash
# Check migration status
kubectl exec -it deployment/electra-web -n electra-production -- \
  python manage.py showmigrations

# Verify data integrity
kubectl exec -it deployment/electra-web -n electra-production -- \
  python manage.py shell -c "
from django.contrib.auth.models import User
print(f'User count: {User.objects.count()}')
# Add other critical data checks
"
```

### 5. Production Health Verification

```bash
# Health endpoint check
curl -f https://electra.example.com/api/health/

# Load balancer health check
kubectl get ingress electra-ingress -n electra-production

# SSL certificate verification
curl -vI https://electra.example.com 2>&1 | grep -i certificate

# Performance baseline check
time curl -s https://electra.example.com/api/health/ >/dev/null
```

### 6. Traffic Switch and Monitoring

```bash
# Switch production traffic
./scripts/deploy_k8s.sh \
  --action switch-traffic \
  --version v1.0.0 \
  --namespace electra-production \
  --environment production

# Monitor error rates for 5 minutes
for i in {1..5}; do
  echo "Minute $i - Checking error rate..."
  kubectl logs -l app=electra -n electra-production --since=1m | grep ERROR | wc -l
  sleep 60
done
```

### 7. Disable Maintenance Mode

```bash
# Remove maintenance mode
kubectl patch ingress electra-ingress -n electra-production \
  -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/default-backend":null}}}'

# Verify normal operation
curl -f https://electra.example.com/api/health/

# Send completion notification
echo "✅ Production deployment v1.0.0 completed successfully" | slack-notify
```

## Rollback Procedures

### Automatic Rollback (if deployment fails)

The CD workflow will automatically rollback if:
- Health checks fail
- Deployment timeout is reached
- Critical errors are detected

Monitor GitHub Actions for automatic rollback status.

### Manual Rollback

#### Quick Rollback (Kubernetes)
```bash
# Rollback to previous version
kubectl rollout undo deployment/electra-web -n electra-production

# Check rollback status
kubectl rollout status deployment/electra-web -n electra-production

# Verify rollback
kubectl get deployment electra-web -n electra-production -o jsonpath='{.spec.template.spec.containers[0].image}'
```

#### Full Rollback (with Database)
```bash
# If database changes need to be reverted
./scripts/db_restore.sh --latest production --target-version v0.9.0

# Rollback application
./scripts/deploy_k8s.sh \
  --action rollback \
  --target-version v0.9.0 \
  --environment production
```

#### Using GitHub Actions Rollback
1. Go to GitHub Actions → CD Workflow
2. Click "Run workflow"
3. Select action: "rollback"
4. Specify target version
5. Execute rollback

## Post-Deployment Tasks

### 1. Create GitHub Release

```bash
# If not automatically created by CD workflow
gh release create v1.0.0 \
  --title "Release v1.0.0" \
  --notes "Production deployment $(date)" \
  --target main
```

### 2. Update Documentation

- [ ] Update CHANGELOG.md
- [ ] Update version in README.md  
- [ ] Update API documentation
- [ ] Update deployment records

### 3. Monitoring Setup

```bash
# Verify monitoring dashboards
curl -f https://grafana.electra.example.com/api/health

# Check alerting rules
kubectl get prometheusrules -n monitoring

# Verify log aggregation
kubectl logs -l app=electra -n electra-production | head -10
```

### 4. Cleanup Old Versions

```bash
# Clean up old Docker images (keep last 3)
docker image prune -f

# Clean up old Kubernetes resources
kubectl delete replicasets -n electra-production --field-selector="status.replicas=0"

# Archive old backups (keep based on retention policy)
./scripts/db_backup.sh --cleanup-only --retention-days 30
```

## Troubleshooting

### Common Deployment Issues

#### Image Pull Failures
```bash
# Check image exists
docker pull ghcr.io/rs12a/electra:v1.0.0

# Verify registry credentials
kubectl get secrets -n electra-production | grep registry

# Check imagePullSecrets
kubectl describe deployment electra-web -n electra-production | grep -A5 "Image Pull"
```

#### Database Connection Issues
```bash
# Test database connectivity
kubectl exec -it deployment/electra-web -n electra-production -- \
  python manage.py dbshell -c "SELECT version();"

# Check database secrets
kubectl get secret electra-database -n electra-production -o yaml

# Verify security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx
```

#### Certificate Issues
```bash
# Check certificate status
kubectl describe certificate electra-tls -n electra-production

# Verify cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Manual certificate request
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: electra-tls
  namespace: electra-production
spec:
  secretName: electra-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - electra.example.com
EOF
```

### Emergency Contacts

- **Platform Team**: platform@example.com
- **Database Team**: dba@example.com
- **Security Team**: security@example.com
- **On-Call Engineer**: +1-555-0123
- **Slack Channels**: #electra-alerts, #platform-emergency

### Escalation Matrix

1. **Level 1** (0-15 min): On-call engineer
2. **Level 2** (15-30 min): Platform team lead  
3. **Level 3** (30+ min): Engineering manager
4. **Level 4** (1+ hour): CTO notification

## Deployment Checklist Summary

### Pre-Deployment
- [ ] Code quality checks passed
- [ ] Security scans completed
- [ ] Infrastructure ready
- [ ] Backups created
- [ ] Team notified

### During Deployment
- [ ] Maintenance mode enabled
- [ ] Deployment executed
- [ ] Health checks passed
- [ ] Traffic switched
- [ ] Monitoring confirmed

### Post-Deployment
- [ ] Maintenance mode disabled
- [ ] Documentation updated
- [ ] Release created
- [ ] Old versions cleaned up
- [ ] Team notified

**Remember: When in doubt, rollback first and investigate later.**