#!/bin/bash
source _logger.sh

e_message "Starting setup..."

# Create .zshrc file
touch ~/.zshrc

# Update repo if cloned with git
if $(which git); then
  if [ -d .git ]; then
    e_pending "Updating dotfiles"
    git pull origin main &> /dev/null
  fi
  e_success "Dotfiles updated"
fi

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
if ! $(which brew); then
  e_pending "Installing Homebrew"
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew doctor
  brew tap homebrew/cask-fonts
fi
e_success "Homebrew installed"

e_message "Setup complete!"
