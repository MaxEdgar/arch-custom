#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Arch Custom CLI — Rendering Engine
# Efficient ANSI-based terminal rendering with partial updates.
# No full-screen redraws, no flickering, no `clear`.
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Terminal State ────────────────────────────────────────────────
declare -g TERM_COLS=80
declare -g TERM_ROWS=24
declare -g COLOR_MODE="auto"
declare -ga _PREV_BUFFER=()
declare -ga _CURR_BUFFER=()
declare -g _DIRTY=true

# ── Initialize ────────────────────────────────────────────────────
render_init() {
    # Get terminal size
    if command -v stty &>/dev/null; then
        local size
        size=$(stty size 2>/dev/null || echo "24 80")
        TERM_ROWS="${size%% *}"
        TERM_COLS="${size##* }"
    fi

    # Detect color mode
    COLOR_MODE=$(detect_color_mode 2>/dev/null || echo "16")

    # Hide cursor during rendering
    printf '\033[?25l'

    # Enable alternate screen buffer (no flicker on exit)
    printf '\033[?1049h'
}

render_cleanup() {
    # Show cursor
    printf '\033[?25h'
    # Return to normal screen buffer
    printf '\033[?1049l'
}

# ── ANSI Color Codes ─────────────────────────────────────────────
# We define codes per color mode for graceful degradation.

_set_color() {
    local color_name="$1"
    local fg="${2:-}"
    local bg="${3:-}"

    case "$COLOR_MODE" in
        truecolor)
            case "$color_name" in
                reset)   printf '\033[0m' ;;
                bold)    printf '\033[1m' ;;
                dim)     printf '\033[2m' ;;
                red)     printf '\033[38;2;255;80;80m' ;;
                green)   printf '\033[38;2;80;220;80m' ;;
                yellow)  printf '\033[38;2;255;220;50m' ;;
                blue)    printf '\033[38;2;80;160;255m' ;;
                cyan)    printf '\033[38;2;80;220;220m' ;;
                magenta) printf '\033[38;2;200;100;255m' ;;
                white)   printf '\033[38;2;220;220;220m' ;;
                gray)    printf '\033[38;2;140;140;140m' ;;
                *)       printf '\033[0m' ;;
            esac
            ;;
        256)
            case "$color_name" in
                reset)   printf '\033[0m' ;;
                bold)    printf '\033[1m' ;;
                dim)     printf '\033[2m' ;;
                red)     printf '\033[38;5;196m' ;;
                green)   printf '\033[38;5;82m' ;;
                yellow)  printf '\033[38;5;220m' ;;
                blue)    printf '\033[38;5;75m' ;;
                cyan)    printf '\033[38;5;80m' ;;
                magenta) printf '\033[38;5;141m' ;;
                white)   printf '\033[38;5;252m' ;;
                gray)    printf '\033[38;5;245m' ;;
                *)       printf '\033[0m' ;;
            esac
            ;;
        16)
            case "$color_name" in
                reset)   printf '\033[0m' ;;
                bold)    printf '\033[1m' ;;
                dim)     printf '\033[2m' ;;
                red)     printf '\033[1;31m' ;;
                green)   printf '\033[1;32m' ;;
                yellow)  printf '\033[1;33m' ;;
                blue)    printf '\033[1;34m' ;;
                cyan)    printf '\033[1;36m' ;;
                magenta) printf '\033[1;35m' ;;
                white)   printf '\033[1;37m' ;;
                gray)    printf '\033[2m' ;;
                *)       printf '\033[0m' ;;
            esac
            ;;
        mono)
            case "$color_name" in
                reset)   printf '' ;;
                bold)    printf '' ;;
                dim)     printf '' ;;
                red|green|yellow|blue|cyan|magenta|white|gray) printf '' ;;
                *)       printf '' ;;
            esac
            ;;
    esac
}

# ── Drawing Primitives ────────────────────────────────────────────

