#!/bin/bash

# macOS-specific applications (GUI apps via Homebrew Cask)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
source "$DOTFILES_DIR/_logger.sh"
source "$DOTFILES_DIR/_utils.sh"

e_message "Installing fonts"

# Fonts
brew tap homebrew/cask-fonts &> /dev/null
brew_cask_install "font-jetbrains-mono"

e_message "Installing macOS tools"

# Tools
brew_install "watchman"
brew_install "trash"
brew_install "thefuck"

if ! has_command "direnv"; then
  brew_install "direnv"
  zshrc 'eval "$(direnv hook $SHELL)"' "direnv config"
fi

e_message "Installing apps"

# Terminal
brew_cask_install "iterm2"

# Utils
brew_cask_install "1password"
brew_cask_install "maccy"
brew_cask_install "bambu-studio"
brew_cask_install "displaylink"

# Communication
brew_cask_install "slack"
brew_cask_install "discord"
brew_cask_install "whatsapp"
brew_cask_install "zoom"

# Browsers
brew_cask_install "google-chrome"

# IDEs
brew_cask_install "antigravity"
brew_cask_install "neovim"

# Development
brew_cask_install "orbstack"
brew_cask_install "figma"
brew_cask_install "linear-linear"
brew_cask_install "mongodb-compass"
brew_cask_install "ngrok"
brew_cask_install "postico"
brew_cask_install "postman"
