#!/bin/bash

zshrc() {
    if ! [ -z "$2" ]; then
        echo "" >> ~/.zshrc
        echo "# $2" >> ~/.zshrc
    fi
    echo "$1" >> ~/.zshrc
    source $HOME/.zshrc
}

has_path() {
  local path="$@"
  if [ -e "$HOME/$path" ]; then
    return 0
  fi
  return 1
}

has_command() {
  if [ -x $(command -v $1) ]; then
    return 0
  fi
  return 1
}

has_brew() {
  if $(brew ls --versions $1 &> /dev/null); then
    return 0
  fi
  return 1
}

has_cask() {
  if $(brew ls --cask $1 &> /dev/null); then
    return 0
  fi
  return 1
}

has_app() {
  local name="$@"
  if [ -e "/Applications/$name.app" ]; then
    return 0
  fi
  return 1
}

has_variable() {
  if [ -z "${!1}" ]; then
    return 1
  fi
  return 0
}

test_path() {
  if has_path $1; then
    e_success "$1"
  else
    e_failure "$1"
  fi
}

test_command() {
  if has_command $1; then
    e_success "$1"
  else
    e_failure "$1"
  fi
}

test_brew() {
  if has_brew $1; then
    e_success "$1"
  else
    e_failure "$1"
  fi
}

test_cask() {
  if has_cask $1; then
    e_success "$1"
  else
    e_failure "$1"
  fi
}

test_app() {
  if has_app $1; then
    e_success "$1"
  else
    e_failure "$1"
  fi
}

brew_install() {
  if ! has_brew $1; then
    e_pending "Installing $1"
    brew install $1 > /dev/null
  fi
  test_brew $1
}

brew_cask_install() {
  if ! has_cask $1; then
    e_pending "Installing $1"
    brew install --cask $1 > /dev/null
  fi
  test_cask $1
}
