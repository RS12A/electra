#!/bin/bash
set -euo pipefail

# Electra Docker Image Push Script
# Production-grade Docker image pushing with authentication and error handling

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REGISTRY="${DOCKER_REGISTRY:-ghcr.io}"
IMAGE_NAME="${IMAGE_NAME:-electra}"
VERSION="${VERSION:-latest}"

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
        log_error "Push operation failed with exit code $exit_code"
    fi
    
    # Logout from registries if logged in
    if [[ "${AUTO_LOGOUT:-true}" == "true" ]]; then
        docker logout "$REGISTRY" 2>/dev/null || true
    fi
    
    exit $exit_code
}

trap cleanup EXIT

# Usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Push Docker images to registry

OPTIONS:
    -t, --target TARGET     Push target (development|production|all) [default: all]
    -v, --version VERSION   Version tag to push [default: latest]
    -r, --registry REGISTRY Registry to push to [default: ghcr.io]
    -n, --name NAME         Image base name [default: electra]
    --dry-run               Show what would be pushed without actually pushing
    --verify                Verify images exist before pushing
    --sign                  Sign images after pushing (requires cosign)
    --sbom                  Generate and attach SBOM (requires syft)
    --retry-count COUNT     Number of retry attempts [default: 3]
    --retry-delay SECONDS   Delay between retries [default: 5]
    -h, --help             Show this help message

AUTHENTICATION:
    Set one of the following environment variables:
    - DOCKER_REGISTRY_TOKEN: Registry token/password
    - DOCKER_REGISTRY_USER: Registry username (with DOCKER_REGISTRY_PASS)
    - GITHUB_TOKEN: GitHub token (for ghcr.io)

EXAMPLES:
    $0 --target production --version v1.0.0
    $0 --registry myregistry.com --name myapp --verify
    $0 --dry-run --target all

ENVIRONMENT VARIABLES:
    DOCKER_REGISTRY         Docker registry URL
    DOCKER_REGISTRY_USER    Registry username
    DOCKER_REGISTRY_TOKEN   Registry token/password
    DOCKER_REGISTRY_PASS    Registry password (alternative to token)
    GITHUB_TOKEN            GitHub token (for ghcr.io)
    IMAGE_NAME              Base image name
    VERSION                 Image version tag

EOF
}

# Parse command line arguments
TARGET="all"
DRY_RUN=false
VERIFY_IMAGES=false
SIGN_IMAGES=false
GENERATE_SBOM=false
RETRY_COUNT=3
RETRY_DELAY=5

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--target)
            TARGET="$2"
            shift 2
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verify)
            VERIFY_IMAGES=true
            shift
            ;;
        --sign)
            SIGN_IMAGES=true
            shift
            ;;
        --sbom)
            GENERATE_SBOM=true
            shift
            ;;
        --retry-count)
            RETRY_COUNT="$2"
            shift 2
            ;;
        --retry-delay)
            RETRY_DELAY="$2"
            shift 2
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

# Validate target
if [[ "$TARGET" != "development" && "$TARGET" != "production" && "$TARGET" != "all" ]]; then
    log_error "Invalid target: $TARGET. Must be 'development', 'production', or 'all'"
    exit 1
fi

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi
    
    # Check authentication requirements
    check_authentication
    
    # Check signing tools if requested
    if [[ "$SIGN_IMAGES" == true ]] && ! command -v cosign &> /dev/null; then
        log_error "cosign is required for image signing but not found"
        exit 1
    fi
    
    # Check SBOM tools if requested
    if [[ "$GENERATE_SBOM" == true ]] && ! command -v syft &> /dev/null; then
        log_error "syft is required for SBOM generation but not found"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Check authentication
