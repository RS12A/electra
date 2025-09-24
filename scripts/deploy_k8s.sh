#!/bin/bash
set -euo pipefail

# Electra Kubernetes Deployment Script
# Production-grade Kubernetes deployment with Blue/Green strategy

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NAMESPACE="electra"
APP_NAME="electra"
STRATEGY="blue-green"
ACTION="deploy"

# Default values
DEPLOYMENT_TIMEOUT="600s"
HEALTH_CHECK_TIMEOUT="300s"
ROLLBACK_TIMEOUT="300s"

# Logging functions
log() {
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] $*" >&2
}

log_error() {
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] ERROR: $*" >&2
}

log_info() {
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] INFO: $*" >&2
}

log_success() {
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] SUCCESS: $*" >&2
}

log_warning() {
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] WARNING: $*" >&2
}

# Error handling
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Deployment failed with exit code $exit_code"
        
        # Cleanup temporary resources
        kubectl delete configmap electra-temp-config -n "$NAMESPACE" 2>/dev/null || true
        kubectl delete secret electra-temp-secret -n "$NAMESPACE" 2>/dev/null || true
    fi
    exit $exit_code
}

trap cleanup EXIT

# Usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy Electra application to Kubernetes using Blue/Green strategy

OPTIONS:
    --namespace NAMESPACE       Kubernetes namespace [default: electra]
    --image IMAGE              Docker image to deploy [required for deploy action]
    --version VERSION          Application version [required for deploy action]
    --strategy STRATEGY        Deployment strategy (blue-green|canary) [default: blue-green]
    --environment ENV          Environment (staging|production) [default: staging]
    --action ACTION            Action to perform (deploy|switch-traffic|rollback|status)
    --target-version VERSION   Target version for rollback
    --dry-run                  Show what would be deployed without actually deploying
    --timeout TIMEOUT          Deployment timeout [default: 600s]
    --health-timeout TIMEOUT   Health check timeout [default: 300s]
    --config-file FILE         Path to deployment configuration file
    --force                    Force deployment even if validation fails
    -h, --help                Show this help message

ACTIONS:
    deploy              Deploy new version (Blue/Green)
    switch-traffic      Switch traffic to Green deployment
    rollback            Rollback to previous version
    status              Show deployment status
    cleanup             Cleanup old deployments

EXAMPLES:
    $0 --image ghcr.io/rs12a/electra:v1.0.0 --version v1.0.0 --environment production
    $0 --action switch-traffic --version v1.0.0 --namespace electra-prod
    $0 --action rollback --target-version v0.9.0 --environment production
    $0 --action status --namespace electra-staging

ENVIRONMENT VARIABLES:
    KUBECONFIG              Path to kubeconfig file
    KUBECTL_CONTEXT         Kubectl context to use
    DATABASE_URL            Database connection string
    REGISTRY_CREDENTIALS    Docker registry credentials

EOF
}

# Parse command line arguments
IMAGE=""
VERSION=""
ENVIRONMENT="staging"
DRY_RUN=false
CONFIG_FILE=""
FORCE=false
TARGET_VERSION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --image)
            IMAGE="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --strategy)
            STRATEGY="$2"
            shift 2
            ;;
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --action)
            ACTION="$2"
            shift 2
            ;;
        --target-version)
            TARGET_VERSION="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --timeout)
            DEPLOYMENT_TIMEOUT="$2"
            shift 2
            ;;
        --health-timeout)
            HEALTH_CHECK_TIMEOUT="$2"
            shift 2
            ;;
        --config-file)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate parameters
validate_parameters() {
    case "$ACTION" in
        "deploy")
            if [[ -z "$IMAGE" ]] || [[ -z "$VERSION" ]]; then
                log_error "Image and version are required for deploy action"
                exit 1
            fi
            ;;
        "switch-traffic"|"rollback")
            if [[ -z "$VERSION" && -z "$TARGET_VERSION" ]]; then
                log_error "Version or target-version is required for $ACTION action"
                exit 1
            fi
            ;;
        "status"|"cleanup")
            # No additional parameters required
            ;;
        *)
            log_error "Invalid action: $ACTION"
            exit 1
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check kubectl context
    if ! kubectl config current-context &> /dev/null; then
        log_error "No kubectl context configured"
        exit 1
    fi
    
    # Check namespace exists
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_info "Creating namespace: $NAMESPACE"
        if [[ "$DRY_RUN" == false ]]; then
            kubectl create namespace "$NAMESPACE"
        fi
    fi
    
    # Check cluster connectivity
    if ! kubectl get nodes &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Get current deployment state
