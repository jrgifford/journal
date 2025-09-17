#!/bin/bash
# Docker run script for journal generation
# Usage: ./docker-run.sh generate [options]

set -euo pipefail

# Default values
COMMAND="generate"
OUTPUT_DIR="$(pwd)/output"
CONFIG_FILE=""
JOURNAL_YEAR=""
JOURNAL_QUARTER=""
JOURNAL_LOCALE="en_GB.utf-8"
WEEK_START_MONDAY="true"
IMAGE_TAG="journal:2025-q4"
DEBUG=""

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
Usage: $0 COMMAND [OPTIONS]

Run Docker container for journal generation operations.

COMMANDS:
    generate            Generate PDF journal (default)
    validate            Validate configuration
    shell              Start interactive shell in container
    clean              Clean generated files

OPTIONS:
    --output-dir PATH      Output directory for generated PDF (default: ./output)
    --config-file PATH     Custom configuration file (optional)
    --year YEAR           Override year setting (e.g., 2025)
    --quarter QUARTER     Override quarter setting (1-4, optional)
    --locale LOCALE       Locale setting (default: en_GB.utf-8)
    --week-start-monday   Week starts on Monday (true/false, default: true)
    --image TAG           Docker image tag (default: journal:2025-q4)
    --debug               Enable debug output
    -h, --help           Show this help message

ENVIRONMENT VARIABLES:
    JOURNAL_YEAR          Target year for journal (overrides config)
    JOURNAL_QUARTER       Specific quarter (1-4, optional)
    JOURNAL_LOCALE        Locale setting
    WEEK_START_MONDAY     Week start preference (true/false)

EXAMPLES:
    $0 generate                                    # Generate with default settings
    $0 generate --year 2026 --quarter 1          # Generate Q1 2026 journal
    $0 generate --output-dir /tmp/journals        # Custom output directory
    $0 validate --config-file custom-config.py   # Validate custom configuration
    $0 shell                                      # Interactive debugging
    $0 clean                                      # Clean generated files

PERFORMANCE TARGETS:
    - PDF generation: < 2 minutes
    - Memory usage: < 4GB
    - Output size: 10-15MB for quarterly journal

EOF
}

# Parse command line arguments
if [[ $# -gt 0 ]]; then
    COMMAND="$1"
    shift
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --config-file)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --year)
            JOURNAL_YEAR="$2"
            shift 2
            ;;
        --quarter)
            JOURNAL_QUARTER="$2"
            shift 2
            ;;
        --locale)
            JOURNAL_LOCALE="$2"
            shift 2
            ;;
        --week-start-monday)
            WEEK_START_MONDAY="$2"
            shift 2
            ;;
        --image)
            IMAGE_TAG="$2"
            shift 2
            ;;
        --debug)
            DEBUG="1"
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

# Validate command
case "$COMMAND" in
    generate|validate|shell|clean)
        ;;
    *)
        log_error "Invalid command: $COMMAND"
        show_help
        exit 1
        ;;
esac

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

# Check if image exists
if ! docker image inspect "$IMAGE_TAG" &> /dev/null; then
    log_error "Docker image '$IMAGE_TAG' not found"
    log_info "Build the image first: ./docker-build.sh"
    exit 1
fi

# Create output directory if it doesn't exist
if [[ "$COMMAND" == "generate" ]]; then
    mkdir -p "$OUTPUT_DIR"
    if [[ ! -w "$OUTPUT_DIR" ]]; then
        log_error "Output directory '$OUTPUT_DIR' is not writable"
        exit 1
    fi
fi

# Set up environment variables
ENV_VARS=()

# Use environment variables or command line overrides
if [[ -n "${JOURNAL_YEAR:-}" || -n "$JOURNAL_YEAR" ]]; then
    YEAR_VALUE="${JOURNAL_YEAR:-${JOURNAL_YEAR:-}}"
    ENV_VARS+=("-e" "JOURNAL_YEAR=$YEAR_VALUE")
fi

if [[ -n "${JOURNAL_QUARTER:-}" || -n "$JOURNAL_QUARTER" ]]; then
    QUARTER_VALUE="${JOURNAL_QUARTER:-${JOURNAL_QUARTER:-}}"
    ENV_VARS+=("-e" "JOURNAL_QUARTER=$QUARTER_VALUE")
fi

if [[ -n "$JOURNAL_LOCALE" ]]; then
    ENV_VARS+=("-e" "JOURNAL_LOCALE=$JOURNAL_LOCALE")
fi

if [[ -n "$WEEK_START_MONDAY" ]]; then
    ENV_VARS+=("-e" "WEEK_START_MONDAY=$WEEK_START_MONDAY")
fi

if [[ -n "$DEBUG" ]]; then
    ENV_VARS+=("-e" "DEBUG=1")
fi

# Set up volume mounts
VOLUMES=("-v" "$(pwd):/data")

if [[ "$COMMAND" == "generate" ]]; then
    VOLUMES+=("-v" "$OUTPUT_DIR:/data/output")
