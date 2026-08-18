#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Script Name : start_nethunter_x11.sh
# Repository  : AbuZar-Ansarii/AndroidLinux-GPU
# One-Liner   : bash <(curl -sL https://raw.githubusercontent.com/AbuZar-Ansarii/AndroidLinux-GPU/main/start_nethunter_x11.sh)
# Description : Robust launcher for Kali NetHunter Desktop on Termux-X11
# ==============================================================================

# Colors & Formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
cat << 'BANNER'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║        🐉  STARTING KALI NETHUNTER DESKTOP (X11) 🐉           ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

# ------------------------------------------------------------------------------
# 1. Locate NetHunter Container & Launcher
# ------------------------------------------------------------------------------
CHROOT=""
for DIR in "$HOME/kali-arm64" "$HOME/kali-armhf"; do
    if [ -d "$DIR" ] && { [ -f "$DIR/usr/bin/bash" ] || [ -f "$DIR/bin/bash" ]; }; then
        CHROOT="$DIR"
        break
    fi
done

if [ -z "$CHROOT" ]; then
    echo -e "${RED}[✘] Kali NetHunter is not installed yet!${NC}"
    echo -e "${YELLOW}Please run the installer script first:${NC}"
    echo -e "  ${CYAN}curl -sL https://raw.githubusercontent.com/AbuZar-Ansarii/AndroidLinux-GPU/main/install_nethunter_rootless.sh | bash${NC}"
    exit 1
fi

echo -e "${BLUE}[+] Located NetHunter container in ${WHITE}$CHROOT${NC}"

# ------------------------------------------------------------------------------
# 2. Check and Install Termux-X11 & PulseAudio in Termux
# ------------------------------------------------------------------------------
if ! command -v termux-x11 >/dev/null 2>&1; then
    echo -e "${YELLOW}[+] Installing Termux-X11 package in Termux...${NC}"
    pkg install -y x11-repo || true
    pkg update -y || true
    pkg install -y termux-x11-nightly || pkg install -y termux-x11 || true
fi

if ! command -v pulseaudio >/dev/null 2>&1; then
    echo -e "${YELLOW}[+] Installing PulseAudio in Termux...${NC}"
    pkg install -y pulseaudio || true
fi

# ------------------------------------------------------------------------------
# 3. Clean up any stale sessions
# ------------------------------------------------------------------------------
echo -e "${BLUE}[+] Cleaning up old X11 and Audio processes...${NC}"
pkill -9 -f "termux.x11" 2>/dev/null || true
pkill -9 -f "termux-x11" 2>/dev/null || true
pkill -9 -f "pulseaudio" 2>/dev/null || true
pkill -9 -f "xfce" 2>/dev/null || true
pkill -9 -f "dbus" 2>/dev/null || true
sleep 1

# ------------------------------------------------------------------------------
# 4. Prepare /tmp and X11 Socket Directories
# ------------------------------------------------------------------------------
TMP_DIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
mkdir -p "$TMP_DIR/.X11-unix" 2>/dev/null || true
chmod 1777 "$TMP_DIR" 2>/dev/null || true
chmod 1777 "$TMP_DIR/.X11-unix" 2>/dev/null || true

# Remove old lock/socket files
rm -f "$TMP_DIR/.X11-unix/X0" "$TMP_DIR/.X0-lock" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 5. Ensure NetHunter Launcher mounts Termux /tmp
# ------------------------------------------------------------------------------
LAUNCHER_PATH="$PREFIX/bin/nethunter"
SHORTCUT_PATH="$PREFIX/bin/nh"

cat > "$LAUNCHER_PATH" << 'LAUNCHER_EOF'
#!/data/data/com.termux/files/usr/bin/bash -e
cd "${HOME}"
unset LD_PRELOAD

if [ -d "${HOME}/kali-arm64" ]; then
    CHROOT="${HOME}/kali-arm64"
elif [ -d "${HOME}/kali-armhf" ]; then
    CHROOT="${HOME}/kali-armhf"
else
    echo "[!] Kali NetHunter directory not found!"
    exit 1
fi

if [ ! -f "$CHROOT/root/.version" ]; then
    touch "$CHROOT/root/.version" 2>/dev/null || true
fi

user="kali"
home="/home/$user"
start="sudo -u kali /bin/bash"

if ! grep -q "kali" "${CHROOT}/etc/passwd" 2>/dev/null || [[ "$#" != "0" && ("$1" == "-r" || "$1" == "-R") ]]; then
    user="root"
    home="/$user"
    start="/bin/bash --login"
    if [[ "$#" != "0" && ("$1" == "-r" || "$1" == "-R") ]]; then
        shift
    fi
fi

TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
mkdir -p "$TERMUX_TMP/.X11-unix" 2>/dev/null || true
chmod 1777 "$TERMUX_TMP" 2>/dev/null || true
chmod 1777 "$TERMUX_TMP/.X11-unix" 2>/dev/null || true

