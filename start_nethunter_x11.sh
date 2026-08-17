#!/usr/bin/env bash
# ==============================================================================
# Script Name : start_nethunter_x11.sh
# Description : Quick launcher for Kali NetHunter XFCE UI using Termux-X11
# ==============================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}======================================================"
echo "    Starting Kali NetHunter in Termux-X11 Desktop Mode"
echo -e "======================================================${NC}"

# 1. Install termux-x11 package if missing
if ! command -v termux-x11 >/dev/null 2>&1; then
    echo -e "${YELLOW}[+] Installing termux-x11-nightly package...${NC}"
    pkg install termux-x11-nightly -y
fi

# 2. Kill existing Termux-X11 instances
pkill -f termux-x11 || true
sleep 1

# 3. Start Termux-X11 server on DISPLAY :1
echo -e "${GREEN}[+] Starting Termux-X11 X server on DISPLAY :1...${NC}"
termux-x11 :1 -ac &
sleep 2

# 4. Attempt to open Termux-X11 App automatically
echo -e "${GREEN}[+] Opening Termux-X11 app...${NC}"
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true

# 5. Launch Kali XFCE Desktop inside NetHunter chroot
echo -e "${GREEN}[+] Launching Kali XFCE session...${NC}"
echo -e "${CYAN}Switch over to your Termux-X11 Android app now!${NC}"

nethunter -c "export DISPLAY=:1; export PULSE_SERVER=127.0.0.1; dbus-launch --exit-with-session xfce4-session"
