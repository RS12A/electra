#!/bin/bash
set -euo pipefail

# Electra Docker Image Build Script
# Production-grade Docker image building with error handling and logging

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REGISTRY="${DOCKER_REGISTRY:-ghcr.io}"
IMAGE_NAME="${IMAGE_NAME:-electra}"
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
VCS_REF="${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo 'unknown')}"
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

# Error handling
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Build failed with exit code $exit_code"
        # Clean up any temporary resources
        docker system prune -f --filter "label=electra-build=temp" 2>/dev/null || true
    fi
    exit $exit_code
}

trap cleanup EXIT

# Usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Build Docker images for Electra application

OPTIONS:
    -t, --target TARGET     Build target (development|production) [default: both]
    -v, --version VERSION   Version tag for the image [default: latest]
    -r, --registry REGISTRY Registry to use [default: ghcr.io]
    -n, --name NAME         Image base name [default: electra]
    --no-cache              Build without cache
    --platform PLATFORM    Target platform (linux/amd64,linux/arm64)
    --push                  Push images after building
    --scan                  Run security scan after building
    -h, --help             Show this help message

EXAMPLES:
    $0 --target production --version v1.0.0 --push
    $0 --target development --no-cache
    $0 --platform linux/amd64,linux/arm64 --push

ENVIRONMENT VARIABLES:
    DOCKER_REGISTRY         Docker registry URL
    IMAGE_NAME              Base image name
    VERSION                 Image version tag
    GITHUB_SHA              Git commit SHA (auto-detected)
    DOCKER_BUILDKIT         Enable BuildKit (recommended: 1)

EOF
}

# Parse command line arguments
TARGET="both"
NO_CACHE=""
PLATFORM=""
PUSH_IMAGES=false
SCAN_IMAGES=false

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
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --platform)
            PLATFORM="--platform $2"
            shift 2
            ;;
        --push)
            PUSH_IMAGES=true
            shift
            ;;
        --scan)
            SCAN_IMAGES=true
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

# Validate target
if [[ "$TARGET" != "development" && "$TARGET" != "production" && "$TARGET" != "both" ]]; then
    log_error "Invalid target: $TARGET. Must be 'development', 'production', or 'both'"
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
    
    # Check Dockerfile exists
    if [[ ! -f "$PROJECT_ROOT/Dockerfile" ]]; then
        log_error "Dockerfile not found at $PROJECT_ROOT/Dockerfile"
        exit 1
    fi
    
    # Check requirements.txt exists
    if [[ ! -f "$PROJECT_ROOT/requirements.txt" ]]; then
        log_error "requirements.txt not found at $PROJECT_ROOT/requirements.txt"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Enable BuildKit for better performance and features
export DOCKER_BUILDKIT=1

# Build image function
build_image() {
    local target=$1
    local image_tag="$REGISTRY/$IMAGE_NAME:$target-$VERSION"
    local latest_tag="$REGISTRY/$IMAGE_NAME:$target-latest"
    
    log_info "Building $target image..."
    log_info "Image tag: $image_tag"
    log_info "Latest tag: $latest_tag"
    
    # Build command
    local build_cmd=(
        docker build
        --target "$target"
        --tag "$image_tag"
        --tag "$latest_tag"
        --label "org.opencontainers.image.created=$BUILD_DATE"
        --label "org.opencontainers.image.source=https://github.com/RS12A/electra"
        --label "org.opencontainers.image.version=$VERSION"
        --label "org.opencontainers.image.revision=$VCS_REF"
        --label "org.opencontainers.image.title=Electra"
        --label "org.opencontainers.image.description=Secure Digital Voting System"
        --label "electra.target=$target"
        --label "electra.version=$VERSION"
        --label "electra.build-date=$BUILD_DATE"
        --label "electra.vcs-ref=$VCS_REF"
        --build-arg "VERSION=$VERSION"
        --build-arg "BUILD_DATE=$BUILD_DATE"
        --build-arg "VCS_REF=$VCS_REF"
    )
    
    # Add optional flags
    if [[ -n "$NO_CACHE" ]]; then
        build_cmd+=("$NO_CACHE")
    fi
    
    if [[ -n "$PLATFORM" ]]; then
        build_cmd+=($PLATFORM)
    fi
    
    # Add context path
    build_cmd+=("$PROJECT_ROOT")
    
    # Execute build
    log_info "Executing: ${build_cmd[*]}"
    if "${build_cmd[@]}"; then
        log_success "$target image built successfully"
        
        # Get image info
        local image_id
        image_id=$(docker images --format "{{.ID}}" "$image_tag" | head -n1)
        local image_size
        image_size=$(docker images --format "{{.Size}}" "$image_tag" | head -n1)
        
        log_info "Image ID: $image_id"
        log_info "Image Size: $image_size"
        
        # Security scan if requested
        if [[ "$SCAN_IMAGES" == true ]]; then
            scan_image "$image_tag"
        fi
        
        # Push if requested
        if [[ "$PUSH_IMAGES" == true ]]; then
            push_image "$image_tag" "$latest_tag"
        fi
        
        return 0
    else
        log_error "Failed to build $target image"
        return 1
    fi
}

# Security scan function
scan_image() {
    local image_tag=$1
    
    log_info "Running security scan on $image_tag..."
    
    # Use Trivy if available
    if command -v trivy &> /dev/null; then
        log_info "Running Trivy security scan..."
        trivy image --exit-code 0 --severity HIGH,CRITICAL "$image_tag" || {
            log_error "Security vulnerabilities found in $image_tag"
            return 1
        }
    else
        log_info "Trivy not available, skipping security scan"
        log_info "Install Trivy for security scanning: https://aquasecurity.github.io/trivy/"
    fi
}

# Push image function
push_image() {
    local image_tag=$1
    local latest_tag=$2
    
    log_info "Pushing images..."
    
    # Push versioned tag
    if docker push "$image_tag"; then
        log_success "Pushed $image_tag"
    else
        log_error "Failed to push $image_tag"
        return 1
    fi
    
    # Push latest tag
    if docker push "$latest_tag"; then
        log_success "Pushed $latest_tag"
    else
        log_error "Failed to push $latest_tag"
        return 1
    fi
}

# Generate build summary
generate_summary() {
    log_info "Build Summary:"
    log_info "=============="
    log_info "Registry: $REGISTRY"
    log_info "Image Name: $IMAGE_NAME"
    log_info "Version: $VERSION"
    log_info "Target(s): $TARGET"
    log_info "Build Date: $BUILD_DATE"
    log_info "VCS Ref: $VCS_REF"
    log_info "Platform: ${PLATFORM:-default}"
    log_info "Push: $PUSH_IMAGES"
    log_info "Scan: $SCAN_IMAGES"
    
    # List built images
    log_info ""
    log_info "Built Images:"
    docker images --filter "label=electra.version=$VERSION" --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedAt}}"
}

# Main execution
main() {
    log_info "Starting Electra Docker image build process"
    log_info "Version: $VERSION"
    log_info "Target: $TARGET"
    
    # Check prerequisites
    check_prerequisites
    
    # Build images based on target
    case "$TARGET" in
        "development")
            build_image "development"
            ;;
        "production")
            build_image "production"
            ;;
        "both")
            build_image "development"
            build_image "production"
            ;;
    esac
    
    # Generate summary
    generate_summary
    
    log_success "Docker image build process completed successfully"
}

# Run main function
main "$@"