#!/usr/bin/env bash
# shellcheck disable=SC2034
# profiledef.sh — Arch Custom ISO Profile Definition

iso_name="arch-custom"
iso_label="ARCH_CUSTOM_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Arch Custom <https://github.com/MaxEdgar/arch-custom>"
iso_application="Arch Custom Linux — Minimal Install"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=(
    'bios.syslinux'
    'uefi.systemd-boot'
)
arch="x86_64"
kernel=('linux')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-b' '1M')
file_permissions=(
    ["/etc/shadow"]="0:0:400"
    ["/root"]="0:0:750"
)
