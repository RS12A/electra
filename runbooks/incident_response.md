# Electra Incident Response Runbook

This runbook provides step-by-step procedures for responding to incidents in the Electra secure digital voting system.

## Incident Classification

### Severity Levels

#### P0 - Critical (Complete Service Outage)
- **Response Time**: 15 minutes
- **Examples**: 
  - Complete application unavailability
  - Database corruption/loss
  - Security breach with data exposure
  - Voting system compromised during active election

#### P1 - High (Major Feature Impact)  
- **Response Time**: 1 hour
- **Examples**:
  - Login/authentication failures
  - Database connectivity issues
  - Significant performance degradation
  - SSL certificate expiration

#### P2 - Medium (Minor Feature Impact)
- **Response Time**: 4 hours
- **Examples**:
  - Single feature unavailable
  - Monitoring alerts
  - Non-critical API endpoints failing
  - UI rendering issues

#### P3 - Low (Minimal Impact)
- **Response Time**: 24 hours
- **Examples**:
  - Documentation issues
  - Cosmetic UI problems
  - Non-critical warnings in logs

## Initial Response Procedures

### 1. Alert Recognition

**When you receive an alert:**

```bash
# Immediately acknowledge the alert
echo "Acknowledged incident $(date)" | slack-notify

# Check multiple sources to confirm the issue
curl -f https://electra.example.com/api/health/
kubectl get pods -n electra-production
kubectl get services -n electra-production
```

### 2. Initial Assessment (First 5 minutes)

```bash
# Check overall system status
kubectl get pods -A | grep -v Running

# Check recent deployments
kubectl rollout history deployment/electra-web -n electra-production

# Check resource utilization
kubectl top nodes
kubectl top pods -n electra-production

# Review recent logs
kubectl logs -l app=electra -n electra-production --since=10m | tail -50
```

### 3. Incident Declaration

**For P0/P1 incidents:**

1. **Create incident channel**: `#incident-YYYY-MM-DD-HHMM`
2. **Notify stakeholders**:
   ```bash
   # Post to incident channel
   echo "🚨 P0 INCIDENT DECLARED
   Time: $(date)
   Impact: [Description]
   Responder: [Your name]
   Status: Investigating" | slack-notify
   ```
3. **Update status page** (if available)
4. **Start incident log**

### 4. Establish Communication

**Incident Commander Responsibilities:**
- Coordinate response efforts
- Communicate with stakeholders
- Make decisions about service impacts
- Delegate tasks to team members

**Communication Template:**
```
🚨 INCIDENT UPDATE - [SEVERITY]
Time: [TIMESTAMP]
Status: [INVESTIGATING/IDENTIFIED/IMPLEMENTING FIX/RESOLVED]
Impact: [DESCRIPTION]
Next Update: [TIME]
```

## Common Incident Scenarios

### Application Unavailable (P0)

#### Symptoms
- Health check endpoints failing
- 5xx errors from load balancer
- Users cannot access the application

#### Investigation Steps

1. **Check service status:**
```bash
# Verify pods are running
kubectl get pods -n electra-production

# Check service endpoints
kubectl get endpoints -n electra-production

# Verify ingress configuration
kubectl describe ingress electra-ingress -n electra-production
```

2. **Check recent changes:**
```bash
# Recent deployments
kubectl rollout history deployment/electra-web -n electra-production

# Recent configuration changes
kubectl get events -n electra-production --sort-by='.lastTimestamp' | head -20
```

3. **Resource constraints:**
```bash
# Memory and CPU usage
kubectl top pods -n electra-production

# Node resources
kubectl describe nodes | grep -A5 "Allocated resources"

# Storage issues
kubectl get pvc -n electra-production
```

#### Resolution Steps

1. **Quick fixes:**
```bash
# Restart deployment
kubectl rollout restart deployment/electra-web -n electra-production

# Scale up replicas
kubectl scale deployment electra-web --replicas=5 -n electra-production

# Check if rollback is needed
kubectl rollout undo deployment/electra-web -n electra-production
```

