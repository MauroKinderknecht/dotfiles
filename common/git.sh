#!/bin/bash

# Shared Git configuration - works on macOS, Debian, and Fedora

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../_logger.sh"
source "$SCRIPT_DIR/../_utils.sh"

e_message "Installing and configuring Git"

# Install git using platform-specific package manager
pkg_install "git"

# Install GitHub CLI
case "$OS_TYPE" in
  macos)
    brew_install "gh"
    ;;
  debian)
    if ! has_command "gh"; then
      e_pending "Installing GitHub CLI"
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
      sudo apt-get update > /dev/null
      sudo apt-get install -y gh > /dev/null
    fi
    test_command "gh"
    ;;
  fedora)
    if ! has_command "gh"; then
      e_pending "Installing GitHub CLI"
      sudo dnf install -y 'dnf-command(config-manager)' > /dev/null
      sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo > /dev/null
      sudo dnf install -y gh > /dev/null
    fi
    test_command "gh"
    ;;
esac

# Configure git if not already configured
if ! has_command "git" || [ ! -f ~/.gitconfig ]; then
  e_pending "Configuring Git"
  cat > ~/.gitconfig <<'_EOF_'
[user]
  email = mauro.mkinderknecht@gmail.com
  name = Mauro Kinderknecht
  username = MauroKinderknecht
[init]
    defaultBranch = main
[core]
    editor = code -n -w
    autocrlf = input
[rerere]
  enabled = true
[color]
  ui = true
[branch]
  autosetuprebase = always
[push]
  default = upstream
    autoSetupRemote = true
[url "ssh://git@github.com/"]
    insteadOf = https://github.com/
[alias]
  a = add --all
  #############
  b = branch
  ba = branch -a
  bd = branch -d
  bdd = branch -D
  br = branch -r
  #############
  c = commit
  ca = commit -a
  cm = commit -m
  cam = commit -am
  cd = commit --amend
  cad = commit -a --amend
  #############
  cl = clone
  cld = clone --depth 1
  clg = !sh -c 'git clone git://github.com/$1 $(basename $1)' -
  clgp = !sh -c 'git clone git@github.com:$1 $(basename $1)' -
  clgu = !sh -c 'git clone git@github.com:$(git config --get user.username)/$1 $1' -
  #############
  cp = cherry-pick
  cpa = cherry-pick --abort
  cpc = cherry-pick --continue
  #############
  d = diff
  #############
  f = fetch
  fo = fetch origin
  fu = fetch upstream
  #############
  g = grep -p
  #############
  m = merge
  ma = merge --abort
  mc = merge --continue
  ms = merge --skip
  #############
  o = checkout
  om = checkout master
  ob = checkout -b
  opr = !sh -c 'git fo pull/$1/head:pr-$1 && git o pr-$1'
  #############
  pr = prune -v
  #############
  ps = push
  psf = push -f
  psu = push -u
  pst = push --tags
  #############
  pso = push origin
  psao = push --all origin
  psfo = push -f origin
  psuo = push -u origin
  #############
  psom = push origin master
  psaom = push --all origin master
  psfom = push -f origin master
  psuom = push -u origin master
  psoc = !git push origin $(git bc)
  psaoc = !git push --all origin $(git bc)
  psfoc = !git push -f origin $(git bc)
  psuoc = !git push -u origin $(git bc)
  psdc = !git push origin :$(git bc)
  #############
  pl = pull
  pb = pull --rebase
  #############
  plo = pull origin
  pbo = pull --rebase origin
  plom = pull origin master
  ploc = !git pull origin $(git bc)
  pbom = pull --rebase origin master
  pboc = !git pull --rebase origin $(git bc)
  #############
  plu = pull upstream
  plum = pull upstream master
  pluc = !git pull upstream $(git bc)
  pbum = pull --rebase upstream master
  pbuc = !git pull --rebase upstream $(git bc)
  #############
  rb = rebase
  rba = rebase --abort
  rbc = rebase --continue
  rbi = rebase --interactive
  rbs = rebase --skip
  #############
  re = reset
  rh = reset HEAD
  reh = reset --hard
  rem = reset --mixed
  res = reset --soft
  rehh = reset --hard HEAD
  remh = reset --mixed HEAD
  resh = reset --soft HEAD
  rehom = reset --hard origin/master
  #############
  r = remote
  ra = remote add
  rr = remote rm
  rv = remote -v
  rn = remote rename
  rp = remote prune
  rs = remote show
  rao = remote add origin
  rau = remote add upstream
  rro = remote remove origin
  rru = remote remove upstream
  rso = remote show origin
  rsu = remote show upstream
  rpo = remote prune origin
  rpu = remote prune upstream
  #############
  rmf = rm -f
  rmrf = rm -r -f
  #############
  s = status
  sb = status -s -b
  #############
  sa = stash apply
  sc = stash clear
  sd = stash drop
  sl = stash list
  sp = stash pop
  ss = stash save
  ssk = stash save -k
  sw = stash show
  st = !git stash list | wc -l 2>/dev/null | grep -oEi '[0-9][0-9]*'
  #############
  t = tag
  td = tag -d
_EOF_
  e_success "Git configured"
else
  e_success "Git already configured"
fi

# Authenticate with GitHub CLI if not already authenticated
if has_command "gh" && ! gh auth status &>/dev/null; then
  e_info "Please authenticate with GitHub CLI"
  gh auth login
fi
