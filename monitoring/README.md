# Electra Monitoring & Observability System

A comprehensive, production-grade monitoring and observability stack for the Electra secure digital voting system.

## 🎯 Overview

This monitoring system provides complete visibility into the Electra platform with:

- **Metrics Collection**: Prometheus for time-series metrics
- **Centralized Logging**: ELK stack (Elasticsearch, Logstash, Kibana) + Loki/Grafana
- **Distributed Tracing**: Jaeger for request tracing across services
- **Visualization**: Grafana dashboards for metrics and logs
- **Alerting**: Prometheus AlertManager with multi-channel notifications
- **Audit Logging**: Tamper-proof, cryptographically signed audit trails
- **Client Observability**: Sentry integration for Flutter apps

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Django App    │    │  Flutter App    │    │  Infrastructure │
│                 │    │                 │    │                 │
│ • django-       │    │ • Sentry        │    │ • Node Exporter │
│   prometheus    │    │ • Log Shipping  │    │ • cAdvisor      │
│ • OpenTelemetry │    │ • Performance   │    │ • Postgres      │
│ • Custom        │    │   Monitoring    │    │   Exporter      │
│   Metrics       │    │                 │    │ • Redis Exporter│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
            ┌────────────────────┴────────────────────┐
            │             Monitoring Stack             │
            │                                         │
            │  ┌─────────────┐  ┌─────────────────┐   │
            │  │ Prometheus  │  │   Alertmanager  │   │
            │  │             │  │                 │   │
            │  │ • Metrics   │  │ • Slack/Email   │   │
            │  │ • Rules     │  │ • Webhooks      │   │
            │  │ • Targets   │  │ • Escalation    │   │
            │  └─────────────┘  └─────────────────┘   │
            │                                         │
            │  ┌─────────────┐  ┌─────────────────┐   │
            │  │   Grafana   │  │     Jaeger      │   │
            │  │             │  │                 │   │
            │  │ • Dashboards│  │ • Traces        │   │
            │  │ • Alerts    │  │ • Performance   │   │
            │  │ • Users     │  │ • Dependencies  │   │
            │  └─────────────┘  └─────────────────┘   │
            │                                         │
            │  ┌─────────────┐  ┌─────────────────┐   │
            │  │    Loki     │  │ Elasticsearch   │   │
            │  │             │  │                 │   │
            │  │ • Log       │  │ • Audit Logs    │   │
            │  │   Aggregation│  │ • Search        │   │
            │  │ • Querying  │  │ • Analytics     │   │
            │  └─────────────┘  └─────────────────┘   │
            └─────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Kubernetes cluster (optional, for production)
- Helm 3.x (for Kubernetes deployment)

### Local Development Setup

1. **Clone and navigate to monitoring directory:**
   ```bash
   cd monitoring
   ```

2. **Deploy with Docker Compose:**
   ```bash
   ./scripts/deploy_monitoring.sh deploy --environment dev --platform docker
   ```

3. **Access monitoring services:**
   - Grafana: http://localhost:3000 (admin/your_KEY_goes_here)
   - Prometheus: http://localhost:9090
   - Jaeger: http://localhost:16686
   - Kibana: http://localhost:5601

### Production Kubernetes Setup

1. **Deploy to Kubernetes:**
   ```bash
   ./scripts/deploy_monitoring.sh deploy --environment prod --platform kubernetes
   ```

2. **Set up port forwarding:**
   ```bash
   ./port-forward-monitoring.sh
   ```

## 📊 Dashboards

### Pre-configured Grafana Dashboards

1. **Election Turnout Dashboard** (`dashboards/election-turnout.json`)
   - Real-time vote count vs registered voters
   - Turnout percentage with thresholds
   - Votes cast over time
   - Vote distribution by election
   - Active voting sessions
   - Vote processing queue status

2. **System Health Dashboard** (`dashboards/system-health.json`)
   - Service availability status
   - CPU and memory utilization
   - API request rates and response times
   - Database query performance
   - Disk usage monitoring
   - Network and container metrics

3. **Error & Exception Dashboard**
   - Error rates by service and endpoint
   - Exception types and frequencies
   - Failed authentication attempts
   - Security incidents timeline

4. **Queue Health Dashboard**
   - Offline sync job status
   - Pending ballot generation
   - Background task performance
   - Worker health and capacity

### Dashboard Features

- **Real-time Updates**: Auto-refresh every 10-30 seconds
- **Interactive Filters**: Filter by time range, environment, service
- **Drill-down**: Click metrics to view detailed logs/traces
- **Alerting**: Visual alert indicators and notifications
- **Mobile Responsive**: Optimized for mobile viewing

