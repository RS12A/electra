#!/bin/bash
"""
Electra Monitoring Stack Deployment Script
Deploys and manages the complete monitoring and observability stack.
"""

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MONITORING_DIR="$PROJECT_ROOT/monitoring"
NAMESPACE="electra-monitoring"
HELM_TIMEOUT="600s"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# Help function
show_help() {
    cat << EOF
Electra Monitoring Stack Deployment Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    deploy      Deploy the complete monitoring stack
    teardown    Remove the monitoring stack
    redeploy    Teardown and redeploy the stack
    status      Check the status of monitoring components
    logs        Show logs from monitoring components
    test        Run monitoring tests and health checks

Options:
    --environment ENV    Target environment (dev, staging, prod) [default: dev]
    --platform PLATFORM  Target platform (docker, kubernetes) [default: docker]
    --namespace NS       Kubernetes namespace [default: electra-monitoring]
    --dry-run           Show what would be done without executing
    --skip-deps         Skip dependency checks
    --force             Force operations without confirmation
    --debug             Enable debug output
    --help              Show this help message

Examples:
    # Deploy to development with Docker
    $0 deploy --environment dev --platform docker

    # Deploy to production with Kubernetes
    $0 deploy --environment prod --platform kubernetes

    # Teardown and redeploy
    $0 redeploy --environment staging

    # Check status
    $0 status --platform kubernetes

Environment Variables:
    MONITORING_SLACK_WEBHOOK    Slack webhook for alerts
    MONITORING_EMAIL_FROM       Email address for alerts
    MONITORING_EMAIL_PASSWORD   Email password for alerts
    GRAFANA_ADMIN_PASSWORD      Grafana admin password
    SENTRY_DSN                  Sentry DSN for error tracking
EOF
}

# Dependency checks
check_dependencies() {
    if [[ "${SKIP_DEPS:-false}" == "true" ]]; then
        warn "Skipping dependency checks"
        return 0
    fi

    local missing_deps=()

    if [[ "$PLATFORM" == "kubernetes" ]]; then
        command -v kubectl >/dev/null 2>&1 || missing_deps+=("kubectl")
        command -v helm >/dev/null 2>&1 || missing_deps+=("helm")
    elif [[ "$PLATFORM" == "docker" ]]; then
        command -v docker >/dev/null 2>&1 || missing_deps+=("docker")
        command -v docker-compose >/dev/null 2>&1 || missing_deps+=("docker-compose")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing_deps[*]}"
        error "Please install the missing dependencies and try again"
        exit 1
    fi

    log "All dependencies satisfied"
}

# Create namespace for Kubernetes
create_namespace() {
    if [[ "$PLATFORM" == "kubernetes" ]]; then
        log "Creating namespace: $NAMESPACE"
        kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
        kubectl label namespace "$NAMESPACE" monitoring=electra --overwrite
    fi
}

# Deploy with Docker Compose
deploy_docker() {
    log "Deploying monitoring stack with Docker Compose"
    
    cd "$MONITORING_DIR/docker-compose"
    
    # Check if monitoring network exists, create if not
    if ! docker network ls | grep -q electra_network; then
        warn "Main application network not found. Creating electra_network..."
        docker network create electra_network
    fi
    
    # Generate environment file
    generate_env_file
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "DRY RUN: Would execute: docker-compose up -d"
        return 0
    fi
    
    # Deploy the stack
    docker-compose -f monitoring-stack.yml up -d
    
    # Wait for services to be healthy
    wait_for_docker_services
    
    log "Monitoring stack deployed successfully with Docker"
    show_access_urls_docker
}

# Deploy with Kubernetes/Helm
deploy_kubernetes() {
    log "Deploying monitoring stack with Kubernetes"
    
    create_namespace
    
    # Add Helm repositories
    log "Adding Helm repositories"
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
    helm repo update
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "DRY RUN: Would deploy Helm charts"
        return 0
    fi
    
    # Deploy Prometheus stack
    deploy_prometheus_stack
    
    # Deploy Jaeger
    deploy_jaeger
    
    # Deploy Loki
    deploy_loki
    
    # Apply custom configurations
    apply_custom_configs
    
    log "Monitoring stack deployed successfully with Kubernetes"
    show_access_urls_kubernetes
}

# Deploy Prometheus monitoring stack
deploy_prometheus_stack() {
    log "Deploying Prometheus monitoring stack"
    
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace "$NAMESPACE" \
        --timeout "$HELM_TIMEOUT" \
        --set grafana.adminPassword="${GRAFANA_ADMIN_PASSWORD:-your_KEY_goes_here}" \
        --set grafana.persistence.enabled=true \
        --set grafana.persistence.size=10Gi \
        --set prometheus.prometheusSpec.retention=15d \
        --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=20Gi \
        --set alertmanager.config.global.slack_api_url="${MONITORING_SLACK_WEBHOOK:-your_KEY_goes_here}" \
        --values "$MONITORING_DIR/helm-charts/prometheus-values.yaml" \
        --wait
}