2. **If quick fixes don't work:**
```bash
# Check database connectivity
kubectl exec -it deployment/electra-web -n electra-production -- \
  python manage.py dbshell -c "SELECT 1;"

# Check external dependencies
curl -f https://api.external-service.com/health
```

### Database Issues (P0/P1)

#### Symptoms
- Database connection timeouts
- Data inconsistency errors
- Slow query performance

#### Investigation Steps

1. **Database connectivity:**
```bash
# Test connection from application
kubectl exec -it deployment/electra-web -n electra-production -- \
  python manage.py shell -c "from django.db import connection; connection.ensure_connection()"

# Check database pod/service (if running in cluster)
kubectl get pods -l app=postgresql

# For RDS, check AWS console for status
aws rds describe-db-instances --db-instance-identifier electra-prod
```

2. **Database performance:**
```bash
# Check active connections
kubectl exec -it deployment/electra-web -n electra-production -- \
  python manage.py dbshell -c "SELECT count(*) FROM pg_stat_activity;"

# Check for long-running queries
kubectl exec -it deployment/electra-web -n electra-production -- \
  python manage.py dbshell -c "
  SELECT pid, now() - pg_stat_activity.query_start AS duration, query 
  FROM pg_stat_activity 
  WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';"
```

#### Resolution Steps

1. **Immediate actions:**
```bash
# Kill long-running queries (carefully!)
kubectl exec -it deployment/electra-web -n electra-production -- \
  python manage.py dbshell -c "SELECT pg_terminate_backend(PID);"

# Restart database connection pool
kubectl rollout restart deployment/electra-web -n electra-production
```

2. **Database recovery:**
```bash
# If data corruption suspected
./scripts/db_restore.sh --latest production

# Point-in-time recovery (RDS)
aws rds restore-db-instance-to-point-in-time \
  --db-instance-identifier electra-prod-recovery \
  --source-db-instance-identifier electra-prod \
  --restore-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)
```

### Security Incident (P0)

#### Symptoms
- Unusual access patterns
- Unauthorized data access
- Compromised user accounts
- DDoS attacks

#### Immediate Actions

1. **Contain the threat:**
```bash
# Block suspicious IPs at load balancer level
kubectl patch service electra-web -n electra-production \
  -p '{"spec":{"loadBalancerSourceRanges":["10.0.0.0/8"]}}'

# Scale down affected services if needed
kubectl scale deployment electra-web --replicas=0 -n electra-production

# Enable maintenance mode
kubectl patch ingress electra-ingress -n electra-production \
  -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/default-backend":"maintenance-service"}}}'
```

2. **Preserve evidence:**
```bash
# Capture logs immediately
kubectl logs -l app=electra -n electra-production --since=2h > incident-logs-$(date +%Y%m%d-%H%M).log

# Snapshot current state
kubectl get all -n electra-production -o yaml > incident-state-$(date +%Y%m%d-%H%M).yaml

# Database snapshot (if safe to do so)
./scripts/db_backup.sh production incident-$(date +%Y%m%d-%H%M)
```

3. **Investigation:**
```bash
# Check for suspicious activity
kubectl logs -l app=electra -n electra-production | grep -i "unauthorized\|failed\|error\|suspicious"

# Review recent changes
kubectl get events -n electra-production --sort-by='.lastTimestamp'

# Check access logs
kubectl logs -l app=nginx -n electra-production | grep -E "(40[0-9]|50[0-9])"
```

#### Recovery Steps

1. **Rotate all secrets:**
```bash
# Update GitHub secrets with new values
# Rotate database passwords
# Regenerate JWT signing keys
# Update API keys
```

2. **Apply security patches:**
```bash
# Update base images
docker pull python:3.11-slim
./scripts/build_images.sh --no-cache --target production

# Update dependencies
pip-audit --fix
```

3. **Gradual service restoration:**
```bash
# Start with limited access
kubectl scale deployment electra-web --replicas=1 -n electra-production

# Monitor for 15 minutes before full restoration
kubectl scale deployment electra-web --replicas=3 -n electra-production

# Remove maintenance mode
kubectl patch ingress electra-ingress -n electra-production \
  -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/default-backend":null}}}'
```

