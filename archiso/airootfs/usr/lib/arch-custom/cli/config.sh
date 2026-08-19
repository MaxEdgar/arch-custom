#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Arch Custom CLI — Configuration Module
# Manages all dashboard, metrics, and UI settings.
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

ARCH_CUSTOM_CONFIG="${ARCH_CUSTOM_CONFIG:-/etc/arch-custom/config}"
ARCH_CUSTOM_USER_CONFIG="${ARCH_CUSTOM_USER_CONFIG:-$HOME/.config/arch-custom/config}"

# ── Defaults ──────────────────────────────────────────────────────
declare -A CONFIG_DEFAULTS=(
    # Appearance
    ["color_mode"]="auto"
    ["show_title"]="true"
    ["show_border"]="true"
    ["border_style"]="single"

    # Metrics visibility
    ["show_cpu"]="true"
    ["show_ram"]="true"
    ["show_temp"]="true"
    ["show_gpu"]="true"
    ["show_disk"]="true"
    ["show_network"]="true"
    ["show_battery"]="true"
    ["show_load"]="true"

    # Refresh intervals (seconds)
    ["refresh_cpu"]="1"
    ["refresh_ram"]="1"
    ["refresh_temp"]="2"
    ["refresh_gpu"]="2"
    ["refresh_disk"]="5"
    ["refresh_network"]="1"
    ["refresh_battery"]="5"

    # Network
    ["dns_primary"]="1.1.1.1"
    ["dns_fallback"]="1.0.0.1"
    ["dns_mode"]="cloudflare"

    # Power
    ["power_button_action"]="display-off"
    ["lid_action"]="suspend"

    # Performance
    ["dashboard_mode"]="full"
    ["max_cpu_history"]="60"
    ["history_enabled"]="false"
)

# ── Config File I/O ───────────────────────────────────────────────
config_load() {
    local file="${1:-$ARCH_CUSTOM_CONFIG}"
    [[ -f "$file" ]] && source "$file" 2>/dev/null || true
}

config_save() {
    local file="${1:-$ARCH_CUSTOM_CONFIG}"
    mkdir -p "$(dirname "$file")"

    for key in "${!CONFIG_DEFAULTS[@]}"; do
        local varname="ARCH_CUSTOM_${key//[-.]/_}"
        local val="${!varname:-${CONFIG_DEFAULTS[$key]}}"
        echo "${key}=${val}" >> "$file"
    done
}

config_get() {
    local key="$1"
    local varname="ARCH_CUSTOM_${key//[-.]/_}"
    local default="${CONFIG_DEFAULTS[$key]:-}"

    # Check user config first
    if [[ -f "$ARCH_CUSTOM_USER_CONFIG" ]]; then
        local val
        val=$(grep "^${key}=" "$ARCH_CUSTOM_USER_CONFIG" 2>/dev/null | tail -1 | cut -d= -f2-)
        [[ -n "$val" ]] && echo "$val" && return 0
    fi

    # Check system config
    if [[ -f "$ARCH_CUSTOM_CONFIG" ]]; then
        local val
        val=$(grep "^${key}=" "$ARCH_CUSTOM_CONFIG" 2>/dev/null | tail -1 | cut -d= -f2-)
        [[ -n "$val" ]] && echo "$val" && return 0
    fi

    # Check environment variable
    [[ -n "${!varname}" ]] && echo "${!varname}" && return 0

    # Return default
    echo "$default"
}

config_set() {
    local key="$1"
    local value="$2"
    local file="${3:-$ARCH_CUSTOM_USER_CONFIG}"

    mkdir -p "$(dirname "$file")"

    # Remove existing key
    if [[ -f "$file" ]]; then
        local tmp
        tmp=$(grep -v "^${key}=" "$file" 2>/dev/null || true)
        echo "$tmp" > "$file"
    fi

    echo "${key}=${value}" >> "$file"
}

config_reset() {
    local file="${1:-$ARCH_CUSTOM_USER_CONFIG}"
    rm -f "$file" 2>/dev/null || true
}

# ── Color Mode Detection ─────────────────────────────────────────
detect_color_mode() {
    local mode
    mode=$(config_get "color_mode")

    case "$mode" in
        truecolor|24bit)
            echo "truecolor"
            return
            ;;
        256)
            echo "256"
            return
            ;;
        16|ansi)
            echo "16"
            return
            ;;
        mono|monochrome|off)
            echo "mono"
            return
            ;;
    esac

    # Auto-detect
    local term="${TERM:-}"
    local colorterm="${COLORTERM:-}"
    local colors="${colors:-}"

    if [[ "$colorterm" == *"truecolor"* || "$colorterm" == *"24bit"* ]]; then
        echo "truecolor"
    elif [[ "$colors" -ge 256 ]] || [[ "$term" == *"256color"* ]]; then
        echo "256"
    elif [[ "$colors" -ge 16 ]] || [[ -n "$term" ]]; then
        echo "16"
    else
        echo "mono"
    fi
}
