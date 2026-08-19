#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Arch Custom — Network Metrics Collector
# Reads /proc/net/dev for throughput, iw/nmcli for Wi-Fi info.
# ═══════════════════════════════════════════════════════════════════

declare -g _NET_PREV_RX=0
declare -g _NET_PREV_TX=0
declare -g _NET_PREV_TIME=0

# Get active network interface
net_get_interface() {
    # Find default route interface
    local iface
    iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5}' | head -1)
    [[ -n "$iface" ]] && echo "$iface" && return

    # Fallback: first non-lo interface
    awk 'NR>2 && $1!~/lo:/ {gsub(/:/, "", $1); print $1; exit}' /proc/net/dev 2>/dev/null || echo "N/A"
}

# Get connection state
net_get_state() {
    local iface
    iface=$(net_get_interface)
    [[ "$iface" == "N/A" || -z "$iface" ]] && { echo "disconnected"; return; }

    local state
    state=$(cat "/sys/class/net/$iface/operstate" 2>/dev/null || echo "unknown")
    echo "$state"
}

# Get Wi-Fi SSID (if connected)
net_get_ssid() {
    if command -v iw &>/dev/null; then
        local iface
        iface=$(net_get_interface)
        local ssid
        ssid=$(iw dev "$iface" link 2>/dev/null | grep "SSID:" | awk '{print $2}')
        [[ -n "$ssid" ]] && echo "$ssid" && return
    fi

    if command -v nmcli &>/dev/null; then
        local ssid
        ssid=$(nmcli -t -f SSID,TYPE dev wifi 2>/dev/null | head -1 | cut -d: -f1)
        [[ -n "$ssid" ]] && echo "$ssid" && return
    fi

    echo ""
}

# Get Wi-Fi signal strength (0-100)
net_get_signal() {
    if command -v iw &>/dev/null; then
        local iface
        iface=$(net_get_interface)
        local signal
        signal=$(iw dev "$iface" link 2>/dev/null | grep "signal:" | awk '{print $2}' | tr -d '-' | cut -d. -f1)
        [[ -n "$signal" ]] && echo "$signal" && return
    fi

    if command -v nmcli &>/dev/null; then
        local signal
        signal=$(nmcli -t -f SIGNAL dev wifi 2>/dev/null | head -1)
        [[ -n "$signal" ]] && echo "$signal" && return
    fi

    echo ""
}

# Get IP address for active interface
net_get_ip() {
    local iface
    iface=$(net_get_interface)
    [[ "$iface" == "N/A" || -z "$iface" ]] && { echo "N/A"; return; }

    local ip
    ip=$(ip -4 addr show "$iface" 2>/dev/null | grep inet | awk '{print $2}' | cut -d/ -f1 | head -1)
    echo "${ip:-N/A}"
}

# Get throughput (bytes/sec) since last call
net_get_throughput() {
    local now_rx=0 now_tx=0 now_time
    now_time=$(date +%s)

    # Read all interfaces in one pass using awk (skips headers)
    local rx_tx
    rx_tx=$(awk 'NR>2 && $1!~/lo:/ {gsub(/:/, "", $1); rx+=$2; tx+=$10} END {print rx, tx}' /proc/net/dev 2>/dev/null)
    now_rx=$(echo "$rx_tx" | awk '{print $1}')
    now_tx=$(echo "$rx_tx" | awk '{print $2}')
    now_rx=${now_rx:-0}
    now_tx=${now_tx:-0}

    local dt=$((now_time - _NET_PREV_TIME))
    if [[ $dt -gt 0 && $_NET_PREV_TIME -gt 0 ]]; then
        local rx_speed=$(( (now_rx - _NET_PREV_RX) / dt ))
        local tx_speed=$(( (now_tx - _NET_PREV_TX) / dt ))

        # Clamp negative values
        ((rx_speed < 0)) && rx_speed=0
        ((tx_speed < 0)) && tx_speed=0

        _NET_PREV_RX=$now_rx
        _NET_PREV_TX=$now_tx
        _NET_PREV_TIME=$now_time

        echo "$(net_fmt_bytes $rx_speed) $(net_fmt_bytes $tx_speed)"
    else
        _NET_PREV_RX=$now_rx
        _NET_PREV_TX=$now_tx
        _NET_PREV_TIME=$now_time
        echo "0 B/s 0 B/s"
    fi
}

# Format bytes to human-readable
net_fmt_bytes() {
    local bytes=$1
    if ((bytes >= 1073741824)); then
        printf "%.1f GB/s" "$(echo "scale=1; $bytes/1073741824" | bc 2>/dev/null || echo "$((bytes/1073741824))")"
    elif ((bytes >= 1048576)); then
        printf "%.1f MB/s" "$(echo "scale=1; $bytes/1048576" | bc 2>/dev/null || echo "$((bytes/1048576))")"
    elif ((bytes >= 1024)); then
        printf "%.1f KB/s" "$(echo "scale=1; $bytes/1024" | bc 2>/dev/null || echo "$((bytes/1024))")"
    else
        printf "%d B/s" "$bytes"
    fi
}

# Get total bytes transferred (cumulative)
net_get_total() {
    local rx=0 tx=0
    while IFS= read -r line; do
        local iface
        iface=$(echo "$line" | awk '{print $1}' | tr -d ':')
        [[ "$iface" == "lo" ]] && continue
        rx=$((rx + $(echo "$line" | awk '{print $2}')))
        tx=$((tx + $(echo "$line" | awk '{print $10}')))
    done < /proc/net/dev
    echo "$(net_fmt_bytes $rx) / $(net_fmt_bytes $tx)"
}
