#!/bin/bash
#
# Helper script to run OMS 13.5 installation with proper environment setup
# This ensures ORACLE_BASE is set to avoid the "permanent log directory unknown" error
#

set -e

# Configuration - Update these paths to match your environment
ORACLE_BASE="${ORACLE_BASE:-/u01/app/oracle}"
INSTALLER_PATH="${INSTALLER_PATH:-/u01/app/oracle/software/}"
INSTALLER_FILE="${INSTALLER_FILE:-em13500_linux64.bin}"
RESPONSE_FILE="${RESPONSE_FILE:-/u01/app/oracle/software/oms13.5_install.rsp}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if ORACLE_BASE is set
if [ -z "$ORACLE_BASE" ]; then
    print_error "ORACLE_BASE is not set!"
    print_info "Please set it as an environment variable or update this script"
    exit 1
fi

print_info "Setting up environment for OMS 13.5 installation..."
print_info "ORACLE_BASE: $ORACLE_BASE"

# Export ORACLE_BASE - This is critical for the installer to know where to put logs
export ORACLE_BASE="$ORACLE_BASE"

# Create log directory if it doesn't exist
LOG_DIR="${ORACLE_BASE}/cfgtoollogs"
if [ ! -d "$LOG_DIR" ]; then
    print_info "Creating log directory: $LOG_DIR"
    mkdir -p "$LOG_DIR"
    chmod 755 "$LOG_DIR"
else
    print_info "Log directory exists: $LOG_DIR"
fi

# Verify installer exists
if [ ! -f "${INSTALLER_PATH}/${INSTALLER_FILE}" ]; then
    print_error "Installer not found at ${INSTALLER_PATH}/${INSTALLER_FILE}"
    print_info "Please update INSTALLER_PATH and INSTALLER_FILE in this script"
    exit 1
fi

# Make installer executable
chmod +x "${INSTALLER_PATH}/${INSTALLER_FILE}"

# Verify response file exists
if [ ! -f "$RESPONSE_FILE" ]; then
    print_warning "Response file not found: $RESPONSE_FILE"
    print_info "Installation will proceed in interactive mode"
    RESPONSE_FILE_OPTION=""
else
    print_info "Using response file: $RESPONSE_FILE"
        unset CLASSPATH
	RESPONSE_FILE_OPTION="-silent -responseFile $RESPONSE_FILE"
fi

# Change to installer directory
cd "$INSTALLER_PATH"

print_info "Starting OMS 13.5 installation..."
print_warning "This may take 1-3 hours. Do not interrupt the process."
print_info "Logs will be available at: ${LOG_DIR}/install/"
echo ""

# Run the installer
if [ -n "$RESPONSE_FILE_OPTION" ]; then
    print_info "Running: ./${INSTALLER_FILE} ${RESPONSE_FILE_OPTION}"
    ./"${INSTALLER_FILE}" ${RESPONSE_FILE_OPTION}
else
    print_info "Running: ./${INSTALLER_FILE}"
    ./"${INSTALLER_FILE}"
fi

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    print_success "Installation completed successfully!"
    print_info "Check logs at: ${LOG_DIR}/install/"
else
    print_error "Installation failed with exit code: $EXIT_CODE"
    print_info "Check logs at: ${LOG_DIR}/install/"
    exit $EXIT_CODE
fi