#!/bin/bash

color_reset=$(tput sgr0)
color_red=$(tput setaf 1)
color_green=$(tput setaf 2)
color_yellow=$(tput setaf 3)
color_blue=$(tput setaf 4)

e_failure() {
  printf "${color_red}🔴  %s${color_reset}" "$@"
  printf "\n"
}

e_pending() {
  printf "${color_yellow}⏳  %s...${color_reset}" "$@"
  printf "\n"
}

e_success() {
  printf "${color_green}🟢  %s${color_reset}" "$@"
  printf "\n"
}

e_message() {
  printf "\n"
  printf "${color_blue}✨  %s${color_reset}" "$@"
  printf "\n\n"
}

brew_install() {
  if ! has_brew $1; then
    e_pending "Installing $1"
    brew install $1 > /dev/null
    test_brew $1
    if ! [ -z "$2" ]; then
      $2
    fi
  fi
}

brew_cask_install() {
  if ! has_cask $1; then
    e_pending "Installing $1"
    brew install --cask $1 > /dev/null
    test_cask $1
  fi
}

has_command() {
  if [ $(type -P $1) ]; then
    return 0
  fi
  return 1
}

test_command() {
  if has_command $1; then
    e_success "$1"
  else
    e_failure "$1"
  fi
}

has_brew() {
  if $(brew ls --versions $1 > /dev/null); then
    return 0
  fi
  return 1
}

test_brew() {
  if has_brew $1; then
    e_success "$1"
  else
    e_failure "$1"
  fi
}

has_path() {
  local path="$@"
  if [ -e "$HOME/$path" ]; then
    return 0
  fi
  return 1
}

test_path() {
  # local path=$(echo "$@" | sed 's:.*/::')
  if has_path $1; then
    # e_success "$path"
    e_success "$1"
  else
    # e_failure "$path"
    e_failure "$1"
  fi
}

has_cask() {
  if $(brew ls --cask $1 &> /dev/null); then
    return 0
  fi
  return 1
}

test_cask() {
  if has_cask $1; then
    e_success "$1"
  else
    e_failure "$1"
  fi
}

has_app() {
  local name="$@"
  if [ -e "/Applications/$name.app" ]; then
    return 0
  fi
  return 1
}

test_app() {
  if has_app $1; then
    e_success "$1"
  else
    e_failure "$1"
  fi
}

has_arm() {
  if [[ $(uname -p) == 'arm' ]]; then
    return 0
  fi
  return 1
}

has_consent() {
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    return 0
  fi
  return 1
}

get_consent() {
  printf "❔  %s? [y/n]:" "$@"
  read -p " " -n 1
  printf "\n"
}

zprofile() {
  if [ -z "$2" ]; then
    echo "# $2" >> $HOME/.zprofile
  fi
  echo $1 >> $HOME/.zprofile
  echo "" >> $HOME/.zprofile
}

zshrc() {
  if ! [ -z "$2" ]; then
    echo "" >> $HOME/.zshrc
    echo "# $2" >> $HOME/.zshrc
  fi
  echo $1 >> $HOME/.zshrc
}

# ------------------------------------------------------------------------------
e_message "Starting setup"
# ------------------------------------------------------------------------------

if ! [[ "${OSTYPE}" == "darwin"* ]]; then
  e_failure "Unsupported operating system (macOS only)"
  exit 1
fi

get_consent "Autohide Dock"
if has_consent; then
  e_pending "Autohiding Dock"
  defaults write com.apple.dock autohide -boolean true
  killall Dock
fi

get_consent "Display hidden Finder files/folders"
if has_consent; then
  e_pending "Displaying hidden Finder files/folders"
  defaults write com.apple.finder AppleShowAllFiles -boolean true
  killall Finder
fi

if ! has_path "files"; then
  e_pending "Creating ~/files folder"
  mkdir -p ~/files ~/files/sandbox ~/files/projects ~/files/work
  test_path "files"
fi

if ! has_command "xcode-select"; then
  e_pending "Installing xcode-select (CLI tools)"
  xcode-select --install
  test_command "xcode-select"
fi

if ! has_command "brew"; then
  e_pending "Installing brew (Homebrew)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" > /dev/null
  if has_arm; then
    zprofile 'eval "$(/opt/homebrew/bin/brew shellenv)"' "homebrew"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  brew doctor
  brew tap homebrew/cask-fonts
  test_command "brew"
fi

# ------------------------------------------------------------------------------
e_message "Installing fonts"
# ------------------------------------------------------------------------------

brew_cask_install "font-jetbrains-mono"

# ------------------------------------------------------------------------------
e_message "Installing tools"
# ------------------------------------------------------------------------------

# Tools
brew_install "watchman"

brew_install "trash"

if ! has_brew "curl"; then
  brew_install "curl"
  zshrc 'export PATH="/usr/local/opt/curl/bin:$PATH"' "curl config"
