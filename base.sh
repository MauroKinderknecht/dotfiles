#!/bin/bash

source _logger.sh
source _utils.sh

e_message "Starting setup..."

# Check if MacOS
if ! [[ "${OSTYPE}" == "darwin"* ]]; then
  e_failure "Unsupported operating system. This setup is only available for MacOS"
  exit 1
fi

# Ask for sudo access and keep it alive
e_pending "Requesting sudo access"
sudo -v
while true
do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done &> /dev/null &
e_success "Sudo access granted"

# Create .zshrc file
if ! has_path ".zshrc"; then
  touch $HOME/.zshrc
  touch $HOME/.zprofile
fi

e_message "installing base tools"

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
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &> /dev/null
  zshrc 'eval "$(/opt/homebrew/bin/brew shellenv)"' "Homebrew"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  brew doctor
  brew tap homebrew/cask-fonts
fi
e_success "Homebrew installed"

source config.sh
source apps.sh

e_message "Setup complete!"