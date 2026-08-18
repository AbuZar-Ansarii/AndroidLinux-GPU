#!/usr/bin/env bash
# ==============================================================================
# Script Name : install_nethunter_rootless.sh
# Repository  : AbuZar-Ansarii/AndroidLinux-GPU
# One-Liner   : curl -sL https://raw.githubusercontent.com/AbuZar-Ansarii/AndroidLinux-GPU/main/install_nethunter_rootless.sh | bash
# Description : Fully automated single-command installer for Kali NetHunter Rootless on Termux
# ==============================================================================

set -e

# Colors & Formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "=================================================================="
    echo "    Kali NetHunter Rootless Automated Installer (Termux)"
    echo "    Repo: AbuZar-Ansarii/AndroidLinux-GPU"
    echo "=================================================================="
    echo -e "${NC}"
}

print_info() { echo -e "${BLUE}[+] $1${NC}"; }
print_success() { echo -e "${GREEN}[✔] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[!] $1${NC}"; }
print_error() { echo -e "${RED}[✘] $1${NC}"; }

# ------------------------------------------------------------------------------
# 1. Environment & Storage Setup
# ------------------------------------------------------------------------------
print_header

print_info "Requesting Termux storage permissions..."
if command -v termux-setup-storage >/dev/null 2>&1; then
    termux-setup-storage || true
    sleep 1
fi

# ------------------------------------------------------------------------------
# 2. Package Updates & Prerequisites Installation
# ------------------------------------------------------------------------------
print_info "Updating Termux repositories and installing all dependencies..."
export DEBIAN_FRONTEND=noninteractive

pkg update -y >/dev/null 2>&1 || pkg update -y
pkg install -y x11-repo >/dev/null 2>&1 || pkg install -y x11-repo
pkg install -y proot tar axel xz-utils wget curl termux-x11-nightly xwayland >/dev/null 2>&1 || pkg install -y proot tar axel xz-utils wget curl termux-x11-nightly xwayland

print_success "All Termux prerequisites installed successfully."

# ------------------------------------------------------------------------------
# 3. Clean Incomplete Previous Attempts
# ------------------------------------------------------------------------------
cd "$HOME"
for CHROOT_DIR in kali-arm64 kali-armhf; do
    if [ -d "$CHROOT_DIR" ] && [ ! -f "$CHROOT_DIR/usr/bin/bash" ]; then
        print_warning "Incomplete rootfs directory found ($CHROOT_DIR). Cleaning up..."
        rm -rf "$CHROOT_DIR"
    fi
done

# ------------------------------------------------------------------------------
# 4. Download Official NetHunter Installer Script
# ------------------------------------------------------------------------------
INSTALLER="install-nethunter-termux"
OFFICIAL_URL="https://offs.ec/2MceZWr"
FALLBACK_URL="https://offsec.com/nethunter-installer"

print_info "Downloading official Kali NetHunter installer script..."
rm -f "$INSTALLER"

if wget -q --no-check-certificate "$OFFICIAL_URL" -O "$INSTALLER"; then
    print_success "Official installer downloaded successfully."
elif wget -q --no-check-certificate "$FALLBACK_URL" -O "$INSTALLER"; then
    print_success "Official installer downloaded from fallback mirror."
else
    print_error "Download failed. Please check your internet connection."
    exit 1
fi

chmod +x "$INSTALLER"

# ------------------------------------------------------------------------------
# 5. Launch Official Installer Interactively
# ------------------------------------------------------------------------------
echo ""
print_info "Launching Kali NetHunter Setup..."
print_info "Select your edition (1: Full, 2: Minimal, 3: Nano) in the prompt below:"
echo ""

if [ -c /dev/tty ]; then
    ./"$INSTALLER" < /dev/tty
else
    ./"$INSTALLER"
fi

# ------------------------------------------------------------------------------
# 6. Post-Installation Summary & Guidance
# ------------------------------------------------------------------------------
echo ""
echo -e "${GREEN}${BOLD}=================================================================="
echo "    Kali NetHunter Rootless Setup Completed!"
echo -e "==================================================================${NC}"
echo -e "${BOLD}Quick Usage Commands:${NC}"
echo -e "  • Start NetHunter CLI:         ${CYAN}nethunter${NC} or ${CYAN}nh${NC}"
echo -e "  • Start NetHunter as Root:     ${CYAN}nethunter -r${NC} or ${CYAN}nh -r${NC}"
echo -e "  • Start Desktop (Termux-X11):  ${CYAN}bash <(curl -sL https://raw.githubusercontent.com/AbuZar-Ansarii/AndroidLinux-GPU/main/start_nethunter_x11.sh)${NC}"
echo -e "=================================================================="
echo -e "${YELLOW}${BOLD}[!] ATTENTION ANDROID 12, 13, 14, 15, 16+ USERS:${NC}"
echo -e "If NetHunter closes automatically with '[Process completed - signal 9]',"
echo -e "run these ADB commands once via Wireless Debugging / PC ADB:"
echo -e "  ${CYAN}adb shell device_config put activity_manager max_phantom_processes 2147483647${NC}"
echo -e "  ${CYAN}adb shell settings put global settings_enable_monitor_phantom_procs false${NC}"
echo -e "=================================================================="
