#!/bin/bash

# Main entry point - detects OS and routes to appropriate setup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_logger.sh"
source "$SCRIPT_DIR/_utils.sh"

e_message "Starting setup..."

# Detect OS
OS_TYPE=$(get_os)
e_info "Detected OS: $OS_TYPE"

if [[ "$OS_TYPE" == "unknown" ]]; then
  e_failure "Unsupported operating system. Supported: macOS, Debian/Ubuntu, Fedora"
  exit 1
fi

# Ask for sudo access and keep it alive
e_pending "Requesting sudo access"
sudo -v
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done &> /dev/null &
e_success "Sudo access granted"

# Create .zshrc file if not exists
if ! has_path ".zshrc"; then
  touch "$HOME/.zshrc"
  touch "$HOME/.zprofile"
fi

# Route to platform-specific setup
case "$OS_TYPE" in
  macos)
    source "$SCRIPT_DIR/macos/base.sh"
    ;;
  debian)
    source "$SCRIPT_DIR/linux/debian.sh"
    ;;
  fedora)
    source "$SCRIPT_DIR/linux/fedora.sh"
    ;;
esac

e_message "Setup complete!"