### Performance Degradation (P1/P2)

#### Symptoms
- Increased response times
- Timeout errors
- High resource utilization

#### Investigation Steps

1. **Resource analysis:**
```bash
# Check CPU and memory usage
kubectl top pods -n electra-production
kubectl top nodes

# Check disk usage
kubectl exec -it deployment/electra-web -n electra-production -- df -h

# Network connectivity
kubectl exec -it deployment/electra-web -n electra-production -- ping -c 3 8.8.8.8
```

2. **Application profiling:**
```bash
# Check slow queries
kubectl logs -l app=electra -n electra-production | grep "slow query"

# Memory profiling (if available)
kubectl exec -it deployment/electra-web -n electra-production -- \
  python -c "import psutil; print(f'Memory: {psutil.virtual_memory().percent}%')"
```

#### Resolution Steps

1. **Immediate relief:**
```bash
# Scale up replicas
kubectl scale deployment electra-web --replicas=5 -n electra-production

# Increase resource limits
kubectl patch deployment electra-web -n electra-production \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"electra","resources":{"limits":{"memory":"1Gi","cpu":"1000m"}}}]}}}}'
```

2. **Optimize performance:**
```bash
# Clear caches
kubectl exec -it deployment/electra-web -n electra-production -- \
  python manage.py shell -c "from django.core.cache import cache; cache.clear()"

# Restart services
kubectl rollout restart deployment/electra-web -n electra-production
```

## Monitoring and Alerting

### Key Metrics to Monitor

```bash
# Application health
curl -f https://electra.example.com/api/health/

# Metrics endpoint
curl -f https://electra.example.com/metrics

# Response time monitoring  
time curl -s https://electra.example.com/api/health/ >/dev/null

# Error rate
kubectl logs -l app=electra -n electra-production --since=5m | grep ERROR | wc -l

# Resource utilization
kubectl top pods -n electra-production
```

### Monitoring Stack Health Checks

```bash
# Check all monitoring services
./scripts/deploy_monitoring.sh status

# Verify Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'

# Check Grafana datasources
curl -H "Authorization: Bearer $GRAFANA_TOKEN" http://localhost:3000/api/datasources

# Verify alert rules
curl http://localhost:9090/api/v1/rules | jq '.data.groups[].rules[] | select(.state == "firing")'

# Check log ingestion
curl http://localhost:9200/_cat/indices/electra-logs-*
```

### Alert Response Procedures

#### Critical Alert Response (P0)
1. **Immediate Actions** (within 5 minutes):
   ```bash
   # Check service status
   kubectl get pods -n electra-production
   
   # Check recent deployments
   kubectl rollout history deployment/electra-web -n electra-production
   
   # View recent logs
   kubectl logs -l app=electra -n electra-production --since=10m --tail=100
   ```

2. **Investigation**:
   ```bash
   # Check Grafana dashboards
   # - System Health: http://localhost:3000/d/system-health
   # - Election Turnout: http://localhost:3000/d/election-turnout
   
   # Query Prometheus for alerts
   curl http://localhost:9090/api/v1/alerts
   
   # Check Jaeger for traces
   # Navigate to http://localhost:16686 and search for recent errors
   ```

3. **Escalation**:
   - If not resolved in 15 minutes, escalate to on-call engineer
   - Page incident commander for election-related issues
   - Notify security team for security alerts

#### Performance Alert Response (P1)
1. **Check System Resources**:
   ```bash
   # CPU and memory
   kubectl top nodes
   kubectl top pods -n electra-production
   
   # Database performance
   curl http://localhost:9090/api/v1/query?query=django_db_execute_time
   
   # API response times
   curl http://localhost:9090/api/v1/query?query=histogram_quantile(0.95,rate(django_http_request_duration_seconds_bucket[5m]))
   ```

