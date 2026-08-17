#!/usr/bin/env bash
# ==============================================================================
# Script Name : install_nethunter_rootless.sh
# Repository  : AbuZar-Ansarii/AndroidLinux-GPU
# One-Liner   : bash <(curl -sL https://raw.githubusercontent.com/AbuZar-Ansarii/AndroidLinux-GPU/main/install_nethunter_rootless.sh)
#               OR
#               curl -sL https://raw.githubusercontent.com/AbuZar-Ansarii/AndroidLinux-GPU/main/install_nethunter_rootless.sh | bash
# Description : Fully automated single-command installer for Kali NetHunter Rootless on Termux
# ==============================================================================

set -e

# Terminal Colors
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

print_info "Setting up storage permission..."
if command -v termux-setup-storage >/dev/null 2>&1; then
    termux-setup-storage || true
    sleep 1
fi

# ------------------------------------------------------------------------------
# 2. Package Updates & Prerequisites
# ------------------------------------------------------------------------------
print_info "Updating Termux packages and installing dependencies (x11-repo, wget, proot, tar, curl, termux-x11)..."
export DEBIAN_FRONTEND=noninteractive
pkg update -y >/dev/null 2>&1 || pkg update -y
pkg install -y x11-repo >/dev/null 2>&1 || pkg install -y x11-repo
pkg install -y wget proot tar curl termux-x11-nightly >/dev/null 2>&1 || pkg install -y wget proot tar curl termux-x11-nightly

print_success "Dependencies installed successfully."

# ------------------------------------------------------------------------------
# 3. Download Official NetHunter Installer Script
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
# 4. Interactive Version Selection Menu
# ------------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}${BOLD}Select Kali NetHunter Image Edition to Install:${NC}"
echo -e "  ${CYAN}[1] Full${NC}     - Complete Kali toolkit (~1.6GB download / ~8GB installed) ${GREEN}[Recommended]${NC}"
echo -e "  ${CYAN}[2] Minimal${NC}  - Essential CLI penetration testing tools (~900MB download)"
echo -e "  ${CYAN}[3] Nano${NC}     - Bare minimum lightweight image (~500MB download)"
echo ""

# Read from /dev/tty if stdin is piped
if [ -c /dev/tty ]; then
    read -p "Enter your choice [1-3] (Default: 1): " CHOICE < /dev/tty
else
    read -p "Enter your choice [1-3] (Default: 1): " CHOICE
fi

CHOICE=${CHOICE:-1}

case "$CHOICE" in
    1)
        IMAGE_TYPE="1"
        EDITION_NAME="Full"
        ;;
    2)
        IMAGE_TYPE="2"
        EDITION_NAME="Minimal"
        ;;
    3)
        IMAGE_TYPE="3"
        EDITION_NAME="Nano"
        ;;
    *)
        print_warning "Invalid selection. Defaulting to [1] Full Edition."
        IMAGE_TYPE="1"
        EDITION_NAME="Full"
        ;;
esac

print_info "Selected: ${BOLD}${EDITION_NAME} Edition${NC}"
print_info "Starting NetHunter installation... Please wait."
echo ""

# ------------------------------------------------------------------------------
# 5. Launch Installer with Selected Option
# ------------------------------------------------------------------------------
# Pipe choice to installer so it installs without hanging
echo "$IMAGE_TYPE" | ./"$INSTALLER"

# ------------------------------------------------------------------------------
# 6. Post-Installation Summary & Usage
# ------------------------------------------------------------------------------
echo ""
echo -e "${GREEN}${BOLD}=================================================================="
echo "    Kali NetHunter Rootless Setup Completed Successfully!"
echo -e "==================================================================${NC}"
echo -e "${BOLD}Quick Usage Commands:${NC}"
echo -e "  • Start NetHunter CLI:         ${CYAN}nethunter${NC} or ${CYAN}nh${NC}"
echo -e "  • Start NetHunter as Root:     ${CYAN}nethunter -r${NC} or ${CYAN}nh -r${NC}"
echo -e "  • Setup Desktop (KeX) Pass:    ${CYAN}nethunter kex passwd${NC}"
echo -e "  • Launch Desktop (KeX):        ${CYAN}nethunter kex &${NC}"
echo -e "  • Stop Desktop (KeX):          ${CYAN}nethunter kex stop${NC}"
echo -e "=================================================================="
echo -e "${YELLOW}${BOLD}[!] ATTENTION ANDROID 12, 13, 14, 15, 16+ USERS:${NC}"
echo -e "If NetHunter closes/stops automatically with '[Process completed - signal 9]',"
echo -e "disable Android's Phantom Process Killer via Wireless Debugging / ADB:"
echo -e "  ${CYAN}adb shell device_config put activity_manager max_phantom_processes 2147483647${NC}"
echo -e "  ${CYAN}adb shell settings put global settings_enable_monitor_phantom_procs false${NC}"
echo -e "=================================================================="