cmdline="proot \
        --link2symlink \
        -0 \
        -r $CHROOT \
        -b /dev \
        -b /proc \
        -b /sdcard \
        -b $TERMUX_TMP:/tmp \
        -b $CHROOT$home:/dev/shm \
        -w $home \
        /usr/bin/env -i \
        HOME=$home \
        PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin \
        TERM=$TERM \
        LANG=C.UTF-8 \
        $start"

cmd="$@"
if [ "$#" == "0" ]; then
    exec $cmdline
else
    $cmdline -c "$cmd"
fi
LAUNCHER_EOF
chmod 755 "$LAUNCHER_PATH"
ln -sf "$LAUNCHER_PATH" "$SHORTCUT_PATH"

# ------------------------------------------------------------------------------
# 6. Fix Kali Sudo, DBus, & Disable XFWM4 Compositor (Fixes Black Screen)
# ------------------------------------------------------------------------------
echo -e "${BLUE}[+] Applying XFCE display & DBus optimizations...${NC}"

# Fix Kali sudo permissions
chmod +s "$CHROOT/usr/bin/sudo" 2>/dev/null || true
chmod +s "$CHROOT/usr/bin/su" 2>/dev/null || true
mkdir -p "$CHROOT/etc/sudoers.d"
echo "kali    ALL=(ALL:ALL) ALL" > "$CHROOT/etc/sudoers.d/kali" 2>/dev/null || true
chmod 0440 "$CHROOT/etc/sudoers.d/kali" 2>/dev/null || true

# Ensure machine-id exists for DBus
mkdir -p "$CHROOT/var/lib/dbus" "$CHROOT/etc"
if [ ! -s "$CHROOT/etc/machine-id" ]; then
    echo "0123456789abcdef0123456789abcdef" > "$CHROOT/etc/machine-id" 2>/dev/null || true
    ln -sf /etc/machine-id "$CHROOT/var/lib/dbus/machine-id" 2>/dev/null || true
fi

# Pre-configure XFWM4 Compositor OFF to eliminate black screen
mkdir -p "$CHROOT/home/kali/.config/xfce4/xfconf/xfce-perchannel-xml"
mkdir -p "$CHROOT/root/.config/xfce4/xfconf/xfce-perchannel-xml"

cat > "$CHROOT/home/kali/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" << 'XFWM_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
  </property>
</channel>
XFWM_EOF
cp -f "$CHROOT/home/kali/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" "$CHROOT/root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" 2>/dev/null || true

# Fix user ownership
"$SHORTCUT_PATH" -r "chown -R kali:kali /home/kali" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 7. Start PulseAudio Server in Termux
# ------------------------------------------------------------------------------
echo -e "${BLUE}[+] Starting PulseAudio sound server...${NC}"
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 2>/dev/null || true

# ------------------------------------------------------------------------------
# 8. Start Termux-X11 Server on DISPLAY :0
# ------------------------------------------------------------------------------
echo -e "${GREEN}[+] Starting Termux-X11 display server on DISPLAY :0...${NC}"
termux-x11 :0 -ac &
X11_PID=$!

# Wait for X11 socket to initialize
COUNT=0
while [ ! -S "$TMP_DIR/.X11-unix/X0" ] && [ $COUNT -lt 15 ]; do
    sleep 0.2
    COUNT=$((COUNT + 1))
done

# ------------------------------------------------------------------------------
# 9. Launch Termux-X11 Android App
# ------------------------------------------------------------------------------
echo -e "${GREEN}[+] Launching Termux-X11 app...${NC}"
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true

# ------------------------------------------------------------------------------
# 10. Start Kali NetHunter Desktop Session
# ------------------------------------------------------------------------------
echo ""
echo -e "${CYAN}${BOLD}=================================================================="
echo "  🚀 Kali NetHunter XFCE4 Desktop is Starting!"
echo "  📱 Switch to the Termux-X11 app to view your desktop!"
echo -e "==================================================================${NC}"
echo ""

# Launch XFCE inside Kali via PRoot
"$SHORTCUT_PATH" "
    export DISPLAY=:0
    export PULSE_SERVER=127.0.0.1
    export XDG_RUNTIME_DIR=/tmp
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
    export MESA_GL_VERSION_OVERRIDE=3.3
    export MESA_GLES_VERSION_OVERRIDE=3.0

    # Ensure desktop packages are installed
    if ! command -v xfce4-session >/dev/null 2>&1; then
        echo '[!] XFCE Desktop packages not found inside Kali. Installing...'
        sudo apt update && sudo apt install -y xfce4 xfce4-terminal dbus-x11
    fi

    # Disable compositor dynamically if xfconf is active
    xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true

    # Start XFCE Desktop Session with DBus
    dbus-launch --exit-with-session startxfce4
"

# ------------------------------------------------------------------------------
# 11. Cleanup upon exit
# ------------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}[*] NetHunter Desktop session ended. Cleaning up...${NC}"
pkill -9 -f "termux.x11" 2>/dev/null || true
pkill -9 -f "termux-x11" 2>/dev/null || true
pkill -9 -f "pulseaudio" 2>/dev/null || true
echo -e "${GREEN}[✔] Cleaned up successfully.${NC}"
