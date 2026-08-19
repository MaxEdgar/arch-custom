#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Arch Custom CLI — Input Handler
# Non-blocking keyboard input with escape sequence parsing.
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Terminal Raw Mode ─────────────────────────────────────────────
_input_init() {
    # Save original terminal settings
    _ORIG_STTY=$(stty -g 2>/dev/null || echo "")

    # Set raw mode: no echo, no buffering, no signal processing
    stty -echo -icanon min 0 time 0 2>/dev/null || true
}

_input_cleanup() {
    # Restore original terminal settings
    [[ -n "${_ORIG_STTY:-}" ]] && stty "$_ORIG_STTY" 2>/dev/null || true
}

# ── Read Single Key ───────────────────────────────────────────────
# Returns: key name or character
# Non-blocking: returns "" if no key pressed within timeout
input_read_key() {
    local key=""
    local char

    # Read one byte
    char=$(dd bs=1 count=1 2>/dev/null || echo "")

    if [[ -z "$char" ]]; then
        echo ""
        return
    fi

    # Convert to ordinal
    local ord
    ord=$(printf '%d' "'$char" 2>/dev/null || echo "0")

    case "$ord" in
        27)  # ESC sequence
            local seq1 seq2
            seq1=$(dd bs=1 count=1 2>/dev/null || echo "")
            seq2=$(dd bs=1 count=1 2>/dev/null || echo "")

            if [[ "$seq1" == "[" ]]; then
                case "$seq2" in
                    A) echo "up" ;;
                    B) echo "down" ;;
                    C) echo "right" ;;
                    D) echo "left" ;;
                    Z) echo "shift-tab" ;;
                    1) # Extended escape sequence
                        local ext
                        ext=$(dd bs=1 count=1 2>/dev/null || echo "")
                        dd bs=1 count=1 2>/dev/null > /dev/null  # consume '~'
                        case "$ext" in
                            H) echo "home" ;;
                            F) echo "end" ;;
                            *) echo "unknown" ;;
                        esac
                        ;;
                    *) echo "unknown" ;;
                esac
            elif [[ "$seq1" == "O" ]]; then
                case "$seq2" in
                    P) echo "f1" ;;
                    Q) echo "f2" ;;
                    R) echo "f3" ;;
                    S) echo "f4" ;;
                    *) echo "unknown" ;;
                esac
            else
                # Bare ESC (no following sequence within 0.1s)
                # We already consumed 1 char, check if more pending
                echo "escape"
            fi
            ;;
        9)  echo "tab" ;;
        10) echo "enter" ;;
        13) echo "enter" ;;
        127) echo "backspace" ;;
        8)  echo "backspace" ;;
        3)  echo "ctrl-c" ;;
        4)  echo "ctrl-d" ;;
        11) echo "ctrl-k" ;;
        12) echo "ctrl-l" ;;
        21) echo "ctrl-u" ;;
        27) echo "escape" ;;  # duplicate, but safe
        *)
            # Printable character
            if ((ord >= 32 && ord <= 126)); then
                echo "$char"
            else
                echo "unknown"
            fi
            ;;
    esac
}

# ── Wait for Key (blocking) ───────────────────────────────────────
input_wait_key() {
    local timeout="${1:-0}"
    local key

    if [[ "$timeout" -gt 0 ]]; then
        # Read with timeout
        key=$(read -rsn1 -t "$timeout" 2>/dev/null || echo "")
    else
        # Blocking read
        key=$(read -rsn1 2>/dev/null || echo "")
    fi

    if [[ -z "$key" ]]; then
        echo ""
        return
    fi

    local ord
    ord=$(printf '%d' "'$key" 2>/dev/null || echo "0")

    case "$ord" in
        27)
            local seq1 seq2
            seq1=$(read -rsn1 -t 0.05 2>/dev/null || echo "")
            seq2=$(read -rsn1 -t 0.05 2>/dev/null || echo "")
            if [[ "$seq1" == "[" ]]; then
                case "$seq2" in
                    A) echo "up" ;;
                    B) echo "down" ;;
                    C) echo "right" ;;
                    D) echo "left" ;;
                    Z) echo "shift-tab" ;;
                    *) echo "escape" ;;
                esac
            else
                echo "escape"
            fi
            ;;
        9)  echo "tab" ;;
        10|13) echo "enter" ;;
        127|8) echo "backspace" ;;
        3)  echo "ctrl-c" ;;
        *)
            if ((ord >= 32 && ord <= 126)); then
                echo "$key"
            else
                echo "unknown"
            fi
            ;;
    esac
}

# ── Key Name to Display ──────────────────────────────────────────
input_key_display() {
    case "$1" in
        up)        echo "↑" ;;
        down)      echo "↓" ;;
        left)      echo "←" ;;
        right)     echo "→" ;;
        enter)     echo "Enter" ;;
        escape)    echo "Esc" ;;
        tab)       echo "Tab" ;;
        shift-tab) echo "Shift+Tab" ;;
        backspace) echo "⌫" ;;
        ctrl-c)    echo "Ctrl+C" ;;
        home)      echo "Home" ;;
        end)       echo "End" ;;
        *)         echo "$1" ;;
    esac
}
