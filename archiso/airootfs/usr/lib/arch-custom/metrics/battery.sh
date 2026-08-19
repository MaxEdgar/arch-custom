#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Arch Custom — Battery Metrics Collector
# Reads /sys/class/power_supply/BAT* — zero subprocess overhead.
# ═══════════════════════════════════════════════════════════════════

# Find battery directory
_bat_find() {
    local bat
    for bat in /sys/class/power_supply/BAT0 /sys/class/power_supply/BAT1; do
        [[ -d "$bat" ]] && echo "$bat" && return
    done
    echo ""
}

# Check if battery exists
battery_exists() {
    [[ -n "$(_bat_find)" ]] && return 0 || return 1
}

# Get battery capacity (0-100)
battery_get_capacity() {
    local bat
    bat=$(_bat_find)
    [[ -z "$bat" ]] && { echo "N/A"; return; }
    cat "$bat/capacity" 2>/dev/null || echo "N/A"
}

# Get battery status (Charging, Discharging, Full, Not charging)
battery_get_status() {
    local bat
    bat=$(_bat_find)
    [[ -z "$bat" ]] && { echo "N/A"; return; }
    cat "$bat/status" 2>/dev/null || echo "N/A"
}

# Get battery health (design vs current capacity)
battery_get_health() {
    local bat
    bat=$(_bat_find)
    [[ -z "$bat" ]] && { echo "N/A"; return; }

    local design current
    design=$(cat "$bat/energy_full_design" 2>/dev/null || cat "$bat/charge_full_design" 2>/dev/null || echo "0")
    current=$(cat "$bat/energy_full" 2>/dev/null || cat "$bat/charge_full" 2>/dev/null || echo "0")

    if [[ "$design" -gt 0 ]]; then
        echo "$((current * 100 / design))%"
    else
        echo "N/A"
    fi
}

# Get time to full/empty
battery_get_time() {
    local bat
    bat=$(_bat_find)
    [[ -z "$bat" ]] && { echo "N/A"; return; }

    local status now full rate
    status=$(battery_get_status)

    case "$status" in
        Charging)
            now=$(cat "$bat/energy_now" 2>/dev/null || cat "$bat/charge_now" 2>/dev/null || echo "0")
            full=$(cat "$bat/energy_full" 2>/dev/null || cat "$bat/charge_full" 2>/dev/null || echo "0")
            rate=$(cat "$bat/current_now" 2>/dev/null || echo "0")
            if [[ "$rate" -gt 0 ]]; then
                local remaining=$(( (full - now) / rate / 60 ))
                echo "${remaining}min"
            else
                echo "N/A"
            fi
            ;;
        Discharging)
            now=$(cat "$bat/energy_now" 2>/dev/null || cat "$bat/charge_now" 2>/dev/null || echo "0")
            rate=$(cat "$bat/current_now" 2>/dev/null || echo "0")
            if [[ "$rate" -gt 0 ]]; then
                local remaining=$(( now / rate / 60 ))
                echo "${remaining}min"
            else
                echo "N/A"
            fi
            ;;
        *)
            echo "N/A"
            ;;
    esac
}
