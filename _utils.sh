#!/bin/bash

# Cross-platform utility functions

# =============================================================================
# Logging (source-able from any script)
# =============================================================================
source "$(dirname "${BASH_SOURCE[0]}")/_logger.sh"

# =============================================================================
# OS Detection
# =============================================================================
get_os() {
  if [[ "${OSTYPE}" == "darwin"* ]]; then
    echo "macos"
  elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
      debian|ubuntu|pop|linuxmint|elementary)
        echo "debian"
        ;;
      fedora|rhel|centos|rocky|almalinux)
        echo "fedora"
        ;;
      *)
        echo "unknown"
        ;;
    esac
  else
    echo "unknown"
  fi
}

OS_TYPE=$(get_os)

# =============================================================================
# Path and Command Utilities
# =============================================================================
zshrc() {
  if ! [ -z "$2" ]; then
    echo "" >> ~/.zshrc
    echo "# $2" >> ~/.zshrc
  fi
  echo "$1" >> ~/.zshrc
  source $HOME/.zshrc
}

has_path() {
  local path="$*"
  if [ -e "$HOME/$path" ]; then
    return 0
  fi
  return 1
}

has_command() {
  if [ -x "$(command -v $1)" ]; then
    return 0
  fi
  return 1
}

# =============================================================================
# Package Manager Detection
# =============================================================================
has_brew() {
  if command -v brew &> /dev/null && brew ls --versions "$1" &> /dev/null; then
    return 0
  fi
  return 1
}

has_apt() {
  if command -v dpkg &> /dev/null && dpkg -l "$1" 2>/dev/null | grep -q "^ii"; then
    return 0
  fi
  return 1
}

has_dnf() {
  if command -v rpm &> /dev/null && rpm -q "$1" &> /dev/null; then
    return 0
  fi
  return 1
}

has_cask() {
  if brew ls --cask "$1" &> /dev/null; then
    return 0
  fi
  return 1
}

has_app() {
  local name="$*"
  if [ -e "/Applications/$name.app" ]; then
    return 0
  fi
  return 1
}

has_variable() {
  if [ -z "${!1}" ]; then
    return 1
  fi
  return 0
}

# =============================================================================
# Cross-Platform Package Check
# =============================================================================
has_pkg() {
  case "$OS_TYPE" in
    macos)  has_brew "$1" ;;
    debian) has_apt "$1" ;;
    fedora) has_dnf "$1" ;;
    *)      return 1 ;;
  esac
}

# =============================================================================
# Test Functions
# =============================================================================
test_path() {
  if has_path "$1"; then
    e_success "$1"
  else
    e_failure "$1"
  fi
}

test_command() {
  if has_command "$1"; then
    e_success "$1"
  else
    e_failure "$1"
  fi
}

test_brew() {
  if has_brew "$1"; then
    e_success "$1"
  else
    e_failure "$1"
  fi
}

test_cask() {
  if has_cask "$1"; then
    e_success "$1"
  else
    e_failure "$1"
  fi
}

test_app() {
  if has_app "$1"; then
    e_success "$1"
  else
    e_failure "$1"
  fi
}

test_apt() {
  if has_apt "$1"; then
    e_success "$1"
  else
    e_failure "$1"
  fi
}

test_dnf() {
  if has_dnf "$1"; then
    e_success "$1"
  else
    e_failure "$1"
  fi
}

# =============================================================================
# Package Installation Functions
# =============================================================================
brew_install() {
  if ! has_brew "$1"; then
    e_pending "Installing $1"
    brew install "$1" > /dev/null
  fi
  test_brew "$1"
}

brew_cask_install() {
  if ! has_cask "$1"; then
    e_pending "Installing $1"
    brew install --cask "$1" > /dev/null
  fi
  test_cask "$1"
}

apt_install() {
  if ! has_apt "$1"; then
    e_pending "Installing $1"
    sudo apt-get install -y "$1" > /dev/null
  fi
  test_apt "$1"
}

dnf_install() {
  if ! has_dnf "$1"; then
    e_pending "Installing $1"
    sudo dnf install -y "$1" > /dev/null
  fi
  test_dnf "$1"
}

# =============================================================================
# Cross-Platform Package Installation
# =============================================================================
pkg_install() {
  case "$OS_TYPE" in
    macos)  brew_install "$1" ;;
    debian) apt_install "$1" ;;
    fedora) dnf_install "$1" ;;
    *)      e_failure "Unknown OS, cannot install $1" ;;
  esac
}
