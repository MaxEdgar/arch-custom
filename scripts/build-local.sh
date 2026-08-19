#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Arch Custom — Local Build Script
# Fallback for building ISO locally. Requires Arch Linux or Docker.
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

BUILD_DIR="/tmp/archiso-build"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

info() { echo -e "${GREEN}→${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
die()  { echo -e "${RED}ERROR:${NC} $*"; exit 1; }

# ── Check Environment ────────────────────────────────────────────
echo -e "\n${CYAN}${BOLD}═══ Arch Custom Local Build ═══${NC}\n"

# Check disk space
FREE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
echo -e "Free disk space: ${FREE_SPACE}G"

if ((FREE_SPACE < 8)); then
    die "Insufficient disk space. Need at least 8GB free, have ${FREE_SPACE}G."
fi

# Check if running on Arch
if ! grep -q "Arch" /etc/os-release 2>/dev/null; then
    warn "Not running on Arch Linux. Attempting Docker build..."
    USE_DOCKER=true
else
    USE_DOCKER=false
fi

# ── Docker Build ─────────────────────────────────────────────────
if $USE_DOCKER; then
    if ! command -v docker &>/dev/null; then
        die "Docker not found. Install Docker or run on Arch Linux."
    fi

    info "Building ISO in Docker container..."

    docker run --rm \
        -v "$SCRIPT_DIR":/arch-custom \
        -v "$BUILD_DIR":/build \
        archlinux:latest \
        bash -c '
            pacman -Sy --noconfirm archiso git
            mkdir -p /build/work /build/out
            cp -r /arch-custom/archiso /build/archiso
            cd /build/archiso
            chmod +x airootfs/usr/bin/* 2>/dev/null || true
            mkarchiso -v -w /build/work -o /build/out profiles/arch-custom
        '

    ISO_FILE=$(find "$BUILD_DIR/out" -name "*.iso" -type f 2>/dev/null | head -1)
else
    # ── Direct Build ─────────────────────────────────────────────
    info "Building ISO directly..."

    # Check for archiso
    if ! pacman -Qs archiso &>/dev/null; then
        info "Installing archiso..."
        sudo pacman -S --noconfirm archiso
    fi

    # Setup build directory
    sudo mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    # Clone archiso if not present
    if [[ ! -d archiso ]]; then
        info "Cloning archiso..."
        git clone --depth 1 https://gitlab.archlinux.org/archlinux/archiso.git archiso
    fi

    # Copy our profile
    info "Copying profile..."
    cp -r "$SCRIPT_DIR/archiso" archiso/profiles/arch-custom
    chmod -R +x archiso/profiles/arch-custom/airootfs/usr/bin/ 2>/dev/null || true

    # Build
    info "Building ISO..."
    cd archiso
    sudo ./mkarchiso -v \
        -w "$BUILD_DIR/work" \
        -o "$BUILD_DIR/out" \
        profiles/arch-custom

    ISO_FILE=$(find "$BUILD_DIR/out" -name "*.iso" -type f 2>/dev/null | head -1)
fi

# ── Report ────────────────────────────────────────────────────────
if [[ -n "$ISO_FILE" && -f "$ISO_FILE" ]]; then
    ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)
    SHA256=$(sha256sum "$ISO_FILE" | cut -d' ' -f1)

    echo -e "\n${GREEN}${BOLD}═══ Build Complete ═══${NC}"
    echo -e "  ISO:     $(basename "$ISO_FILE")"
    echo -e "  Size:    $ISO_SIZE"
    echo -e "  SHA256:  $SHA256"
    echo -e "  Location: $ISO_FILE"

    # Generate checksum
    sha256sum "$ISO_FILE" > "${ISO_FILE}.sha256"
    info "Checksum saved: ${ISO_FILE}.sha256"
else
    die "Build failed. No ISO file produced."
fi
