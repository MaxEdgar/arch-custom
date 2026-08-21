#!/usr/bin/env bash
# profiledef.sh — Arch Custom ISO Profile Definition

iso_name="arch-custom"
iso_label="ARCH_CUSTOM_$(date +%Y%m)"
iso_publisher="Arch Custom <https://github.com/MaxEdgar/arch-custom>"
iso_application="Arch Custom Linux — Minimal Install"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=()
bootmodes=(
    'bios/syslinux/syslinux.bin'
    'uefi-x64/grub/grubx64.efi'
)
arch="x86_64"
kernel=('linux')
mkarchiso_opts=("-v")
