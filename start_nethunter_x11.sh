#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Script Name : start_nethunter_x11.sh
# Repository  : AbuZar-Ansarii/AndroidLinux-GPU
# One-Liner   : bash <(curl -sL https://raw.githubusercontent.com/AbuZar-Ansarii/AndroidLinux-GPU/main/start_nethunter_x11.sh)
# Description : Robust launcher for Kali NetHunter XFCE Desktop on Termux-X11 & KeX
# ==============================================================================

# Colors & Formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

clear
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
# 1. Locate NetHunter Container
# ------------------------------------------------------------------------------
CHROOT=""
for DIR in "$HOME/kali-arm64" "$HOME/kali-armhf"; do
    if [ -d "$DIR" ] && { [ -f "$DIR/usr/bin/bash" ] || [ -f "$DIR/bin/bash" ]; }; then
        CHROOT="$DIR"
        break
    fi
done

if [ -z "$CHROOT" ]; then
    echo -e "${RED}[✘] Kali NetHunter rootfs not found!${NC}"
    echo -e "${YELLOW}Please install NetHunter first by running:${NC}"
    echo -e "  ${CYAN}curl -sL https://raw.githubusercontent.com/AbuZar-Ansarii/AndroidLinux-GPU/main/install_nethunter_rootless.sh | bash${NC}"
    exit 1
fi

echo -e "${BLUE}[+] NetHunter container detected at: ${WHITE}$CHROOT${NC}"

# ------------------------------------------------------------------------------
# 2. Termux Configuration & Permissions
# ------------------------------------------------------------------------------
mkdir -p "$HOME/.termux"
if ! grep -q "allow-external-apps" "$HOME/.termux/termux.properties" 2>/dev/null; then
    echo "allow-external-apps = true" >> "$HOME/.termux/termux.properties"
    termux-reload-settings 2>/dev/null || true
fi

# Install Termux-X11 & PulseAudio in Termux if missing
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
# 3. Clean Previous Stale Sessions
# ------------------------------------------------------------------------------
echo -e "${BLUE}[+] Stopping previous sessions...${NC}"
pkill -9 -f "termux.x11" 2>/dev/null || true
pkill -9 -f "termux-x11" 2>/dev/null || true
pkill -9 -f "pulseaudio" 2>/dev/null || true
pkill -9 -f "xfce" 2>/dev/null || true
pkill -9 -f "dbus" 2>/dev/null || true
sleep 1

# ------------------------------------------------------------------------------
# 4. Setup Shared /tmp, /dev/shm, and X11 Socket Directories
# ------------------------------------------------------------------------------
TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
mkdir -p "$TERMUX_TMP/.X11-unix" 2>/dev/null || true
chmod 1777 "$TERMUX_TMP" 2>/dev/null || true
chmod 1777 "$TERMUX_TMP/.X11-unix" 2>/dev/null || true
rm -f "$TERMUX_TMP/.X11-unix/X0" "$TERMUX_TMP/.X0-lock" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 5. Configure Enhanced NetHunter PRoot Launcher (nh / nethunter)
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
        --sysvipc \
        -0 \
        -r $CHROOT \
        -b /dev \
        -b /proc \
        -b /sdcard \
        -b $TERMUX_TMP:/tmp \
        -b $TERMUX_TMP:/dev/shm \
        -w $home \
        /usr/bin/env -i \
        HOME=$home \
        PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin \
        TERM=$TERM \
        LANG=C.UTF-8 \
        $start"

if [ "$#" -ge 1 ] && [ "$1" = "kex" ]; then
    shift
    $cmdline -c "/usr/bin/kex $*"
elif [ "$#" == "0" ]; then
    exec $cmdline
else
    $cmdline -c "$*"
fi
LAUNCHER_EOF

chmod 755 "$LAUNCHER_PATH"
ln -sf "$LAUNCHER_PATH" "$SHORTCUT_PATH"

# Create Termux kex command shortcut
cat > "$PREFIX/bin/kex" << 'KEX_SH_EOF'
#!/data/data/com.termux/files/usr/bin/bash
nh kex "$@"
KEX_SH_EOF
chmod 755 "$PREFIX/bin/kex"

