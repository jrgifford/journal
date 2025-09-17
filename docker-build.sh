#!/bin/bash
# Docker build automation script for journal generation system
# Usage: ./docker-build.sh [--no-cache] [--target stage] [--parallel-jobs N]

set -euo pipefail

# Default values
NO_CACHE=""
TARGET_STAGE="runtime"
PARALLEL_JOBS="4"
BUILD_TAG="journal:2025-q4"
VERBOSE=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Build Docker image for journal generation with optimization.

OPTIONS:
    --no-cache          Disable Docker layer caching
    --target STAGE      Build target stage (builder|runtime, default: runtime)
    --parallel-jobs N   Number of parallel build jobs (default: 4)
    --tag TAG          Custom image tag (default: journal:2025-q4)
    --verbose          Enable verbose output
    -h, --help         Show this help message

EXAMPLES:
    $0                          # Standard build
    $0 --no-cache              # Clean build without cache
    $0 --target builder        # Build only the builder stage
    $0 --parallel-jobs 8       # Use 8 parallel jobs
    $0 --tag journal:dev       # Custom tag for development

PERFORMANCE TARGETS:
    - Build time: < 5 minutes
    - Image size: < 1.5GB
    - Cache hit rate: > 80%

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --target)
            TARGET_STAGE="$2"
            shift 2
            ;;
        --parallel-jobs)
            PARALLEL_JOBS="$2"
            shift 2
            ;;
        --tag)
            BUILD_TAG="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE="--progress=plain"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate target stage
if [[ "$TARGET_STAGE" != "builder" && "$TARGET_STAGE" != "runtime" ]]; then
    log_error "Invalid target stage: $TARGET_STAGE. Must be 'builder' or 'runtime'"
    exit 1
fi

# Validate parallel jobs
if ! [[ "$PARALLEL_JOBS" =~ ^[0-9]+$ ]] || [[ "$PARALLEL_JOBS" -lt 1 || "$PARALLEL_JOBS" -gt 16 ]]; then
    log_error "Invalid parallel jobs: $PARALLEL_JOBS. Must be a number between 1 and 16"
    exit 1
fi

# Check Docker availability
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed or not in PATH"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    log_error "Docker daemon is not running"
    exit 1
fi

# Check if Dockerfile exists
if [[ ! -f "Dockerfile" ]]; then
    log_error "Dockerfile not found in current directory"
    exit 1
fi

# Start timing
START_TIME=$(date +%s)

log_info "Starting Docker build with the following configuration:"
log_info "  Target stage: $TARGET_STAGE"
log_info "  Cache: $([ -n "$NO_CACHE" ] && echo "disabled" || echo "enabled")"
log_info "  Parallel jobs: $PARALLEL_JOBS"
log_info "  Image tag: $BUILD_TAG"

# Build the Docker image
log_info "Building Docker image..."

BUILD_ARGS=(
    "build"
    "$NO_CACHE"
    "--target" "$TARGET_STAGE"
    "--build-arg" "PARALLEL_JOBS=$PARALLEL_JOBS"
    "--tag" "$BUILD_TAG"
    $VERBOSE
    "."
)

# Remove empty arguments reliably
FILTERED_ARGS=()
for arg in "${BUILD_ARGS[@]}"; do
    if [[ -n "$arg" ]]; then
        FILTERED_ARGS+=("$arg")
    fi
done

if docker "${FILTERED_ARGS[@]}"; then
    # Calculate build time
    END_TIME=$(date +%s)
    BUILD_TIME=$((END_TIME - START_TIME))
    
    log_success "Docker build completed successfully in ${BUILD_TIME} seconds"
    
    # Get image information
    log_info "Collecting image metrics..."
    
    IMAGE_SIZE=$(docker images --format "table {{.Size}}" "$BUILD_TAG" | tail -n 1)
    LAYER_COUNT=$(docker history "$BUILD_TAG" --format "{{.ID}}" | wc -l)
    IMAGE_ID=$(docker images --format "{{.ID}}" "$BUILD_TAG" | head -n 1)
    
    # Display build results
    echo
    log_success "BUILD SUMMARY"
    echo "  Image ID: $IMAGE_ID"
    echo "  Image tag: $BUILD_TAG"
    echo "  Image size: $IMAGE_SIZE"
    echo "  Layer count: $LAYER_COUNT"
    echo "  Build time: ${BUILD_TIME}s"
    
    # Performance evaluation
    echo
    log_info "PERFORMANCE EVALUATION"
    
    # Check build time target (5 minutes = 300 seconds)
    if [[ $BUILD_TIME -lt 300 ]]; then
        log_success "✅ Build time target met: ${BUILD_TIME}s < 300s"
    else
        log_warning "⚠️  Build time target missed: ${BUILD_TIME}s >= 300s"
    fi
    
    # Extract numeric size for comparison (assuming format like "1.23GB")
    SIZE_VALUE=$(echo "$IMAGE_SIZE" | grep -oE '[0-9]+\.?[0-9]*')
    SIZE_UNIT=$(echo "$IMAGE_SIZE" | grep -oE '[A-Z]+')
    
    # Convert to MB for comparison
    case "$SIZE_UNIT" in
        "GB")
            SIZE_MB=$(echo "$SIZE_VALUE * 1024" | bc -l 2>/dev/null || echo "0")
            ;;
        "MB")
            SIZE_MB="$SIZE_VALUE"
            ;;
        *)
            SIZE_MB="0"
            ;;
    esac
    
    # Check size target (1.5GB = 1536MB)
    if command -v bc &> /dev/null && [[ $(echo "$SIZE_MB < 1536" | bc) -eq 1 ]]; then
        log_success "✅ Image size target met: $IMAGE_SIZE < 1.5GB"
    else
        log_warning "⚠️  Image size target assessment: $IMAGE_SIZE (target: < 1.5GB)"
    fi
    
    # Save metrics to file
    METRICS_FILE="build-metrics.json"
    cat > "$METRICS_FILE" << EOF
{
  "build_timestamp": "$(date -Iseconds)",
  "build_time_seconds": $BUILD_TIME,
  "image_id": "$IMAGE_ID",
  "image_tag": "$BUILD_TAG",
  "image_size": "$IMAGE_SIZE",
  "layer_count": $LAYER_COUNT,
  "target_stage": "$TARGET_STAGE",
  "cache_enabled": $([ -z "$NO_CACHE" ] && echo "true" || echo "false"),
  "parallel_jobs": $PARALLEL_JOBS
}
EOF
    
    log_info "Build metrics saved to $METRICS_FILE"
    
    # Next steps
    echo
    log_info "NEXT STEPS"
    echo "  Test the image: docker run --rm -v \"\$(pwd)/output:/data/output\" $BUILD_TAG"
    echo "  Generate journal: ./docker-run.sh generate"
    echo "  Validate output: ./scripts/validate-pdf.sh output/*.pdf"
    
else
    END_TIME=$(date +%s)
    BUILD_TIME=$((END_TIME - START_TIME))
    log_error "Docker build failed after ${BUILD_TIME} seconds"
    
    # Save error metrics
    METRICS_FILE="build-metrics.json"
    cat > "$METRICS_FILE" << EOF
{
  "build_timestamp": "$(date -Iseconds)",
  "build_time_seconds": $BUILD_TIME,
  "status": "failed",
  "target_stage": "$TARGET_STAGE",
  "cache_enabled": $([ -z "$NO_CACHE" ] && echo "true" || echo "false"),
  "parallel_jobs": $PARALLEL_JOBS
}
EOF
    
    log_info "Error metrics saved to $METRICS_FILE"
    exit 1
fi
