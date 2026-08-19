# ═══════════════════════════════════════════════════════════════════
# Arch Custom — .zshrc
# Fast shell startup, clean prompt, minimal overhead.
# ═══════════════════════════════════════════════════════════════════

# ── Options ───────────────────────────────────────────────────────
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt CORRECT
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt NO_BEEP

# ── History ───────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# ── Completion ────────────────────────────────────────────────────
autoload -Uz compinit
compinit -C  # Skip security check for speed

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zsh/compcache

# ── Prompt ────────────────────────────────────────────────────────
autoload -Uz vcs_info
precmd() { vcs_info }

zstyle ':vcs_info:git:*' formats ' (%b)'
zstyle ':vcs_info:git:*' actionformats ' (%b|%a)'

# ── Key Bindings ──────────────────────────────────────────────────
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[C' forward-word
bindkey '^[[D' backward-word
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# ── Aliases ───────────────────────────────────────────────────────
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -lah'
alias la='ls -la'
alias l='ls -CF'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -10'
alias gd='git diff'
alias df='df -h'
alias free='free -h'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias status='arch-status'
alias sysinfo='arch-status --full'

mkcd() { mkdir -p "$1" && cd "$1"; }
extract() {
    case "$1" in
        *.tar.bz2) tar xjf "$1" ;;
        *.tar.gz)  tar xzf "$1" ;;
        *.tar.xz)  tar xJf "$1" ;;
        *.tar.zst) tar --zstd -xf "$1" ;;
        *.bz2)     bunzip2 "$1" ;;
        *.gz)      gunzip "$1" ;;
        *.xz)      unxz "$1" ;;
        *.zst)     unzstd "$1" ;;
        *.zip)     unzip "$1" ;;
        *.7z)      7z x "$1" ;;
        *) echo "Unknown format: $1" ;;
    esac
}

# ── PATH ──────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export EDITOR='nvim'
export VISUAL='nvim'
export LESS='-R -F -X'

# ── Starship ──────────────────────────────────────────────────────
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)" 2>/dev/null
else
    PROMPT='
%F{cyan}┌─%F{magenta}%n%f@%F{bold}%m%f${vcs_info_msg_0_} %F{cyan}─%f
%F{cyan}└─%F{blue}%~%f %F{cyan}─%f %# '
fi

# ── Plugins ───────────────────────────────────────────────────────
[[ -f ~/.local/share/fzf/shell/key-bindings.zsh ]] && \
    . ~/.local/share/fzf/shell/key-bindings.zsh
