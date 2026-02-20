#!/bin/bash

# Symbolic Links Creation Script
# This script creates symbolic links for dotfiles based on the original ansible playbook

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

Create symbolic links for dotfiles

OPTIONS:
    -h, --help      Show this help message
    -y, --yes       Skip confirmation prompts
    -n, --dry-run   Show what would be done without making changes
    -f, --force     Force create links (overwrite existing files)

EXAMPLES:
    ${SCRIPT_NAME}           # Run with confirmation prompts
    ${SCRIPT_NAME} -y        # Run without confirmation prompts
    ${SCRIPT_NAME} -n        # Dry run mode
    ${SCRIPT_NAME} -f        # Force create links

EOF
}

# Parse command line arguments
DRY_RUN=false
SKIP_CONFIRM=false
FORCE=false

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
        -f|--force)
            FORCE=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Symlink definitions (from ansible vars)
declare -a SYMLINKS=(
    # Zsh
    "~/dotfiles/zsh/zshrc:~/.zshrc"
    "~/dotfiles/zsh/.zshrc.local:~/.zshrc.local"
    # Terminal
    "~/dotfiles/terminal/tmux.conf:~/.tmux.conf"
    "~/dotfiles/terminal/hyper.js:~/.hyper.js"
    "~/dotfiles/terminal/agignore:~/.agignore"
    "~/dotfiles/terminal/git/gitconfig:~/.gitconfig"
    "~/dotfiles/terminal/git/gitignore_global:~/.gitignore_global"
    # Vim
    "~/dotfiles/vim/xvimrc:~/.xvimrc"
    "~/dotfiles/vim/init.vim:~/.vimrc"
    "~/dotfiles/vim/init.vim:~/.config/nvim/init.vim"
    "~/dotfiles/vim/colors:~/.config/nvim/colors"
    "~/dotfiles/vim/colors:~/.vim/colors"
    "~/dotfiles/vim/textlintrc:~/.textlintrc"
    "~/dotfiles/vim/plugin_settings:~/.config/nvim/plugin_settings"
    "~/dotfiles/vim/coc/coc-settings.json:~/.config/nvim/coc-settings.json"
    "~/dotfiles/vim/coc/package.json:~/.config/coc/extensions/package.json"
    "~/dotfiles/vim/UltiSnips:~/.config/nvim/UltiSnips"
    "~/dotfiles/vim/autoload:~/.config/nvim/myautoload"
    "~/dotfiles/vim/lua:~/.config/nvim/lua"
    # Claude
    "~/dotfiles/claude/CLAUDE.md:~/.config/claude/CLAUDE.md"
    "~/dotfiles/claude/settings.json:~/.config/claude/settings.json"
    "~/dotfiles/claude/commands:~/.config/claude/commands"
    "~/dotfiles/claude/CLAUDE.md:~/.claude/CLAUDE.md"
    "~/dotfiles/claude/settings.json:~/.claude/settings.json"
    "~/dotfiles/claude/commands:~/.claude/commands"
)

# Confirmation prompt
if [[ "${SKIP_CONFIRM}" != "true" ]] && [[ "${DRY_RUN}" != "true" ]]; then
    echo "This script will create symbolic links for dotfiles."
    echo "Total links to create: ${#SYMLINKS[@]}"
    echo
    echo "Categories:"
    echo "  - Zsh configuration files"
    echo "  - Terminal configuration (tmux, git, etc.)"
    echo "  - Vim/Neovim configuration"
    echo "  - Claude configuration"
    echo
    if [[ "${FORCE}" == "true" ]]; then
        echo "WARNING: Force mode is enabled. Existing files will be overwritten!"
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
info "Starting symbolic links creation"
info "Log file: ${LOG_FILE}"

if [[ "${DRY_RUN}" == "true" ]]; then
    info "Running in DRY RUN mode - no changes will be made"
fi

# Function to expand tilde in path
expand_path() {
    echo "${1/#\~/$HOME}"
}

# Function to create symlink
create_symlink() {
    local src=$(expand_path "$1")
    local dest=$(expand_path "$2")
    local dest_dir=$(dirname "${dest}")
    
    # Check if source exists
    if [[ ! -e "${src}" ]]; then
        error "Source does not exist: ${src}"
        return 1
    fi
    
    # Create destination directory if it doesn't exist
    if [[ ! -d "${dest_dir}" ]]; then
        info "Creating directory: ${dest_dir}"
        if [[ "${DRY_RUN}" != "true" ]]; then
            mkdir -p "${dest_dir}"
        fi
    fi
    
    # Check if destination already exists
    if [[ -e "${dest}" ]] || [[ -L "${dest}" ]]; then
        if [[ -L "${dest}" ]]; then
            local current_target=$(readlink "${dest}")
            if [[ "${current_target}" == "${src}" ]]; then
                info "Link already exists and points to correct target: ${dest}"
                return 0
            fi
        fi
        
        if [[ "${FORCE}" == "true" ]]; then
            info "Removing existing file/link: ${dest}"
            if [[ "${DRY_RUN}" != "true" ]]; then
                rm -rf "${dest}"
            fi
        else
            error "Destination already exists: ${dest}"
            error "Use -f/--force to overwrite"
            return 1
        fi
    fi
    
    # Create symlink
    info "Creating link: ${dest} -> ${src}"
    if [[ "${DRY_RUN}" != "true" ]]; then
        if ln -s "${src}" "${dest}"; then
            success "Created: ${dest}"
        else
            error "Failed to create link: ${dest}"
            return 1
        fi
    else
        info "[DRY RUN] Would create: ${dest} -> ${src}"
    fi
}

# Process all symlinks
total=${#SYMLINKS[@]}
completed=0
failed=0

echo
info "Processing ${total} symbolic links..."
echo

for link_spec in "${SYMLINKS[@]}"; do
    IFS=':' read -r src dest <<< "${link_spec}"
    
    # Show progress
    echo -ne "${BLUE}[$(($completed + 1))/${total}]${NC} "
    
    if create_symlink "${src}" "${dest}"; then
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
    success "Symbolic links creation completed!"
fi
info "Total: ${total}, Successful: ${completed}, Failed: ${failed}"

if [[ ${failed} -gt 0 ]]; then
    error "Some links failed to create. Check the log for details."
fi

info "Log saved to: ${LOG_FILE}"

# Exit with error if any links failed
if [[ ${failed} -gt 0 ]]; then
    exit 1
fi

exit 0