fi

# Custom configuration file mount
if [[ -n "$CONFIG_FILE" ]]; then
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Configuration file '$CONFIG_FILE' not found"
        exit 1
    fi
    VOLUMES+=("-v" "$(realpath "$CONFIG_FILE"):/data/gen_config.py")
fi

# Determine command to run in container
case "$COMMAND" in
    generate)
        # Run make and copy any generated PDFs to the mounted /data/output directory
        CONTAINER_CMD=("bash" "-lc" "make && { ls *.pdf >/dev/null 2>&1 && cp -v *.pdf /data/output/; } || true")
        log_info "Starting journal generation..."
        ;;
    validate)
        CONTAINER_CMD=("python3" "scripts/validate_config.py")
        log_info "Validating configuration..."
        ;;
    shell)
        CONTAINER_CMD=("/bin/bash")
        log_info "Starting interactive shell..."
        ;;
    clean)
        CONTAINER_CMD=("make" "clean")
        log_info "Cleaning generated files..."
        ;;
esac

# Start timing for generate command
if [[ "$COMMAND" == "generate" ]]; then
    START_TIME=$(date +%s)
fi

# Build Docker run command
DOCKER_CMD=(
    "docker" "run"
    "--rm"
    "${VOLUMES[@]}"
    "${ENV_VARS[@]}"
    "-u" "0"  # run as root to ensure write access to bind-mounted workspace
)

# Add interactive flags for shell command
if [[ "$COMMAND" == "shell" ]]; then
    DOCKER_CMD+=("-it")
fi

DOCKER_CMD+=("$IMAGE_TAG" "${CONTAINER_CMD[@]}")

# Display configuration
log_info "Docker run configuration:"
log_info "  Command: $COMMAND"
log_info "  Image: $IMAGE_TAG"
if [[ "$COMMAND" == "generate" ]]; then
    log_info "  Output directory: $OUTPUT_DIR"
fi
if [[ -n "$CONFIG_FILE" ]]; then
    log_info "  Custom config: $CONFIG_FILE"
fi
if [[ ${#ENV_VARS[@]} -gt 0 ]]; then
    log_info "  Environment variables: ${ENV_VARS[*]}"
fi

# Execute the command
if "${DOCKER_CMD[@]}"; then
    if [[ "$COMMAND" == "generate" ]]; then
        # Calculate generation time
        END_TIME=$(date +%s)
        GENERATION_TIME=$((END_TIME - START_TIME))
        
        log_success "Journal generation completed in ${GENERATION_TIME} seconds"
        
        # Check for generated files
        if ls "$OUTPUT_DIR"/*.pdf &> /dev/null; then
            PDF_FILES=($(ls "$OUTPUT_DIR"/*.pdf))
            log_success "Generated PDF files:"
            for pdf in "${PDF_FILES[@]}"; do
                PDF_SIZE=$(du -h "$pdf" | cut -f1)
                echo "  $(basename "$pdf") ($PDF_SIZE)"
            done
            
            # Performance evaluation
            echo
            log_info "PERFORMANCE EVALUATION"
            
            # Check generation time target (2 minutes = 120 seconds)
            if [[ $GENERATION_TIME -lt 120 ]]; then
                log_success "✅ Generation time target met: ${GENERATION_TIME}s < 120s"
            else
                log_warning "⚠️  Generation time target missed: ${GENERATION_TIME}s >= 120s"
            fi
            
            # Save generation metrics
            METRICS_FILE="$OUTPUT_DIR/generation-metrics.json"
            cat > "$METRICS_FILE" << EOF
{
  "generation_timestamp": "$(date -Iseconds)",
  "generation_time_seconds": $GENERATION_TIME,
  "output_files": [
$(printf '    "%s"' "${PDF_FILES[@]}" | sed 's/.*/"&"/' | paste -sd, -)
  ],
  "command": "$COMMAND",
  "configuration": {
    "year": "${JOURNAL_YEAR:-}",
    "quarter": "${JOURNAL_QUARTER:-}",
    "locale": "$JOURNAL_LOCALE",
    "week_start_monday": "$WEEK_START_MONDAY"
  }
}
EOF
            
            log_info "Generation metrics saved to $METRICS_FILE"
            
            # Next steps
            echo
            log_info "NEXT STEPS"
            echo "  Validate PDF: ./scripts/validate-pdf.sh ${PDF_FILES[0]}"
            echo "  View PDF: open ${PDF_FILES[0]}"
            echo "  Performance metrics: cat $METRICS_FILE"
            
        else
            log_warning "No PDF files found in output directory"
        fi
    else
        log_success "$COMMAND completed successfully"
    fi
else
    if [[ "$COMMAND" == "generate" ]]; then
        END_TIME=$(date +%s)
        GENERATION_TIME=$((END_TIME - START_TIME))
        log_error "Journal generation failed after ${GENERATION_TIME} seconds"
    else
        log_error "$COMMAND failed"
    fi
    exit 1
fi
