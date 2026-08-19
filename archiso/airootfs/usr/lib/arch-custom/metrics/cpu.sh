#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Arch Custom — CPU Metrics Collector
# Reads /proc/stat for cheap, accurate CPU usage.
# ═══════════════════════════════════════════════════════════════════

# State for delta calculation
declare -g _CPU_PREV_IDLE=0
declare -g _CPU_PREV_TOTAL=0

# Read CPU usage as a percentage (0-100)
cpu_get_usage() {
    local cpu_line
    cpu_line=$(head -1 /proc/stat 2>/dev/null) || { echo "N/A"; return; }

    # Parse values from 'cpu  user nice system idle iowait irq softirq steal'
    local user nice system idle iowait irq softirq steal
    read -r _ user nice system idle iowait irq softirq steal _extra <<< "$cpu_line"

    # Defaults for missing fields
    user=${user:-0}; nice=${nice:-0}; system=${system:-0}; idle=${idle:-0}
    iowait=${iowait:-0}; irq=${irq:-0}; softirq=${softirq:-0}; steal=${steal:-0}

    # Compute totals
    local total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    local idle_total=$((idle + iowait))

    # Delta
    local dtotal=$((total - _CPU_PREV_TOTAL))
    local didle=$((idle_total - _CPU_PREV_IDLE))

    # Store for next call
    _CPU_PREV_TOTAL=$total
    _CPU_PREV_IDLE=$idle_total

    if [[ $dtotal -eq 0 ]]; then
        echo "0"
        return
    fi

    local usage=$(( (dtotal - didle) * 100 / dtotal ))
    echo "$usage"
}

# Get load averages
cpu_get_load() {
    awk '{printf "%.2f", $1}' /proc/loadavg 2>/dev/null || echo "N/A"
}

# Get CPU info summary
cpu_get_info() {
    local model cores
    model=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | xargs)
    cores=$(nproc 2>/dev/null || echo "?")
    echo "${model:-Unknown} (${cores} cores)"
}

# Get CPU frequency
cpu_get_freq() {
    local freq
    freq=$(cat /proc/cpuinfo 2>/dev/null | grep "cpu MHz" | head -1 | awk '{print $4}' | cut -d. -f1)
    [[ -n "$freq" ]] && echo "${freq} MHz" || echo "N/A"
}
