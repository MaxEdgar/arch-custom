#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Arch Custom — RAM Metrics Collector
# Reads /proc/meminfo — cheap, no subprocess overhead.
# ═══════════════════════════════════════════════════════════════════

# Get total RAM in human-readable format
ram_get_total() {
    awk '/^MemTotal/ {printf "%.1f", $2/1048576}' /proc/meminfo 2>/dev/null || echo "N/A"
}

# Get used RAM in human-readable format (total - available)
ram_get_used() {
    awk '/^MemTotal/ {t=$2} /^MemAvailable/ {a=$2} END {printf "%.1f", (t-a)/1048576}' /proc/meminfo 2>/dev/null || echo "N/A"
}

# Get RAM percentage
ram_get_percent() {
    awk '/^MemTotal/ {t=$2} /^MemAvailable/ {a=$2} END {printf "%.0f", (t-a)*100/t}' /proc/meminfo 2>/dev/null || echo "0"
}

# Get cached/buffered memory
ram_get_cached() {
    awk '/^Cached/ {c=$2} /^Buffers/ {b=$2} END {printf "%.1f", (c+b)/1048576}' /proc/meminfo 2>/dev/null || echo "N/A"
}

# Get swap usage
ram_get_swap() {
    awk '/^SwapTotal/ {t=$2} /^SwapFree/ {f=$2} END {printf "%.1f/%.1f", (t-f)/1048576, t/1048576}' /proc/meminfo 2>/dev/null || echo "N/A"
}

# Full summary
ram_get_summary() {
    local total used pct
    total=$(ram_get_total)
    used=$(ram_get_used)
    pct=$(ram_get_percent)
    echo "${used}G / ${total}G (${pct}%)"
}
