#!/usr/bin/env bash
# Arch Custom — Welcome Banner

echo -e "\033[0;36m"
cat << 'EOF'
     _             _     _     ____  _               _    
    / \   _ __ ___| |__ | |   / ___|| |__   ___  ___| | __
   / _ \ | '__/ __| '_ \| |   \___ \| '_ \ / _ \/ __| |/ /
  / ___ \| | | (__| | | | |___ ___) | | | |  __/ (__|   < 
 /_/   \_\_|  \___|_| |_|_____|____/|_| |_|\___|\___|_|\_\
EOF
echo -e "\033[0m"
echo -e "\033[1;33m  Minimal • Fast • Secure\033[0m"
echo ""
echo -e "  Version: \033[1;37m$(cat /etc/arch-custom-version 2>/dev/null || echo 'dev')\033[0m"
echo -e "  Kernel:  \033[1;37m$(uname -r)\033[0m"
echo -e "  Arch:    \033[1;37m$(uname -m)\033[0m"
echo ""