# Move cursor to row, col (1-indexed)
_move_to() {
    printf '\033[%d;%dH' "$1" "$2"
}

# Clear from cursor to end of line
_clear_eol() {
    printf '\033[K'
}

# Print at position without full redraw
_print_at() {
    local row=$1 col=$2
    _move_to "$row" "$col"
}

# ── Progress Bar ──────────────────────────────────────────────────
draw_bar() {
    local percent=$1
    local width=${2:-10}
    local filled=$((percent * width / 100))
    local empty=$((width - filled))

    # Choose color based on level
    if ((percent >= 90)); then
        _set_color "red"
    elif ((percent >= 70)); then
        _set_color "yellow"
    else
        _set_color "green"
    fi

    # Draw filled portion
    local i
    for ((i = 0; i < filled; i++)); do
        printf '█'
    done

    _set_color "gray"
    for ((i = 0; i < empty; i++)); do
        printf '░'
    done

    _set_color "reset"
}

# ── Box Drawing ───────────────────────────────────────────────────
draw_hline() {
    local width=$1
    local char="${2:-─}"
    local i
    for ((i = 0; i < width; i++)); do
        printf '%s' "$char"
    done
}

# ── Buffer Comparison (Double Buffer) ────────────────────────────
# Only redraw lines that actually changed.

_buffer_set() {
    local row=$1
    local content="$2"
    _CURR_BUFFER[$row]="$content"
}

_buffer_swap() {
    local row
    for row in $(seq 1 "$TERM_ROWS"); do
        if [[ "${_CURR_BUFFER[$row]:-}" != "${_PREV_BUFFER[$row]:-}" ]]; then
            _move_to "$row" 1
            _clear_eol
            printf '%s' "${_CURR_BUFFER[$row]:-}"
        fi
    done
    _PREV_BUFFER=("${_CURR_BUFFER[@]}")
}

# ── Section Drawing ───────────────────────────────────────────────
draw_section() {
    local row=$1
    local label=$2
    local content=$3
    local width=${4:-$TERM_COLS}

    local line=""

    # Label
    _set_color "cyan"
    line+="$label"
    _set_color "reset"
    line+=" "

    # Content
    line+="$content"

    _buffer_set "$row" "$line"
}

draw_separator() {
    local row=$1
    local width=${2:-$TERM_COLS}

    local line=""
    _set_color "gray"
    line+="├"
    line+=$(draw_hline $((width - 2)))
    line+="┤"
    _set_color "reset"

    _buffer_set "$row" "$line"
}

draw_top_border() {
    local row=$1
    local title=$2
    local width=${3:-$TERM_COLS}

    local line=""
    _set_color "cyan"
    line+="┌"
    local title_len=${#title}
    local padding=$(( (width - 2 - title_len) / 2 ))
    line+=$(draw_hline "$padding")
    line+=" $title "
    line+=$(draw_hline $((width - 2 - padding - title_len - 2)))
    line+="┐"
    _set_color "reset"

    _buffer_set "$row" "$line"
}

draw_bottom_border() {
    local row=$1
    local width=${2:-$TERM_COLS}

    local line=""
    _set_color "cyan"
    line+="└"
    line+=$(draw_hline $((width - 2)))
    line+="┘"
    _set_color "reset"

    _buffer_set "$row" "$line"
}

# ── Status Bar ────────────────────────────────────────────────────
draw_status_bar() {
    local row=$1
    local left_text=$2
    local right_text=$3
    local width=${4:-$TERM_COLS}

    local line=""
    _set_color "gray"
    line+="│"

    local content_len=$(( ${#left_text} + ${#right_text} + 4 ))
    local gap=$(( width - 2 - content_len ))
    ((gap < 1)) && gap=1

    _set_color "white"
    line+=" $left_text"
    _set_color "gray"
    line+=$(draw_hline "$gap")
    _set_color "white"
    line+="$right_text "
    _set_color "gray"
    line+="│"
    _set_color "reset"

    _buffer_set "$row" "$line"
}
