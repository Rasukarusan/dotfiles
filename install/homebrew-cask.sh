#!/bin/bash

#================================================
# Homebrew Cask Applications Installation Script
#================================================
# This script installs macOS applications via Homebrew Cask.
# Features:
#   - Standalone execution
#   - Help option (-h)
#   - Confirmation prompt before installation
#   - Skip already installed applications
#   - Error handling
#   - Execution logging
#================================================

set -e  # Exit on error

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Script info
readonly SCRIPT_NAME=$(basename "$0")
readonly LOG_FILE="${HOME}/.dotfiles-install-homebrew-cask.log"

# Homebrew Cask applications to be installed
readonly CASK_APPS=(
  "google-chrome"
  "firefox"
  "google-japanese-ime"
  "visual-studio-code"
  "iterm2"
  "hyper"
  "docker"
  "wireshark"
  "virtualbox"
  "sequel-ace"
  "ngrok"
  "java11"
  "couleurs"
  "keycastr"
  "another-redis-desktop-manager"
  "font-hackgen"
  "font-hackgen-nerd"
)

# Functions
log() {
  local message="$1"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[${timestamp}] ${message}" | tee -a "${LOG_FILE}"
}

print_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
  log "[INFO] $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
  log "[SUCCESS] $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
  log "[WARNING] $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
  log "[ERROR] $1"
}

show_help() {
  cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

This script installs macOS applications via Homebrew Cask.

OPTIONS:
  -h, --help    Show this help message and exit
  -y, --yes     Skip confirmation prompt

FEATURES:
  - Checks if Homebrew is installed
  - Installs Cask applications to /Applications
  - Skips already installed applications
  - Logs all operations to ${LOG_FILE}

EXAMPLES:
  ${SCRIPT_NAME}          # Run with confirmation prompt
  ${SCRIPT_NAME} -y       # Run without confirmation prompt
  ${SCRIPT_NAME} -h       # Show this help message

EOF
}

check_homebrew() {
  if ! command -v brew &> /dev/null; then
    print_error "Homebrew is not installed. Please install Homebrew first."
    print_info "Visit https://brew.sh for installation instructions."
    exit 1
  fi
  print_success "Homebrew is installed: $(brew --version | head -n1)"
}

confirm_installation() {
  local skip_confirmation=$1
  
  if [[ "${skip_confirmation}" == "true" ]]; then
    return 0
  fi
  
  echo
  print_info "This script will install the following Cask applications:"
  echo
  echo "APPLICATIONS (${#CASK_APPS[@]} items):"
  printf '  - %s\n' "${CASK_APPS[@]}"
  echo
  
  read -p "Do you want to proceed with the installation? [y/N] " -n 1 -r
  echo
  
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installation cancelled by user."
    exit 0
  fi
}

install_cask_apps() {
  print_info "Installing Homebrew Cask applications..."
  
  local installed_count=0
  local skipped_count=0
  local failed_count=0
  
  # Set environment variable for installation directory
  export HOMEBREW_CASK_OPTS="--appdir=/Applications"
  
  for app in "${CASK_APPS[@]}"; do
    if brew list --cask | grep -q "^${app}$"; then
      print_info "Already installed: ${app}"
      ((skipped_count++))
    else
      print_info "Installing: ${app}"
      if brew install --cask "${app}"; then
        print_success "Installed: ${app}"
        ((installed_count++))
      else
        print_error "Failed to install: ${app}"
        ((failed_count++))
      fi
    fi
  done
  
  echo
  print_info "Installation summary:"
  print_info "  - Newly installed: ${installed_count}"
  print_info "  - Already installed: ${skipped_count}"
  if [[ ${failed_count} -gt 0 ]]; then
    print_warning "  - Failed: ${failed_count}"
  fi
}

main() {
  local skip_confirmation=false
  
  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        show_help
        exit 0
        ;;
      -y|--yes)
        skip_confirmation=true
        shift
        ;;
      *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done
  
  print_info "Starting Homebrew Cask applications installation..."
  log "----------------------------------------"
  
  # Check if Homebrew is installed
  check_homebrew
  
  # Confirm installation
  confirm_installation "${skip_confirmation}"
  
  # Install Cask applications
  install_cask_apps
  
  print_success "Homebrew Cask applications installation completed!"
  print_info "Log file: ${LOG_FILE}"
}

# Run main function
main "$@"