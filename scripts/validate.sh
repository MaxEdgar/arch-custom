#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Arch Custom — Validation Script
# Verifies the ISO and installed system meet requirements.
# ═══════════════════════════════════════════════════════════════════
set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

pass() { echo -e "  ${GREEN}✓${NC} $*"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}✗${NC} $*"; FAIL=$((FAIL + 1)); }
warn() { echo -e "  ${YELLOW}!${NC} $*"; WARN=$((WARN + 1)); }

echo -e "\n${CYAN}${BOLD}═══ Arch Custom ISO Validation ═══${NC}\n"

# ── 1. Check for ISO ─────────────────────────────────────────────
echo -e "${BOLD}1. ISO File${NC}"
ISO_FILE=$(find . -name "*.iso" -type f 2>/dev/null | head -1)
if [[ -n "$ISO_FILE" ]]; then
    pass "ISO found: $ISO_FILE"
    ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)
    echo -e "     Size: $ISO_SIZE"

    # Size check
    ISO_BYTES=$(stat -c%s "$ISO_FILE")
    if ((ISO_BYTES > 1073741824)); then
        warn "ISO is larger than 1GB ($ISO_SIZE)"
    elif ((ISO_BYTES < 104857600)); then
        warn "ISO is smaller than 100MB ($ISO_SIZE)"
    else
        pass "ISO size is reasonable ($ISO_SIZE)"
    fi
else
    fail "No ISO file found"
fi

# ── 2. Check ISO structure ───────────────────────────────────────
echo -e "\n${BOLD}2. ISO Structure${NC}"
if [[ -n "$ISO_FILE" ]]; then
    # Check El Torito header
    if file "$ISO_FILE" | grep -q "ISO 9660"; then
        pass "Valid ISO 9660 filesystem"
    else
        fail "Not a valid ISO 9660 filesystem"
    fi

    # Check for required files
    for f in "arch/boot/x86_64/vmlinuz-linux" "arch/boot/x86_64/initramfs-linux.img"; do
        if isoinfo -l -i "$ISO_FILE" 2>/dev/null | grep -q "$f"; then
            pass "Contains $f"
        else
            warn "Cannot verify $f (isoinfo not available)"
        fi
    done
fi

# ── 3. Check checksums ───────────────────────────────────────────
echo -e "\n${BOLD}3. Checksums${NC}"
SHA_FILE=$(find . -name "*.sha256" -type f 2>/dev/null | head -1)
if [[ -n "$SHA_FILE" ]]; then
    if sha256sum -c "$SHA_FILE" 2>/dev/null; then
        pass "SHA256 checksum verified"
    else
        fail "SHA256 checksum verification failed"
    fi
else
    warn "No SHA256 checksum file found"
fi

# ── 4. Check packages ────────────────────────────────────────────
echo -e "\n${BOLD}4. Package List${NC}"
PKG_FILE="archiso/packages.x86_64"
if [[ -f "$PKG_FILE" ]]; then
    PKG_COUNT=$(grep -v '^#' "$PKG_FILE" | grep -v '^$' | wc -l)
    pass "Package list exists ($PKG_COUNT packages)"

    # Check for essential packages
    for pkg in base linux systemd networkmanager grub; do
        if grep -q "^$pkg$" "$PKG_FILE"; then
            pass "Essential package: $pkg"
        else
            fail "Missing essential package: $pkg"
        fi
    done

    # Check for bloat
    BLOAT_PKGS=$(grep -E '(firefox|chromium|thunderbird|libreoffice|gimp|blender|steam)' "$PKG_FILE" 2>/dev/null | wc -l)
    if [[ "$BLOAT_PKGS" -gt 0 ]]; then
        warn "Found $BLOAT_PKGS potentially bloated packages"
    else
        pass "No obvious bloat in package list"
    fi
else
    fail "Package list not found"
fi