get_deployment_state() {
    local blue_ready=false
    local green_ready=false
    local active_color=""
    
    # Check blue deployment
    if kubectl get deployment "$APP_NAME-blue" -n "$NAMESPACE" &> /dev/null; then
        local blue_replicas
        blue_replicas=$(kubectl get deployment "$APP_NAME-blue" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' || echo "0")
        if [[ "$blue_replicas" -gt 0 ]]; then
            blue_ready=true
        fi
    fi
    
    # Check green deployment
    if kubectl get deployment "$APP_NAME-green" -n "$NAMESPACE" &> /dev/null; then
        local green_replicas
        green_replicas=$(kubectl get deployment "$APP_NAME-green" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' || echo "0")
        if [[ "$green_replicas" -gt 0 ]]; then
            green_ready=true
        fi
    fi
    
    # Determine active color from service
    if kubectl get service "$APP_NAME" -n "$NAMESPACE" &> /dev/null; then
        local service_selector
        service_selector=$(kubectl get service "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.selector.version}' || echo "")
        if [[ "$service_selector" == *"blue"* ]]; then
            active_color="blue"
        elif [[ "$service_selector" == *"green"* ]]; then
            active_color="green"
        fi
    fi
    
    echo "$blue_ready:$green_ready:$active_color"
}

# Generate Kubernetes manifests
generate_manifests() {
    local color=$1
    local image=$2
    local version=$3
    
    # Deployment manifest
    cat > "/tmp/$APP_NAME-$color-deployment.yaml" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $APP_NAME-$color
  namespace: $NAMESPACE
  labels:
    app: $APP_NAME
    version: $version
    color: $color
    environment: $ENVIRONMENT
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: $APP_NAME
      color: $color
  template:
    metadata:
      labels:
        app: $APP_NAME
        version: $version
        color: $color
        environment: $ENVIRONMENT
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
      - name: $APP_NAME
        image: $image
        imagePullPolicy: Always
        ports:
        - containerPort: 8000
          name: http
          protocol: TCP
        env:
        - name: DJANGO_SETTINGS_MODULE
          value: "electra_server.settings.prod"
        - name: ENVIRONMENT
          value: "$ENVIRONMENT"
        - name: VERSION
          value: "$version"
        - name: COLOR
          value: "$color"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: electra-secrets
              key: database-url
        - name: DJANGO_SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: electra-secrets
              key: django-secret-key
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /api/health/
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /api/health/
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        volumeMounts:
        - name: static-files
          mountPath: /app/staticfiles
        - name: media-files
          mountPath: /app/media
      volumes:
      - name: static-files
        persistentVolumeClaim:
          claimName: electra-static-pvc
      - name: media-files
        persistentVolumeClaim:
          claimName: electra-media-pvc
      imagePullSecrets:
      - name: registry-credentials
EOF

    # Service manifest (only create if it doesn't exist)
    if ! kubectl get service "$APP_NAME" -n "$NAMESPACE" &> /dev/null; then
        cat > "/tmp/$APP_NAME-service.yaml" << EOF
apiVersion: v1
kind: Service
metadata:
  name: $APP_NAME
  namespace: $NAMESPACE
  labels:
    app: $APP_NAME
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8000
    protocol: TCP
    name: http
  selector:
    app: $APP_NAME
    color: blue  # Initially point to blue
EOF
    fi
}

# Deploy new version
deploy_new_version() {
    local image=$1
    local version=$2
    
    log_info "Starting deployment of version $version"
    
    # Get current deployment state
    local state
    state=$(get_deployment_state)
    IFS=':' read -r blue_ready green_ready active_color <<< "$state"
    
    # Determine target color for new deployment
    local target_color="green"
    if [[ "$active_color" == "green" ]] || [[ "$blue_ready" == false ]]; then
        target_color="blue"
    fi
    
    log_info "Deploying to $target_color environment"
    log_info "Current active: $active_color"
    log_info "Blue ready: $blue_ready, Green ready: $green_ready"
    
    # Generate manifests
    generate_manifests "$target_color" "$image" "$version"
    
    # Apply deployment
    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY RUN: Would apply deployment:"
        cat "/tmp/$APP_NAME-$target_color-deployment.yaml"
        return 0
    fi
    
    log_info "Applying $target_color deployment..."
    kubectl apply -f "/tmp/$APP_NAME-$target_color-deployment.yaml"
    
    # Apply service if needed
    if [[ -f "/tmp/$APP_NAME-service.yaml" ]]; then
        log_info "Creating service..."
        kubectl apply -f "/tmp/$APP_NAME-service.yaml"
    fi
    
    # Wait for deployment to be ready
    log_info "Waiting for deployment to be ready..."
    if kubectl rollout status deployment "$APP_NAME-$target_color" -n "$NAMESPACE" --timeout="$DEPLOYMENT_TIMEOUT"; then
        log_success "✓ $target_color deployment is ready"
    else
        log_error "✗ $target_color deployment failed to become ready"
        return 1
    fi
    
    # Run health checks
    run_health_checks "$target_color"
    
    log_success "Deployment completed successfully"
    log_info "Ready to switch traffic to $target_color"
    log_info "Run: $0 --action switch-traffic --version $version --namespace $NAMESPACE"
}

# Switch traffic between blue and green
switch_traffic() {
    local version=${1:-$VERSION}
    
    log_info "Switching traffic for version $version"
    
    # Get current deployment state
    local state
    state=$(get_deployment_state)
    IFS=':' read -r blue_ready green_ready active_color <<< "$state"
    
    # Determine target color
    local target_color=""
    if [[ "$blue_ready" == true && "$active_color" != "blue" ]]; then
        target_color="blue"
    elif [[ "$green_ready" == true && "$active_color" != "green" ]]; then
        target_color="green"
    else
        log_error "No viable target for traffic switch"
        return 1
    fi
    
    log_info "Switching traffic from $active_color to $target_color"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY RUN: Would switch traffic to $target_color"
        return 0
    fi
    
    # Update service selector
    kubectl patch service "$APP_NAME" -n "$NAMESPACE" -p "{\"spec\":{\"selector\":{\"color\":\"$target_color\"}}}"
    
    # Wait a moment for service to update
    sleep 5
    
    # Verify traffic switch
    log_info "Verifying traffic switch..."
    run_health_checks "$target_color"
    
    log_success "Traffic successfully switched to $target_color"
    
    # Scale down the old deployment after successful switch
    local old_color=""
    if [[ "$target_color" == "blue" ]]; then
        old_color="green"
    else
        old_color="blue"
    fi
    
    log_info "Scaling down old $old_color deployment..."
    kubectl scale deployment "$APP_NAME-$old_color" -n "$NAMESPACE" --replicas=0 || true
    
    log_success "Traffic switch completed successfully"
}

# Run health checks
run_health_checks() {
    local color=$1
    
    log_info "Running health checks for $color deployment..."
    
    # Get pod name
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l "app=$APP_NAME,color=$color" -o jsonpath='{.items[0].metadata.name}' || echo "")
    
    if [[ -z "$pod_name" ]]; then
        log_error "No pods found for $color deployment"
        return 1
    fi
    
    # Port forward for health check
    log_info "Running health check via port-forward..."
    kubectl port-forward "$pod_name" 8080:8000 -n "$NAMESPACE" &
    local pf_pid=$!
    
    # Wait for port-forward to establish
    sleep 5
    
    # Run health check
    local health_check_passed=false
    local attempts=0
    local max_attempts=10
    
    while [[ $attempts -lt $max_attempts ]]; do
        if curl -f http://localhost:8080/api/health/ --max-time 10 &> /dev/null; then
            health_check_passed=true
            break
        fi
        
        log_info "Health check attempt $((attempts + 1))/$max_attempts failed, retrying..."
        sleep 10
        ((attempts++))
    done
    
    # Cleanup port-forward
    kill $pf_pid 2>/dev/null || true
    
    if [[ "$health_check_passed" == true ]]; then
        log_success "✓ Health checks passed for $color deployment"
        return 0
    else
        log_error "✗ Health checks failed for $color deployment"
        return 1
    fi
}

# Rollback deployment
rollback_deployment() {
    local target_version=${TARGET_VERSION:-""}
    
    log_info "Starting rollback process"
    
    if [[ -z "$target_version" ]]; then
        # Get previous version from deployment history
        target_version=$(kubectl rollout history deployment "$APP_NAME-blue" -n "$NAMESPACE" --revision=1 | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1 || echo "")
        
        if [[ -z "$target_version" ]]; then
            log_error "Cannot determine target version for rollback"
            return 1
        fi
    fi
    
    log_info "Rolling back to version: $target_version"
    
    # Get current active color
    local state
    state=$(get_deployment_state)
    IFS=':' read -r blue_ready green_ready active_color <<< "$state"
    
    # Determine rollback strategy
    local rollback_color=""
    if [[ "$active_color" == "blue" ]]; then
        rollback_color="green"
    else
        rollback_color="blue"
    fi
    
    log_info "Rolling back via $rollback_color deployment"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY RUN: Would rollback to $target_version via $rollback_color"
        return 0
    fi
    
    # Scale up the rollback deployment if needed
    kubectl scale deployment "$APP_NAME-$rollback_color" -n "$NAMESPACE" --replicas=3
    
    # Wait for rollback deployment
    kubectl rollout status deployment "$APP_NAME-$rollback_color" -n "$NAMESPACE" --timeout="$ROLLBACK_TIMEOUT"
    
    # Switch traffic
    kubectl patch service "$APP_NAME" -n "$NAMESPACE" -p "{\"spec\":{\"selector\":{\"color\":\"$rollback_color\"}}}"
    
    # Verify rollback
    run_health_checks "$rollback_color"
    
    log_success "Rollback to $target_version completed successfully"
}

# Show deployment status
show_status() {
    log_info "Deployment Status for namespace: $NAMESPACE"
    log_info "================================================="
    
    # Get deployment state
    local state
    state=$(get_deployment_state)
    IFS=':' read -r blue_ready green_ready active_color <<< "$state"
    
    echo "Active Color: $active_color"
    echo "Blue Ready: $blue_ready"
    echo "Green Ready: $green_ready"
    echo ""
    
    # Show deployments
    echo "Deployments:"
    kubectl get deployments -n "$NAMESPACE" -l "app=$APP_NAME" -o wide || true
    echo ""
    
    # Show services
    echo "Services:"
    kubectl get services -n "$NAMESPACE" -l "app=$APP_NAME" -o wide || true
    echo ""
    
    # Show pods
    echo "Pods:"
    kubectl get pods -n "$NAMESPACE" -l "app=$APP_NAME" -o wide || true
}

# Cleanup old deployments
cleanup_deployments() {
    log_info "Cleaning up old deployments..."
    
    # Keep last 3 replica sets
    kubectl delete replicasets -n "$NAMESPACE" -l "app=$APP_NAME" --field-selector="status.replicas=0" --cascade=orphan || true
    
    log_success "Cleanup completed"
}

# Main execution
main() {
    log_info "Starting Kubernetes deployment process"
    log_info "Action: $ACTION"
    log_info "Namespace: $NAMESPACE"
    log_info "Environment: $ENVIRONMENT"
    
    # Validate parameters
    validate_parameters
    
    # Check prerequisites
    check_prerequisites
    
    # Execute action
    case "$ACTION" in
        "deploy")
            deploy_new_version "$IMAGE" "$VERSION"
            ;;
        "switch-traffic")
            switch_traffic "$VERSION"
            ;;
        "rollback")
            rollback_deployment
            ;;
        "status")
            show_status
            ;;
        "cleanup")
            cleanup_deployments
            ;;
    esac
    
    log_success "Kubernetes deployment process completed successfully"
}

# Run main function
main "$@"