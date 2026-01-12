#!/bin/bash

#================================================
# Dotfiles Installation Main Script
#================================================
# This is the main installation script that coordinates the execution
# of individual installation scripts with selective execution capability.
# Features:
#   - Interactive menu for selecting which installers to run
#   - Run all installers at once
#   - Individual script execution
#   - Help option (-h)
#   - Non-interactive mode with specific scripts
#   - Execution logging
#================================================

set -e  # Exit on error

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Script info
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
readonly LOG_FILE="${HOME}/.dotfiles-install-main.log"

# Available installation scripts
declare -A INSTALLERS=(
  ["1"]="install/homebrew.sh:Homebrew packages"
  ["2"]="install/homebrew-cask.sh:Homebrew Cask applications"
  ["3"]="install/npm.sh:NPM global packages"
  ["4"]="install/yarn.sh:Yarn global packages"
  ["5"]="install/appstore.sh:App Store applications"
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

print_header() {
  echo -e "${CYAN}================================================${NC}"
  echo -e "${CYAN}$1${NC}"
  echo -e "${CYAN}================================================${NC}"
}

show_help() {
  cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS] [SCRIPTS...]

This is the main installation script for dotfiles setup.
It allows selective execution of individual installation scripts.

OPTIONS:
  -h, --help    Show this help message and exit
  -y, --yes     Skip confirmation prompts in individual scripts
  -a, --all     Run all installation scripts

SCRIPTS:
  homebrew      Run Homebrew packages installation
  cask          Run Homebrew Cask applications installation
  npm           Run NPM packages installation
  yarn          Run Yarn packages installation
  appstore      Run App Store applications installation

EXAMPLES:
  ${SCRIPT_NAME}                    # Interactive menu mode
  ${SCRIPT_NAME} -a                 # Run all installers
  ${SCRIPT_NAME} homebrew npm       # Run specific installers
  ${SCRIPT_NAME} -y homebrew cask   # Run specific installers without prompts
  ${SCRIPT_NAME} -h                 # Show this help message

NOTES:
  - Each script can also be run independently from the install/ directory
  - All scripts support -h for help and -y for skipping confirmations
  - Installation logs are saved to ~/.dotfiles-install-*.log

EOF
}

check_script_exists() {
  local script_path="$1"
  if [[ ! -f "${SCRIPT_DIR}/${script_path}" ]]; then
    print_error "Script not found: ${script_path}"
    return 1
  fi
  if [[ ! -x "${SCRIPT_DIR}/${script_path}" ]]; then
    print_error "Script not executable: ${script_path}"
    return 1
  fi
  return 0
}

run_installer() {
  local script_path="$1"
  local description="$2"
  local skip_confirmation="$3"
  
  print_header "Running: ${description}"
  
  if check_script_exists "${script_path}"; then
    if [[ "${skip_confirmation}" == "true" ]]; then
      "${SCRIPT_DIR}/${script_path}" -y
    else
      "${SCRIPT_DIR}/${script_path}"
    fi
    local exit_code=$?
    
    if [[ ${exit_code} -eq 0 ]]; then
      print_success "${description} completed successfully"
    else
      print_error "${description} failed with exit code ${exit_code}"
      return ${exit_code}
    fi
  else
    return 1
  fi
  
  echo
}

show_menu() {
  print_header "Dotfiles Installation Menu"
  echo
  echo "Select which installers to run:"
  echo
  
  for key in $(echo "${!INSTALLERS[@]}" | tr ' ' '\n' | sort -n); do
    local installer_info="${INSTALLERS[$key]}"
    local description="${installer_info#*:}"
    echo "  ${key}) ${description}"
  done
  
  echo
  echo "  a) Run all installers"
  echo "  q) Quit"
  echo
}

get_script_name_from_arg() {
  local arg="$1"
  case "${arg}" in
    homebrew)
      echo "install/homebrew.sh"
      ;;
    cask|homebrew-cask)
      echo "install/homebrew-cask.sh"
      ;;
    npm)
      echo "install/npm.sh"
      ;;
    yarn)
      echo "install/yarn.sh"
      ;;
    appstore|app-store)
      echo "install/appstore.sh"
      ;;
    *)
      return 1
      ;;
  esac
}

interactive_mode() {
  local skip_confirmation="$1"
  
  while true; do
    show_menu
    read -p "Enter your choice: " choice
    
    case "${choice}" in
      [1-5])
        local installer_info="${INSTALLERS[$choice]}"
        local script_path="${installer_info%:*}"
        local description="${installer_info#*:}"
        run_installer "${script_path}" "${description}" "${skip_confirmation}"
        ;;
      a|A)
        print_info "Running all installers..."
        for key in $(echo "${!INSTALLERS[@]}" | tr ' ' '\n' | sort -n); do
          local installer_info="${INSTALLERS[$key]}"
          local script_path="${installer_info%:*}"
          local description="${installer_info#*:}"
          run_installer "${script_path}" "${description}" "${skip_confirmation}"
        done
        break
        ;;
      q|Q)
        print_info "Installation cancelled by user."
        break
        ;;
      *)
        print_warning "Invalid choice. Please try again."
        ;;
    esac
    
    if [[ "${choice}" != [aAqQ] ]]; then
      echo
      read -p "Press Enter to continue..."
    fi
  done
}

main() {
  local skip_confirmation=false
  local run_all=false
  local scripts_to_run=()
  
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
      -a|--all)
        run_all=true
        shift
        ;;
      -*)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
      *)
        # Try to map argument to script name
        if script_name=$(get_script_name_from_arg "$1"); then
          scripts_to_run+=("${script_name}")
        else
          print_error "Unknown script: $1"
          show_help
          exit 1
        fi
        shift
        ;;
    esac
  done
  
  print_info "Starting dotfiles installation..."
  log "----------------------------------------"
  
  # Determine execution mode
  if [[ ${run_all} == true ]]; then
    # Run all installers
    print_info "Running all installers..."
    for key in $(echo "${!INSTALLERS[@]}" | tr ' ' '\n' | sort -n); do
      local installer_info="${INSTALLERS[$key]}"
      local script_path="${installer_info%:*}"
      local description="${installer_info#*:}"
      run_installer "${script_path}" "${description}" "${skip_confirmation}"
    done
  elif [[ ${#scripts_to_run[@]} -gt 0 ]]; then
    # Run specific scripts
    for script_path in "${scripts_to_run[@]}"; do
      # Find description from INSTALLERS array
      local description="Unknown script"
      for installer_info in "${INSTALLERS[@]}"; do
        if [[ "${installer_info%:*}" == "${script_path}" ]]; then
          description="${installer_info#*:}"
          break
        fi
      done
      run_installer "${script_path}" "${description}" "${skip_confirmation}"
    done
  else
    # Interactive mode
    interactive_mode "${skip_confirmation}"
  fi
  
  print_success "Dotfiles installation process completed!"
  print_info "Log file: ${LOG_FILE}"
}

# Run main function
main "$@"