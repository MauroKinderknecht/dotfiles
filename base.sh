#!/bin/bash

source _logger.sh

e_message "Starting setup..."

# Check if MacOS
if ! [[ "${OSTYPE}" == "darwin"* ]]; then
  e_failure "Unsupported operating system. This setup is only available for MacOS"
  exit 1
fi

# Ask for sudo access and keep it alive
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Create .zshrc file
touch ~/.zshrc
zsh

# Install XCode Command Line Tools
if ! $(xcode-select --print-path &> /dev/null); then
  e_pending "Installing XCode Command Line Tools"
  xcode-select --install &> /dev/null

  until $(xcode-select --print-path &> /dev/null); do
    sleep 5;
  done
fi
e_success "XCode Command Line Tools installed"

# Install Homebrew
if ! $(which brew &> /dev/null); then
  e_pending "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew doctor
  brew tap homebrew/cask-fonts
fi
e_success "Homebrew installed"

e_message "Setup complete!"