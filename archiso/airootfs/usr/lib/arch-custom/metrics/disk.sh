#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Arch Custom — Disk Metrics Collector
# Reads df for disk usage — cheap, infrequent updates.
# ═══════════════════════════════════════════════════════════════════

# Get disk usage percentage for root
disk_get_percent() {
    df / 2>/dev/null | awk 'NR==2 {gsub(/%/, "", $5); print $5}' || echo "0"
}

# Get disk used/total
disk_get_used_total() {
    df -h / 2>/dev/null | awk 'NR==2 {printf "%s / %s", $3, $2}' || echo "N/A"
}

# Get disk available
disk_get_available() {
    df -h / 2>/dev/null | awk 'NR==2 {print $4}' || echo "N/A"
}

# Get inode usage
disk_get_inodes() {
    df -i / 2>/dev/null | awk 'NR==2 {gsub(/%/, "", $5); printf "%s%%", $5}' || echo "N/A"
}

# I/O stats from /proc/diskstats (bytes read/written since boot)
disk_get_io() {
    local root_dev
    root_dev=$(findmnt -n -o SOURCE / 2>/dev/null | sed 's|/dev/||; s/[0-9]*$//')
    if [[ -n "$root_dev" ]]; then
        grep "^ *${root_dev} " /proc/diskstats 2>/dev/null | awk '{printf "R:%s W:%s", $6, $10}' || echo "N/A"
    else
        echo "N/A"
    fi
}
