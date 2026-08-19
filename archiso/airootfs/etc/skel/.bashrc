# ═══════════════════════════════════════════════════════════════════
# Arch Custom — .bashrc
# Fast shell startup, clean prompt, minimal overhead.
# ═══════════════════════════════════════════════════════════════════

# ── Shell Options ─────────────────────────────────────────────────
shopt -s checkwinsize
shopt -s globstar
shopt -s autocd
shopt -s cdspell
shopt -s dirspell
shopt -s extglob
shopt -s histappend
shopt -s cmdhist

# ── History ───────────────────────────────────────────────────────
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T  '
# Avoid storing duplicate commands
PROMPT_COMMAND="history -a"

# ── Prompt ────────────────────────────────────────────────────────
# Ultra-fast prompt — no external commands on every line
__arch_prompt() {
    local exit_code=$?
    local reset='\[\033[0m\]'
    local bold='\[\033[1m\]'
    local red='\[\033[0;31m\]'
    local green='\[\033[0;32m\]'
    local yellow='\[\033[1;33m\]'
    local blue='\[\033[0;34m\]'
    local cyan='\[\033[0;36m\]'
    local magenta='\[\033[0;35m\]'
    local dim='\[\033[2m\]'

    # Exit code indicator
    local status_color="$green"
    local status_icon="→"
    if [[ $exit_code -ne 0 ]]; then
        status_color="$red"
        status_icon="✗"
    fi

    # Git branch (cheap — only reads .git/HEAD)
    local git_branch=""
    if [[ -d .git ]] || git rev-parse --git-dir &>/dev/null 2>&1; then
        git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "")
    fi

    # Build prompt
    local PS1=""

    # Top line: box drawing
    PS1+="${cyan}┌─${reset}"
    PS1+="${bold}${magenta}\u${reset}"
    PS1+="${cyan}@${reset}"
    PS1+="${bold}\h${reset}"

    # Git branch
    if [[ -n "$git_branch" ]]; then
        PS1+="${cyan} (${yellow}${git_branch}${cyan})${reset}"
    fi

    PS1+="${cyan} ─${reset}"

    # Fill remaining width with dashes
    PS1+="${dim}───${reset}"

    PS1+="${cyan}┐${reset}\n"

    # Bottom line: directory + arrow
    PS1+="${cyan}└─${reset}"
    PS1+="${bold}${blue}\w${reset}"
    PS1+="${cyan} ─${reset}"
    PS1+="${status_color}${status_icon}${reset} "

    export PS1
}

PROMPT_COMMAND="__arch_prompt"

# ── Aliases (minimal, useful) ─────────────────────────────────────
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -lah'
alias la='ls -la'
alias l='ls -CF'

alias grep='grep --color=auto'
alias diff='diff --color=auto'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'

# Quick aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -10'
alias gd='git diff'

alias df='df -h'
alias free='free -h'
alias top='htop 2>/dev/null || top'

# System status
alias status='arch-status'
alias sysinfo='arch-status --full'

# ── Functions ─────────────────────────────────────────────────────

# Quick directory jumping
mkcd() { mkdir -p "$1" && cd "$1"; }

# Extract any archive
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1"   ;;
            *.tar.gz)  tar xzf "$1"   ;;
            *.tar.xz)  tar xJf "$1"   ;;
            *.tar.zst) tar --zstd -xf "$1" ;;
            *.tar.lz)  tar --lzip -xf "$1" ;;
            *.bz2)     bunzip2 "$1"   ;;
            *.gz)      gunzip "$1"    ;;
            *.xz)      unxz "$1"     ;;
            *.zst)     unzstd "$1"   ;;
            *.zip)     unzip "$1"    ;;
            *.7z)      7z x "$1"     ;;
            *)         echo "Don't know how to extract '$1'" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick backup
bak() { cp "$1"{,.bak.$(date +%Y%m%d%H%M%S)}; }

# Disk usage summary
dusage() { du -sh * 2>/dev/null | sort -rh | head -20; }

# ── PATH ──────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# ── Editor ────────────────────────────────────────────────────────
export EDITOR='nvim'
export VISUAL='nvim'

# ── Less colors ───────────────────────────────────────────────────
export LESS='-R -F -X'
export MANPAGER='sh -c "col -bx | bat -l man -p" 2>/dev/null || less'

# ── Completion ────────────────────────────────────────────────────
[[ -f /usr/share/bash-completion/bash_completion ]] && \
    . /usr/share/bash-completion/bash_completion

# Fish-style completion if available
[[ -f ~/.local/share/fzf/shell/key-bindings.bash ]] && \
    . ~/.local/share/fzf/shell/key-bindings.bash

# ── Starship prompt (if installed) ────────────────────────────────
if command -v starship &>/dev/null; then
    eval "$(starship init bash)" 2>/dev/null
fi

# ── Zoxide (if installed) ────────────────────────────────────────
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)" 2>/dev/null
fi

# ── NVM (lazy load if present) ────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use