# Create Termux nh-x11 shortcut
cat > "$PREFIX/bin/nh-x11" << 'NHX11_SH_EOF'
#!/data/data/com.termux/files/usr/bin/bash
if [ -f "$HOME/start_nethunter_x11.sh" ]; then
    bash "$HOME/start_nethunter_x11.sh"
else
    bash <(curl -sL https://raw.githubusercontent.com/AbuZar-Ansarii/AndroidLinux-GPU/main/start_nethunter_x11.sh)
fi
NHX11_SH_EOF
chmod 755 "$PREFIX/bin/nh-x11"
ln -sf "$PREFIX/bin/nh-x11" "$PREFIX/bin/nethunter-x11" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 6. Configure Kali Container DNS, Passwordless Sudo, DBus & Compositor
# ------------------------------------------------------------------------------
# Fix DNS
mkdir -p "$CHROOT/etc"
cat > "$CHROOT/etc/resolv.conf" << 'DNSEOF'
nameserver 8.8.8.8
nameserver 1.1.1.1
DNSEOF

# Passwordless Sudo for kali user
chmod +s "$CHROOT/usr/bin/sudo" 2>/dev/null || true
chmod +s "$CHROOT/usr/bin/su" 2>/dev/null || true
mkdir -p "$CHROOT/etc/sudoers.d"
echo "kali    ALL=(ALL:ALL) NOPASSWD: ALL" > "$CHROOT/etc/sudoers.d/kali" 2>/dev/null || true
chmod 0440 "$CHROOT/etc/sudoers.d/kali" 2>/dev/null || true

# DBus Machine ID
mkdir -p "$CHROOT/var/lib/dbus" "$CHROOT/etc"
if [ ! -s "$CHROOT/etc/machine-id" ]; then
    echo "0123456789abcdef0123456789abcdef" > "$CHROOT/etc/machine-id" 2>/dev/null || true
    ln -sf /etc/machine-id "$CHROOT/var/lib/dbus/machine-id" 2>/dev/null || true
fi

# Disable XFWM4 Compositor permanently (Fixes black screen)
for U_DIR in "$CHROOT/home/kali" "$CHROOT/root"; do
    mkdir -p "$U_DIR/.config/xfce4/xfconf/xfce-perchannel-xml"
    cat > "$U_DIR/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" << 'XFWM_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
  </property>
</channel>
XFWM_EOF
done

# Fix user directory permissions
"$SHORTCUT_PATH" -r "chown -R kali:kali /home/kali 2>/dev/null || true" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 7. Install / Setup /usr/bin/kex inside Kali (For VNC / RealVNC / RVNC)
# ------------------------------------------------------------------------------
cat > "$CHROOT/usr/bin/kex" << 'KEX_SCRIPT_EOF'
#!/bin/bash
# ==============================================================================
# Script Name : kex
# Description : Kali NetHunter KeX (VNC Desktop Server) Manager
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

USR=$(whoami)
SCREEN=":1"
PORT="5901"
if [ "$USR" = "root" ]; then
    SCREEN=":2"
    PORT="5902"
fi
export USER="$USR"

function check_vnc_installed() {
    if ! command -v vncserver >/dev/null 2>&1 || ! command -v vncpasswd >/dev/null 2>&1; then
        echo -e "${YELLOW}[!] VNC server packages missing. Installing TigerVNC & XFCE4...${NC}"
        sudo apt-get update
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            tigervnc-standalone-server \
            tigervnc-tools \
            xfce4 \
            xfce4-terminal \
            dbus-x11 \
            kali-themes \
            kali-menu
    fi
}

function setup_vnc_config() {
    mkdir -p "$HOME/.vnc"
    cat > "$HOME/.vnc/xstartup" << 'XSEOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export DISPLAY=:1
export XDG_RUNTIME_DIR=/tmp
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export QT_X11_NO_MITSHM=1
export _X11_NO_MITSHM=1
export MITSHM=0
export GDK_RENDERING=image
export NO_AT_BRIDGE=1

[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources 2>/dev/null || true
dbus-launch --exit-with-session startxfce4 &
XSEOF
    chmod 755 "$HOME/.vnc/xstartup"
}

function passwd_kex() {
    check_vnc_installed
    mkdir -p "$HOME/.vnc"
    echo -e "${CYAN}${BOLD}[+] Set your NetHunter KeX (VNC) Password (min 6 chars):${NC}"
    vncpasswd "$HOME/.vnc/passwd"
    chmod 600 "$HOME/.vnc/passwd" 2>/dev/null || true
    echo -e "${GREEN}[✔] KeX password configured successfully!${NC}"
}

function start_kex() {
    check_vnc_installed
    setup_vnc_config

    if [ ! -f "$HOME/.vnc/passwd" ]; then
        echo -e "${YELLOW}[!] No KeX password found. Please create one now:${NC}"
        passwd_kex
    fi

    # Clean old locks
    vncserver -kill "$SCREEN" 2>/dev/null || true
    rm -f "/tmp/.X11-unix/X${SCREEN#:}" "/tmp/.X${SCREEN#:}-lock" 2>/dev/null || true

    echo -e "${GREEN}[+] Starting NetHunter KeX VNC server on display $SCREEN (Port: $PORT)...${NC}"
    vncserver "$SCREEN" -geometry 1280x720 -depth 24 -localhost no -extension MIT-SHM 2>/dev/null || \
    vncserver "$SCREEN" -geometry 1280x720 -depth 24 -localhost no

    echo ""
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  🎉 KALI NETHUNTER KEX (VNC) SERVER IS READY! 🎉${NC}"
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo -e "  ${BOLD}📱 App:${NC}      NetHunter KeX / RealVNC / RVNC / AVNC Viewer"
    echo -e "  ${BOLD}🌐 Address:${NC}  ${CYAN}127.0.0.1:${PORT}${NC}  (or ${CYAN}localhost:${PORT}${NC})"
    echo -e "  ${BOLD}🔑 Password:${NC} (The password you just configured)"
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo -e "  • Stop KeX:  ${YELLOW}nh kex stop${NC}  or  ${YELLOW}kex stop${NC}"
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

function stop_kex() {
    echo -e "${YELLOW}[*] Stopping NetHunter KeX VNC Server...${NC}"
    vncserver -kill :1 2>/dev/null || true
    vncserver -kill :2 2>/dev/null || true
    pkill -9 -f "Xtigervnc" 2>/dev/null || true
    rm -f /tmp/.X11-unix/X1 /tmp/.X11-unix/X2 /tmp/.X1-lock /tmp/.X2-lock 2>/dev/null || true
    echo -e "${GREEN}[✔] KeX VNC server stopped.${NC}"
}

function status_kex() {
    check_vnc_installed
    vncserver -list
}

case "$1" in
    passwd|password)
        passwd_kex
        ;;
    stop|kill)
        stop_kex
        ;;
    status)
        status_kex
        ;;
    start|"")
        start_kex
        ;;
    *)
        start_kex
        ;;
