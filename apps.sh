#!/bin/bash

source _logger.sh
source _utils.sh

e_message "Installing fonts"

# Fonts
brew tap homebrew/cask-fonts &> /dev/null
brew_cask_install "font-jetbrains-mono"

e_message "Installing languages"

# Languages

## Python
brew_install "pyenv"
if ! has_brew "python"; then
  brew_install "python"
  zshrc 'alias python=/usr/bin/python3' "python config"
  zshrc 'alias pip=/usr/bin/pip3'
  zshrc 'eval "$(pyenv init -)"']
else
  e_success "python installed"
fi
pip install --user pipenv &> /dev/null
pip install --upgrade setuptools &> /dev/null
pip install --upgrade pip &> /dev/null

## Golang
if ! has_brew "go"; then
  brew_install "go"
  zshrc 'export GOPATH=$HOME/golang' "golang config"
  zshrc 'export GOROOT="$(brew --prefix golang)/libexec"'
  zshrc 'export PATH=$PATH:$GOPATH/bin'
  zshrc 'export PATH=$PATH:$GOROOT/bin'
else
  e_success "golang installed"
fi
brew_install "protobuf"
brew_install "sqlc"

## Java
if has_path ".sdkman"; then
  curl -s "https://get.sdkman.io" | bash &> /dev/null
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  zshrc 'export SDKMAN_DIR="$HOME/.sdkman"' "sdkman config"
  zshrc '[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"'
  sdk install java &> /dev/null
else
  e_success "sdkman installed"
fi
brew_install "maven"
brew_install "gradle"

## Kubernetes
brew_install "kubectx"
brew_install "kubectl"
brew_install "asdf"

# Node
if ! has_path ".nvm"; then
  mkdir -p ~/.nvm
  brew_install "nvm"
  zshrc 'export NVM_DIR="$HOME/.nvm"' "nvm config"
  zshrc '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
  zshrc '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
  source $(brew --prefix nvm)/nvm.sh
  nvm install node &> /dev/null

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
else
  e_success "nvm installed"
fi
brew_install "yarn"

## Terraform
brew_install "terraform"

e_message "Installing tools"

# Tools
brew_install "watchman"
brew_install "trash"
brew_install "thefuck"

if ! has_command "direnv"; then
  brew_install "direnv"
  zshrc 'eval "$(direnv hook $SHELL)"' "direnv config"
fi

# Git
if ! has_brew "git"; then
  brew_install "git"
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
else
  e_success "git already installed"
fi

if ! has_brew "gh"; then
  brew_install "gh"
  gh auth login
fi

# Install oh-my-zsh
brew_install "zsh"

