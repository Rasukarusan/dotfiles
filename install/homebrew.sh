#!/bin/bash

#================================================
# Homebrew Packages Installation Script
#================================================
# This script installs Homebrew packages based on the list defined in this file.
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
readonly LOG_FILE="${HOME}/.dotfiles-install-homebrew.log"

# Homebrew taps to be added
readonly TAPS=(
  "homebrew/cask"
  "homebrew/core"
  "heroku/brew"
  "Rasukarusan/tap"
  "homebrew/cask-fonts"
  "homebrew/cask-versions"
)

# Homebrew packages to be installed
readonly PACKAGES=(
  "autoconf"
  "bat"
  "carthage"
  "composer"
  "coreutils"
  "ctags"
  "curl"
  "diff-so-fancy"
  "exiftool"
  "fish"
  "fzf"
  "fzf-chrome-active-tab"
  "gawk"
  "gcc"
  "git"
  "gitblamer"
  "global"
  "gnu-sed"
  "go"
  "grep"
  "heroku"
  "imagemagick"
  "jq"
  "mas"
  "mitmproxy"
  "ncdu"
  "neovim"
  "nkf"
  "node"
  "nodebrew"
  "pyenv"
  "pyenv-virtualenv"
  "python3"
  "ripgrep"
  "ruby"
  "the_silver_searcher"
  "tmux"
  "tree"
  "vim"
  "w3m"
  "watch"
  "wget"
  "yarn"
  "zsh"
  "swiftformat"
  "cocoapods"
  "chromedriver"
  "tokei"
  "ffmpeg"
  "rga"
  "pastel"
  "git-ftp"
  "silicon"
  "git-delta"
  "python-yq"
  "st"
  "jc"
  "gh"
  "gron"
  "lolcat"
  "flyctl"
  "azure-cli"
  "rust"
  "dasel"
  "kind"
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

This script installs Homebrew packages defined in the script.

OPTIONS:
  -h, --help    Show this help message and exit
  -y, --yes     Skip confirmation prompt

FEATURES:
  - Checks if Homebrew is installed
  - Taps required repositories
  - Installs packages (skips already installed ones)
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
  print_info "This script will install the following:"
  echo
  echo "TAPS (${#TAPS[@]} items):"
  printf '  - %s\n' "${TAPS[@]}"
  echo
  echo "PACKAGES (${#PACKAGES[@]} items):"
  printf '  - %s\n' "${PACKAGES[@]}"
  echo
  
  read -p "Do you want to proceed with the installation? [y/N] " -n 1 -r
  echo
  
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installation cancelled by user."
    exit 0
  fi
}

tap_repositories() {
  print_info "Tapping Homebrew repositories..."
  
  for tap in "${TAPS[@]}"; do
    if brew tap | grep -q "^${tap}$"; then
      print_info "Already tapped: ${tap}"
    else
      print_info "Tapping: ${tap}"
      if brew tap "${tap}"; then
        print_success "Tapped: ${tap}"
      else
        print_warning "Failed to tap: ${tap}"
      fi
    fi
  done
}

install_packages() {
  print_info "Installing Homebrew packages..."
  
  local installed_count=0
  local skipped_count=0
  local failed_count=0
  
  for package in "${PACKAGES[@]}"; do
    if brew list --formula | grep -q "^${package}$"; then
      print_info "Already installed: ${package}"
      ((skipped_count++))
    else
      print_info "Installing: ${package}"
      if brew install "${package}"; then
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
  
  print_info "Starting Homebrew packages installation..."
  log "----------------------------------------"
  
  # Check if Homebrew is installed
  check_homebrew
  
  # Confirm installation
  confirm_installation "${skip_confirmation}"
  
  # Tap repositories
  tap_repositories
  
  # Install packages
  install_packages
  
  print_success "Homebrew packages installation completed!"
  print_info "Log file: ${LOG_FILE}"
}

# Run main function
main "$@"