esac
KEX_SCRIPT_EOF
chmod 755 "$CHROOT/usr/bin/kex"
cp -f "$CHROOT/usr/bin/kex" "$CHROOT/usr/local/bin/kex" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 8. Check & Install XFCE Desktop Inside Kali (if not present)
# ------------------------------------------------------------------------------
echo -e "${BLUE}[+] Checking XFCE Desktop packages inside Kali...${NC}"

XFCE_EXISTS=0
if "$SHORTCUT_PATH" -r "command -v xfce4-session >/dev/null 2>&1 || command -v startxfce4 >/dev/null 2>&1"; then
    XFCE_EXISTS=1
fi

if [ "$XFCE_EXISTS" -eq 0 ]; then
    echo ""
    echo -e "${YELLOW}${BOLD}[!] XFCE Desktop is not installed in Kali yet.${NC}"
    echo -e "${GREEN}[+] Installing XFCE4 Desktop & dependencies inside Kali (First-time setup, ~2-4 mins)...${NC}"
    echo ""
    "$SHORTCUT_PATH" -r "
        apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            xfce4 \
            xfce4-terminal \
            dbus-x11 \
            kali-themes \
            kali-menu \
            x11-xserver-utils \
            tigervnc-standalone-server \
            tigervnc-tools
    "
    echo -e "${GREEN}[✔] XFCE4 Desktop & TigerVNC packages installed successfully!${NC}"
