"""
OpenTelemetry instrumentation configuration for Electra.
"""
import logging
from django.conf import settings
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.instrumentation.django import DjangoInstrumentor
from opentelemetry.instrumentation.psycopg2 import Psycopg2Instrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.propagate import set_global_textmap
from opentelemetry.propagators.b3 import B3MultiFormat

logger = logging.getLogger(__name__)


def configure_tracing():
    """Configure OpenTelemetry tracing."""
    try:
        # Create resource with service information
        resource = Resource.create({
            "service.name": getattr(settings, 'OTEL_SERVICE_NAME', 'electra-django'),
            "service.version": "1.0.0",
            "service.namespace": "electra",
            "deployment.environment": getattr(settings, 'DJANGO_ENV', 'development'),
        })
        
        # Configure tracer provider
        trace.set_tracer_provider(TracerProvider(resource=resource))
        
        # Configure Jaeger exporter
        jaeger_exporter = JaegerExporter(
            agent_host_name=getattr(settings, 'OTEL_EXPORTER_JAEGER_AGENT_HOST', 'jaeger'),
            agent_port=getattr(settings, 'OTEL_EXPORTER_JAEGER_AGENT_PORT', 14268),
            collector_endpoint=getattr(settings, 'OTEL_EXPORTER_JAEGER_ENDPOINT', 
                                     'http://jaeger:14268/api/traces'),
        )
        
        # Add span processor
        span_processor = BatchSpanProcessor(jaeger_exporter)
        trace.get_tracer_provider().add_span_processor(span_processor)
        
        # Set global propagator
        set_global_textmap(B3MultiFormat())
        
        # Instrument Django
        DjangoInstrumentor().instrument()
        
        # Instrument database
        Psycopg2Instrumentor().instrument()
        
        # Instrument HTTP requests
        RequestsInstrumentor().instrument()
        
        logger.info("OpenTelemetry tracing configured successfully")
        
    except Exception as e:
        logger.error(f"Failed to configure OpenTelemetry tracing: {e}")


def get_tracer(name: str = __name__):
    """Get a tracer instance."""
    return trace.get_tracer(name)


class ElectraTracer:
    """Custom tracer for Electra-specific operations."""
    
    def __init__(self):
        self.tracer = get_tracer("electra.custom")
    
    def trace_vote_processing(self, election_id, voter_id=None):
        """Create a span for vote processing."""
        return self.tracer.start_span(
            "vote.process",
            attributes={
                "election.id": election_id,
                "voter.id": voter_id if voter_id else "anonymous",
                "operation.type": "vote_processing"
            }
        )
    
    def trace_ballot_generation(self, election_id, ballot_type):
        """Create a span for ballot generation."""
        return self.tracer.start_span(
            "ballot.generate",
            attributes={
                "election.id": election_id,
                "ballot.type": ballot_type,
                "operation.type": "ballot_generation"
            }
        )
    
    def trace_auth_operation(self, operation_type, user_id=None):
        """Create a span for authentication operations."""
        return self.tracer.start_span(
            f"auth.{operation_type}",
            attributes={
                "user.id": user_id if user_id else "anonymous",
                "operation.type": f"auth_{operation_type}"
            }
        )
    
    def trace_database_query(self, query_type, table_name=None):
        """Create a span for database queries."""
        return self.tracer.start_span(
            f"db.{query_type}",
            attributes={
                "db.operation": query_type,
                "db.table": table_name if table_name else "unknown",
                "operation.type": "database_query"
            }
        )
    
    def trace_audit_operation(self, event_type, user_id=None):
        """Create a span for audit operations."""
        return self.tracer.start_span(
            f"audit.{event_type}",
            attributes={
                "audit.event_type": event_type,
                "user.id": user_id if user_id else "system",
                "operation.type": "audit_logging"
            }
        )


# Global tracer instance
electra_tracer = ElectraTracer()


def add_span_attributes(span, **attributes):
    """Add custom attributes to a span."""
    try:
        for key, value in attributes.items():
            span.set_attribute(key, str(value))
    except Exception as e:
        logger.error(f"Failed to add span attributes: {e}")


def record_exception(span, exception):
    """Record an exception in a span."""
    try:
        span.record_exception(exception)
        span.set_status(trace.Status(trace.StatusCode.ERROR, str(exception)))
    except Exception as e:
        logger.error(f"Failed to record exception in span: {e}")


# Initialize tracing if enabled
if getattr(settings, 'ELECTRA_METRICS_ENABLED', True):
    configure_tracing()