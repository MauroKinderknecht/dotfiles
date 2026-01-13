#!/bin/bash

# macOS-specific base setup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
source "$DOTFILES_DIR/_logger.sh"
source "$DOTFILES_DIR/_utils.sh"

e_message "Installing macOS base tools"

# Install XCode Command Line Tools
if ! xcode-select --print-path &> /dev/null; then
  e_pending "Installing XCode Command Line Tools"
  xcode-select --install &> /dev/null

  until xcode-select --print-path &> /dev/null; do
    sleep 5
  done
fi
e_success "XCode Command Line Tools installed"

# Install Homebrew
if ! command -v brew &> /dev/null; then
  e_pending "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &> /dev/null
  zshrc 'eval "$(/opt/homebrew/bin/brew shellenv)"' "Homebrew"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  brew doctor
  brew tap homebrew/cask-fonts
fi
e_success "Homebrew installed"

# Source common scripts
source "$DOTFILES_DIR/common/git.sh"
source "$DOTFILES_DIR/common/languages.sh"
source "$DOTFILES_DIR/common/oh-my-zsh.sh"

# Source macOS-specific config and apps
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/apps.sh"
