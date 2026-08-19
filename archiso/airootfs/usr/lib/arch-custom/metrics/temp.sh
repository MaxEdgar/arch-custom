#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Arch Custom — Temperature Metrics Collector
# Reads thermal zones from /sys — extremely cheap.
# ═══════════════════════════════════════════════════════════════════

# Get temperature in Celsius
temp_get_value() {
    local temp_file="/sys/class/thermal/thermal_zone0/temp"
    if [[ -f "$temp_file" ]]; then
        local raw
        raw=$(cat "$temp_file" 2>/dev/null || echo "0")
        echo $((raw / 1000))
    else
        # Try hwmon
        local hwmon_temp
        hwmon_temp=$(find /sys/class/hwmon -name "temp1_input" 2>/dev/null | head -1)
        if [[ -n "$hwmon_temp" ]]; then
            local raw
            raw=$(cat "$hwmon_temp" 2>/dev/null || echo "0")
            echo $((raw / 1000))
        else
            echo "N/A"
        fi
    fi
}

# Get temperature zone name
temp_get_zone() {
    local zone_file="/sys/class/thermal/thermal_zone0/type"
    if [[ -f "$zone_file" ]]; then
        cat "$zone_file" 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# Get formatted temperature string
temp_get_display() {
    local temp
    temp=$(temp_get_value)
    if [[ "$temp" == "N/A" ]]; then
        echo "N/A"
    else
        echo "${temp}°C"
    fi
}
