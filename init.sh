#!/bin/bash

# Install homebrew
if ! hash brew
then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew update
else
    brew update
fi

# Install curl
brew install curl

# Install and config git
brew install git
# TODO: Add git config and setup

# Install fonts
brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono

# Install and config zsh
brew install zsh zsh-completions
sudo chmod -R 755 /usr/local/share/zsh
sudo chown -R root:staff /usr/local/share/zsh

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# TODO: Install tesseract.zsh-theme and set it as the theme

# Install iterm2
brew install --cask iterm2
# TODO: Copy iterm2 config

# Productivity
brew install --cask notion
brew install --cask 1password

# Communication
brew install --cask slack
brew install --cask whatsapp
brew install --cask discord

# Music
brew install --cask spotify
brew install --cask tidal

# Browser
brew install --cask brave-browser

# IDEs
brew install --cask jetbrains-toolbox
brew install --cask visual-studio-code

# Development
brew install --cask airtable
brew install --cask docker
brew install --cask figma
brew install --cask linear-linear
brew install --cask mongodb-compass
brew install --cask ngrok
brew install --cask postman
brew install --cask postico

# Utilities
brew install --cask rectangle
brew install --cask maccy
brew install --cask protonvpn
brew install direnv
brew install gh
brew install qmk

# Languages

## Node
# Install nvm
mkdir ~/.nvm
brew install nvm
nvm install node                                                                                     # "node" is an alias for the latest version
brew install yarn

## Java
curl -s "https://get.sdkman.io" | bash                                                               # sdkman is a tool to manage multiple version of java
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java
brew install maven
brew install gradle

## Golang
brew install go
brew install protobuf
brew install sqlc

## Python
brew install python
pip install --user pipenv
pip install --upgrade setuptools
pip install --upgrade pip
brew install pyenv

## Terraform
brew install terraform
terraform -v

# K8S command line
brew install kubectx
brew install asdf
asdf install kubectl latest

# TODO: copy .zshrc

# Create folder structure
mkdir files
cd files
mkdir projects sandbox work