#!/bin/bash

# Directories Creation Script
# This script creates necessary directories based on the original ansible playbook

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script name for logging
SCRIPT_NAME=$(basename "$0")
LOG_FILE="${HOME}/.dotfiles-setup-$(date +%Y%m%d-%H%M%S).log"

# Functions
log() {
    echo -e "${1}" | tee -a "${LOG_FILE}"
}

error() {
    log "${RED}[ERROR] ${1}${NC}"
}

success() {
    log "${GREEN}[SUCCESS] ${1}${NC}"
}

info() {
    log "${YELLOW}[INFO] ${1}${NC}"
}

show_help() {
    cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Create necessary directories for dotfiles

OPTIONS:
    -h, --help      Show this help message
    -y, --yes       Skip confirmation prompts
    -n, --dry-run   Show what would be done without making changes

EXAMPLES:
    ${SCRIPT_NAME}           # Run with confirmation prompts
    ${SCRIPT_NAME} -y        # Run without confirmation prompts
    ${SCRIPT_NAME} -n        # Dry run mode

EOF
}

# Parse command line arguments
DRY_RUN=false
SKIP_CONFIRM=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -y|--yes)
            SKIP_CONFIRM=true
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Directory definitions (from ansible vars)
declare -a DIRECTORIES=(
    "~/.zsh"
    "~/.config/nvim/plugin"
    "~/.cache/cdr"
    "~/.claude"
)

# Confirmation prompt
if [[ "${SKIP_CONFIRM}" != "true" ]] && [[ "${DRY_RUN}" != "true" ]]; then
    echo "This script will create necessary directories for dotfiles."
    echo "Total directories to create: ${#DIRECTORIES[@]}"
    echo
    echo "Directories:"
    for dir in "${DIRECTORIES[@]}"; do
        echo "  - ${dir}"
    done
    echo
    read -p "Do you want to continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Operation cancelled by user"
        exit 0
    fi
fi

# Start logging
info "Starting directory creation"
info "Log file: ${LOG_FILE}"

if [[ "${DRY_RUN}" == "true" ]]; then
    info "Running in DRY RUN mode - no changes will be made"
fi

# Function to expand tilde in path
expand_path() {
    echo "${1/#\~/$HOME}"
}

# Function to create directory
create_directory() {
    local dir=$(expand_path "$1")
    
    # Check if directory already exists
    if [[ -d "${dir}" ]]; then
        info "Directory already exists: ${dir}"
        return 0
    fi
    
    # Check if a file exists with the same name
    if [[ -e "${dir}" ]]; then
        error "A file exists with the same name: ${dir}"
        return 1
    fi
    
    # Create directory
    info "Creating directory: ${dir}"
    if [[ "${DRY_RUN}" != "true" ]]; then
        if mkdir -p "${dir}"; then
            success "Created: ${dir}"
            
            # Verify creation
            if [[ ! -d "${dir}" ]]; then
                error "Directory creation verification failed: ${dir}"
                return 1
            fi
        else
            error "Failed to create directory: ${dir}"
            return 1
        fi
    else
        info "[DRY RUN] Would create: ${dir}"
    fi
}

# Process all directories
total=${#DIRECTORIES[@]}
completed=0
failed=0

echo
info "Processing ${total} directories..."
echo

for dir in "${DIRECTORIES[@]}"; do
    # Show progress
    echo -ne "${BLUE}[$(($completed + 1))/${total}]${NC} "
    
    if create_directory "${dir}"; then
        ((completed++))
    else
        ((failed++))
    fi
done

# Summary
echo
echo "----------------------------------------"
if [[ "${DRY_RUN}" == "true" ]]; then
    success "Dry run completed. No changes were made."
else
    success "Directory creation completed!"
fi
info "Total: ${total}, Successful: ${completed}, Failed: ${failed}"

if [[ ${failed} -gt 0 ]]; then
    error "Some directories failed to create. Check the log for details."
fi

info "Log saved to: ${LOG_FILE}"

# Exit with error if any directories failed
if [[ ${failed} -gt 0 ]]; then
    exit 1
fi

exit 0