if has_command "zsh"; then
  if ! has_path ".oh-my-zsh"; then
    e_pending "Installing oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    cat >> ~/.oh-my-zsh/custom/themes/tesseract.zsh-theme << '_EOF_'
    autoload -Uz add-zsh-hook

    zmodload zsh/datetime # To calculate the time elapsed during command execution
    zmodload zsh/zpty # To be able to run commands in a pseudo-terminal
    zmodload zsh/zle # zsh line editor

    setopt prompt_subst # expand and execute the PROMPT variable 

    export VIRTUAL_ENV_DISABLE_PROMPT=true # setup this flag for hidden python `venv` default prompt

    typeset -g sgr_reset="%{\e[00m%}" # reset terminal colors and disable all visual effects

    # theme element symbol mapping
    typeset -gA TESSERACT_SYMBOL=(
        corner.top    '╭─'
        corner.bottom '╰─'

        git.dirty ' ✘'
        git.clean ' ✔'

        arrow '>'
        arrow.git-clean '>'
        arrow.git-dirty '>'
    )

    # theme color pallete mapping
    typeset -gA TESSERACT_PALETTE=(
        # hostname
        host '%F{141}'

        # common user name
        user '%F{44}'

        # only root user
        root '%B%F{203}'

        # current work dir path
        path '%B%F{48}%}'

        # git status info (dirty or clean / rebase / merge / cherry-pick)
        git '%F{57}'

        # virtual env activate prompt for python
        venv '%F{167}'
    
        # current time when prompt render, pin at end-of-line
        time '%F{147}'

        # elapsed time of last command executed
        elapsed '%F{222}'

        # exit code of last command
        exit.mark '%F{246}'
        exit.code '%B%F{203}'

        # 'conj.': short for 'conjunction', like as, at, in, on, using
        conj. '%F{102}'

        # shell typing area pointer
        typing '%F{255}'

        # for other common case text color
        normal '%F{255}'

        success '%F{040}'
        error '%F{203}'
    )

    # theme promp order and priority mapping. 
    # Order dictates order and priority dictates which elements to hide when terminal width is not enough.
    typeset -ga TESSERACT_PROMPT_ORDER=( host user path dev-env git-info )
    typeset -ga TESSERACT_PROMPT_PRIORITY=(
        path
        git-info
        user
        host
        dev-env
    )

    # prefixes and suffixes
    typeset -gA TESSERACT_AFFIXES=(
        host.prefix            '${TESSERACT_PALETTE[normal]}['
        # hostname/username use `Prompt-Expansion` syntax in default
        #   https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
        # but you can override it with simple constant string
        hostname               '${(%):-%m}'
        host.suffix            '${TESSERACT_PALETTE[normal]}] ${TESSERACT_PALETTE[conj.]}as'

        user.prefix            ' '
        username               '${(%):-%n}'
        user.suffix            ' ${TESSERACT_PALETTE[conj.]}in'

        path.prefix            ' '
        path.suffix            ''

        dev-env.prefix         ' '
        dev-env.suffix         ''

        git-info.prefix        ' ${TESSERACT_PALETTE[conj.]}on ${TESSERACT_PALETTE[normal]}'
        git-info.suffix        '${TESSERACT_PALETTE[normal]}'

        venv.prefix            ' ${TESSERACT_PALETTE[normal]}('
        venv.suffix            '${TESSERACT_PALETTE[normal]})'

        exec-elapsed.prefix    ' ${TESSERACT_PALETTE[elapsed]}~'
        exec-elapsed.suffix    ' '

        exit-code.prefix       ' ${TESSERACT_PALETTE[exit.mark]}exit:'
        exit-code.suffix       ' '

        current-time.prefix    ' '
        current-time.suffix    ' '
    )

    @tsrct.iscommand() { [[ -e ${commands[$1]} ]] }

    # https://superuser.com/questions/380772/removing-ansi-color-codes-from-text-stream
    # https://www.refining-linux.org/archives/52-ZSH-Gem-18-Regexp-search-and-replace-on-parameters.html
    @tsrct.unstyle-len() {
        # use (%) for expand `prompt` format like color `%F{123}` or username `%n`
        # https://zsh.sourceforge.io/Doc/Release/Expansion.html#Parameter-Expansion-Flags
        # https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html#Prompt-Expansion
        local str="${(%)1}"
        local store_var="$2"

        ## regexp with POSIX mode
        ## compatible with macOS Catalina default zsh
        #
        ## !!! NOTE: note that the "empty space" in this regexp at the beginning is not a common "space",
        ## it is the ANSI escape ESC char ("\e") which is cannot wirte as literal in there
        local unstyle_regex="\[[0-9;]*[a-zA-Z]"

        # inspired by zsh builtin regexp-replace
        # https://github.com/zsh-users/zsh/blob/zsh-5.8/Functions/Misc/regexp-replace
        # it same as next line
        # regexp-replace str "${unstyle_regex}" ''

        local unstyled
        # `MBEGIN` `MEND` are zsh builtin variables
        # https://zsh.sourceforge.io/Doc/Release/Expansion.html

        while [[ -n ${str} ]]; do
            if [[ ${str} =~ ${unstyle_regex} ]]; then
                # append initial part and subsituted match
                unstyled+=${str[1,MBEGIN-1]}
                # truncate remaining string
                str=${str[MEND+1,-1]}
            else
                break
            fi
        done
        unstyled+=${str}

        eval ${store_var}=${#unstyled}
    }


    # @tsrct.rev-parse-find(filename:string, path:string, output:boolean)
    # reverse from path to root wanna find the targe file
    # output: whether show the file path
    @tsrct.rev-parse-find() {
        local target="$1"
        local current_path="${2:-${PWD}}"
        local whether_output=${3:-false}

        local root_regex='^(/)[^/]*$'
        local dirname_regex='^((/[^/]+)+)/[^/]+/?$'

        # [hacking] it's same as  parent_path=`\dirname ${current_path}`,
        # but better performance due to reduce subprocess call
        # `match` is zsh builtin variable
        # https://zsh.sourceforge.io/Doc/Release/Expansion.html
        if [[ ${current_path} =~ ${root_regex} || ${current_path} =~ ${dirname_regex} ]]; then
            local parent_path="${match[1]}"
        else
            return 1
        fi

        while [[ ${parent_path} != "/" && ${current_path} != "${HOME}" ]]; do
            if [[ -e ${current_path}/${target} ]]; then
                if ${whether_output}; then
                    echo "${current_path}";
                fi
                return 0
            fi
            current_path="${parent_path}"

            # [hacking] it's same as  parent_path=`\dirname ${parent_path}`,
            # but better performance due to reduce subprocess call
            if [[ ${parent_path} =~ ${root_regex} || ${parent_path} =~ ${dirname_regex} ]]; then
                parent_path="${match[1]}"
            else
                return 1
            fi
        done
        return 1
    }


    # map for { job-name -> file-descriptor }
    typeset -gA tesseract_async_jobs=()
    # map for { file-descriptor -> job-name }
    typeset -gA tesseract_async_fds=()
    # map for { job-name -> callback }
    typeset -gA tesseract_async_callbacks=()

    # tiny util for run async job with callback via zpty and zle
    # inspired by https://github.com/mafredri/zsh-async
    #
    # @tsrct.async <job-name> <handler-func> <callback-func>
    #
    # `handler-func`  cannot handle with not any param
    # `callback-func` can only receive one param: <output-data>
    # 
    # https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html
    @tsrct.async() {
        local job_name=$1
        local handler=$2
        local callback=$3

        # if job is running, donot run again
        # by believe all zpty job will clear itself by trigger in callback
        # it's an alternative to`zpty -t ${job_name}`
        # because zpty test job done not means the job cleared, they cannot create again
        if [[ -n ${tesseract_async_jobs[${job_name}]} ]]; then
            return
        fi

        # async run as non-blocking output subprocess in zpty
        zpty -b ${job_name} @tsrct.zpty-worker ${handler}
        # REPLY a file-descriptor which was opened by the lost zpty job 
        local -i fd=${REPLY}

        tesseract_async_jobs[${job_name}]=${fd}
        tesseract_async_fds[${fd}]=${job_name}
        tesseract_async_callbacks[${job_name}]=${callback}

        zle -F ${fd} @tsrct.zle-callback-handler
    }

    @tsrct.zpty-worker() {
        local handler=$1

        ${handler}

        # always print new line to avoid handler has not any output that cannot trigger callback
        echo ''
    }

    # callback for zle, forward zpty output to really job callback
    @tsrct.zle-callback-handler() {
        local -i fd=$1
        local data=''

        local job_name=${tesseract_async_fds[${fd}]}
        local callback=${tesseract_async_callbacks[${job_name}]}

        # assume the job only have one-line output
        # so if the handler called, we can read all message at this time,
        # then we can remove callback and kill subprocess safety
        zle -F ${fd}
        zpty -r ${job_name} data
        zpty -d ${job_name}

        unset "tesseract_async_jobs[${job_name}]"
        unset "tesseract_async_fds[${fd}]"
        unset "tesseract_async_callbacks[${job_name}]"

        # forward callback, and trimming any leading/trailing whitespace same as command s  ubstitution
        # `[[:graph:]]` is glob for whitespace
        # https://zsh.sourceforge.io/Doc/Release/Expansion.html#Glob-Operators
        # https://stackoverflow.com/questions/68259691/trimming-whitespace-from-the-ends-of-a-string-in-zsh/68288735#68288735
        ${callback} "${(MS)data##[[:graph:]]*[[:graph:]]}"
    }


    typeset -g tesseract_prompt_part_changed=false

    @tsrct.infer-prompt-rerender() {
        local has_changed="$1"

        if [[ ${has_changed} == true ]]; then
            tesseract_prompt_part_changed=true
        fi

        # only rerender if changed and all async jobs done
        if [[ ${tesseract_prompt_part_changed} == true ]] && (( ! ${(k)#tesseract_async_jobs} )); then
            tesseract_prompt_part_changed=false

            # only call zle rerender while prompt prepared
            if (( tesseract_prompt_run_count > 1 )); then
                zle reset-prompt
            fi
        fi
    }

    zle -N @tsrct.infer-prompt-rerender



    # variables for git prompt
    typeset -g tesseract_rev_git_dir=""
    typeset -g tesseract_is_git_dirty=false

    @tsrct.chpwd-git-dir-hook() {
        # it's the same as  tesseract_rev_git_dir=`\git rev-parse --git-dir 2>/dev/null`
        # but better performance due to reduce subprocess call

        local project_root_dir="$(@tsrct.rev-parse-find .git '' true)"

        if [[ -n ${project_root_dir} ]]; then
            tesseract_rev_git_dir="${project_root_dir}/.git"
        else
            tesseract_rev_git_dir=""
        fi
    }

    add-zsh-hook chpwd @tsrct.chpwd-git-dir-hook
    @tsrct.chpwd-git-dir-hook


    typeset -gi tesseract_prompt_run_count=0

    # tesseract prompt element value
    typeset -gA tesseract_parts=() tesseract_part_lengths=()
    typeset -gA tesseract_previous_parts=() tesseract_previous_lengths=()

    @tsrct.reset-prompt-parts() {
        for key in ${(k)tesseract_parts}; do
            tesseract_previous_parts[${key}]="${tesseract_parts[${key}]}"
            tesseract_previous_lengths[${key}]="${tesseract_part_lengths[${key}]}"
        done

        tesseract_parts=(
            exec-elapsed    ''
            exit-code       ''
            margin-line     ''
            host            ''
            user            ''
            path            ''
            dev-env         ''
            git-info        ''
            current-time    ''
            typing          ''
            venv            ''
        )

        tesseract_part_lengths=(
            host            0
            user            0
            path            0
            dev-env         0
            git-info        0
            current-time    0
        )
    }

    # store calculated lengths of `TESSERACT_AFFIXES` part
    typeset -gA tesseract_affix_lengths=()

    @tsrct.init-affix() {
        local key result
        for key in ${(k)TESSERACT_AFFIXES}; do
            eval "TESSERACT_AFFIXES[${key}]"=\""${TESSERACT_AFFIXES[${key}]}"\"
            # remove `.prefix`, `.suffix`
            # `xxx.prefix`` -> `xxx`
            local part="${key/%.(prefix|suffix)/}"

            local -i affix_len
            @tsrct.unstyle-len "${TESSERACT_AFFIXES[${key}]}" affix_len

            tesseract_affix_lengths[${part}]=$((
                ${tesseract_affix_lengths[${part}]:-0}
                + affix_len
            ))
        done
    }

    @tsrct.set-typing-pointer() {
        tesseract_parts[typing]="${TESSERACT_PALETTE[typing]}"

        if [[ -n ${tesseract_rev_git_dir} ]]; then
            if [[ ${tesseract_is_git_dirty} == false ]]; then
                tesseract_parts[typing]+="${TESSERACT_SYMBOL[arrow.git-clean]}"
            else
                tesseract_parts[typing]+="${TESSERACT_SYMBOL[arrow.git-dirty]}"
            fi
        else
            tesseract_parts[typing]+="${TESSERACT_SYMBOL[arrow]}"
        fi
    }

    @tsrct.set-venv-info() {
        if [[ -z ${VIRTUAL_ENV} ]]; then
            tesseract_parts[venv]=''
        else
            tesseract_parts[venv]="${TESSERACT_AFFIXES[venv.prefix]}${TESSERACT_PALETTE[venv]}$(basename ${VIRTUAL_ENV})${TESSERACT_AFFIXES[venv.suffix]}"
        fi
    }

    # https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
    @tsrct.set-host-name() {
        tesseract_parts[host]="${TESSERACT_AFFIXES[hostname]}"
        tesseract_part_lengths[host]=$((
            ${#tesseract_parts[host]}
            + ${tesseract_affix_lengths[host]}
        ))

        tesseract_parts[host]="${TESSERACT_AFFIXES[host.prefix]}${TESSERACT_PALETTE[host]}${tesseract_parts[host]}${TESSERACT_AFFIXES[host.suffix]}"
    }

    @tsrct.set-user-name() {
        tesseract_parts[user]="${TESSERACT_AFFIXES[username]}"

        tesseract_part_lengths[user]=$((
            ${#tesseract_parts[user]}
            + ${tesseract_affix_lengths[user]}
        ))

        local name_color="${TESSERACT_PALETTE[user]}"
        if [[ ${UID} == 0 || ${USER} == 'root' ]]; then
            name_color="${TESSERACT_PALETTE[root]}"
        fi

        tesseract_parts[user]="${TESSERACT_AFFIXES[user.prefix]}${name_color}${tesseract_parts[user]}${TESSERACT_AFFIXES[user.suffix]}"
    }

    @tsrct.set-current-dir() {
        tesseract_parts[path]="${(%):-%~}"

        tesseract_part_lengths[path]=$((
            ${#tesseract_parts[path]}
            + ${tesseract_affix_lengths[path]}
        ))

        tesseract_parts[path]="${TESSERACT_AFFIXES[path.prefix]}${TESSERACT_PALETTE[path]}${tesseract_parts[path]}${TESSERACT_AFFIXES[path.suffix]}"
    }


    @tsrct.align-previous-right() {
        # References:
        #
        # CSI ref: https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_sequences
        # http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html
        # https://en.wikipedia.org/wiki/ANSI_escape_code#Terminal_output_sequences
        # https://donsnotes.com/tech/charsets/ascii.html
        #
        # Cursor Up        <ESC>[{COUNT}A
        # Cursor Down      <ESC>[{COUNT}B
        # Cursor Right     <ESC>[{COUNT}C
        # Cursor Left      <ESC>[{COUNT}D
        # Cursor Horizontal Absolute      <ESC>[{COUNT}G

        local str="$1"
        local len=$2
        local store_var="$3"

        local align_site=$(( ${COLUMNS} - ${len} + 1 ))
        local previous_line="\e[1F"
        local next_line="\e[1E"
        local new_line="\n"
        # use `%{ %}` wrapper to aviod ANSI cause eat previous line after prompt rerender (zle reset-prompt)
        local cursor_col="%{\e[${align_site}G%}"
        local result="${previous_line}${cursor_col}${str}"

        eval ${store_var}=${(q)result}
    }

    @tsrct.align-right() {
        local str="$1"
        local len=$2
        local store_var="$3"

        local align_site=$(( ${COLUMNS} - ${len} + 1 ))
        local cursor_col="%{\e[${align_site}G%}"
        local result="${cursor_col}${str}"

        eval ${store_var}=${(q)result}
    }


    # pin the last command execute elapsed and exit code at previous line end
    @tsrct.pin-execute-info() {
        local -i exec_seconds="${1:-0}"
        local -i exit_code="${2:-0}"

        local -i pin_length=0

        if (( TESSERACT_EXEC_THRESHOLD_SECONDS >= 0)) && (( exec_seconds >= TESSERACT_EXEC_THRESHOLD_SECONDS )); then
            local -i seconds=$(( exec_seconds % 60 ))
            local -i minutes=$(( exec_seconds / 60 % 60 ))
            local -i hours=$(( exec_seconds / 3600 ))

            local -a humanize=()

            (( hours > 0 )) && humanize+="${hours}h"
            (( minutes > 0 )) && humanize+="${minutes}m"
            (( seconds > 0 )) && humanize+="${seconds}s"

            # join array with 1 space
            local elapsed="${(j.:.)humanize}"

            tesseract_parts[exec-elapsed]="${sgr_reset}${TESSERACT_AFFIXES[exec-elapsed.prefix]}${TESSERACT_PALETTE[elapsed]}${elapsed}${TESSERACT_AFFIXES[exec-elapsed.suffix]}"
            pin_length+=$(( ${tesseract_affix_lengths[exec-elapsed]} + ${#elapsed} ))
        fi

        if (( exit_code != 0 )); then
            tesseract_parts[exit-code]="${sgr_reset}${TESSERACT_AFFIXES[exit-code.prefix]}${TESSERACT_PALETTE[exit.code]}${exit_code}${TESSERACT_AFFIXES[exit-code.suffix]}"
            pin_length+=$(( ${tesseract_affix_lengths[exit-code]} + ${#exit_code} ))
        fi
        
        if (( pin_length > 0 )); then
            local pin_message="${tesseract_parts[exec-elapsed]}${tesseract_parts[exit-code]}"
            @tsrct.align-previous-right "${pin_message}" ${pin_length} pin_message
            print -P "${pin_message}"
        fi
    }


    @tsrct.set-date-time() {
        # trimming suffix trailing whitespace
        # donot print trailing whitespace for better interaction while terminal width in narrowing
        local suffix="${(MS)TESSERACT_AFFIXES[current-time.suffix]##*[[:graph:]]}"
        local current_time="${TESSERACT_AFFIXES[current-time.prefix]}${TESSERACT_PALETTE[time]}${(%):-%D{%H:%M:%S\}}${suffix}"
        # 8 is fixed lenght of datatime format `hh:mm:ss`
        tesseract_part_lengths[current-time]=$(( 8 + ${tesseract_affix_lengths[current-time]} ))
        @tsrct.align-right "${current_time}" ${tesseract_part_lengths[current-time]} 'tesseract_parts[current-time]'
    }



    @tsrct.prompt-node-version() {
        if @tsrct.rev-parse-find "package.json"; then
            if @tsrct.iscommand node; then
                local node_prompt_prefix="${TESSERACT_PALETTE[conj.]}using "
                local node_prompt="%F{120}node `\node -v`"
            else
                local node_prompt_prefix="${TESSERACT_PALETTE[normal]}[${TESSERACT_PALETTE[error]}need "
                local node_prompt="Nodejs${TESSERACT_PALETTE[normal]}]"
            fi
            echo "${node_prompt_prefix}${node_prompt}"
        fi
    }

    @tsrct.prompt-golang-version() {
        if @tsrct.rev-parse-find "go.mod"; then
            if @tsrct.iscommand go; then
                local go_prompt_prefix="${TESSERACT_PALETTE[conj.]}using "
                # go version go1.7.4 linux/amd64
                local go_version=`go version`
                if [[ ${go_version} =~ ' go([0-9]+\.[0-9]+\.[0-9]+) ' ]]; then
                    go_version="${match[1]}"
                else
                    return 1
                fi
                local go_prompt="%F{086}Golang ${go_version}"
            else
                local go_prompt_prefix="${TESSERACT_PALETTE[normal]}[${TESSERACT_PALETTE[error]}need "
                local go_prompt="Golang${TESSERACT_PALETTE[normal]}]"
            fi
            echo "${go_prompt_prefix}${go_prompt}"
        fi
    }

    # http://php.net/manual/en/reserved.constants.php
    @tsrct.prompt-php-version() {
        if @tsrct.rev-parse-find "composer.json"; then
            if @tsrct.iscommand php; then
                local php_prompt_prefix="${TESSERACT_PALETTE[conj.]}using "
                local php_prompt="%F{105}php `\php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION . "." . PHP_RELEASE_VERSION . "\n";'`"
            else
                local php_prompt_prefix="${TESSERACT_PALETTE[normal]}[${TESSERACT_PALETTE[error]}need "
                local php_prompt="php${TESSERACT_PALETTE[normal]}]"
            fi
            echo "${php_prompt_prefix}${php_prompt}"
        fi
    }

    @tsrct.prompt-python-version() {
        local python_prompt_prefix="${TESSERACT_PALETTE[conj.]}using "

        if [[ -n ${VIRTUAL_ENV} ]] && @tsrct.rev-parse-find "venv"; then
            local python_prompt="%F{123}`$(@tsrct.rev-parse-find venv '' true)/venv/bin/python --version 2>&1`"
            echo "${python_prompt_prefix}${python_prompt}"
            return 0
        fi

        if @tsrct.rev-parse-find "requirements.txt"; then
            if @tsrct.iscommand python; then
                local python_prompt="%F{123}`\python --version 2>&1`"
            else
                python_prompt_prefix="${TESSERACT_PALETTE[normal]}[${TESSERACT_PALETTE[error]}need "
                local python_prompt="Python${TESSERACT_PALETTE[normal]}]"
            fi
            echo "${python_prompt_prefix}${python_prompt}"
        fi
    }

    typeset -ga TESSERACT_DEV_ENV_DETECT_FUNCS=(
        @tsrct.prompt-node-version
        @tsrct.prompt-golang-version
        @tsrct.prompt-python-version
        @tsrct.prompt-php-version
    )

    @tsrct.dev-env-detect() {
        for segment_func in ${TESSERACT_DEV_ENV_DETECT_FUNCS[@]}; do
            local segment=`${segment_func}`
            if [[ -n ${segment} ]]; then 
                echo "${segment}"
                break
            fi
        done
    }

    @tsrct.set-dev-env-info() {
        local result="$1"
        local has_changed=false

        if [[ -z ${result} ]]; then
            if [[ -n ${tesseract_previous_parts[dev-env]} ]]; then
                tesseract_parts[dev-env]=''
                tesseract_part_lengths[dev-env]=0
                has_changed=true
            fi

            @tsrct.infer-prompt-rerender ${has_changed}
            return
        fi

        tesseract_parts[dev-env]="${TESSERACT_AFFIXES[dev-env.prefix]}${result}${TESSERACT_AFFIXES[dev-env.suffix]}"

        local -i result_len
        @tsrct.unstyle-len "${result}" result_len

        tesseract_part_lengths[dev-env]=$((
            result_len
            + ${tesseract_affix_lengths[dev-env]}
        ))

        if [[ ${tesseract_parts[dev-env]} != ${tesseract_previous_parts[dev-env]} ]]; then
            has_changed=true
        fi

        @tsrct.infer-prompt-rerender ${has_changed}
    }


    @tsrct.sync-dev-env-detect() {
        local -i output_fd=$1

        local dev_env="$(<& ${output_fd})"
        exec {output_fd}>& -

        @tsrct.set-dev-env-info "${dev_env}"
    }

    @tsrct.async-dev-env-detect() {
        # use cached prompt part for render, and try to update as async

        tesseract_parts[dev-env]="${tesseract_previous_parts[dev-env]}"
        tesseract_part_lengths[dev-env]="${tesseract_previous_lengths[dev-env]}"

        @tsrct.async 'dev-env' @tsrct.dev-env-detect @tsrct.set-dev-env-info
    }

    # return `true` for dirty
    # return `false` for clean
    @tsrct.judge-git-dirty() {
        local git_status
        local -a flags
        flags=('--porcelain' '--ignore-submodules')
        if [[ ${DISABLE_UNTRACKED_FILES_DIRTY} == true ]]; then
            flags+='--untracked-files=no'
        fi
        git_status="$(\git status ${flags} 2> /dev/null)"
        if [[ -n ${git_status} ]]; then
            echo true
        else
            echo false
        fi
    }

    @tsrct.git-action-prompt() {
        # always depend on ${tesseract_rev_git_dir} path is existed

        local action=''
        local rebase_process=''
        local rebase_merge="${tesseract_rev_git_dir}/rebase-merge"
        local rebase_apply="${tesseract_rev_git_dir}/rebase-apply"

        if [[ -d ${rebase_merge} ]]; then
            if [[ -f ${rebase_merge}/interactive ]]; then
                action="REBASE-i"
            else
                action="REBASE-m"
            fi

            # while edit rebase interactive message,
            # `msgnum` `end` are not exist yet
            if [[ -f ${rebase_merge}/msgnum ]]; then
                local rebase_step="$(< ${rebase_merge}/msgnum)"
                local rebase_total="$(< ${rebase_merge}/end)"
                rebase_process="${rebase_step}/${rebase_total}"
            fi
        elif [[ -d ${rebase_apply} ]]; then
            if [[ -f ${rebase_apply}/rebasing ]]; then
                action="REBASE"
            elif [[ -f ${rebase_apply}/applying ]]; then
                action="AM"
            else
                action="AM/REBASE"
            fi

            local rebase_step="$(< ${rebase_merge}/next)"
            local rebase_total="$(< ${rebase_merge}/last)"
            rebase_process="${rebase_step}/${rebase_total}"
        elif [[ -f ${tesseract_rev_git_dir}/MERGE_HEAD ]]; then
            action="MERGING"
        elif [[ -f ${tesseract_rev_git_dir}/CHERRY_PICK_HEAD ]]; then
            action="CHERRY-PICKING"
        elif [[ -f ${tesseract_rev_git_dir}/REVERT_HEAD ]]; then
            action="REVERTING"
        elif [[ -f ${tesseract_rev_git_dir}/BISECT_LOG ]]; then
            action="BISECTING"
        fi

        if [[ -n ${rebase_process} ]]; then
            action="${action} ${rebase_process}"
        fi
        if [[ -n ${action} ]]; then
            action="|${action}"
        fi

        echo "${action}"
    }

    @tsrct.git-branch() {
        # always depend on ${tesseract_rev_git_dir} path is existed

        local ref
        ref="$(\git symbolic-ref HEAD 2> /dev/null)" \
          || ref="$(\git describe --tags --exact-match 2> /dev/null)" \
          || ref="$(\git rev-parse --short HEAD 2> /dev/null)" \
          || return 0
        ref="${ref#refs/heads/}"

        echo "${ref}"
    }


    # use `exec` to parallel run commands and capture stdout into file descriptor
    #   @tsrct.set-git-info [true|false]
    # first param is whether git is dirty or not (`true` or `false`), 
    # if first param is not set, will try to read by exec
    @tsrct.set-git-info() {
        local is_dirty="$1"

        local dirty_fd branch_fd action_fd

        if [[ -z ${is_dirty} ]]; then
            exec {dirty_fd}<> <(@tsrct.judge-git-dirty)
        fi

        exec {branch_fd}<> <(@tsrct.git-branch)
        exec {action_fd}<> <(@tsrct.git-action-prompt)

        # read and close file descriptors
        local git_branch="$(<& ${branch_fd})"
        local git_action="$(<& ${action_fd})"
        exec {branch_fd}>& -
        exec {action_fd}>& -

        if [[ -n ${dirty_fd} ]]; then
            is_dirty="$(<& ${dirty_fd})"
            exec {dirty_fd}>& -
        fi

        local git_state='' state_color='' git_dirty_status=''
    
        if [[ ${is_dirty} == true ]]; then
            git_state='dirty'
            state_color='error'
        else
            git_state='clean'
            state_color='success'
        fi

        git_dirty_status="${TESSERACT_PALETTE[${state_color}]}${TESSERACT_SYMBOL[git.${git_state}]}"

        tesseract_parts[git-info]="${TESSERACT_AFFIXES[git-info.prefix]}${TESSERACT_PALETTE[git]}${git_branch}${git_action}${TESSERACT_AFFIXES[git-info.suffix]}${git_dirty_status}"

        tesseract_part_lengths[git-info]=$((
            ${#TESSERACT_SYMBOL[git.${git_state}]}
            + ${tesseract_affix_lengths[git-info]}
            + ${#git_branch}
            + ${#git_action}
        ))

        local has_changed=false

        if [[ ${tesseract_parts[git-info]} != ${tesseract_previous_parts[git-info]} ]]; then
            has_changed=true
        fi

        # `tesseract_is_git_dirty` is global variable that `true` or `false`
        tesseract_is_git_dirty="${is_dirty}"

        # set typing-pointer due to git_dirty state maybe changed
        @tsrct.set-typing-pointer

        @tsrct.infer-prompt-rerender ${has_changed}
    }


    @tsrct.sync-git-check() {
        if [[ -z ${tesseract_rev_git_dir} ]]; then return; fi

        @tsrct.set-git-info
    }

    @tsrct.async-git-check() {
        if [[ -z ${tesseract_rev_git_dir} ]]; then return; fi

        # use cached prompt part for render, and try to update as async

        tesseract_parts[git-info]="${tesseract_previous_parts[git-info]}"
        tesseract_part_lengths[git-info]="${tesseract_previous_lengths[git-info]}"

        @tsrct.async 'git-info' @tsrct.judge-git-dirty @tsrct.set-git-info
    }

    # `EPOCHSECONDS` is setup in zsh/datetime module
    # https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fdatetime-Module
    typeset -gi tesseract_exec_timestamp=0
    @tsrct.exec-timestamp() {
        tesseract_exec_timestamp=${EPOCHSECONDS}
    }
    add-zsh-hook preexec @tsrct.exec-timestamp

    @tsrct.set-margin-line() {
        # donot print empty line if terminal height less than 12 lines when prompt initial load
        if (( tesseract_prompt_run_count == 1 )) && (( LINES <= 12 )); then
            return
        fi

        tesseract_parts[margin-line]='\n'
    }

    @tsrct.prompt-prepare() {
        local -i exit_code=$?
        local -i exec_seconds=0

        if (( tesseract_exec_timestamp > 0 )); then
            exec_seconds=$(( EPOCHSECONDS - tesseract_exec_timestamp ))
            tesseract_exec_timestamp=0
        fi

        tesseract_prompt_run_count+=1

        @tsrct.reset-prompt-parts

        if (( tesseract_prompt_run_count == 1 )); then
            @tsrct.init-affix
            
            local -i dev_env_fd
            exec {dev_env_fd}<> <(@tsrct.dev-env-detect)
            @tsrct.sync-git-check
            @tsrct.sync-dev-env-detect ${dev_env_fd}
        else
            @tsrct.async-dev-env-detect
            @tsrct.async-git-check
        fi

        @tsrct.pin-execute-info ${exec_seconds} ${exit_code}
        @tsrct.set-margin-line
        @tsrct.set-host-name
        @tsrct.set-user-name
        @tsrct.set-current-dir
        @tsrct.set-typing-pointer
        @tsrct.set-venv-info
    }

    add-zsh-hook precmd @tsrct.prompt-prepare



    @tesseract-prompt() {
        local -i total_length=${#TESSERACT_SYMBOL[corner.top]}
        local -A prompts=(
            margin-line ''
            host ''
            user ''
            path ''
            dev-env ''
            git-info ''
            current-time ''
            typing ''
            venv ''
        )

        local prompt_is_emtpy=true
        local key

        for key in ${TESSERACT_PROMPT_PRIORITY[@]}; do
            local -i part_length=${tesseract_part_lengths[${key}]}

            # keep padding right 1 space
            if (( total_length + part_length + 1 > COLUMNS )) && [[ ${prompt_is_emtpy} == false ]] ; then
                break
            fi
            
            prompt_is_emtpy=false

            total_length+=${part_length}
            prompts[${key}]="${sgr_reset}${tesseract_parts[${key}]}"
        done

        # always auto detect rest spaces to float current time
        @tsrct.set-date-time
        if (( total_length + ${tesseract_part_lengths[current-time]} <= COLUMNS )); then
            prompts[current-time]="${sgr_reset}${tesseract_parts[current-time]}"
        fi

        prompts[margin-line]="${sgr_reset}${tesseract_parts[margin-line]}"
        prompts[typing]="${sgr_reset}${tesseract_parts[typing]}"
        prompts[venv]="${sgr_reset}${tesseract_parts[venv]}"

        local -a ordered_parts=()
        for key in ${TESSERACT_PROMPT_ORDER[@]}; do
            ordered_parts+="${prompts[${key}]}"
        done

        local corner_top="${prompts[margin-line]}${TESSERACT_PALETTE[normal]}${TESSERACT_SYMBOL[corner.top]}"
        local corner_bottom="${sgr_reset}${TESSERACT_PALETTE[normal]}${TESSERACT_SYMBOL[corner.bottom]}"

        echo "${corner_top}${(j..)ordered_parts}${prompts[current-time]}"
        echo "${corner_bottom}${prompts[typing]}${prompts[venv]} ${sgr_reset}"
    }


    PROMPT='$(@tesseract-prompt)'
_EOF_
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

e_message "Installing apps"

# Terminal
brew_cask_install "iterm2"

# Utils
brew_cask_install "1password"
brew_cask_install "maccy"
brew_cask_install "notion"
brew_cask_install "protonvpn"
brew_cask_install "logitech-options"

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
brew_cask_install "neovim"

# Development
brew_cask_install "docker"
brew_cask_install "figma"
brew_cask_install "linear-linear"
brew_cask_install "mongodb-compass"
brew_cask_install "ngrok"
brew_cask_install "postico"
brew_cask_install "postman"