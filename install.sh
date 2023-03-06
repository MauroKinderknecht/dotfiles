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

source base.sh

e_message "Setup complete!"
