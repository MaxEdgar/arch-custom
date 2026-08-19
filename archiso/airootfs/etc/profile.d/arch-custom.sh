#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Arch Custom — Live Environment Profile
# Shown when logging in to the live ISO.
# ═══════════════════════════════════════════════════════════════════

# Only on TTY login (not SSH or display managers)
if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" && -z "$SSH_CLIENT" ]]; then

    # Show welcome banner
    if [[ -f /usr/share/arch-custom/welcome.sh ]]; then
        /usr/share/arch-custom/welcome.sh
    fi

    # Auto-prompt to install
    echo ""
    echo -e "\033[1;36m╔══════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;36m║       Arch Custom Live Environment          ║\033[0m"
    echo -e "\033[1;36m╚══════════════════════════════════════════════╝\033[0m"
    echo ""
    echo -e "  Commands:"
    echo -e "    \033[1;33march-install\033[0m  — Launch the installer"
    echo -e "    \033[1;33march-status\033[0m   — System status"
    echo -e "    \033[1;33march-config\033[0m   — System configuration"
    echo ""
    echo -e "  Quick start:"
    echo -e "    \033[1;32march-install\033[0m"
    echo ""

fi