## 🚨 Alerting

### Alert Rules

Critical alerts are configured in `prometheus/alert_rules.yml`:

#### Service Availability
- **ElectraServiceDown**: Service unavailable for >1 minute
- **DatabaseConnectionsHigh**: >80 active DB connections
- **HighMemoryUsage**: >85% memory utilization

#### Performance
- **HighErrorRate**: >5% error rate for 5 minutes
- **DatabaseHighLatency**: DB queries >500ms
- **HighAPILatency**: 95th percentile >2 seconds

#### Security
- **FailedAuthenticationSpike**: >10 failed logins/second
- **AnomalousVotingPattern**: Vote rate 3x above normal
- **SSLCertificateExpiringSoon**: Certificate expires <30 days

#### Election-Specific
- **VotingQueueBacklog**: >100 pending votes for 5 minutes

### Alert Channels

Configured in `alertmanager/alertmanager.yml`:

- **Slack**: Real-time notifications to channels
- **Email**: Critical alerts to security team
- **Webhooks**: Integration with external systems
- **Escalation**: Automatic escalation for unacknowledged critical alerts

### Testing Alerts

```bash
# Test alert firing
curl -X POST http://localhost:9090/api/v1/alerts

# Simulate high error rate
for i in {1..100}; do curl -f http://localhost:8000/api/invalid-endpoint; done

# Check alert status
curl http://localhost:9093/api/v1/alerts
```

## 📋 Logs

### Centralized Logging Architecture

#### Django Backend Logs
- **JSON Format**: Structured logging with correlation IDs
- **Request Tracking**: Full request lifecycle logging
- **Security Events**: Authentication, authorization, suspicious activity
- **Performance Metrics**: Response times, database queries

#### Flutter Client Logs
- **Secure Shipping**: Encrypted log transmission to backend
- **Privacy Aware**: Automatic PII redaction
- **Performance Tracking**: App startup, screen transitions, API calls
- **Error Reporting**: Crash reports and exception tracking

#### Log Retention
- **Application Logs**: 30 days in Elasticsearch
- **Audit Logs**: Permanent retention with integrity verification
- **Performance Logs**: 7 days for analysis
- **Security Logs**: 90 days minimum

### Log Queries

#### Common Elasticsearch/Kibana Queries

```json
# High error rate detection
{
  "query": {
    "bool": {
      "must": [
        {"range": {"@timestamp": {"gte": "now-5m"}}},
        {"term": {"level": "ERROR"}}
      ]
    }
  }
}

# Failed authentication attempts
{
  "query": {
    "bool": {
      "must": [
        {"match": {"message": "authentication failed"}},
        {"range": {"@timestamp": {"gte": "now-1h"}}}
      ]
    }
  }
}

# Vote casting events
{
  "query": {
    "bool": {
      "must": [
        {"term": {"event_type": "vote_cast"}},
        {"term": {"election_id": "election-123"}}
      ]
    }
  }
}
```

## 🔍 Tracing

### OpenTelemetry Integration

Distributed tracing across all services:

#### Django Instrumentation
- **HTTP Requests**: Automatic request/response tracing
- **Database Queries**: PostgreSQL query performance
- **Background Tasks**: Celery task execution
- **External APIs**: Third-party service calls

#### Custom Spans
```python
from electra_server.telemetry import electra_tracer

# Vote processing tracing
with electra_tracer.trace_vote_processing(election_id, voter_id) as span:
    result = process_vote(vote_data)
    span.set_attribute("vote.result", result.status)
```

#### Flutter Tracing
- **Screen Navigation**: Page transitions and load times
- **API Calls**: Request/response correlation
- **User Interactions**: Button clicks, form submissions

### Trace Analysis

Access Jaeger UI to:
- **Find Traces**: Search by service, operation, tags
- **Performance Analysis**: Identify bottlenecks and latencies
- **Dependency Mapping**: Visualize service dependencies
- **Error Investigation**: Trace error propagation

## 🔐 Audit Logging

### Tamper-Proof Audit System

Critical security events are logged with cryptographic signatures:

#### Audit Log Features
- **RSA Signatures**: Each log entry digitally signed
- **Immutable Storage**: Append-only log files
- **Content Hashing**: SHA-256 integrity verification
- **Privacy Protection**: Voter ID anonymization

#### Audit Events
- **Vote Casting**: Every vote with ballot hash
- **Election Management**: Start/stop elections, configuration changes
- **Security Events**: Failed logins, suspicious activities
- **Data Access**: Sensitive data queries and exports

