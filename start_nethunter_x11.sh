#!/usr/bin/env bash
# ==============================================================================
# Script Name : start_nethunter_x11.sh
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

# 1. Enable x11-repo and install termux-x11-nightly if missing
if ! command -v termux-x11 >/dev/null 2>&1; then
    echo -e "${YELLOW}[+] Enabling x11-repo and installing termux-x11-nightly...${NC}"
    pkg install x11-repo -y
    pkg install termux-x11-nightly -y
fi

# 2. Ensure X11 socket directory exists with proper permissions
TMP_X11_DIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X11-unix"
mkdir -p "$TMP_X11_DIR"
chmod 1777 "$TMP_X11_DIR" 2>/dev/null || true

# 3. Kill any old Termux-X11 instances
pkill -f termux-x11 || true
sleep 1

# 4. Start Termux-X11 server on DISPLAY :1
echo -e "${GREEN}[+] Starting Termux-X11 X server on DISPLAY :1...${NC}"
termux-x11 :1 -ac &
sleep 2

# 5. Open Termux-X11 Android app
echo -e "${GREEN}[+] Opening Termux-X11 app...${NC}"
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true

# 6. Check and launch Desktop inside NetHunter
echo -e "${GREEN}[+] Launching Kali XFCE Desktop session...${NC}"

nethunter -c "
if ! command -v xfce4-session >/dev/null 2>&1; then
    echo '[+] XFCE Desktop not found inside Kali. Installing xfce4 & dbus-x11...'
    apt update && apt install -y xfce4 xfce4-terminal dbus-x11
fi
export DISPLAY=:1
export PULSE_SERVER=127.0.0.1
dbus-launch --exit-with-session xfce4-session
"
