#!/bin/bash

source _logger.sh

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