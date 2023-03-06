#!/bin/bash

zshrc() {
    if ! [ -z "$2" ]; then
        echo "" >> ~/.zshrc
        echo "# $2" >> ~/.zshrc
    fi
    echo "$1" >> ~/.zshrc
    zsh &
}