check_authentication() {
    log_info "Checking registry authentication..."
    
    local auth_available=false
    
    # Check for various authentication methods
    if [[ -n "${DOCKER_REGISTRY_TOKEN:-}" ]]; then
        log_info "Using registry token authentication"
        auth_available=true
    elif [[ -n "${DOCKER_REGISTRY_USER:-}" ]] && [[ -n "${DOCKER_REGISTRY_PASS:-}" ]]; then
        log_info "Using username/password authentication"
        auth_available=true
    elif [[ -n "${GITHUB_TOKEN:-}" ]] && [[ "$REGISTRY" == *"ghcr.io"* ]]; then
        log_info "Using GitHub token authentication"
        auth_available=true
    elif docker info | grep -q "Username:"; then
        log_info "Already authenticated to Docker registry"
        auth_available=true
    fi
    
    if [[ "$auth_available" == false ]]; then
        log_error "No authentication method available"
        log_error "Set DOCKER_REGISTRY_TOKEN, DOCKER_REGISTRY_USER/PASS, or GITHUB_TOKEN"
        exit 1
    fi
}

# Authenticate to registry
authenticate_registry() {
    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY RUN: Would authenticate to $REGISTRY"
        return 0
    fi
    
    log_info "Authenticating to registry: $REGISTRY"
    
    # Determine authentication method
    if [[ -n "${DOCKER_REGISTRY_TOKEN:-}" ]]; then
        # Use token authentication
        local username="${DOCKER_REGISTRY_USER:-oauth2accesstoken}"
        echo "$DOCKER_REGISTRY_TOKEN" | docker login "$REGISTRY" --username "$username" --password-stdin
    elif [[ -n "${DOCKER_REGISTRY_USER:-}" ]] && [[ -n "${DOCKER_REGISTRY_PASS:-}" ]]; then
        # Use username/password
        echo "$DOCKER_REGISTRY_PASS" | docker login "$REGISTRY" --username "$DOCKER_REGISTRY_USER" --password-stdin
    elif [[ -n "${GITHUB_TOKEN:-}" ]] && [[ "$REGISTRY" == *"ghcr.io"* ]]; then
        # Use GitHub token
        echo "$GITHUB_TOKEN" | docker login "$REGISTRY" --username "$GITHUB_ACTOR" --password-stdin
    else
        log_error "No valid authentication method found"
        exit 1
    fi
    
    log_success "Successfully authenticated to $REGISTRY"
}

# Verify image exists locally
verify_image_exists() {
    local image_tag=$1
    
    if docker image inspect "$image_tag" &> /dev/null; then
        log_info "✓ Image exists locally: $image_tag"
        return 0
    else
        log_error "✗ Image not found locally: $image_tag"
        return 1
    fi
}

# Push image with retry logic
push_image_with_retry() {
    local image_tag=$1
    local attempt=1
    
    while [[ $attempt -le $RETRY_COUNT ]]; do
        log_info "Push attempt $attempt/$RETRY_COUNT for $image_tag"
        
        if [[ "$DRY_RUN" == true ]]; then
            log_info "DRY RUN: Would push $image_tag"
            return 0
        fi
        
        if docker push "$image_tag"; then
            log_success "Successfully pushed $image_tag"
            return 0
        else
            log_warning "Push attempt $attempt failed for $image_tag"
            if [[ $attempt -lt $RETRY_COUNT ]]; then
                log_info "Waiting ${RETRY_DELAY}s before retry..."
                sleep "$RETRY_DELAY"
            fi
            ((attempt++))
        fi
    done
    
    log_error "Failed to push $image_tag after $RETRY_COUNT attempts"
    return 1
}

# Sign image with cosign
sign_image() {
    local image_tag=$1
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY RUN: Would sign $image_tag"
        return 0
    fi
    
    if [[ "$SIGN_IMAGES" == true ]]; then
        log_info "Signing image: $image_tag"
        
        # Note: In production, you would use proper key management
        # This is a placeholder for the signing process
        if cosign sign --yes "$image_tag"; then
            log_success "Successfully signed $image_tag"
        else
            log_error "Failed to sign $image_tag"
            return 1
        fi
    fi
}

# Generate and attach SBOM
generate_sbom() {
    local image_tag=$1
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY RUN: Would generate SBOM for $image_tag"
        return 0
    fi
    
    if [[ "$GENERATE_SBOM" == true ]]; then
        log_info "Generating SBOM for: $image_tag"
        
        local sbom_file="/tmp/$(basename "$image_tag" | tr ':' '-')-sbom.json"
        
        if syft "$image_tag" -o spdx-json > "$sbom_file"; then
            log_success "Generated SBOM: $sbom_file"
            
            # Attach SBOM to image (requires cosign)
            if command -v cosign &> /dev/null; then
                cosign attach sbom --sbom "$sbom_file" "$image_tag"
                log_success "Attached SBOM to $image_tag"
            fi
            
            # Clean up
            rm -f "$sbom_file"
        else
            log_error "Failed to generate SBOM for $image_tag"
            return 1
        fi
    fi
}

