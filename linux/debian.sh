#!/bin/bash

# Debian/Ubuntu-specific setup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
source "$DOTFILES_DIR/_logger.sh"
source "$DOTFILES_DIR/_utils.sh"

e_message "Installing Debian/Ubuntu base packages"

# Update package lists
e_pending "Updating package lists"
sudo apt-get update > /dev/null
e_success "Package lists updated"

# Install essential packages
apt_install "curl"
apt_install "wget"
apt_install "build-essential"
apt_install "ca-certificates"
apt_install "gnupg"
apt_install "lsb-release"

e_message "Installing development tools"

# Common development tools
apt_install "jq"
apt_install "tree"
apt_install "htop"
apt_install "unzip"

# direnv
if ! has_command "direnv"; then
  apt_install "direnv"
  zshrc 'eval "$(direnv hook zsh)"' "direnv config"
fi

# thefuck
if ! has_command "thefuck"; then
  apt_install "python3-dev"
  apt_install "python3-pip"
  pip3 install thefuck --user > /dev/null 2>&1
  zshrc 'eval "$(thefuck --alias)"' "thefuck config"
fi
test_command "thefuck"

# Configure folder structure
e_message "Setting folder structure"
if ! has_path "files"; then
  e_pending "Creating ~/files folder"
  mkdir -p ~/files ~/files/sandbox ~/files/projects ~/files/work
fi

# Source common scripts
source "$DOTFILES_DIR/common/git.sh"
source "$DOTFILES_DIR/common/languages.sh"
source "$DOTFILES_DIR/common/oh-my-zsh.sh"