2. **Scale Resources**:
   ```bash
   # Scale application pods
   kubectl scale deployment electra-web --replicas=5 -n electra-production
   
   # Scale database connections (if needed)
   kubectl patch deployment electra-web -n electra-production -p '{"spec":{"template":{"spec":{"containers":[{"name":"web","env":[{"name":"DB_MAX_CONNECTIONS","value":"50"}]}]}}}}'
   ```

#### Security Alert Response (P0)
1. **Immediate Containment**:
   ```bash
   # Check failed login attempts
   curl http://localhost:9200/electra-logs-*/_search -d '{
     "query": {
       "bool": {
         "must": [
           {"match": {"event_type": "security_failed_login"}},
           {"range": {"@timestamp": {"gte": "now-1h"}}}
         ]
       }
     }
   }' | jq '.hits.total'
   
   # Review suspicious activities
   kubectl logs -l app=electra -n electra-production | grep -i "suspicious\|unauthorized\|failed"
   ```

2. **Block Malicious IPs**:
   ```bash
   # Add IP to deny list (example)
   kubectl patch configmap nginx-config -n electra-production --patch '{"data":{"deny-ips":"$MALICIOUS_IP"}}'
   
   # Restart nginx to apply changes
   kubectl rollout restart deployment/electra-nginx -n electra-production
   ```

### Setting Up Alerts

**Prometheus AlertManager rules example:**
```yaml
groups:
- name: electra-alerts
  rules:
  - alert: ElectraDown
    expr: up{job="electra-django"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Electra service is down"
      runbook_url: "https://github.com/RS12A/electra/blob/main/runbooks/incident_response.md#service-down"
      
  - alert: HighErrorRate  
    expr: rate(django_http_requests_total_by_view_transport_method{status=~"5.."}[5m]) / rate(django_http_requests_total_by_view_transport_method[5m]) > 0.05
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "High error rate detected (>5%)"
      description: "Error rate is {{ $value | humanizePercentage }} for the last 5 minutes"
      runbook_url: "https://github.com/RS12A/electra/blob/main/runbooks/incident_response.md#high-error-rate"

  - alert: DatabaseHighLatency
    expr: django_db_execute_time > 0.5
    for: 1m
    labels:
      severity: warning
    annotations:
      summary: "Database latency is high (>500ms)"
      description: "Database query latency is {{ $value }}s"
      
  - alert: VotingQueueBacklog
    expr: electra_vote_queue_pending > 100
    for: 5m
    labels:
      severity: warning
      category: election
    annotations:
      summary: "Voting queue has high backlog"
      description: "{{ $value }} votes pending in queue for more than 5 minutes"
```

### Monitoring Maintenance

#### Daily Tasks
```bash
# Check monitoring stack health
./scripts/deploy_monitoring.sh test

# Verify audit log integrity (last 7 days)
./scripts/verify_audit_logs.py --public-key keys/audit_public.pem --log-dir audit_logs

# Review overnight alerts
curl http://localhost:9093/api/v1/alerts?silenced=false | jq '.data[] | select(.startsAt | . < (now - 24*3600))'

# Check disk usage for monitoring volumes
df -h | grep -E "(prometheus|grafana|elasticsearch)"
```

#### Weekly Tasks
```bash
# Backup Grafana dashboards
curl -H "Authorization: Bearer $GRAFANA_TOKEN" http://localhost:3000/api/search | \
  jq -r '.[].uid' | xargs -I {} curl -H "Authorization: Bearer $GRAFANA_TOKEN" \
  http://localhost:3000/api/dashboards/uid/{} > dashboards_backup.json

# Clean up old logs
curl -X DELETE http://localhost:9200/electra-logs-$(date -d '30 days ago' +%Y.%m.%d)

# Review alert fatigue
curl http://localhost:9093/api/v1/alerts | jq '[.data[].labels.alertname] | group_by(.) | map({alert: .[0], count: length}) | sort_by(.count) | reverse'
```

#### Monthly Tasks
```bash
# Update monitoring stack
./scripts/deploy_monitoring.sh redeploy --environment production

# Review and optimize retention policies
# Check Prometheus storage usage
curl http://localhost:9090/api/v1/label/__name__/values | jq 'length'

# Generate monitoring report
./scripts/generate_monitoring_report.py --month $(date +%Y-%m)
```

