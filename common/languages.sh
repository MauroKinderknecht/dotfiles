#!/bin/bash

# Shared programming languages setup - works on macOS, Debian, and Fedora

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../_logger.sh"
source "$SCRIPT_DIR/../_utils.sh"

e_message "Installing programming languages"

# =============================================================================
# Python (via pyenv)
# =============================================================================
install_python() {
  e_message "Setting up Python"
  
  # Install pyenv dependencies
  case "$OS_TYPE" in
    macos)
      brew_install "pyenv"
      brew_install "python"
      ;;
    debian)
      apt_install "build-essential"
      apt_install "libssl-dev"
      apt_install "zlib1g-dev"
      apt_install "libbz2-dev"
      apt_install "libreadline-dev"
      apt_install "libsqlite3-dev"
      apt_install "curl"
      apt_install "libncursesw5-dev"
      apt_install "xz-utils"
      apt_install "tk-dev"
      apt_install "libxml2-dev"
      apt_install "libxmlsec1-dev"
      apt_install "libffi-dev"
      apt_install "liblzma-dev"
      ;;
    fedora)
      dnf_install "gcc"
      dnf_install "make"
      dnf_install "zlib-devel"
      dnf_install "bzip2-devel"
      dnf_install "readline-devel"
      dnf_install "sqlite-devel"
      dnf_install "openssl-devel"
      dnf_install "tk-devel"
      dnf_install "libffi-devel"
      dnf_install "xz-devel"
      ;;
  esac

  # Install pyenv if not present
  if ! has_command "pyenv"; then
    e_pending "Installing pyenv"
    curl -fsSL https://pyenv.run | bash > /dev/null 2>&1
    zshrc 'export PYENV_ROOT="$HOME/.pyenv"' "pyenv config"
    zshrc 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"'
    zshrc 'eval "$(pyenv init -)"'
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
  fi
  test_command "pyenv"

  # Install latest Python if not installed
  if ! pyenv versions | grep -q "3."; then
    e_pending "Installing Python via pyenv"
    pyenv install 3 > /dev/null 2>&1
    pyenv global 3
  fi
  e_success "Python installed"

  # Upgrade pip
  pip install --upgrade pip > /dev/null 2>&1
  pip install --user pipenv > /dev/null 2>&1
}

# =============================================================================
# Go
# =============================================================================
install_go() {
  e_message "Setting up Go"
  
  case "$OS_TYPE" in
    macos)
      if ! has_brew "go"; then
        brew_install "go"
        zshrc 'export GOPATH=$HOME/golang' "golang config"
        zshrc 'export GOROOT="$(brew --prefix golang)/libexec"'
        zshrc 'export PATH=$PATH:$GOPATH/bin'
        zshrc 'export PATH=$PATH:$GOROOT/bin'
      else
        e_success "Go installed"
      fi
      brew_install "protobuf"
      brew_install "sqlc"
      ;;
    debian|fedora)
      if ! has_command "go"; then
        e_pending "Installing Go"
        local go_version="1.22.0"
        local arch
        arch=$(uname -m)
        case "$arch" in
          x86_64) arch="amd64" ;;
          aarch64) arch="arm64" ;;
        esac
        curl -fsSL "https://go.dev/dl/go${go_version}.linux-${arch}.tar.gz" -o /tmp/go.tar.gz
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf /tmp/go.tar.gz
        rm /tmp/go.tar.gz
        zshrc 'export PATH=$PATH:/usr/local/go/bin' "golang config"
        zshrc 'export GOPATH=$HOME/golang'
        zshrc 'export PATH=$PATH:$GOPATH/bin'
        export PATH=$PATH:/usr/local/go/bin
      fi
      test_command "go"
      ;;
  esac
}

# =============================================================================
# Node.js (via nvm)
# =============================================================================
install_node() {
  e_message "Setting up Node.js"
  
  if ! has_path ".nvm"; then
    e_pending "Installing nvm"
    mkdir -p ~/.nvm
    
    case "$OS_TYPE" in
      macos)
        brew_install "nvm"
        export NVM_DIR="$HOME/.nvm"
        [ -s "$(brew --prefix nvm)/nvm.sh" ] && source "$(brew --prefix nvm)/nvm.sh"
        ;;
      debian|fedora)
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash > /dev/null 2>&1
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
        ;;
    esac
    
    zshrc 'export NVM_DIR="$HOME/.nvm"' "nvm config"
    zshrc '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
    zshrc '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
    
    # Install latest node
    nvm install node > /dev/null 2>&1
    
    # Add auto-switch for .nvmrc
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
  test_command "nvm"
  
  # Install yarn
  case "$OS_TYPE" in
    macos) brew_install "yarn" ;;
    debian|fedora)
      if ! has_command "yarn"; then
        npm install -g yarn > /dev/null 2>&1
      fi
      test_command "yarn"
      ;;
  esac
}

# =============================================================================
# Java (via SDKMAN)
# =============================================================================
install_java() {
  e_message "Setting up Java"
  
  if ! has_path ".sdkman"; then
    e_pending "Installing SDKMAN"
    curl -s "https://get.sdkman.io" | bash > /dev/null 2>&1
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    zshrc 'export SDKMAN_DIR="$HOME/.sdkman"' "sdkman config"
    zshrc '[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"'
    sdk install java > /dev/null 2>&1
  fi
  e_success "SDKMAN installed"
  
  # Install build tools
  case "$OS_TYPE" in
    macos)
      brew_install "maven"
      brew_install "gradle"
      ;;
    debian)
      apt_install "maven"
      apt_install "gradle"
      ;;
    fedora)
      dnf_install "maven"
      dnf_install "gradle"
      ;;
  esac
}

# =============================================================================
# Kubernetes Tools
# =============================================================================
install_kubernetes_tools() {
  e_message "Setting up Kubernetes tools"
  
  case "$OS_TYPE" in
    macos)
      brew_install "kubectl"
      brew_install "kubectx"
      brew_install "asdf"
      ;;
    debian|fedora)
      if ! has_command "kubectl"; then
        e_pending "Installing kubectl"
        curl -fsSL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o /tmp/kubectl
        sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
        rm /tmp/kubectl
      fi
      test_command "kubectl"
      
      if ! has_command "kubectx"; then
        e_pending "Installing kubectx"
        sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx > /dev/null 2>&1
        sudo ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx
        sudo ln -sf /opt/kubectx/kubens /usr/local/bin/kubens
      fi
      test_command "kubectx"
      ;;
  esac
}

# =============================================================================
# Terraform
# =============================================================================
install_terraform() {
  e_message "Setting up Terraform"
  
  case "$OS_TYPE" in
    macos)
      brew_install "terraform"
      ;;
    debian)
      if ! has_command "terraform"; then
        e_pending "Installing Terraform"
        sudo apt-get install -y gnupg software-properties-common > /dev/null
        curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
        sudo apt-get update > /dev/null
        sudo apt-get install -y terraform > /dev/null
      fi
      test_command "terraform"
      ;;
    fedora)
      if ! has_command "terraform"; then
        e_pending "Installing Terraform"
        sudo dnf install -y dnf-plugins-core > /dev/null
        sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo > /dev/null
        sudo dnf install -y terraform > /dev/null
      fi
      test_command "terraform"
      ;;
  esac
}

# Run all installations
install_python
install_go
install_node
install_java
install_kubernetes_tools
install_terraform
