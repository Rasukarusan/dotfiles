#!/bin/bash

# Git Clone Script
# This script clones necessary Git repositories based on the original ansible playbook

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

Clone necessary Git repositories

OPTIONS:
    -h, --help      Show this help message
    -y, --yes       Skip confirmation prompts
    -n, --dry-run   Show what would be done without making changes
    -u, --update    Update existing repositories (pull latest changes)

EXAMPLES:
    ${SCRIPT_NAME}           # Run with confirmation prompts
    ${SCRIPT_NAME} -y        # Run without confirmation prompts
    ${SCRIPT_NAME} -n        # Dry run mode
    ${SCRIPT_NAME} -u        # Update existing repos

EOF
}

# Parse command line arguments
DRY_RUN=false
SKIP_CONFIRM=false
UPDATE_EXISTING=false

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
        -u|--update)
            UPDATE_EXISTING=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Repository definitions (from ansible vars)
declare -a REPOSITORIES=(
    "https://github.com/Rasukarusan/nvim.git:~/.config/nvim"
    "https://github.com/Rasukarusan/nvim-block-paste.git:~/.config/nvim/plugin"
    "https://github.com/Rasukarusan/nvim-popup-message.git:~/.config/nvim/plugin"
    "https://github.com/Rasukarusan/nvim.git:~/.vim"
    "https://github.com/Rasukarusan/develop_tools.git:~/Desktop/develop_tools"
    "https://github.com/Rasukarusan/chrome-extension-packs.git:~/Documents/chrome-extension-packs"
    "https://github.com/Rasukarusan/keynote-template.git:~/Documents/keynote-template"
    "https://github.com/Rasukarusan/scripts.git:~/scripts"
    "https://github.com/Rasukarusan/articles.git:~/Documents/articles"
)

# Check if git is installed
if ! command -v git &> /dev/null; then
    error "git is not installed. Please install git first."
    exit 1
fi

# Confirmation prompt
if [[ "${SKIP_CONFIRM}" != "true" ]] && [[ "${DRY_RUN}" != "true" ]]; then
    echo "This script will clone Git repositories."
    echo "Total repositories to clone: ${#REPOSITORIES[@]}"
    echo
    echo "Repositories:"
    for repo_spec in "${REPOSITORIES[@]}"; do
        IFS=':' read -r repo dest <<< "${repo_spec}"
        echo "  - ${repo}"
        echo "    -> ${dest}"
    done
    echo
    if [[ "${UPDATE_EXISTING}" == "true" ]]; then
        echo "Note: Existing repositories will be updated (git pull)"
        echo
    fi
    read -p "Do you want to continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Operation cancelled by user"
        exit 0
    fi
fi

# Start logging
info "Starting Git repository cloning"
info "Log file: ${LOG_FILE}"

if [[ "${DRY_RUN}" == "true" ]]; then
    info "Running in DRY RUN mode - no changes will be made"
fi

# Function to expand tilde in path
expand_path() {
    echo "${1/#\~/$HOME}"
}

# Function to clone or update repository
clone_repository() {
    local repo_url="$1"
    local dest=$(expand_path "$2")
    local dest_dir=$(dirname "${dest}")
    
    # Create parent directory if needed
    if [[ ! -d "${dest_dir}" ]]; then
        info "Creating parent directory: ${dest_dir}"
        if [[ "${DRY_RUN}" != "true" ]]; then
            mkdir -p "${dest_dir}"
        fi
    fi
    
    # Check if destination already exists
    if [[ -d "${dest}" ]]; then
        if [[ -d "${dest}/.git" ]]; then
            # It's a git repository
            if [[ "${UPDATE_EXISTING}" == "true" ]]; then
                info "Updating existing repository: ${dest}"
                if [[ "${DRY_RUN}" != "true" ]]; then
                    cd "${dest}"
                    if git pull; then
                        success "Updated: ${dest}"
                    else
                        error "Failed to update: ${dest}"
                        return 1
                    fi
                    cd - > /dev/null
                else
                    info "[DRY RUN] Would update: ${dest}"
                fi
            else
                info "Repository already exists: ${dest}"
                info "Use -u/--update to update existing repositories"
            fi
            return 0
        else
            error "Destination exists but is not a git repository: ${dest}"
            return 1
        fi
    fi
    
    # Clone repository
    info "Cloning: ${repo_url}"
    info "    to: ${dest}"
    if [[ "${DRY_RUN}" != "true" ]]; then
        if git clone "${repo_url}" "${dest}"; then
            success "Cloned: ${dest}"
        else
            error "Failed to clone: ${repo_url}"
            return 1
        fi
    else
        info "[DRY RUN] Would clone: ${repo_url} to ${dest}"
    fi
}

# Process all repositories
total=${#REPOSITORIES[@]}
completed=0
failed=0

echo
info "Processing ${total} repositories..."
echo

for repo_spec in "${REPOSITORIES[@]}"; do
    IFS=':' read -r repo dest <<< "${repo_spec}"
    
    # Show progress
    echo -ne "${BLUE}[$(($completed + 1))/${total}]${NC} "
    
    if clone_repository "${repo}" "${dest}"; then
        ((completed++))
    else
        ((failed++))
    fi
    echo
done

# Summary
echo
echo "----------------------------------------"
if [[ "${DRY_RUN}" == "true" ]]; then
    success "Dry run completed. No changes were made."
else
    success "Git repository cloning completed!"
fi
info "Total: ${total}, Successful: ${completed}, Failed: ${failed}"

if [[ ${failed} -gt 0 ]]; then
    error "Some repositories failed to clone. Check the log for details."
fi

info "Log saved to: ${LOG_FILE}"

# Exit with error if any repositories failed
if [[ ${failed} -gt 0 ]]; then
    exit 1
fi

exit 0