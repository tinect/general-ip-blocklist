#!/bin/sh

# Script to import unwanted IP addresses into CrowdSec decisions
# Downloads the combined blocklist and imports it into CrowdSec
# POSIX sh compatible

set -eu

# Configuration
BLOCKLIST_URL="https://raw.githubusercontent.com/tinect/general-ip-blocklist/refs/heads/main/combined-blocklist.txt"
BAN_DURATION="${BAN_DURATION:-24h}"
BAN_REASON="${BAN_REASON:-general-ip-blocklist}"
DOCKER_CONTAINER_NAME="${CROWDSEC_DOCKER_CONTAINER:-}"
TEMP_DIR=$(mktemp -d)
DECISIONS_FILE="${TEMP_DIR}/decisions.json"
BLOCKLIST_FILE="${TEMP_DIR}/blocklist.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Cleanup function
cleanup() {
    rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

# Logging functions
log_info() {
    printf "%b[INFO]%b %s\n" "${GREEN}" "${NC}" "$1"
}

log_warn() {
    printf "%b[WARN]%b %s\n" "${YELLOW}" "${NC}" "$1"
}

log_error() {
    printf "%b[ERROR]%b %s\n" "${RED}" "${NC}" "$1"
}

# Check if running in Docker or local
check_crowdsec_environment() {
    if [ -n "${DOCKER_CONTAINER_NAME}" ]; then
        if ! docker ps --format '{{.Names}}' | grep -q "^${DOCKER_CONTAINER_NAME}$"; then
            log_error "Docker container '${DOCKER_CONTAINER_NAME}' is not running"
            exit 1
        fi
        log_info "Using CrowdSec in Docker container: ${DOCKER_CONTAINER_NAME}"
        return 0
    fi

    if ! command -v cscli > /dev/null 2>&1; then
        log_error "cscli command not found. Please install CrowdSec or set CROWDSEC_DOCKER_CONTAINER environment variable"
        exit 1
    fi

    log_info "Using local CrowdSec installation"
}

# Download blocklist
download_blocklist() {
    log_info "Downloading blocklist from ${BLOCKLIST_URL}..."

    if ! curl -fsSL "${BLOCKLIST_URL}" -o "${BLOCKLIST_FILE}"; then
        log_error "Failed to download blocklist"
        exit 1
    fi

    total_ips=$(wc -l < "${BLOCKLIST_FILE}")
    log_info "Downloaded ${total_ips} IP addresses"
}

# Convert blocklist to CrowdSec JSON format
create_decisions_json() {
    log_info "Creating CrowdSec decisions JSON..."

    echo "[" > "${DECISIONS_FILE}"

    first=true
    while IFS= read -r ip; do
        # Skip empty lines and comments
        [ -z "${ip}" ] && continue
        case "${ip}" in
            \#*) continue ;;
        esac

        # Add comma before all entries except the first
        if [ "${first}" = true ]; then
            first=false
        else
            echo "," >> "${DECISIONS_FILE}"
        fi

        # Create JSON decision entry
        cat >> "${DECISIONS_FILE}" << EOF
  {
    "duration": "${BAN_DURATION}",
    "origin": "lists",
    "reason": "${BAN_REASON}",
    "scope": "ip",
    "type": "ban",
    "value": "${ip}"
  }
EOF
    done < "${BLOCKLIST_FILE}"

    echo "" >> "${DECISIONS_FILE}"
    echo "]" >> "${DECISIONS_FILE}"

    log_info "Created decisions file with $(grep -c '"value"' "${DECISIONS_FILE}") entries"
}

# Import decisions into CrowdSec
import_decisions() {
    log_info "Importing decisions into CrowdSec..."

    if [ -n "${DOCKER_CONTAINER_NAME}" ]; then
        # Docker mode: copy file and execute inside container
        docker cp "${DECISIONS_FILE}" "${DOCKER_CONTAINER_NAME}:/tmp/decisions.json"

        if docker exec "${DOCKER_CONTAINER_NAME}" cscli decisions import -i /tmp/decisions.json; then
            log_info "Successfully imported decisions via Docker"
            docker exec "${DOCKER_CONTAINER_NAME}" rm /tmp/decisions.json
        else
            log_error "Failed to import decisions via Docker"
            exit 1
        fi
    else
        # Local mode: execute directly
        if cscli decisions import -i "${DECISIONS_FILE}"; then
            log_info "Successfully imported decisions locally"
        else
            log_error "Failed to import decisions"
            exit 1
        fi
    fi
}

# Show statistics
show_statistics() {
    log_info "Fetching current CrowdSec statistics..."

    if [ -n "${DOCKER_CONTAINER_NAME}" ]; then
        docker exec "${DOCKER_CONTAINER_NAME}" cscli decisions list -o json | \
            grep -c "${BAN_REASON}" || echo "0"
    else
        cscli decisions list -o json | grep -c "${BAN_REASON}" || echo "0"
    fi
}

# Main execution
main() {
    log_info "Starting CrowdSec blocklist import..."
    log_info "Ban duration: ${BAN_DURATION}"
    log_info "Ban reason: ${BAN_REASON}"

    check_crowdsec_environment
    download_blocklist
    create_decisions_json
    import_decisions

    log_info "Import completed successfully!"
    log_info "To view imported decisions, run:"

    if [ -n "${DOCKER_CONTAINER_NAME}" ]; then
        echo "  docker exec ${DOCKER_CONTAINER_NAME} cscli decisions list --origin lists"
    else
        echo "  cscli decisions list --origin lists"
    fi
}

# Run main function
main