#### Log Verification

```bash
# Verify single day
./scripts/verify_audit_logs.py --public-key keys/audit_public.pem \
                               --log-dir audit_logs \
                               --date 2024-01-15

# Verify date range with report
./scripts/verify_audit_logs.py --public-key keys/audit_public.pem \
                               --log-dir audit_logs \
                               --start-date 2024-01-01 \
                               --end-date 2024-01-31 \
                               --report-file audit_report.txt
```

## 🎛️ Configuration

### Environment Variables

Create `.env` file for Docker deployment:

```bash
# Grafana
GRAFANA_ADMIN_PASSWORD=your_secure_password_here

# Alerting
MONITORING_SLACK_WEBHOOK=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
MONITORING_EMAIL_FROM=alerts@your-domain.com
MONITORING_EMAIL_PASSWORD=your_email_password_here

# Sentry (optional)
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id

# Environment
ENVIRONMENT=production
```

### Django Settings

Add to your Django settings:

```python
# Monitoring configuration
PROMETHEUS_EXPORT_MIGRATIONS = False
ELECTRA_METRICS_ENABLED = True

# OpenTelemetry
OTEL_SERVICE_NAME = 'electra-django'
OTEL_EXPORTER_JAEGER_ENDPOINT = 'http://jaeger:14268/api/traces'

# Sentry
SENTRY_DSN = 'your_KEY_goes_here'
```

### Flutter Configuration

Initialize monitoring in your Flutter app:

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'your_KEY_goes_here';
      options.environment = 'production';
      options.tracesSampleRate = 0.1;
    },
    appRunner: () => runApp(MyApp()),
  );
}
```

## 🧪 Testing & Validation

### Health Checks

```bash
# Run comprehensive health check
./scripts/deploy_monitoring.sh test

# Individual service checks
curl -f http://localhost:9090/-/healthy    # Prometheus
curl -f http://localhost:3000/api/health   # Grafana
curl -f http://localhost:16686/           # Jaeger
```

### Load Testing

Generate test metrics and logs:

```bash
# Generate test votes
python scripts/generate_test_data.py --votes 1000 --elections 5

# Simulate high load
ab -n 1000 -c 10 http://localhost:8000/api/health/

# Generate test alerts
curl -X POST http://localhost:9090/api/v1/admin/tsdb/delete_series?match[]={__name__!=""}
```

### Monitoring Validation

1. **Metrics Collection**: Verify metrics in Prometheus
2. **Dashboard Functionality**: Test all dashboard panels
3. **Alert Firing**: Trigger test alerts and verify notifications
4. **Log Shipping**: Confirm logs appear in Elasticsearch/Loki
5. **Trace Collection**: Generate traces and verify in Jaeger

## 🔧 Troubleshooting

### Common Issues

#### Metrics Not Appearing
```bash
# Check Django metrics endpoint
curl http://localhost:8000/metrics

# Verify Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check Prometheus logs
docker logs electra-prometheus
```

#### Alerts Not Firing
```bash
# Check alert rules syntax
promtool check rules prometheus/alert_rules.yml

# Verify alertmanager config
curl http://localhost:9093/api/v1/status

# Test alert routing
curl -XPOST http://localhost:9093/api/v1/alerts -d '[{"labels":{"alertname":"test"}}]'
```

#### Logs Not Shipping
```bash
# Check Elasticsearch health
curl http://localhost:9200/_cluster/health

# Verify log shipping service
curl -X POST http://localhost:5000/logs/ingest -d '{"test": "log"}'

# Check Logstash processing
docker logs electra-logstash
```

### Performance Tuning

#### Resource Limits
- **Prometheus**: 2GB RAM, 20GB storage
- **Elasticsearch**: 4GB RAM, 50GB storage
- **Grafana**: 512MB RAM
- **Jaeger**: 1GB RAM

#### Retention Policies
- **Metrics**: 15 days default
- **Traces**: 7 days default
- **Logs**: 30 days application, permanent audit

## 📚 References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)
- [OpenTelemetry Python](https://opentelemetry-python.readthedocs.io/)
- [Sentry Flutter](https://docs.sentry.io/platforms/flutter/)

## 🆘 Support

For monitoring issues:

1. Check service logs: `./scripts/deploy_monitoring.sh logs [service]`
2. Verify configuration: `./scripts/deploy_monitoring.sh status`
3. Review runbooks: `runbooks/incident_response.md`
4. Contact monitoring team: monitoring@your-domain.com

---

**Last Updated**: $(date)
**Version**: 1.0.0