## Communication Templates

### Initial Incident Report
```
🚨 INCIDENT DECLARED - P[SEVERITY]

INCIDENT: [Brief description]
TIME: [YYYY-MM-DD HH:MM UTC]
IMPACT: [Description of user impact]
STATUS: Investigating
RESPONDER: [Name]

We are investigating and will provide updates every 15 minutes.
```

### Status Update
```
📊 INCIDENT UPDATE - P[SEVERITY]

INCIDENT: [Brief description]  
TIME: [YYYY-MM-DD HH:MM UTC]
STATUS: [Current status]
PROGRESS: [What has been done]
NEXT STEPS: [What's being done next]
ETA: [Expected resolution time]

Next update in 15 minutes.
```

### Resolution Notice
```
✅ INCIDENT RESOLVED - P[SEVERITY]

INCIDENT: [Brief description]
RESOLVED: [YYYY-MM-DD HH:MM UTC]
DURATION: [Total incident time]
ROOT CAUSE: [Brief explanation]
RESOLUTION: [What fixed it]

Post-incident review will be scheduled within 24 hours.
```

## Post-Incident Procedures

### 1. Immediate Post-Resolution

```bash
# Verify full service restoration
curl -f https://electra.example.com/api/health/
kubectl get pods -n electra-production

# Check monitoring dashboards
# Verify all metrics are normal

# Update status page
echo "All systems operational" | status-page-update
```

### 2. Post-Incident Review (PIR)

**Schedule within 24 hours for P0/P1 incidents**

**PIR Agenda:**
1. Timeline reconstruction
2. Root cause analysis  
3. Response effectiveness review
4. Action items identification
5. Process improvements

### 3. Documentation Updates

- Update runbooks based on lessons learned
- Create/update monitoring alerts
- Document new procedures
- Share knowledge with team

## Escalation Procedures

### On-Call Escalation

1. **Primary On-Call**: Immediate response
2. **Secondary On-Call**: If no response in 15 minutes  
3. **Engineering Manager**: If no response in 30 minutes
4. **Director of Engineering**: For P0 incidents lasting >1 hour

### External Escalation

**Vendor Support:**
- AWS Support: `aws support create-case`
- Database Support: [vendor-specific procedures]
- Security Team: security@example.com

**Legal/Compliance:**
- Data Protection Officer: dpo@example.com
- Legal Team: legal@example.com (for security incidents)

## Contact Information

### Emergency Contacts
- **Primary On-Call**: +1-555-0123
- **Secondary On-Call**: +1-555-0124  
- **Engineering Manager**: +1-555-0125
- **Security Team**: +1-555-0126

### Slack Channels
- **#incident-response**: Primary coordination
- **#electra-alerts**: Automated alerts
- **#platform-team**: Team notifications
- **#security-incidents**: Security-related incidents

### External Services
- **Status Page**: status.electra.example.com
- **Monitoring Dashboard**: monitoring.electra.example.com
- **Log Aggregation**: logs.electra.example.com

## Quick Reference Commands

### System Status
```bash
# Overall health check
kubectl get pods -A | grep -v Running

# Service endpoints
kubectl get svc -n electra-production

# Recent events
kubectl get events -n electra-production --sort-by='.lastTimestamp' | head -10
```

### Emergency Actions
```bash
# Enable maintenance mode
kubectl patch ingress electra-ingress -n electra-production \
  -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/default-backend":"maintenance-service"}}}'

# Scale up for performance issues
kubectl scale deployment electra-web --replicas=10 -n electra-production

# Emergency rollback
kubectl rollout undo deployment/electra-web -n electra-production
```

### Data Recovery
```bash
# Database backup
./scripts/db_backup.sh production emergency-$(date +%Y%m%d-%H%M)

# Database restore
./scripts/db_restore.sh --latest production
```

---

**Remember: Stay calm, communicate clearly, and document everything. The goal is to restore service quickly while preserving the ability to learn from the incident.**