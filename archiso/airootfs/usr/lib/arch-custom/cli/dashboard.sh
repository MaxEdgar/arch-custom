#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Arch Custom CLI — Dashboard
# Full-screen metrics display with efficient partial updates.
# No `clear`, no full redraws, no flickering.
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

# Source all modules
_LIBDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$_LIBDIR/lib/arch-custom/cli/config.sh"
source "$_LIBDIR/lib/arch-custom/cli/rendering.sh"
source "$_LIBDIR/lib/arch-custom/cli/input.sh"
source "$_LIBDIR/lib/arch-custom/metrics/cpu.sh"
source "$_LIBDIR/lib/arch-custom/metrics/ram.sh"
source "$_LIBDIR/lib/arch-custom/metrics/temp.sh"
source "$_LIBDIR/lib/arch-custom/metrics/gpu.sh"
source "$_LIBDIR/lib/arch-custom/metrics/disk.sh"
source "$_LIBDIR/lib/arch-custom/metrics/network.sh"
source "$_LIBDIR/lib/arch-custom/metrics/battery.sh"

# ── State ─────────────────────────────────────────────────────────
declare -g _DASH_RUNNING=true
declare -g _DASH_LAST_CPU=0
declare -g _DASH_LAST_RAM=0
declare -g _DASH_LAST_TEMP=0
declare -g _DASH_LAST_GPU=0
declare -g _DASH_LAST_NET=""
declare -g _DASH_LAST_BAT=""
declare -g _DASH_LAST_DISK=0
declare -g _DASH_ROWS=20

# ── Layout Positions ──────────────────────────────────────────────
# Row assignments for the dashboard
_ROW_TITLE=1
_ROW_TOP_BORDER=2
_ROW_HDR=3
_ROW_CPU_RAM_TEMP=4
_ROW_GPU_DISK_LOAD=5
_ROW_BLANK1=6
_ROW_WIFI=7
_ROW_NET=8
_ROW_BLANK2=9
_ROW_BAT=10
_ROW_SEP=11
_ROW_PROMPT=12
_ROW_CMD=13
_ROW_BOTTOM=14

