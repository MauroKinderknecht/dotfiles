#!/bin/bash

# Shared oh-my-zsh setup with tesseract theme - works on macOS, Debian, and Fedora

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../_logger.sh"
source "$SCRIPT_DIR/../_utils.sh"

e_message "Installing and configuring Zsh & Oh-My-Zsh"

# =============================================================================
# Install Zsh
# =============================================================================
case "$OS_TYPE" in
  macos)
    brew_install "zsh"
    ;;
  debian)
    apt_install "zsh"
    ;;
  fedora)
    dnf_install "zsh"
    ;;
esac

# Set zsh as default shell if not already
if [[ "$SHELL" != *"zsh"* ]]; then
  e_pending "Setting zsh as default shell"
  chsh -s "$(which zsh)"
fi

# =============================================================================
# Install Oh-My-Zsh
# =============================================================================
if ! has_path ".oh-my-zsh"; then
  e_pending "Installing oh-my-zsh"
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

  # Install tesseract theme
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

@tsrct.unstyle-len() {
    local str="${(%)1}"
    local store_var="$2"
    local unstyle_regex="\e\[[0-9;]*[a-zA-Z]"
    local unstyled
    while [[ -n ${str} ]]; do
        if [[ ${str} =~ ${unstyle_regex} ]]; then
            unstyled+=${str[1,MBEGIN-1]}
            str=${str[MEND+1,-1]}
        else
            break
        fi
    done
    unstyled+=${str}
    eval ${store_var}=${#unstyled}
}

@tsrct.rev-parse-find() {
    local target="$1"
    local current_path="${2:-${PWD}}"
    local whether_output=${3:-false}
    local root_regex='^(/)[^/]*$'
    local dirname_regex='^((/[^/]+)+)/[^/]+/?$'
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
        if [[ ${parent_path} =~ ${root_regex} || ${parent_path} =~ ${dirname_regex} ]]; then
            parent_path="${match[1]}"
        else
            return 1
        fi
    done
    return 1
}

typeset -gA tesseract_async_jobs=()
typeset -gA tesseract_async_fds=()
typeset -gA tesseract_async_callbacks=()

@tsrct.async() {
    local job_name=$1
    local handler=$2
    local callback=$3
    if [[ -n ${tesseract_async_jobs[${job_name}]} ]]; then
        return
    fi
    zpty -b ${job_name} @tsrct.zpty-worker ${handler}
    local -i fd=${REPLY}
    tesseract_async_jobs[${job_name}]=${fd}
    tesseract_async_fds[${fd}]=${job_name}
    tesseract_async_callbacks[${job_name}]=${callback}
    zle -F ${fd} @tsrct.zle-callback-handler
}

@tsrct.zpty-worker() {
    local handler=$1
    ${handler}
    echo ''
}

@tsrct.zle-callback-handler() {
    local -i fd=$1
    local data=''
    local job_name=${tesseract_async_fds[${fd}]}
    local callback=${tesseract_async_callbacks[${job_name}]}
    zle -F ${fd}
    zpty -r ${job_name} data
    zpty -d ${job_name}
    unset "tesseract_async_jobs[${job_name}]"
    unset "tesseract_async_fds[${fd}]"
    unset "tesseract_async_callbacks[${job_name}]"
    ${callback} "${(MS)data##[[:graph:]]*[[:graph:]]}"
}

typeset -g tesseract_prompt_part_changed=false

@tsrct.infer-prompt-rerender() {
    local has_changed="$1"
    if [[ ${has_changed} == true ]]; then
        tesseract_prompt_part_changed=true
    fi
    if [[ ${tesseract_prompt_part_changed} == true ]] && (( ! ${(k)#tesseract_async_jobs} )); then
        tesseract_prompt_part_changed=false
        if (( tesseract_prompt_run_count > 1 )); then
            zle reset-prompt
        fi
    fi
}

zle -N @tsrct.infer-prompt-rerender

typeset -g tesseract_rev_git_dir=""
typeset -g tesseract_is_git_dirty=false

@tsrct.chpwd-git-dir-hook() {
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

typeset -gA tesseract_affix_lengths=()

@tsrct.init-affix() {
    local key result
    for key in ${(k)TESSERACT_AFFIXES}; do
        eval "TESSERACT_AFFIXES[${key}]"=\""${TESSERACT_AFFIXES[${key}]}"\"
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
    local str="$1"
    local len=$2
    local store_var="$3"
    local align_site=$(( ${COLUMNS} - ${len} + 1 ))
    local previous_line="\e[1F"
    local next_line="\e[1E"
    local new_line="\n"
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
    local suffix="${(MS)TESSERACT_AFFIXES[current-time.suffix]##*[[:graph:]]}"
    local current_time="${TESSERACT_AFFIXES[current-time.prefix]}${TESSERACT_PALETTE[time]}${(%):-%D{%H:%M:%S\}}${suffix}"
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

@tsrct.prompt-php-version() {
    if @tsrct.rev-parse-find "composer.json"; then
        if @tsrct.iscommand php; then
            local php_prompt_prefix="${TESSERACT_PALETTE[conj.]}using "
            local php_prompt="%F{105}php `\php -r 'echo PHP_MAJOR_VERSION . \".\" . PHP_MINOR_VERSION . \".\" . PHP_RELEASE_VERSION . \"\\n\";'`"
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
    tesseract_parts[dev-env]="${tesseract_previous_parts[dev-env]}"
    tesseract_part_lengths[dev-env]="${tesseract_previous_lengths[dev-env]}"
    @tsrct.async 'dev-env' @tsrct.dev-env-detect @tsrct.set-dev-env-info
}

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
    local ref
    ref="$(\git symbolic-ref HEAD 2> /dev/null)" \
      || ref="$(\git describe --tags --exact-match 2> /dev/null)" \
      || ref="$(\git rev-parse --short HEAD 2> /dev/null)" \
      || return 0
    ref="${ref#refs/heads/}"
    echo "${ref}"
}

@tsrct.set-git-info() {
    local is_dirty="$1"
    local dirty_fd branch_fd action_fd
    if [[ -z ${is_dirty} ]]; then
        exec {dirty_fd}<> <(@tsrct.judge-git-dirty)
    fi
    exec {branch_fd}<> <(@tsrct.git-branch)
    exec {action_fd}<> <(@tsrct.git-action-prompt)
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
    tesseract_is_git_dirty="${is_dirty}"
    @tsrct.set-typing-pointer
    @tsrct.infer-prompt-rerender ${has_changed}
}

@tsrct.sync-git-check() {
    if [[ -z ${tesseract_rev_git_dir} ]]; then return; fi
    @tsrct.set-git-info
}

@tsrct.async-git-check() {
    if [[ -z ${tesseract_rev_git_dir} ]]; then return; fi
    tesseract_parts[git-info]="${tesseract_previous_parts[git-info]}"
    tesseract_part_lengths[git-info]="${tesseract_previous_lengths[git-info]}"
    @tsrct.async 'git-info' @tsrct.judge-git-dirty @tsrct.set-git-info
}

typeset -gi tesseract_exec_timestamp=0
@tsrct.exec-timestamp() {
    tesseract_exec_timestamp=${EPOCHSECONDS}
}
add-zsh-hook preexec @tsrct.exec-timestamp

@tsrct.set-margin-line() {
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
        if (( total_length + part_length + 1 > COLUMNS )) && [[ ${prompt_is_emtpy} == false ]] ; then
            break
        fi
        prompt_is_emtpy=false
        total_length+=${part_length}
        prompts[${key}]="${sgr_reset}${tesseract_parts[${key}]}"
    done
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

  # Restore original zshrc and add oh-my-zsh config
  mv ~/.zshrc.pre-oh-my-zsh ~/.zshrc 2>/dev/null || true
  zshrc 'export ZSH="$HOME/.oh-my-zsh"' "oh-my-zsh config"
  zshrc 'ZSH_THEME="tesseract"'
  
  # Platform-specific plugins
  case "$OS_TYPE" in
    macos)
      zshrc 'plugins=(1password aliases aws asdf brew buf colorize docker docker-compose gcloud gh git git-auto-fetch golang helm iterm2 k9s kind kubectl npm nvm python sdk ssh sudo terraform thefuck yarn)'
      ;;
    debian|fedora)
      zshrc 'plugins=(aliases aws colorize docker docker-compose gcloud gh git git-auto-fetch golang helm k9s kind kubectl npm nvm python sdk ssh sudo terraform yarn)'
      ;;
  esac
  
  zshrc 'source $ZSH/oh-my-zsh.sh'
fi
e_success "Oh-My-Zsh installed"

# =============================================================================
# Install zsh plugins
# =============================================================================
e_message "Installing zsh plugins"

case "$OS_TYPE" in
  macos)
    if ! has_brew "zsh-autosuggestions"; then
      brew_install "zsh-autosuggestions"
      zshrc "source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" "zsh-autosuggestions"
    fi
    brew_install "zsh-completions"
    if ! has_brew "zsh-syntax-highlighting"; then
      brew_install "zsh-syntax-highlighting"
      zshrc "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" "zsh-syntax-highlighting"
    fi
    ;;
  debian|fedora)
    # zsh-autosuggestions
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
      e_pending "Installing zsh-autosuggestions"
      git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" > /dev/null 2>&1
      zshrc "source $ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" "zsh-autosuggestions"
    fi
    e_success "zsh-autosuggestions"
    
    # zsh-syntax-highlighting
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
      e_pending "Installing zsh-syntax-highlighting"
      git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" > /dev/null 2>&1
      zshrc "source $ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" "zsh-syntax-highlighting"
    fi
    e_success "zsh-syntax-highlighting"
    ;;
esac