# Deploy Jaeger tracing
deploy_jaeger() {
    log "Deploying Jaeger tracing"
    
    helm upgrade --install jaeger jaegertracing/jaeger \
        --namespace "$NAMESPACE" \
        --timeout "$HELM_TIMEOUT" \
        --set provisionDataStore.cassandra=false \
        --set storage.type=memory \
        --set agent.enabled=true \
        --set collector.enabled=true \
        --set query.enabled=true \
        --wait
}

# Deploy Loki logging
deploy_loki() {
    log "Deploying Loki logging stack"
    
    helm upgrade --install loki grafana/loki-stack \
        --namespace "$NAMESPACE" \
        --timeout "$HELM_TIMEOUT" \
        --set loki.persistence.enabled=true \
        --set loki.persistence.size=10Gi \
        --set promtail.enabled=true \
        --wait
}

# Apply custom configurations
apply_custom_configs() {
    log "Applying custom configurations"
    
    # Apply ServiceMonitors
    kubectl apply -f "$MONITORING_DIR/prometheus/servicemonitor.yaml" -n "$NAMESPACE"
    
    # Apply custom dashboards
    if [[ -d "$MONITORING_DIR/grafana/dashboards" ]]; then
        kubectl create configmap grafana-dashboards \
            --from-file="$MONITORING_DIR/grafana/dashboards/" \
            -n "$NAMESPACE" \
            --dry-run=client -o yaml | kubectl apply -f -
    fi
}

# Generate environment file for Docker
generate_env_file() {
    local env_file="$MONITORING_DIR/docker-compose/.env"
    
    cat > "$env_file" << EOF
# Electra Monitoring Stack Environment Configuration
# Generated at $(date)

# Grafana Configuration
GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-your_KEY_goes_here}

# Alertmanager Configuration
SLACK_WEBHOOK_URL=${MONITORING_SLACK_WEBHOOK:-your_KEY_goes_here}
EMAIL_FROM=${MONITORING_EMAIL_FROM:-alerts@electra.com}
EMAIL_PASSWORD=${MONITORING_EMAIL_PASSWORD:-your_KEY_goes_here}

# Sentry Configuration
SENTRY_DSN=${SENTRY_DSN:-your_KEY_goes_here}

# Environment
ENVIRONMENT=${ENVIRONMENT}
EOF
    
    log "Generated environment file: $env_file"
}

# Wait for Docker services to be healthy
wait_for_docker_services() {
    log "Waiting for services to be healthy"
    
    local services=("prometheus" "grafana" "loki" "jaeger")
    local max_wait=300  # 5 minutes
    local wait_interval=10
    local elapsed=0
    
    while [[ $elapsed -lt $max_wait ]]; do
        local all_healthy=true
        
        for service in "${services[@]}"; do
            if ! docker-compose -f monitoring-stack.yml ps "$service" | grep -q "healthy\|Up"; then
                all_healthy=false
                break
            fi
        done
        
        if [[ "$all_healthy" == "true" ]]; then
            log "All services are healthy"
            return 0
        fi
        
        log "Waiting for services to be healthy... (${elapsed}s/${max_wait}s)"
        sleep $wait_interval
        elapsed=$((elapsed + wait_interval))
    done
    
    warn "Some services may not be fully healthy yet. Check with: $0 status"
}

# Show access URLs for Docker deployment
show_access_urls_docker() {
    log "Monitoring services are available at:"
    echo "  Grafana:     http://localhost:3000 (admin/your_KEY_goes_here)"
    echo "  Prometheus:  http://localhost:9090"
    echo "  Alertmanager: http://localhost:9093"
    echo "  Jaeger:      http://localhost:16686"
    echo "  Kibana:      http://localhost:5601"
}

# Show access URLs for Kubernetes deployment
show_access_urls_kubernetes() {
    log "Setting up port forwards for monitoring services"
    
    # Create port-forward script
    cat > "$PROJECT_ROOT/port-forward-monitoring.sh" << 'EOF'
#!/bin/bash
# Port forward script for Electra monitoring services

kubectl port-forward -n electra-monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
kubectl port-forward -n electra-monitoring svc/prometheus-grafana 3000:80 &
kubectl port-forward -n electra-monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093 &
kubectl port-forward -n electra-monitoring svc/jaeger-query 16686:16686 &
kubectl port-forward -n electra-monitoring svc/loki 3100:3100 &

echo "Port forwards established. Press Ctrl+C to stop."
wait
EOF
    
    chmod +x "$PROJECT_ROOT/port-forward-monitoring.sh"
    
    log "Monitoring services deployed. To access them locally, run:"
    echo "  $PROJECT_ROOT/port-forward-monitoring.sh"
    echo ""
    log "Then access at:"
    echo "  Grafana:     http://localhost:3000"
    echo "  Prometheus:  http://localhost:9090"
    echo "  Alertmanager: http://localhost:9093"
    echo "  Jaeger:      http://localhost:16686"
    echo "  Loki:        http://localhost:3100"
}