fi

if ! has_command "direnv"; then
  brew_install "direnv"
  zshrc 'eval "$(direnv hook zsh)"' "direnv config"
fi

brew_install "thefuck"

# Git
brew_install "git"

brew_install "gh" "gh auth login"

# Install oh-my-zsh
brew_install "zsh"

if has_command "zsh"; then
  if ! has_path ".oh-my-zsh"; then
    e_pending "Installing oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    mv ~/.zshrc.pre-oh-my-zsh ~/.zshrc
    zshrc 'export ZSH="$HOME/.oh-my-zsh"' "oh-my-zsh config"
    zshrc 'ZSH_THEME="tesseract"'
    zshrc 'plugins=(1password aws brew docker docker-compose gcloud gh git golang helm kubectl npm nvm python sdk sudo terraform thefuck)'
    zshrc 'source $ZSH/oh-my-zsh.sh'
    source ~/.zshrc
    test_command "oh-my-zsh"
  fi

  if ! has_brew "zsh-autosuggestions"; then
    brew_install "zsh-autosuggestions"
    zshrc "source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" "zsh-autosuggestions"
  fi

  brew_install "zsh-completions"

  if ! has_brew "zsh-syntax-highlighting"; then
    brew_install "zsh-syntax-highlighting"
    zshrc "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" "zsh-syntax-highlighting"
  fi
fi

# Terminal
brew_cask_install "iterm2"

# Utils
brew_cask_install "1password"
brew_cask_install "maccy"
brew_cask_install "notion"
brew_cask_install "protonvpn"
brew_cask_install "rectangle"

# Communication
brew_cask_install "slack"
brew_cask_install "discord"
brew_cask_install "whatsapp"
brew_cask_install "zoom"

# Music
brew_cask_install "spotify"
brew_cask_install "tidal"

# Browsers
brew_cask_install "google-chrome"
brew_cask_install "firefox"
brew_cask_install "brave-browser"

# IDEs
brew_cask_install "jetbrains-toolbox"
brew_cask_install "visual-studio-code"

# Development
brew_cask_install "docker"
brew_cask_install "figma"
brew_cask_install "linear-linear"
brew_cask_install "mongodb-compass"
brew_cask_install "ngrok"
brew_cask_install "postico"
brew_cask_install "postman"

# Languages

## Golang
if ! has_command "go"; then
  brew_install "go"
  zshrc 'export GOPATH=$HOME/golang' "golang config"
  zshrc 'export GOROOT="$(brew --prefix golang)/libexec"'
  zshrc 'export PATH=$PATH:$GOPATH/bin'
  zshrc 'export PATH=$PATH:$GOROOT/bin'
fi

brew_install "protobuf"

brew_install "sqlc"

## Java
if has_path ".sdkman"; then
  curl -s "https://get.sdkman.io" | bash > /dev/null
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  zshrc 'export SDKMAN_DIR="$HOME/.sdkman"' "sdkman config"
  zshrc '[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"'
  sdk install java > /dev/null
fi

brew_install "maven"

brew_install "gradle"

## Kubernetes
brew_install "kubectx"

brew_install "kubectl"

brew_install "asdf"

## Node
if ! has_path ".nvm"; then
  mkdir -p ~/.nvm
  brew_install "nvm"
  zshrc 'export NVM_DIR="$HOME/.nvm"' "nvm config"
  zshrc 'source $(brew --prefix nvm)/nvm.sh'
  zshrc 'source $(brew --prefix nvm)/bash_completion'
  source $(brew --prefix nvm)/nvm.sh
  nvm install node > /dev/null

  cat >> ~/.zshrc <<'_EOF_'
  # nvmrc config
  autoload -U add-zsh-hook
  load-nvmrc() {
    local node_version="$(nvm version)"
    local nvmrc_path="$(nvm_find_nvmrc)"

    if [ -n "$nvmrc_path" ]; then
      local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

      if [ "$nvmrc_node_version" = "N/A" ]; then
        nvm install
      elif [ "$nvmrc_node_version" != "$node_version" ]; then
        nvm use --silent
      fi
    elif [ "$node_version" != "$(nvm version default)" ]; then
      echo "Reverting to nvm default version"
      nvm use default
    fi
  }
  add-zsh-hook chpwd load-nvmrc
  load-nvmrc
_EOF_

fi

brew_install "yarn"

## Python
if ! has_brew "python"; then
  brew_install "python"
  zshrc 'alias python=/usr/bin/python3' "python config"
  zshrc 'alias pip=/usr/bin/pip3'
  zshrc 'eval "$(pyenv init -)"'
fi

pip install --user pipenv
pip install --upgrade setuptools
pip install --upgrade pip

brew_install "pyenv"

## Terraform
brew_install "terraform"

# ------------------------------------------------------------------------------
e_message "Setup complete"
# ------------------------------------------------------------------------------
