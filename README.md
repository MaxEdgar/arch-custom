# Arch Custom

**Minimal, fast, secure Arch Linux ISO with a custom installer and lightweight CLI.**

## What This Is

A custom Arch Linux ISO built on the official `archiso` infrastructure, featuring:

- **Minimal package selection** — only what you need
- **Custom installer** — replaces `archinstall` with a fast, keyboard-friendly TUI
- **Custom CLI** — lightweight status display (CPU, RAM, Wi-Fi, battery, disk, network)
- **Optimized performance** — tuned kernel parameters, fast boot, low idle RAM
- **Hardware-aware** — detects and installs appropriate drivers
- **Remote builds** — ISO built on GitHub Actions, not your local machine

## Project Structure

```
arch-custom/
├── .github/
│   └── workflows/
│       └── build-iso.yml          # GitHub Actions build workflow
├── archiso/
│   ├── airootfs/                  # Live environment root filesystem
│   │   ├── etc/
│   │   │   ├── pacman.conf        # Optimized pacman configuration
│   │   │   ├── profile.d/         # Login scripts
│   │   │   ├── skel/              # Default shell config
│   │   │   ├── sysctl.d/          # Kernel tuning
│   │   │   └── systemd/           # Systemd optimization
│   │   └── usr/
│   │       ├── bin/
│   │       │   ├── arch-install   # Custom installer (24-step TUI)
│   │       │   └── arch-status    # System status display
│   │       └── share/
│   │           └── arch-custom/   # Welcome scripts
│   ├── grub/
│   │   └── grub.cfg               # GRUB bootloader config
│   ├── efiboot/                   # UEFI boot entries
│   ├── packages.x86_64            # Package list
│   └── profiledef.sh              # Profile definition
├── build-remote                   # Local controller script
├── installer/                     # Installer source (backup)
├── cli/                           # CLI source (backup)
├── scripts/                       # Build scripts
├── config/                        # Configuration
├── .gitignore
├── LICENSE
└── README.md
```

## Quick Start

### Prerequisites

- Git
- GitHub CLI (`gh`) — authenticated
- Internet connection

### Build the ISO

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/arch-custom.git
cd arch-custom

# 2. Initialize (first time only)
./build-remote init

# 3. Run the full pipeline
./build-remote all
```

### Build Commands

| Command | Description |
|---------|-------------|
| `./build-remote status` | Check environment and repo status |
| `./build-remote init` | Initialize GitHub repository |
| `./build-remote push` | Push changes to GitHub |
| `./build-remote build` | Push and trigger ISO build |
| `./build-remote force` | Force rebuild (ignore path filtering) |
| `./build-remote poll` | Poll build status until completion |
| `./build-remote download` | Download ISO artifact |
| `./build-remote logs` | View build logs |
| `./build-remote clean` | Clean local artifacts |
| `./build-remote all` | Run full pipeline |

## Features

### Custom Installer (`arch-install`)

A 24-step TUI installer that covers:

1. Keyboard layout
2. Locale
3. Timezone
4. Hostname
5. User creation
6. Root password
7. Network configuration
8. Disk selection (with safety warnings)
9. Partitioning (UEFI/BIOS auto, manual)
10. Filesystem selection (ext4, btrfs, xfs, f2fs)
11. Swap configuration (file, partition, zram)
12. Bootloader (GRUB, systemd-boot)
13. Kernel (linux, linux-lts, linux-zen, linux-hardened)
14. Microcode (auto-detected)
15. GPU driver (auto-detected)
16. Audio (PipeWire, PulseAudio)
17. Desktop environment (13 options)
18. Essential package selection
19. Review before install
20. Partitioning & formatting
21. Swap setup
22. Base system installation
23. System configuration
24. Completion & reboot

### Custom CLI (`arch-status`)

```text
┌────────────────────────────────────────────────────────────────┐
│  CPU  12%  │  48°C                                            │
│  RAM  3.1G / 15.4G                                             │
│  WIFI MyNetwork ███████░░░ 72%                                 │
│  BAT  ⚡ ████████░░ 82% (Charging)                             │
│  DISK ███████░░░ 71% (12G/17G)                                 │
│  NET  ▲1.2G ▼3.4G                                              │
│  UP   2 hours, 15 minutes                                      │
└────────────────────────────────────────────────────────────────┘
```

### Shell Prompt

Fast, informative prompt with git integration:

```
┌─max@arch ─────────────────────────────────┐
└─ ~/projects/arch-custom ─→ 
```

## Performance Targets

| Metric | Target |
|--------|--------|
| ISO size | < 1 GB |
| Boot time | < 5 seconds to login |
| Idle RAM | < 300 MB |
| Shell startup | < 100ms |
| Installer launch | < 2 seconds |

## Customization

### Packages

Edit `archiso/packages.x86_64` to add/remove packages.

### Installer

The installer is in `archiso/airootfs/usr/bin/arch-install`. Each step is a separate function that can be modified independently.

### CLI

The status display is in `archiso/airootfs/usr/bin/arch-status`. Modify the `show_*` functions to change what's displayed.

### Shell Config

Default shell config is in `archiso/airootfs/etc/skel/.bashrc` and `.zshrc`.

## Architecture

```
LOCAL MACHINE
     │
     │ push source/config
     ▼
GITHUB REPOSITORY
     │
     │ trigger workflow
     ▼
GITHUB ACTIONS WORKER
     │
     │ build + test
     ▼
ARCH ISO ARTIFACT
     │
     │ poll + download
     ▼
LOCAL CONTROLLER
     │
     │ checksum verification
     ▼
FINAL ISO
```

## Safety Features

- **Disk protection**: Never repartitions or formats without explicit confirmation
- **Storage monitoring**: Checks free space before every major operation
- **Remote builds**: ISO built on GitHub Actions, not your local machine
- **Checksum verification**: SHA256 verified after download
- **Build manifest**: Records commit, timestamp, package versions
- **Clean artifacts**: Local cleanup removes build artifacts after completion

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Push and create a pull request

## License

MIT License — see [LICENSE](LICENSE)

## Acknowledgments

- [Arch Linux](https://archlinux.org/) — The base distribution
- [archiso](https://gitlab.archlinux.org/archlinux/archiso) — The ISO build tool
- [Arch Wiki](https://wiki.archlinux.org/) — Comprehensive documentation