# ── Render Individual Sections ────────────────────────────────────
_render_title() {
    local time_str
    time_str=$(date '+%H:%M')
    local user host
    user=$(whoami 2>/dev/null || echo "user")
    host=$(hostname 2>/dev/null || echo "arch")

    local title=" ARCH CUSTOM CLI"
    local right=" $time_str "
    local total=$(( ${#title} + ${#right} ))
    local width=$TERM_COLS
    local gap=$((width - total))

    ((gap < 2)) && gap=2

    local line=""
    _set_color "cyan"
    line+="┌"
    _set_color "bold"
    line+="$title"
    _set_color "reset"
    _set_color "gray"
    local i
    for ((i=0; i<gap; i++)); do line+="─"; done
    _set_color "cyan"
    line+="$right"
    _set_color "reset"

    _buffer_set "$_ROW_TITLE" "$line"
}

_render_top_border() {
    _set_color "cyan"
    local line="├"
    local i
    for ((i=0; i<$((TERM_COLS-2)); i++)); do line+="─"; done
    line+="┤"
    _set_color "reset"
    _buffer_set "$_ROW_TOP_BORDER" "$line"
}

_render_cpu_ram_temp() {
    local line=""
    _set_color "gray"
    line+="│ "
    _set_color "reset"

    # CPU
    _set_color "blue"
    line+="CPU"
    _set_color "reset"
    line+="  "
    local cpu_usage
    cpu_usage=$(cpu_get_usage)
    _DASH_LAST_CPU=$cpu_usage
    if [[ "$cpu_usage" != "N/A" ]]; then
        draw_bar "$cpu_usage" 6
        printf -v bar_str '%s' ""
        line+=" ${cpu_usage}%"
    else
        line+=" N/A"
    fi

    line+="   "

    # RAM
    _set_color "green"
    line+="RAM"
    _set_color "reset"
    line+="  "
    local ram_used ram_total ram_pct
    ram_used=$(ram_get_used)
    ram_total=$(ram_get_total)
    ram_pct=$(ram_get_percent)
    _DASH_LAST_RAM=$ram_pct
    line+="${ram_used}G / ${ram_total}G"

    line+="   "

    # TEMP
    _set_color "magenta"
    line+="TEMP"
    _set_color "reset"
    line+=" "
    local temp
    temp=$(temp_get_display)
    _DASH_LAST_TEMP="$temp"
    line+="$temp"

    # Pad to fill width
    local content_len=0
    # Simple padding
    while [[ ${#line} -lt $((TERM_COLS - 2)) ]]; do
        line+=" "
    done

    _buffer_set "$_ROW_CPU_RAM_TEMP" "$line"
}

_render_gpu_disk_load() {
    local line=""
    _set_color "gray"
    line+="│ "
    _set_color "reset"

    # GPU
    _set_color "cyan"
    line+="GPU"
    _set_color "reset"
    line+="  "
    local gpu_usage
    gpu_usage=$(gpu_get_usage)
    _DASH_LAST_GPU=$gpu_usage
    line+="$gpu_usage"

    line+="   "

    # DISK
    _set_color "yellow"
    line+="DISK"
    _set_color "reset"
    line+=" "
    local disk_pct
    disk_pct=$(disk_get_percent)
    _DASH_LAST_DISK=$disk_pct
    draw_bar "$disk_pct" 6
    line+=" ${disk_pct}%"

    line+="   "

    # LOAD
    _set_color "white"
    line+="LOAD"
    _set_color "reset"
    line+=" "
    local load
    load=$(cpu_get_load)
    line+="$load"

    while [[ ${#line} -lt $((TERM_COLS - 2)) ]]; do
        line+=" "
    done

    _buffer_set "$_ROW_GPU_DISK_LOAD" "$line"
}

_render_blank() {
    local row=$1
    local line=""
    _set_color "gray"
    line+="│"
    _set_color "reset"
    while [[ ${#line} -lt $((TERM_COLS - 1)) ]]; do
        line+=" "
    done
    _buffer_set "$row" "$line"
}

_render_wifi() {
    local line=""
    _set_color "gray"
    line+="│ "
    _set_color "reset"

    local ssid signal state
    ssid=$(net_get_ssid)
    signal=$(net_get_signal)
    state=$(net_get_state)

    _set_color "cyan"
    line+="WIFI"
    _set_color "reset"
    line+="  "

    if [[ -n "$ssid" ]]; then
        _set_color "green"
        line+="$ssid"
        _set_color "reset"
        if [[ -n "$signal" ]]; then
            line+="  "
            draw_bar "$signal" 10
            line+="  ${signal}%"
        fi
    else
        _set_color "gray"
        line+="Disconnected"
        _set_color "reset"
    fi

    while [[ ${#line} -lt $((TERM_COLS - 2)) ]]; do
        line+=" "
    done

    _buffer_set "$_ROW_WIFI" "$line"
}

_render_net() {
    local line=""
    _set_color "gray"
    line+="│ "
    _set_color "reset"

    _set_color "magenta"
    line+="NET"
    _set_color "reset"
    line+="   "

    local throughput
    throughput=$(net_get_throughput)
    local rx tx
    rx=$(echo "$throughput" | awk '{print $1}')
    tx=$(echo "$throughput" | awk '{print $2}')

    _set_color "green"
    line+="↓ $rx"
    _set_color "reset"
    line+="     "
    _set_color "red"
    line+="↑ $tx"
    _set_color "reset"

    while [[ ${#line} -lt $((TERM_COLS - 2)) ]]; do
        line+=" "
    done

    _buffer_set "$_ROW_NET" "$line"
}

_render_battery() {
    local line=""
    _set_color "gray"
    line+="│ "
    _set_color "reset"

    if battery_exists; then
        local cap status
        cap=$(battery_get_capacity)
        status=$(battery_get_status)

        _set_color "yellow"
        line+="BAT"
        _set_color "reset"
        line+="  "

        if [[ "$cap" != "N/A" ]]; then
            draw_bar "$cap" 10
            line+="  ${cap}%"
            [[ -n "$status" && "$status" != "Full" ]] && line+=" ($status)"
        else
            line+="N/A"
        fi
    else
        _set_color "gray"
        line+="BAT   No battery detected"
        _set_color "reset"
    fi

    while [[ ${#line} -lt $((TERM_COLS - 2)) ]]; do
        line+=" "
    done

    _buffer_set "$_ROW_BAT" "$line"
}

_render_separator() {
    local line=""
    _set_color "gray"
    line+="├"
    local i
    for ((i=0; i<$((TERM_COLS-2)); i++)); do line+="─"; done
    line+="┤"
    _set_color "reset"
    _buffer_set "$_ROW_SEP" "$line"
}

_render_prompt() {
    local line=""
    _set_color "gray"
    line+="│ "
    _set_color "bold"
    line+="$ "
    _set_color "reset"

    while [[ ${#line} -lt $((TERM_COLS - 1)) ]]; do
        line+=" "
    done

    _buffer_set "$_ROW_PROMPT" "$line"
}

_render_command_line() {
    local line=""
    _set_color "gray"
    line+="│ "
    _set_color "reset"

    while [[ ${#line} -lt $((TERM_COLS - 1)) ]]; do
        line+=" "
    done

    _buffer_set "$_ROW_CMD" "$line"
}

_render_bottom() {
    local line=""
    _set_color "cyan"
    line+="└"
    local i
    for ((i=0; i<$((TERM_COLS-2)); i++)); do line+="─"; done
    line+="┘"
    _set_color "reset"
    _buffer_set "$_ROW_BOTTOM" "$line"
}

# ── Full Dashboard Render ─────────────────────────────────────────
dashboard_render() {
    _render_title
    _render_top_border
    _render_cpu_ram_temp
    _render_gpu_disk_load
    _render_blank "$_ROW_BLANK1"
    _render_wifi
    _render_net
    _render_blank "$_ROW_BLANK2"
    _render_battery
    _render_separator
    _render_prompt
    _render_command_line
    _render_bottom

    # Swap buffers — only redraws changed lines
    _buffer_swap
}

# ── Dashboard Loop ────────────────────────────────────────────────
dashboard_run() {
    local refresh_interval
    refresh_interval=$(config_get "refresh_cpu")
    [[ -z "$refresh_interval" ]] && refresh_interval=1

    # Initialize
    render_init
    _input_init
    trap '_DASH_RUNNING=false' INT TERM
    trap '_input_cleanup; render_cleanup' EXIT

    # Initial full render
    _buffer_swap

    # Main loop
    while $_DASH_RUNNING; do
        # Render all sections
        dashboard_render

        # Sleep for refresh interval (with input polling)
        local elapsed=0
        while ((elapsed < refresh_interval)); do
            # Quick input check (non-blocking)
            local key
            key=$(input_read_key)
            case "$key" in
                q|Q|ctrl-c)
                    _DASH_RUNNING=false
                    break
                    ;;
                s|S)
                    # Launch system-setup
                    _input_cleanup
                    render_cleanup
                    system-setup 2>/dev/null || true
                    render_init
                    _input_init
                    _buffer_swap
                    ;;
                l|L)
                    # Clear and redraw
                    printf '\033[2J'
                    _PREV_BUFFER=()
                    _buffer_swap
                    ;;
                r|R)
                    # Force full redraw
                    _PREV_BUFFER=()
                    ;;
            esac

            sleep 0.2
            elapsed=$((elapsed + 1))
        done
    done
}

# ── Main ──────────────────────────────────────────────────────────
# Can be sourced or executed directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    config_load
    dashboard_run
fi
