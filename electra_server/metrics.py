"""
Custom Prometheus metrics for Electra application.
"""
from prometheus_client import Counter, Gauge, Histogram, CollectorRegistry
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

# Custom registry for Electra metrics
electra_registry = CollectorRegistry()

# Election-specific metrics
votes_cast_total = Counter(
    'electra_votes_cast_total',
    'Total number of votes cast',
    ['election_id', 'election_name', 'vote_type'],
    registry=electra_registry
)

registered_voters_total = Gauge(
    'electra_registered_voters_total',
    'Total number of registered voters',
    ['election_id', 'election_name'],
    registry=electra_registry
)

active_voting_sessions = Gauge(
    'electra_active_voting_sessions',
    'Number of active voting sessions',
    registry=electra_registry
)

vote_queue_pending = Gauge(
    'electra_vote_queue_pending',
    'Number of votes pending in queue',
    registry=electra_registry
)

vote_queue_processing = Gauge(
    'electra_vote_queue_processing',
    'Number of votes currently being processed',
    registry=electra_registry
)

vote_queue_completed = Counter(
    'electra_vote_queue_completed',
    'Number of votes successfully processed',
    registry=electra_registry
)

# Security metrics
failed_login_attempts = Counter(
    'electra_failed_login_attempts_total',
    'Total number of failed login attempts',
    ['source_ip', 'user_type'],
    registry=electra_registry
)

suspicious_activities = Counter(
    'electra_suspicious_activities_total',
    'Total number of suspicious activities detected',
    ['activity_type', 'severity'],
    registry=electra_registry
)

audit_log_entries = Counter(
    'electra_audit_log_entries_total',
    'Total number of audit log entries',
    ['event_type', 'user_role'],
    registry=electra_registry
)

# Performance metrics
vote_processing_time = Histogram(
    'electra_vote_processing_seconds',
    'Time taken to process a vote',
    buckets=[0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0],
    registry=electra_registry
)

ballot_generation_time = Histogram(
    'electra_ballot_generation_seconds',
    'Time taken to generate a ballot',
    buckets=[0.1, 0.25, 0.5, 1.0, 2.5, 5.0],
    registry=electra_registry
)

# Database metrics
active_db_connections = Gauge(
    'electra_db_connections_active',
    'Number of active database connections',
    registry=electra_registry
)

# Queue health metrics
offline_sync_jobs = Gauge(
    'electra_offline_sync_jobs',
    'Number of offline synchronization jobs pending',
    registry=electra_registry
)

pending_ballots = Gauge(
    'electra_pending_ballots',
    'Number of ballots pending generation',
    registry=electra_registry
)


class ElectraMetricsCollector:
    """Custom metrics collector for Electra-specific metrics."""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
    
    def record_vote_cast(self, election_id, election_name, vote_type='standard'):
        """Record a vote being cast."""
        try:
            votes_cast_total.labels(
                election_id=election_id,
                election_name=election_name,
                vote_type=vote_type
            ).inc()
        except Exception as e:
            self.logger.error(f"Failed to record vote cast metric: {e}")
    
    def update_registered_voters(self, election_id, election_name, count):
        """Update registered voters count."""
        try:
            registered_voters_total.labels(
                election_id=election_id,
                election_name=election_name
            ).set(count)
        except Exception as e:
            self.logger.error(f"Failed to update registered voters metric: {e}")
    
    def update_active_sessions(self, count):
        """Update active voting sessions count."""
        try:
            active_voting_sessions.set(count)
        except Exception as e:
            self.logger.error(f"Failed to update active sessions metric: {e}")
    
    def update_queue_metrics(self, pending=None, processing=None):
        """Update vote queue metrics."""
        try:
            if pending is not None:
                vote_queue_pending.set(pending)
            if processing is not None:
                vote_queue_processing.set(processing)
        except Exception as e:
            self.logger.error(f"Failed to update queue metrics: {e}")
    
    def record_queue_completion(self):
        """Record a vote queue completion."""
        try:
            vote_queue_completed.inc()
        except Exception as e:
            self.logger.error(f"Failed to record queue completion: {e}")
    
    def record_failed_login(self, source_ip, user_type='unknown'):
        """Record a failed login attempt."""
        try:
            # Anonymize IP for privacy
            anonymized_ip = self._anonymize_ip(source_ip)
            failed_login_attempts.labels(
                source_ip=anonymized_ip,
                user_type=user_type
            ).inc()
        except Exception as e:
            self.logger.error(f"Failed to record failed login: {e}")
    
    def record_suspicious_activity(self, activity_type, severity='medium'):
        """Record suspicious activity."""
        try:
            suspicious_activities.labels(
                activity_type=activity_type,
                severity=severity
            ).inc()
        except Exception as e:
            self.logger.error(f"Failed to record suspicious activity: {e}")
    
    def record_audit_entry(self, event_type, user_role='unknown'):
        """Record an audit log entry."""
        try:
            audit_log_entries.labels(
                event_type=event_type,
                user_role=user_role
            ).inc()
        except Exception as e:
            self.logger.error(f"Failed to record audit entry: {e}")
    
    def record_vote_processing_time(self, duration_seconds):
        """Record vote processing time."""
        try:
            vote_processing_time.observe(duration_seconds)
        except Exception as e:
            self.logger.error(f"Failed to record vote processing time: {e}")
    
    def record_ballot_generation_time(self, duration_seconds):
        """Record ballot generation time."""
        try:
            ballot_generation_time.observe(duration_seconds)
        except Exception as e:
            self.logger.error(f"Failed to record ballot generation time: {e}")
    
    def update_db_connections(self, count):
        """Update active database connections count."""
        try:
            active_db_connections.set(count)
        except Exception as e:
            self.logger.error(f"Failed to update DB connections metric: {e}")
    
    def update_offline_sync_jobs(self, count):
        """Update offline sync jobs count."""
        try:
            offline_sync_jobs.set(count)
        except Exception as e:
            self.logger.error(f"Failed to update offline sync jobs: {e}")
    
    def update_pending_ballots(self, count):
        """Update pending ballots count."""
        try:
            pending_ballots.set(count)
        except Exception as e:
            self.logger.error(f"Failed to update pending ballots: {e}")
    
    def _anonymize_ip(self, ip_address):
        """Anonymize IP address for privacy."""
        if ':' in ip_address:  # IPv6
            parts = ip_address.split(':')
            return ':'.join(parts[:4] + ['xxxx'] * (len(parts) - 4))
        else:  # IPv4
            parts = ip_address.split('.')
            return '.'.join(parts[:3] + ['xxx'])


# Global metrics collector instance
metrics = ElectraMetricsCollector()