# Get image manifest digest
get_image_digest() {
    local image_tag=$1
    
    if [[ "$DRY_RUN" == true ]]; then
        echo "sha256:dry-run-digest"
        return 0
    fi
    
    docker inspect --format='{{index .RepoDigests 0}}' "$image_tag" 2>/dev/null | cut -d'@' -f2 || echo "unknown"
}

# Process single target
process_target() {
    local target=$1
    local image_tag="$REGISTRY/$IMAGE_NAME:$target-$VERSION"
    local latest_tag="$REGISTRY/$IMAGE_NAME:$target-latest"
    
    log_info "Processing $target target..."
    
    # Verify images exist if requested
    if [[ "$VERIFY_IMAGES" == true ]]; then
        verify_image_exists "$image_tag" || return 1
        verify_image_exists "$latest_tag" || return 1
    fi
    
    # Push versioned tag
    if ! push_image_with_retry "$image_tag"; then
        return 1
    fi
    
    # Push latest tag
    if ! push_image_with_retry "$latest_tag"; then
        return 1
    fi
    
    # Sign images
    sign_image "$image_tag"
    sign_image "$latest_tag"
    
    # Generate SBOM
    generate_sbom "$image_tag"
    
    # Get and log digest
    local digest
    digest=$(get_image_digest "$image_tag")
    log_info "$target image digest: $digest"
    
    log_success "Completed processing $target target"
    return 0
}

# Generate push summary
generate_summary() {
    log_info "Push Summary:"
    log_info "============="
    log_info "Registry: $REGISTRY"
    log_info "Image Name: $IMAGE_NAME"
    log_info "Version: $VERSION"
    log_info "Target(s): $TARGET"
    log_info "Dry Run: $DRY_RUN"
    log_info "Verify: $VERIFY_IMAGES"
    log_info "Sign: $SIGN_IMAGES"
    log_info "SBOM: $GENERATE_SBOM"
    log_info "Retry Count: $RETRY_COUNT"
    
    if [[ "$DRY_RUN" == false ]]; then
        # Show pushed images
        log_info ""
        log_info "Pushed Images:"
        case "$TARGET" in
            "development")
                echo "  - $REGISTRY/$IMAGE_NAME:development-$VERSION"
                echo "  - $REGISTRY/$IMAGE_NAME:development-latest"
                ;;
            "production")
                echo "  - $REGISTRY/$IMAGE_NAME:production-$VERSION"
                echo "  - $REGISTRY/$IMAGE_NAME:production-latest"
                ;;
            "all")
                echo "  - $REGISTRY/$IMAGE_NAME:development-$VERSION"
                echo "  - $REGISTRY/$IMAGE_NAME:development-latest"
                echo "  - $REGISTRY/$IMAGE_NAME:production-$VERSION"
                echo "  - $REGISTRY/$IMAGE_NAME:production-latest"
                ;;
        esac
    fi
}

# Main execution
main() {
    log_info "Starting Electra Docker image push process"
    log_info "Registry: $REGISTRY"
    log_info "Target: $TARGET"
    log_info "Version: $VERSION"
    
    # Check prerequisites
    check_prerequisites
    
    # Authenticate to registry
    authenticate_registry
    
    # Process targets
    local success=true
    case "$TARGET" in
        "development")
            process_target "development" || success=false
            ;;
        "production")
            process_target "production" || success=false
            ;;
        "all")
            process_target "development" || success=false
            process_target "production" || success=false
            ;;
    esac
    
    # Generate summary
    generate_summary
    
    if [[ "$success" == true ]]; then
        log_success "Docker image push process completed successfully"
    else
        log_error "Docker image push process completed with errors"
        exit 1
    fi
}

# Run main function
main "$@"