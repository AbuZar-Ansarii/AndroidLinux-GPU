#!/usr/bin/env bash
# ==============================================================================
# Script Name : install_nethunter_rootless.sh
# Description : Automated installer for Kali Linux NetHunter (Rootless) in Termux
# Target OS   : Android (via Termux)
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
    echo "========================================================"
    echo "    Kali NetHunter Rootless Setup Helper for Termux"
    echo "========================================================"
    echo -e "${NC}"
}

print_info() {
    echo -e "${BLUE}[I] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[✔] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_error() {
    echo -e "${RED}[✘] $1${NC}"
}

# 1. Environment Check
print_header
print_info "Checking environment..."

if [ -z "$TERMUX_VERSION" ] && [ ! -d "/data/data/com.termux" ]; then
    print_warning "Warning: This script is intended to be executed inside Termux on Android."
    read -p "Do you want to continue anyway? (y/N): " choice
    case "$choice" in 
        [yY][eE][sS]|[yY]) 
            print_info "Proceeding with setup..."
            ;;
        *)
            print_error "Aborted by user."
            exit 1
            ;;
    esac
fi

# 2. Grant Termux Storage Permission
print_info "Requesting storage permissions (allow prompt on your screen if shown)..."
if command -v termux-setup-storage >/dev/null 2>&1; then
    termux-setup-storage || true
    sleep 2
fi

# 3. Update Termux Packages & Install Dependencies
print_info "Updating Termux packages & installing prerequisites (wget, proot)..."
pkg update -y && pkg upgrade -y
pkg install -y wget proot tar

print_success "Prerequisites installed successfully."

# 4. Download Official NetHunter Installer
INSTALLER_NAME="install-nethunter-termux"
PRIMARY_URL="https://offsec.com/nethunter-installer"
FALLBACK_URL="https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project/-/raw/master/nethunter-rootless/install-nethunter-termux"

print_info "Downloading official Kali NetHunter installer..."

if [ -f "$INSTALLER_NAME" ]; then
    print_warning "Existing installer found ($INSTALLER_NAME). Overwriting..."
    rm -f "$INSTALLER_NAME"
fi

if wget --no-check-certificate "$PRIMARY_URL" -O "$INSTALLER_NAME"; then
    print_success "Downloaded installer successfully from primary mirror."
elif wget --no-check-certificate "$FALLBACK_URL" -O "$INSTALLER_NAME"; then
    print_success "Downloaded installer successfully from fallback mirror."
else
    print_error "Failed to download installer script. Check your internet connection."
    exit 1
fi

chmod +x "$INSTALLER_NAME"

# 5. Execution Banner
echo ""
echo -e "${GREEN}${BOLD}========================================================"
echo "    Setup Ready to Run Official Installer"
echo -e "========================================================${NC}"
echo -e "${CYAN}The installer will prompt you to select an image version:"
echo -e " 1) Full     (Recommended for complete Kali toolkit)"
echo -e " 2) Minimal  (Basic CLI tools, lower download size)"
echo -e " 3) Nano     (Lightest version)"
echo -e "========================================================${NC}"
echo ""

read -p "Would you like to start the installation now? (Y/n): " RUN_NOW
RUN_NOW=${RUN_NOW:-Y}

case "$RUN_NOW" in
    [yY][eE][sS]|[yY])
        print_info "Launching official NetHunter installer..."
        ./"$INSTALLER_NAME"
        ;;
    *)
        print_info "Installer saved as ./${INSTALLER_NAME}."
        print_info "To run manually later, execute: ./${INSTALLER_NAME}"
        exit 0
        ;;
esac

# 6. Usage Instructions Post-Install
echo ""
echo -e "${GREEN}${BOLD}========================================================"
echo "    Kali NetHunter Rootless Setup Complete!"
echo -e "========================================================${NC}"
echo -e "${BOLD}Quick Command Reference:${NC}"
echo -e "  • Start NetHunter CLI:      ${CYAN}nethunter${NC} or ${CYAN}nh${NC}"
echo -e "  • Start NetHunter as root:  ${CYAN}nethunter -r${NC} or ${CYAN}nh -r${NC}"
echo -e "  • Set Desktop (KeX) Pass:   ${CYAN}nethunter kex passwd${NC}"
echo -e "  • Start Desktop (KeX):      ${CYAN}nethunter kex &${NC}"
echo -e "  • Stop Desktop (KeX):       ${CYAN}nethunter kex stop${NC}"
echo -e "========================================================"
