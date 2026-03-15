#!/bin/bash

# File Permissions Script
# This script sets file permissions based on the original ansible playbook

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

Set file permissions for specific paths

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

# Permission definitions (from ansible vars)
declare -a PERMISSIONS=(
    "/usr/local/share/zsh:755"
    "/usr/local/share/zsh/site-functions:755"
)

# Confirmation prompt
if [[ "${SKIP_CONFIRM}" != "true" ]] && [[ "${DRY_RUN}" != "true" ]]; then
    echo "This script will set file permissions."
    echo "Total paths to modify: ${#PERMISSIONS[@]}"
    echo
    echo "Permissions to set:"
    for perm_spec in "${PERMISSIONS[@]}"; do
        IFS=':' read -r path mode <<< "${perm_spec}"
        echo "  - ${path} -> ${mode}"
    done
    echo
    echo "Note: This may require sudo privileges for system directories."
    echo
    read -p "Do you want to continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Operation cancelled by user"
        exit 0
    fi
fi

# Start logging
info "Starting file permissions configuration"
info "Log file: ${LOG_FILE}"

if [[ "${DRY_RUN}" == "true" ]]; then
    info "Running in DRY RUN mode - no changes will be made"
fi

# Function to set permissions
set_permissions() {
    local path="$1"
    local mode="$2"
    
    # Check if path exists
    if [[ ! -e "${path}" ]]; then
        error "Path does not exist: ${path}"
        return 1
    fi
    
    # Get current permissions
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        current_mode=$(stat -f "%Lp" "${path}" 2>/dev/null || echo "unknown")
    else
        # Linux
        current_mode=$(stat -c "%a" "${path}" 2>/dev/null || echo "unknown")
    fi
    
    if [[ "${current_mode}" == "${mode}" ]]; then
        info "Permissions already set correctly: ${path} (${mode})"
        return 0
    fi
    
    info "Setting permissions: ${path} (${current_mode} -> ${mode})"
    
    if [[ "${DRY_RUN}" != "true" ]]; then
        # Check if we need sudo
        if [[ -w "${path}" ]]; then
            # We can write to the path, no sudo needed
            if chmod "${mode}" "${path}"; then
                success "Set permissions: ${path} -> ${mode}"
            else
                error "Failed to set permissions: ${path}"
                return 1
            fi
        else
            # We need sudo
            info "Sudo required for: ${path}"
            if sudo chmod "${mode}" "${path}"; then
                success "Set permissions with sudo: ${path} -> ${mode}"
            else
                error "Failed to set permissions with sudo: ${path}"
                return 1
            fi
        fi
    else
        info "[DRY RUN] Would set: ${path} -> ${mode}"
        if [[ ! -w "${path}" ]]; then
            info "[DRY RUN] Would require sudo for: ${path}"
        fi
    fi
}

# Process all permissions
total=${#PERMISSIONS[@]}
completed=0
failed=0

echo
info "Processing ${total} permission changes..."
echo

for perm_spec in "${PERMISSIONS[@]}"; do
    IFS=':' read -r path mode <<< "${perm_spec}"
    
    # Show progress
    echo -ne "${BLUE}[$(($completed + 1))/${total}]${NC} "
    
    if set_permissions "${path}" "${mode}"; then
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
    success "File permissions configuration completed!"
fi
info "Total: ${total}, Successful: ${completed}, Failed: ${failed}"

if [[ ${failed} -gt 0 ]]; then
    error "Some permissions failed to set. Check the log for details."
fi

info "Log saved to: ${LOG_FILE}"

# Exit with error if any permissions failed
if [[ ${failed} -gt 0 ]]; then
    exit 1
fi

exit 0