fi

# ------------------------------------------------------------------------------
# 9. Create In-Container Desktop Startup Script (Prevents Signal 6 / Black Screen)
# ------------------------------------------------------------------------------
cat > "$CHROOT/usr/local/bin/start-kali-desktop" << 'DESKTOPEOF'
#!/bin/bash
# ==============================================================================
# In-Container XFCE4 Launcher with Signal 6 (SIGABRT) & Black Screen Fixes
# ==============================================================================

export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
export XDG_RUNTIME_DIR=/tmp

# Prevent Signal 6 (SIGABRT) shared memory crashes in PRoot
export QT_X11_NO_MITSHM=1
export _X11_NO_MITSHM=1
export MITSHM=0
export GDK_RENDERING=image
export NO_AT_BRIDGE=1

# Software rendering fallback to prevent GLX/Zink lockups
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export MESA_GL_VERSION_OVERRIDE=3.3
export MESA_GLES_VERSION_OVERRIDE=3.0
export XFCE4_SESSION_DISABLE_SAVED_SESSIONS=1

# Ensure /tmp permissions
mkdir -p /tmp/.X11-unix 2>/dev/null || true
chmod 1777 /tmp 2>/dev/null || true
chmod 1777 /tmp/.X11-unix 2>/dev/null || true
dbus-uuidgen --ensure 2>/dev/null || true

# Disable compositor in running session
xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true

# Launch XFCE Desktop Session with DBus
if command -v startxfce4 >/dev/null 2>&1; then
    exec dbus-launch --exit-with-session startxfce4
elif command -v xfce4-session >/dev/null 2>&1; then
    exec dbus-launch --exit-with-session xfce4-session
else
    echo "Error: Neither startxfce4 nor xfce4-session found!"
    exit 1
fi
DESKTOPEOF
chmod 755 "$CHROOT/usr/local/bin/start-kali-desktop"

# ------------------------------------------------------------------------------
# 10. Start PulseAudio Sound Server in Termux
# ------------------------------------------------------------------------------
echo -e "${BLUE}[+] Starting PulseAudio sound server...${NC}"
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 2>/dev/null || true

# ------------------------------------------------------------------------------
# 11. Start Termux-X11 Display Server with MIT-SHM Disabled (Fixes Signal 6)
# ------------------------------------------------------------------------------
echo -e "${GREEN}[+] Starting Termux-X11 display server on DISPLAY :0...${NC}"
termux-x11 :0 -ac -extension MIT-SHM -listen tcp &
sleep 2

# ------------------------------------------------------------------------------
# 12. Launch Termux-X11 Android App
# ------------------------------------------------------------------------------
echo -e "${GREEN}[+] Launching Termux-X11 Android application...${NC}"
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true

# ------------------------------------------------------------------------------
# 13. Start Kali NetHunter Desktop Session
# ------------------------------------------------------------------------------
echo ""
echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}${BOLD}  🚀 Kali NetHunter Desktop is Starting in Termux-X11!${NC}"
echo -e "${CYAN}${BOLD}  📱 Switch to the Termux-X11 app to view your desktop!${NC}"
echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
echo -e "  ${YELLOW}💡 Prefer VNC/RealVNC instead?${NC} Run: ${CYAN}nh kex &${NC}"
echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Run the desktop launcher inside Kali
"$SHORTCUT_PATH" /usr/local/bin/start-kali-desktop

# ------------------------------------------------------------------------------
# 14. Cleanup on Exit
# ------------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}[*] Desktop session ended. Cleaning up background services...${NC}"
pkill -9 -f "termux.x11" 2>/dev/null || true
pkill -9 -f "termux-x11" 2>/dev/null || true
pkill -9 -f "pulseaudio" 2>/dev/null || true
echo -e "${GREEN}[✔] Done.${NC}"
