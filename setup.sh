#!/bin/bash

# Main Setup Script
# This script orchestrates the setup process by calling individual setup scripts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SETUP_DIR="${SCRIPT_DIR}/setup"

# Log file
LOG_FILE="${HOME}/.dotfiles-setup-main-$(date +%Y%m%d-%H%M%S).log"

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

show_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════╗"
    echo "║       Dotfiles Setup Script           ║"
    echo "║         Main Orchestrator             ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

show_help() {
    show_banner
    cat << EOF

Usage: ${0} [OPTIONS] [TASKS]

Run dotfiles setup tasks

OPTIONS:
    -h, --help      Show this help message
    -y, --yes       Skip confirmation prompts
    -n, --dry-run   Show what would be done without making changes
    -l, --list      List available tasks
    -a, --all       Run all tasks (default if no tasks specified)

TASKS:
    directories     Create necessary directories
    git-clone       Clone Git repositories
    symlinks        Create symbolic links
    permissions     Set file permissions
    macos           Configure macOS defaults

EXAMPLES:
    ${0}                    # Run all tasks interactively
    ${0} -y                 # Run all tasks without prompts
    ${0} directories symlinks # Run only specific tasks
    ${0} -n macos           # Dry run macOS configuration
    ${0} -l                 # List available tasks

EOF
}

# Available tasks in order
declare -a ALL_TASKS=(
    "directories"
    "git-clone"
    "symlinks"
    "permissions"
    "macos"
)

# Task descriptions
declare -A TASK_DESCRIPTIONS=(
    ["directories"]="Create necessary directories"
    ["git-clone"]="Clone Git repositories"
    ["symlinks"]="Create symbolic links"
    ["permissions"]="Set file permissions"
    ["macos"]="Configure macOS defaults"
)

# Parse command line arguments
DRY_RUN=""
SKIP_CONFIRM=""
RUN_ALL=false
SELECTED_TASKS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -y|--yes)
            SKIP_CONFIRM="-y"
            shift
            ;;
        -n|--dry-run)
            DRY_RUN="-n"
            shift
            ;;
        -l|--list)
            show_banner
            echo "Available tasks:"
            echo
            for task in "${ALL_TASKS[@]}"; do
                printf "  %-15s %s\n" "${task}" "${TASK_DESCRIPTIONS[$task]}"
            done
            echo
            exit 0
            ;;
        -a|--all)
            RUN_ALL=true
            shift
            ;;
        *)
            # Check if it's a valid task
            if [[ " ${ALL_TASKS[@]} " =~ " ${1} " ]]; then
                SELECTED_TASKS+=("$1")
            else
                error "Unknown option or task: $1"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# If no tasks selected, run all
if [[ ${#SELECTED_TASKS[@]} -eq 0 ]] || [[ "${RUN_ALL}" == "true" ]]; then
    SELECTED_TASKS=("${ALL_TASKS[@]}")
fi

# Show banner
show_banner

# Start logging
info "Starting dotfiles setup"
info "Log file: ${LOG_FILE}"
info "Script directory: ${SCRIPT_DIR}"

if [[ -n "${DRY_RUN}" ]]; then
    info "Running in DRY RUN mode - no changes will be made"
fi

# Show selected tasks
echo
info "Selected tasks:"
for task in "${SELECTED_TASKS[@]}"; do
    echo "  - ${task}: ${TASK_DESCRIPTIONS[$task]}"
done
echo

# Confirmation prompt
if [[ -z "${SKIP_CONFIRM}" ]] && [[ -z "${DRY_RUN}" ]]; then
    read -p "Do you want to continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Operation cancelled by user"
        exit 0
    fi
fi

# Function to run a task
run_task() {
    local task=$1
    local script_path="${SETUP_DIR}/${task}.sh"
    
    echo
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}Running task: ${task}${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    
    if [[ ! -f "${script_path}" ]]; then
        error "Script not found: ${script_path}"
        return 1
    fi
    
    if [[ ! -x "${script_path}" ]]; then
        error "Script is not executable: ${script_path}"
        return 1
    fi
    
    # Run the script with inherited options
    if "${script_path}" ${SKIP_CONFIRM} ${DRY_RUN}; then
        success "Task completed: ${task}"
        return 0
    else
        error "Task failed: ${task}"
        return 1
    fi
}

# Check if setup directory exists
if [[ ! -d "${SETUP_DIR}" ]]; then
    error "Setup directory not found: ${SETUP_DIR}"
    exit 1
fi

# Run selected tasks
total_tasks=${#SELECTED_TASKS[@]}
completed_tasks=0
failed_tasks=0

for i in "${!SELECTED_TASKS[@]}"; do
    task="${SELECTED_TASKS[$i]}"
    
    echo
    echo -e "${CYAN}[$(($i + 1))/${total_tasks}] Processing: ${task}${NC}"
    
    if run_task "${task}"; then
        ((completed_tasks++))
    else
        ((failed_tasks++))
        error "Task failed: ${task}"
        
        # Ask whether to continue
        if [[ -z "${SKIP_CONFIRM}" ]]; then
            read -p "Continue with remaining tasks? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                info "Stopping due to failed task"
                break
            fi
        fi
    fi
done

# Summary
echo
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo -e "${CYAN}            SETUP COMPLETE              ${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo

if [[ "${DRY_RUN}" == "-n" ]]; then
    success "Dry run completed. No changes were made."
else
    success "Dotfiles setup completed!"
fi

info "Total tasks: ${total_tasks}"
info "Successful: ${completed_tasks}"
info "Failed: ${failed_tasks}"

echo
info "Log saved to: ${LOG_FILE}"

# Next steps
if [[ ${failed_tasks} -eq 0 ]] && [[ -z "${DRY_RUN}" ]]; then
    echo
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Restart your terminal to apply shell configuration"
    echo "2. Some macOS settings may require logout/restart"
    echo "3. Check the log file for any warnings or notes"
fi

# Exit with error if any tasks failed
if [[ ${failed_tasks} -gt 0 ]]; then
    exit 1
fi

exit 0