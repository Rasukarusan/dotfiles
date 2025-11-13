#!/bin/bash

#================================================
# Yarn Global Packages Installation Script
#================================================
# This script installs global packages via Yarn.
# Features:
#   - Standalone execution
#   - Help option (-h)
#   - Confirmation prompt before installation
#   - Skip already installed packages
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
readonly LOG_FILE="${HOME}/.dotfiles-install-yarn.log"

# Yarn packages to be installed globally
readonly YARN_PACKAGES=(
  "tailwindcss-language-server"
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

This script installs global packages via Yarn.

OPTIONS:
  -h, --help    Show this help message and exit
  -y, --yes     Skip confirmation prompt

FEATURES:
  - Checks if Yarn is installed
  - Installs packages globally
  - Skips already installed packages
  - Logs all operations to ${LOG_FILE}

EXAMPLES:
  ${SCRIPT_NAME}          # Run with confirmation prompt
  ${SCRIPT_NAME} -y       # Run without confirmation prompt
  ${SCRIPT_NAME} -h       # Show this help message

EOF
}

check_yarn() {
  if ! command -v yarn &> /dev/null; then
    print_error "Yarn is not installed. Please install Yarn first."
    print_info "You can install it via Homebrew: brew install yarn"
    exit 1
  fi
  
  print_success "Yarn is installed: $(yarn --version)"
}

confirm_installation() {
  local skip_confirmation=$1
  
  if [[ "${skip_confirmation}" == "true" ]]; then
    return 0
  fi
  
  echo
  print_info "This script will install the following Yarn packages globally:"
  echo
  echo "PACKAGES (${#YARN_PACKAGES[@]} items):"
  printf '  - %s\n' "${YARN_PACKAGES[@]}"
  echo
  
  read -p "Do you want to proceed with the installation? [y/N] " -n 1 -r
  echo
  
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installation cancelled by user."
    exit 0
  fi
}

get_installed_packages() {
  # Get list of globally installed packages via yarn
  yarn global list --depth=0 2>/dev/null | grep -E "^info" | grep -oE '"[^"]+"' | tr -d '"' | cut -d'@' -f1 || true
}

install_yarn_packages() {
  print_info "Installing Yarn packages globally..."
  
  local installed_count=0
  local skipped_count=0
  local failed_count=0
  
  # Get currently installed packages
  local installed_packages=$(get_installed_packages)
  
  for package in "${YARN_PACKAGES[@]}"; do
    if echo "${installed_packages}" | grep -q "${package}"; then
      print_info "Already installed: ${package}"
      ((skipped_count++))
    else
      print_info "Installing: ${package}"
      if yarn global add "${package}"; then
        print_success "Installed: ${package}"
        ((installed_count++))
      else
        print_error "Failed to install: ${package}"
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
  
  print_info "Starting Yarn packages installation..."
  log "----------------------------------------"
  
  # Check if Yarn is installed
  check_yarn
  
  # Confirm installation
  confirm_installation "${skip_confirmation}"
  
  # Install Yarn packages
  install_yarn_packages
  
  print_success "Yarn packages installation completed!"
  print_info "Log file: ${LOG_FILE}"
}

# Run main function
main "$@"