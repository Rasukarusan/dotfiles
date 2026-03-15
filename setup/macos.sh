#!/bin/bash

# macOS Default Settings Script
# This script configures macOS default settings based on the original ansible playbook

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

Configure macOS default settings

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

# Confirmation prompt
if [[ "${SKIP_CONFIRM}" != "true" ]] && [[ "${DRY_RUN}" != "true" ]]; then
    echo "This script will modify macOS default settings."
    echo "The following settings will be changed:"
    echo "  - iPhone Simulator: Enable fullscreen mode and show single touches"
    echo "  - Finder: Enable quit menu item"
    echo "  - Screenshot: Disable thumbnail preview and set custom filename"
    echo
    read -p "Do you want to continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Operation cancelled by user"
        exit 0
    fi
fi

# Start logging
info "Starting macOS default settings configuration"
info "Log file: ${LOG_FILE}"

if [[ "${DRY_RUN}" == "true" ]]; then
    info "Running in DRY RUN mode - no changes will be made"
fi

# Function to set default
set_default() {
    local domain=$1
    local key=$2
    local type=$3
    local value=$4
    
    # Convert ansible boolean to macOS boolean format
    if [[ "${type}" == "bool" ]]; then
        if [[ "${value}" == "TRUE" ]] || [[ "${value}" == "true" ]]; then
            value="true"
        else
            value="false"
        fi
        type="bool"
    fi
    
    # Check current value
    current_value=$(defaults read "${domain}" "${key}" 2>/dev/null || echo "NOT_SET")
    
    if [[ "${current_value}" == "${value}" ]] || [[ "${current_value}" == "1" && "${value}" == "true" ]] || [[ "${current_value}" == "0" && "${value}" == "false" ]]; then
        info "Setting ${domain} ${key} is already set to ${value}"
        return 0
    fi
    
    info "Setting ${domain} ${key} to ${value} (was: ${current_value})"
    
    if [[ "${DRY_RUN}" != "true" ]]; then
        if defaults write "${domain}" "${key}" "-${type}" "${value}"; then
            success "Set ${domain} ${key} to ${value}"
        else
            error "Failed to set ${domain} ${key}"
            return 1
        fi
    else
        info "[DRY RUN] Would set ${domain} ${key} to ${value}"
    fi
}

# Apply settings
info "Applying macOS default settings..."

# iPhone Simulator settings
set_default "com.apple.iphonesimulator" "AllowFullscreenMode" "bool" "TRUE"
set_default "com.apple.iphonesimulator" "ShowSingleTouches" "bool" "TRUE"

# Finder settings
set_default "com.apple.finder" "QuitMenuItem" "bool" "TRUE"

# Screenshot settings
set_default "com.apple.screencapture" "show-thumbnail" "bool" "FALSE"
set_default "com.apple.screencapture" "name" "string" "screenshot_"

# Kill affected applications if not in dry run mode
if [[ "${DRY_RUN}" != "true" ]]; then
    info "Restarting affected applications..."
    
    # Only restart Finder if it's running and we changed its settings
    if pgrep Finder > /dev/null; then
        killall Finder 2>/dev/null || true
        success "Finder restarted"
    fi
    
    # SystemUIServer handles screenshot settings
    if pgrep SystemUIServer > /dev/null; then
        killall SystemUIServer 2>/dev/null || true
        success "SystemUIServer restarted"
    fi
else
    info "[DRY RUN] Would restart Finder and SystemUIServer"
fi

# Summary
echo
if [[ "${DRY_RUN}" == "true" ]]; then
    success "Dry run completed. No changes were made."
else
    success "macOS default settings configuration completed!"
fi

info "Log saved to: ${LOG_FILE}"

exit 0