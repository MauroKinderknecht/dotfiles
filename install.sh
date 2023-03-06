#!/bin/bash

source _logger.sh

# Update repo if cloned with git
if $(which git &> /dev/null); then
  if [ -d .git ]; then
    e_pending "Updating dotfiles"
    git pull origin main &> /dev/null
  fi
  e_success "Dotfiles updated"
fi

source base.sh
