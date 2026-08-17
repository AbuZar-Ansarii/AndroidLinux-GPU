#!/usr/bin/env bash
# ==============================================================================
# Script Name : start_nethunter_x11.sh
# Description : Robust launcher for Kali NetHunter XFCE UI on Termux-X11
# ==============================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}======================================================"
echo "    Starting Kali NetHunter in Termux-X11 Desktop Mode"
echo -e "======================================================${NC}"

# 1. Enable x11-repo & install termux-x11 dependencies if missing
if ! command -v termux-x11 >/dev/null 2>&1; then
    echo -e "${YELLOW}[+] Installing x11-repo, termux-x11-nightly, and xwayland...${NC}"
    pkg install x11-repo -y
    pkg install termux-x11-nightly xwayland -y
fi

# 2. Stop any running Termux-X11 server instances
pkill -f termux-x11 || true
sleep 1

# 3. Create & authorize X11 socket locations for PRoot
TMP_DIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
mkdir -p "$TMP_DIR/.X11-unix"
chmod 1777 "$TMP_DIR/.X11-unix"

mkdir -p /tmp/.X11-unix 2>/dev/null || true
chmod 1777 /tmp/.X11-unix 2>/dev/null || true

# 4. Start Termux-X11 server on DISPLAY :1 with legacy drawing fallback support
echo -e "${GREEN}[+] Starting Termux-X11 server on DISPLAY :1...${NC}"
termux-x11 :1 -ac &
sleep 2

# 5. Open Termux-X11 Android App automatically
echo -e "${GREEN}[+] Opening Termux-X11 app...${NC}"
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true

# 6. Launch Kali XFCE Desktop using NetHunter exec (bypasses .bashrc reset)
echo -e "${GREEN}[+] Launching Kali XFCE Desktop session...${NC}"
echo -e "${CYAN}Switch to your Termux-X11 app to view your desktop!${NC}"

nethunter exec env DISPLAY=:1 PULSE_SERVER=127.0.0.1 dbus-launch --exit-with-session xfce4-session