# Teardown monitoring stack
teardown() {
    log "Tearing down monitoring stack"
    
    if [[ "${FORCE:-false}" != "true" ]]; then
        read -p "Are you sure you want to teardown the monitoring stack? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Teardown cancelled"
            exit 0
        fi
    fi
    
    if [[ "$PLATFORM" == "docker" ]]; then
        cd "$MONITORING_DIR/docker-compose"
        docker-compose -f monitoring-stack.yml down -v
        log "Docker monitoring stack torn down"
    elif [[ "$PLATFORM" == "kubernetes" ]]; then
        helm uninstall prometheus -n "$NAMESPACE" 2>/dev/null || true
        helm uninstall jaeger -n "$NAMESPACE" 2>/dev/null || true
        helm uninstall loki -n "$NAMESPACE" 2>/dev/null || true
        kubectl delete namespace "$NAMESPACE" 2>/dev/null || true
        log "Kubernetes monitoring stack torn down"
    fi
}

# Check status of monitoring components
check_status() {
    log "Checking monitoring stack status"
    
    if [[ "$PLATFORM" == "docker" ]]; then
        cd "$MONITORING_DIR/docker-compose"
        docker-compose -f monitoring-stack.yml ps
    elif [[ "$PLATFORM" == "kubernetes" ]]; then
        kubectl get pods -n "$NAMESPACE"
        echo ""
        kubectl get svc -n "$NAMESPACE"
    fi
}

# Show logs from monitoring components
show_logs() {
    local service="${1:-}"
    
    if [[ -z "$service" ]]; then
        echo "Available services:"
        if [[ "$PLATFORM" == "docker" ]]; then
            docker-compose -f "$MONITORING_DIR/docker-compose/monitoring-stack.yml" config --services
        elif [[ "$PLATFORM" == "kubernetes" ]]; then
            kubectl get pods -n "$NAMESPACE" -o name | sed 's/pod\///'
        fi
        return 0
    fi
    
    if [[ "$PLATFORM" == "docker" ]]; then
        docker-compose -f "$MONITORING_DIR/docker-compose/monitoring-stack.yml" logs -f "$service"
    elif [[ "$PLATFORM" == "kubernetes" ]]; then
        kubectl logs -f -n "$NAMESPACE" "$service"
    fi
}

# Run monitoring tests
run_tests() {
    log "Running monitoring tests"
    
    # Test Prometheus metrics endpoint
    if curl -f http://localhost:9090/-/healthy >/dev/null 2>&1; then
        log "✅ Prometheus is healthy"
    else
        error "❌ Prometheus health check failed"
    fi
    
    # Test Grafana
    if curl -f http://localhost:3000/api/health >/dev/null 2>&1; then
        log "✅ Grafana is healthy"
    else
        error "❌ Grafana health check failed"
    fi
    
    # Test main application metrics endpoint
    if curl -f http://localhost:8000/metrics >/dev/null 2>&1; then
        log "✅ Django metrics endpoint is accessible"
    else
        warn "⚠️  Django metrics endpoint not accessible (application may not be running)"
    fi
    
    log "Health checks completed"
}

# Main function
main() {
    # Set defaults
    ENVIRONMENT="${ENVIRONMENT:-dev}"
    PLATFORM="${PLATFORM:-docker}"
    COMMAND=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            deploy|teardown|redeploy|status|logs|test)
                COMMAND="$1"
                shift
                ;;
            --environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            --platform)
                PLATFORM="$2"
                shift 2
                ;;
            --namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --debug)
                DEBUG=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    if [[ -z "$COMMAND" ]]; then
        error "No command specified"
        show_help
        exit 1
    fi
    
    # Validate platform
    if [[ "$PLATFORM" != "docker" && "$PLATFORM" != "kubernetes" ]]; then
        error "Invalid platform: $PLATFORM. Must be 'docker' or 'kubernetes'"
        exit 1
    fi
    
    log "Starting $COMMAND for environment: $ENVIRONMENT, platform: $PLATFORM"
    
    # Check dependencies
    check_dependencies
    
    # Execute command
    case "$COMMAND" in
        deploy)
            if [[ "$PLATFORM" == "docker" ]]; then
                deploy_docker
            else
                deploy_kubernetes
            fi
            ;;
        teardown)
            teardown
            ;;
        redeploy)
            teardown
            sleep 5
            if [[ "$PLATFORM" == "docker" ]]; then
                deploy_docker
            else
                deploy_kubernetes
            fi
            ;;
        status)
            check_status
            ;;
        logs)
            show_logs "$2"
            ;;
        test)
            run_tests
            ;;
        *)
            error "Unknown command: $COMMAND"
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"