# ── 5. Check installer ───────────────────────────────────────────
echo -e "\n${BOLD}5. Installer${NC}"
INSTALLER="archiso/airootfs/usr/bin/arch-install"
if [[ -f "$INSTALLER" ]]; then
    pass "Installer script exists"

    # Check for required features
    for feature in "step_keyboard" "step_locale" "step_timezone" "step_hostname" "step_user" "step_rootpw" "step_network" "step_disk" "step_partition" "step_filesystem" "step_swap" "step_bootloader" "step_kernel" "step_microcode" "step_gpu" "step_audio" "step_desktop" "step_packages" "step_review" "perform_install"; do
        if grep -q "$feature" "$INSTALLER"; then
            pass "Installer has: $feature"
        else
            fail "Installer missing: $feature"
        fi
    done

    # Check for safety features
    if grep -q "confirm" "$INSTALLER"; then
        pass "Installer has confirmation prompts"
    else
        fail "Installer missing confirmation prompts"
    fi

    if grep -q "disk.*WARNING\|WARNING.*disk" "$INSTALLER"; then
        pass "Installer has disk warning"
    else
        warn "Installer disk warning may be insufficient"
    fi
else
    fail "Installer not found"
fi

# ── 6. Check CLI ─────────────────────────────────────────────────
echo -e "\n${BOLD}6. CLI Status Display${NC}"
CLI="archiso/airootfs/usr/bin/arch-status"
if [[ -f "$CLI" ]]; then
    pass "Status display exists"

    for feature in "show_cpu" "show_ram" "show_wifi" "show_battery" "show_disk" "show_network_io"; do
        if grep -q "$feature" "$CLI"; then
            pass "Status has: $feature"
        else
            fail "Status missing: $feature"
        fi
    done
else
    fail "Status display not found"
fi

# ── 7. Check shell config ────────────────────────────────────────
echo -e "\n${BOLD}7. Shell Configuration${NC}"
for shell_conf in "archiso/airootfs/etc/skel/.bashrc" "archiso/airootfs/etc/skel/.zshrc"; do
    if [[ -f "$shell_conf" ]]; then
        pass "$(basename "$shell_conf") exists"

        # Check for performance settings
        if grep -q "HISTSIZE\|SAVEHIST" "$shell_conf"; then
            pass "$(basename "$shell_conf") has history settings"
        fi
    else
        fail "$(basename "$shell_conf") not found"
    fi
done

# ── 8. Check systemd configs ─────────────────────────────────────
echo -e "\n${BOLD}8. Systemd Configuration${NC}"
SYSD_CONF="archiso/airootfs/etc/systemd/system.conf.d/performance.conf"
if [[ -f "$SYSD_CONF" ]]; then
    pass "Systemd performance config exists"
    if grep -q "DefaultTimeoutStartSec" "$SYSD_CONF"; then
        pass "Timeout optimization present"
    fi
else
    warn "Systemd performance config not found"
fi

# ── 9. Check sysctl ──────────────────────────────────────────────
echo -e "\n${BOLD}9. Kernel Tuning${NC}"
SYSCTL="archiso/airootfs/etc/sysctl.d/99-arch-custom.conf"
if [[ -f "$SYSCTL" ]]; then
    pass "Sysctl config exists"
    for param in "vm.swappiness" "net.core.rmem_max" "fs.file-max"; do
        if grep -q "$param" "$SYSCTL"; then
            pass "Tuned: $param"
        fi
    done
else
    warn "Sysctl config not found"
fi

# ── 10. Check GitHub Actions ─────────────────────────────────────
echo -e "\n${BOLD}10. GitHub Actions${NC}"
WF=".github/workflows/build-iso.yml"
if [[ -f "$WF" ]]; then
    pass "Build workflow exists"

    if grep -q "upload-artifact" "$WF"; then
        pass "Artifact upload configured"
    else
        fail "Missing artifact upload"
    fi

    if grep -q "sha256sum" "$WF"; then
        pass "Checksum generation configured"
    else
        warn "Checksum generation may be missing"
    fi
else
    fail "Build workflow not found"
fi

# ── Summary ──────────────────────────────────────────────────────
echo -e "\n${CYAN}${BOLD}═══ Validation Summary ═══${NC}\n"
echo -e "  ${GREEN}Passed:${NC} $PASS"
echo -e "  ${YELLOW}Warnings:${NC} $WARN"
echo -e "  ${RED}Failed:${NC} $FAIL"
echo ""

TOTAL=$((PASS + FAIL + WARN))
if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}✅ All critical checks passed!${NC}"
    exit 0
else
    echo -e "${RED}${BOLD}❌ $FAIL critical checks failed.${NC}"
    exit 1
fi
