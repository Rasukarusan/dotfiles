#!/bin/bash

#================================================
# App Store Applications Installation Script
#================================================
# This script installs macOS applications from the App Store using mas-cli.
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
readonly LOG_FILE="${HOME}/.dotfiles-install-appstore.log"

# App Store applications to be installed (ID and Name)
declare -A APPSTORE_APPS=(
  ["409203825"]="Numbers"
  ["1024640650"]="CotEditor"
  ["1081413713"]="GIF Brewery 3"
  ["408981434"]="iMovie"
  ["497799835"]="Xcode"
  ["409201541"]="Pages"
  ["409183694"]="Keynote"
  ["451444120"]="Memory Clean"
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

This script installs macOS applications from the App Store using mas-cli.

OPTIONS:
  -h, --help    Show this help message and exit
  -y, --yes     Skip confirmation prompt

FEATURES:
  - Checks if mas-cli is installed
  - Installs App Store applications
  - Skips already installed applications
  - Logs all operations to ${LOG_FILE}

REQUIREMENTS:
  - mas-cli must be installed (can be installed via Homebrew)
  - Must be signed in to the App Store

EXAMPLES:
  ${SCRIPT_NAME}          # Run with confirmation prompt
  ${SCRIPT_NAME} -y       # Run without confirmation prompt
  ${SCRIPT_NAME} -h       # Show this help message

EOF
}

check_mas() {
  if ! command -v mas &> /dev/null; then
    print_error "mas-cli is not installed. Please install mas-cli first."
    print_info "You can install it via Homebrew: brew install mas"
    exit 1
  fi
  
  print_success "mas-cli is installed: $(mas version)"
  
  # Check if signed in to App Store
  if ! mas account &> /dev/null; then
    print_error "Not signed in to the App Store. Please sign in first."
    print_info "Open the App Store app and sign in with your Apple ID."
    exit 1
  fi
  
  print_success "Signed in to App Store as: $(mas account)"
}

confirm_installation() {
  local skip_confirmation=$1
  
  if [[ "${skip_confirmation}" == "true" ]]; then
    return 0
  fi
  
  echo
  print_info "This script will install the following App Store applications:"
  echo
  echo "APPLICATIONS (${#APPSTORE_APPS[@]} items):"
  for app_id in "${!APPSTORE_APPS[@]}"; do
    echo "  - ${APPSTORE_APPS[$app_id]} (ID: ${app_id})"
  done | sort
  echo
  
  read -p "Do you want to proceed with the installation? [y/N] " -n 1 -r
  echo
  
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installation cancelled by user."
    exit 0
  fi
}

get_installed_apps() {
  # Get list of installed App Store apps
  mas list 2>/dev/null | awk '{print $1}' || true
}

install_appstore_apps() {
  print_info "Installing App Store applications..."
  
  local installed_count=0
  local skipped_count=0
  local failed_count=0
  
  # Get currently installed apps
  local installed_apps=$(get_installed_apps)
  
  for app_id in "${!APPSTORE_APPS[@]}"; do
    local app_name="${APPSTORE_APPS[$app_id]}"
    
    if echo "${installed_apps}" | grep -q "^${app_id}$"; then
      print_info "Already installed: ${app_name} (ID: ${app_id})"
      ((skipped_count++))
    else
      print_info "Installing: ${app_name} (ID: ${app_id})"
      if mas install "${app_id}"; then
        print_success "Installed: ${app_name} (ID: ${app_id})"
        ((installed_count++))
      else
        print_error "Failed to install: ${app_name} (ID: ${app_id})"
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
  
  print_info "Starting App Store applications installation..."
  log "----------------------------------------"
  
  # Check if mas-cli is installed and signed in
  check_mas
  
  # Confirm installation
  confirm_installation "${skip_confirmation}"
  
  # Install App Store applications
  install_appstore_apps
  
  print_success "App Store applications installation completed!"
  print_info "Log file: ${LOG_FILE}"
}

# Run main function
main "$@"