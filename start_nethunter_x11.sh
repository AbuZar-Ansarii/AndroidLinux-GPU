#!/usr/bin/env bash
# ==============================================================================
# Script Name : start_nethunter_x11.sh
# Repository  : AbuZar-Ansarii/AndroidLinux-GPU
# One-Liner   : bash <(curl -sL https://raw.githubusercontent.com/AbuZar-Ansarii/AndroidLinux-GPU/main/start_nethunter_x11.sh)
# Description : Robust launcher for Kali NetHunter XFCE UI on Termux-X11
# ==============================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}======================================================"
echo "    Starting Kali NetHunter in Termux-X11 Desktop Mode"
echo -e "======================================================${NC}"

# 1. Enable x11-repo & install termux-x11 dependencies in Termux if missing
if ! command -v termux-x11 >/dev/null 2>&1; then
    echo -e "${YELLOW}[+] Installing x11-repo, termux-x11-nightly, and xwayland...${NC}"
    pkg install x11-repo -y
    pkg install termux-x11-nightly xwayland -y
fi

# 2. Stop any running Termux-X11 server instances
pkill -f termux-x11 || true
sleep 1

# 3. Create & authorize X11 socket directory in Termux
TMP_DIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
mkdir -p "$TMP_DIR/.X11-unix"
chmod 1777 "$TMP_DIR/.X11-unix"
mkdir -p /tmp/.X11-unix 2>/dev/null || true
chmod 1777 /tmp/.X11-unix 2>/dev/null || true

# 4. Start Termux-X11 server on DISPLAY :1 with legacy drawing (fixes black screen)
echo -e "${GREEN}[+] Starting Termux-X11 X server on DISPLAY :1...${NC}"
termux-x11 :1 -ac -legacy-drawing &
sleep 2

# 5. Sync X11 sockets into Kali rootfs container
echo -e "${GREEN}[+] Syncing display socket to Kali environment...${NC}"
for CHROOT in "$HOME/kali-arm64" "$HOME/kali-armhf"; do
    if [ -d "$CHROOT" ]; then
        mkdir -p "$CHROOT/tmp/.X11-unix"
        chmod 1777 "$CHROOT/tmp/.X11-unix"
        cp -rf "$TMP_DIR/.X11-unix/"* "$CHROOT/tmp/.X11-unix/" 2>/dev/null || true
    fi
done

# 6. Pre-check XFCE Desktop inside Kali; install if missing
if command -v nh >/dev/null 2>&1 || command -v nethunter >/dev/null 2>&1; then
    NH_CMD="nh"
    command -v nh >/dev/null 2>&1 || NH_CMD="nethunter"

    if ! $NH_CMD exec command -v xfce4-session >/dev/null 2>&1; then
        echo -e "${YELLOW}[!] XFCE Desktop not installed inside Kali. Installing (first-time setup)...${NC}"
        $NH_CMD -r exec apt update
        $NH_CMD -r exec apt install -y xfce4 xfce4-terminal dbus-x11
    fi
else
    echo -e "${RED}[✘] NetHunter is not installed yet. Run the installation script first:${NC}"
    echo -e "    curl -sL https://raw.githubusercontent.com/AbuZar-Ansarii/AndroidLinux-GPU/main/install_nethunter_rootless.sh | bash"
    exit 1
fi

# 7. Open Termux-X11 Android App
echo -e "${GREEN}[+] Opening Termux-X11 app...${NC}"
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true

# 8. Launch Kali XFCE Desktop session
echo -e "${GREEN}[+] Launching Kali XFCE Desktop session...${NC}"
echo -e "${CYAN}Switch to your Termux-X11 app to view your desktop!${NC}"

$NH_CMD exec env DISPLAY=:1 PULSE_SERVER=127.0.0.1 dbus-launch --exit-with-session xfce4-session
