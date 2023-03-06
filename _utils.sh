#!/bin/bash

source _logger.sh

zshrc() {
    if ! [ -z "$2" ]; then
        echo "" >> ~/.zshrc
        echo "# $2" >> ~/.zshrc
    fi
    echo "$1" >> ~/.zshrc
    zsh &
    e_info "Wrote to ~/.zshrc"
}