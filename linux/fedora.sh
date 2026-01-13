#!/bin/bash

# Fedora-specific setup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
source "$DOTFILES_DIR/_logger.sh"
source "$DOTFILES_DIR/_utils.sh"

e_message "Installing Fedora base packages"

# Update package lists
e_pending "Updating package lists"
sudo dnf check-update > /dev/null 2>&1 || true
e_success "Package lists updated"

# Install essential packages
dnf_install "curl"
dnf_install "wget"
dnf_install "gcc"
dnf_install "gcc-c++"
dnf_install "make"
dnf_install "ca-certificates"

e_message "Installing development tools"

# Common development tools
dnf_install "jq"
dnf_install "tree"
dnf_install "htop"
dnf_install "unzip"

# direnv
if ! has_command "direnv"; then
  dnf_install "direnv"
  zshrc 'eval "$(direnv hook zsh)"' "direnv config"
fi

# thefuck
if ! has_command "thefuck"; then
  dnf_install "python3-devel"
  dnf_install "python3-pip"
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
