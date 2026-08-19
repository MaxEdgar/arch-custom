#!/usr/bin/env bash
# Arch Custom — Live Environment Init
# Runs once on first boot of the live ISO.

set -euo pipefail

echo "[arch-custom] Initializing live environment..."

# ── Network ──────────────────────────────────────────────────────
# Start NetworkManager for live network setup
if systemctl is-enabled NetworkManager &>/dev/null 2>&1; then
    systemctl start NetworkManager 2>/dev/null || true
fi

# ── Mirrors ──────────────────────────────────────────────────────
# Update mirrorlist if connected
if ping -c 1 -W 2 archlinux.org &>/dev/null 2>&1; then
    echo "[arch-custom] Updating mirrorlist..."
    if command -v reflector &>/dev/null; then
        reflector --latest 15 --protocol https --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null || true
    fi
fi

# ── Package database ─────────────────────────────────────────────
# Sync package database
pacman -Sy --noconfirm 2>/dev/null || true

# ── Create user directories ──────────────────────────────────────
mkdir -p /home/live/.local/bin
mkdir -p /home/live/.config
chown -R live:live /home/live 2>/dev/null || true

# ── Set version ──────────────────────────────────────────────────
echo "1.0.0-$(date +%Y%m%d)" > /etc/arch-custom-version

echo "[arch-custom] Init complete."
