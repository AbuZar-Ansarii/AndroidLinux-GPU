#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Script Name : install_nethunter_rootless.sh
# Repository  : AbuZar-Ansarii/AndroidLinux-GPU
# One-Liner   : curl -sL https://raw.githubusercontent.com/AbuZar-Ansarii/AndroidLinux-GPU/main/install_nethunter_rootless.sh | bash
# Description : Fully automated installer for Kali NetHunter Rootless on Termux
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
NC='\033[0m' # No Color

print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'BANNER'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║      🐉  KALI NETHUNTER ROOTLESS INSTALLER (TERMUX) 🐉        ║
║                                                               ║
║           Repository: AbuZar-Ansarii/AndroidLinux-GPU         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
BANNER
    echo -e "${NC}"
}

print_info()    { echo -e "${BLUE}[+] $1${NC}"; }
print_success() { echo -e "${GREEN}[✔] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[!] $1${NC}"; }
print_error()   { echo -e "${RED}[✘] $1${NC}"; }

# ------------------------------------------------------------------------------
# 1. Environment & Storage Setup
# ------------------------------------------------------------------------------
print_header

print_info "Checking Termux environment & storage permissions..."
if command -v termux-setup-storage >/dev/null 2>&1; then
    termux-setup-storage || true
fi

# Enable external app interaction for Termux-X11
mkdir -p "$HOME/.termux"
if ! grep -q "allow-external-apps" "$HOME/.termux/termux.properties" 2>/dev/null; then
    echo "allow-external-apps = true" >> "$HOME/.termux/termux.properties"
    termux-reload-settings 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 2. Package Updates & Prerequisites Installation
# ------------------------------------------------------------------------------
print_info "Configuring package sources & updating repositories..."
export DEBIAN_FRONTEND=noninteractive

# Update core repo
pkg update -y || apt-get update -y || true

# Add X11 repository
print_info "Installing X11 repository..."
pkg install -y x11-repo || apt-get install -y x11-repo || true
pkg update -y || apt-get update -y || true

# Install all essential Termux tools
print_info "Installing essential tools (proot, tar, axel, xz-utils, wget, curl, termux-x11, pulseaudio)..."
for PKG in proot tar axel xz-utils wget curl pulseaudio; do
    if ! dpkg -s "$PKG" >/dev/null 2>&1; then
        pkg install -y "$PKG" || apt-get install -y "$PKG" || true
    fi
done

# Install Termux-X11 package
if ! dpkg -s "termux-x11-nightly" >/dev/null 2>&1; then
    pkg install -y termux-x11-nightly || pkg install -y termux-x11 || true
fi

print_success "Prerequisites configured successfully."

# ------------------------------------------------------------------------------
# 3. Detect Device Architecture
# ------------------------------------------------------------------------------
print_info "Detecting device CPU architecture..."
ARCH=$(getprop ro.product.cpu.abi 2>/dev/null || uname -m)

case "$ARCH" in
    arm64*|aarch64*)
        SYS_ARCH="arm64"
        ;;
    arm*|armeabi*|armv7*|armv8l*)
        SYS_ARCH="armhf"
        ;;
    *)
        print_warning "Architecture $ARCH detected. Defaulting to arm64..."
        SYS_ARCH="arm64"
        ;;
esac

print_success "Architecture detected: ${BOLD}${SYS_ARCH}${NC}"

# ------------------------------------------------------------------------------
# 4. Edition Selection
# ------------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}${BOLD}Select Kali NetHunter Rootfs Edition:${NC}"
echo -e "  ${CYAN}[1] Full${NC}     - Complete toolkit (~1.6GB download / ~8GB installed) ${GREEN}[Recommended]${NC}"
echo -e "  ${CYAN}[2] Minimal${NC}  - Essential CLI penetration testing tools (~900MB download)"
echo -e "  ${CYAN}[3] Nano${NC}     - Bare minimum lightweight image (~500MB download)"
echo ""

IMAGE_EDITION="full"
if [ -c /dev/tty ]; then
    read -p "Enter selection [1-3] (Default: 1): " CHOICE < /dev/tty || CHOICE=1
else
    CHOICE=1
fi

case "$CHOICE" in
    1|full|Full)
        IMAGE_EDITION="full"
        ;;
    2|minimal|Minimal)
        IMAGE_EDITION="minimal"
        ;;
    3|nano|Nano)
        IMAGE_EDITION="nano"
        ;;
    *)
        IMAGE_EDITION="full"
        ;;
esac

print_info "Selected Edition: ${BOLD}${IMAGE_EDITION} (${SYS_ARCH})${NC}"

CHROOT_DIR="kali-${SYS_ARCH}"
IMAGE_NAME="kali-nethunter-rootfs-${IMAGE_EDITION}-${SYS_ARCH}.tar.xz"
SHA_NAME="${IMAGE_NAME}.sha512sum"
BASE_URL="https://kali.download/nethunter-images/current/rootfs"
FALLBACK_BASE_URL="https://old.kali.org/nethunter-images/current/rootfs"

cd "$HOME"

# ------------------------------------------------------------------------------
# 5. Clean Broken Previous Installations
# ------------------------------------------------------------------------------
if [ -d "$CHROOT_DIR" ]; then
    if [ ! -f "$CHROOT_DIR/usr/bin/bash" ] && [ ! -f "$CHROOT_DIR/bin/bash" ]; then
        print_warning "Incomplete rootfs directory found ($CHROOT_DIR). Removing..."
        rm -rf "$CHROOT_DIR"
    else
        echo ""
        print_warning "Existing NetHunter installation found in $CHROOT_DIR."
        REINSTALL="N"
        if [ -c /dev/tty ]; then
            read -p "Do you want to delete and reinstall fresh? (y/N): " REINSTALL < /dev/tty || REINSTALL="N"
        fi
        case "$REINSTALL" in
            y*|Y*)
                print_info "Removing previous rootfs directory..."
                rm -rf "$CHROOT_DIR"
                ;;
            *)
                print_info "Keeping existing rootfs directory. Updating launchers..."
                SKIP_DOWNLOAD=1
                ;;
        esac
    fi
fi

# ------------------------------------------------------------------------------
# 6. Download Kali Rootfs Image (Resumable)
# ------------------------------------------------------------------------------
if [ -z "$SKIP_DOWNLOAD" ]; then
    DOWNLOAD_NEEDED=1
    if [ -f "$IMAGE_NAME" ]; then
        print_info "Found existing archive: $IMAGE_NAME"
        USE_EXISTING="Y"
        if [ -c /dev/tty ]; then
            read -p "Use existing archive? (Y/n): " USE_EXISTING < /dev/tty || USE_EXISTING="Y"
        fi
        case "$USE_EXISTING" in
            n*|N*)
                rm -f "$IMAGE_NAME" "$SHA_NAME"
                DOWNLOAD_NEEDED=1
                ;;
            *)
                DOWNLOAD_NEEDED=0
                ;;
        esac
    fi

    if [ "$DOWNLOAD_NEEDED" -eq 1 ]; then
        print_info "Downloading Kali NetHunter rootfs (${IMAGE_NAME})..."
        DOWNLOAD_URL="${BASE_URL}/${IMAGE_NAME}"
        
        if command -v axel >/dev/null 2>&1; then
            axel -n 6 -a -o "$IMAGE_NAME" "$DOWNLOAD_URL" || wget -c --show-progress "$DOWNLOAD_URL" -O "$IMAGE_NAME" || wget -c --show-progress "${FALLBACK_BASE_URL}/${IMAGE_NAME}" -O "$IMAGE_NAME"
        else
            wget -c --show-progress "$DOWNLOAD_URL" -O "$IMAGE_NAME" || wget -c --show-progress "${FALLBACK_BASE_URL}/${IMAGE_NAME}" -O "$IMAGE_NAME"
        fi

        if [ ! -f "$IMAGE_NAME" ] || [ ! -s "$IMAGE_NAME" ]; then
            print_error "Failed to download rootfs image. Please check your internet connection."
            exit 1
        fi
        print_success "Rootfs download complete."
    fi

    # --------------------------------------------------------------------------
    # 7. Extract Rootfs Image
    # --------------------------------------------------------------------------
    print_info "Extracting Kali NetHunter rootfs... (This may take 2-5 minutes)"
    proot --link2symlink tar -xf "$IMAGE_NAME" 2>/dev/null || tar -xf "$IMAGE_NAME" 2>/dev/null || {
        print_error "Extraction failed! The archive may be corrupted."
        exit 1
    }
    print_success "Rootfs extracted successfully."
fi

# ------------------------------------------------------------------------------
# 8. Configure Kali System & Sudoers
# ------------------------------------------------------------------------------
print_info "Configuring Kali container permissions & networking..."

# Fix DNS resolution
mkdir -p "$CHROOT_DIR/etc"
cat > "$CHROOT_DIR/etc/resolv.conf" << 'DNSEOF'
nameserver 8.8.8.8
nameserver 1.1.1.1
nameserver 8.8.4.4
DNSEOF

# Fix Sudo permissions (Passwordless sudo for automated launch)
chmod +s "$CHROOT_DIR/usr/bin/sudo" 2>/dev/null || true
chmod +s "$CHROOT_DIR/usr/bin/su" 2>/dev/null || true
mkdir -p "$CHROOT_DIR/etc/sudoers.d"
echo "kali    ALL=(ALL:ALL) NOPASSWD: ALL" > "$CHROOT_DIR/etc/sudoers.d/kali" 2>/dev/null || true
chmod 0440 "$CHROOT_DIR/etc/sudoers.d/kali" 2>/dev/null || true
echo "Set disable_coredump false" > "$CHROOT_DIR/etc/sudo.conf" 2>/dev/null || true

# Fix User/Group ID to match Termux user
TERMUX_UID=$(id -u)
TERMUX_GID=$(id -g)

# Ensure machine-id exists for DBus & X11
mkdir -p "$CHROOT_DIR/var/lib/dbus" "$CHROOT_DIR/etc"
if [ ! -s "$CHROOT_DIR/etc/machine-id" ]; then
    echo "0123456789abcdef0123456789abcdef" > "$CHROOT_DIR/etc/machine-id" 2>/dev/null || true
    ln -sf /etc/machine-id "$CHROOT_DIR/var/lib/dbus/machine-id" 2>/dev/null || true
fi

# Disable XFWM4 compositing inside Kali to permanently prevent black screen
for U_DIR in "$CHROOT_DIR/home/kali" "$CHROOT_DIR/root"; do
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

# ------------------------------------------------------------------------------
# 9. Create Enhanced & Bulletproof NetHunter PRoot Launchers
# ------------------------------------------------------------------------------
print_info "Creating Termux launcher scripts (nh, nethunter, kex, nh-x11)..."

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
    echo "[!] Kali NetHunter directory not found! Run the installation script first."
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

# Create Termux kex shortcut command
cat > "$PREFIX/bin/kex" << 'KEX_SH_EOF'
#!/data/data/com.termux/files/usr/bin/bash
nh kex "$@"
KEX_SH_EOF
chmod 755 "$PREFIX/bin/kex"

# Create /usr/bin/kex inside Kali container for VNC support
cat > "$CHROOT_DIR/usr/bin/kex" << 'KEX_SCRIPT_EOF'
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
    echo -e "  ${BOLD}🔑 Password:${NC} (The password you configured)"
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
chmod 755 "$CHROOT_DIR/usr/bin/kex"
cp -f "$CHROOT_DIR/usr/bin/kex" "$CHROOT_DIR/usr/local/bin/kex" 2>/dev/null || true

# Create in-container desktop script for Termux-X11
cat > "$CHROOT_DIR/usr/local/bin/start-kali-desktop" << 'DESKTOPEOF'
#!/bin/bash
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
export XDG_RUNTIME_DIR=/tmp
export QT_X11_NO_MITSHM=1
export _X11_NO_MITSHM=1
export MITSHM=0
export GDK_RENDERING=image
export NO_AT_BRIDGE=1
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
chmod 755 "$CHROOT_DIR/usr/local/bin/start-kali-desktop"

# Create shortcut command nh-x11 in PATH
cat > "$PREFIX/bin/nh-x11" << 'NHX11_EOF'
#!/data/data/com.termux/files/usr/bin/bash
if [ -f "$HOME/start_nethunter_x11.sh" ]; then
    bash "$HOME/start_nethunter_x11.sh"
else
    bash <(curl -sL https://raw.githubusercontent.com/AbuZar-Ansarii/AndroidLinux-GPU/main/start_nethunter_x11.sh)
fi
NHX11_EOF
chmod 755 "$PREFIX/bin/nh-x11"
ln -sf "$PREFIX/bin/nh-x11" "$PREFIX/bin/nethunter-x11" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 10. Install Desktop & VNC Packages inside Kali
# ------------------------------------------------------------------------------
print_info "Configuring user permissions inside Kali..."
"$SHORTCUT_PATH" -r "
    usermod -u $TERMUX_UID kali 2>/dev/null || true
    groupmod -g $TERMUX_GID kali 2>/dev/null || true
    chown -R kali:kali /home/kali 2>/dev/null || true
" || true

print_info "Installing XFCE4 Desktop & TigerVNC packages inside Kali..."
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
        tigervnc-tools 2>/dev/null || true
" || true

# ------------------------------------------------------------------------------
# 11. Download / Update start_nethunter_x11.sh
# ------------------------------------------------------------------------------
START_SCRIPT="$HOME/start_nethunter_x11.sh"
curl -sL https://raw.githubusercontent.com/AbuZar-Ansarii/AndroidLinux-GPU/main/start_nethunter_x11.sh -o "$START_SCRIPT" 2>/dev/null || true
chmod +x "$START_SCRIPT" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 12. Cleanup Downloaded Rootfs Archive
# ------------------------------------------------------------------------------
if [ -f "$IMAGE_NAME" ]; then
    echo ""
    CLEAN_ARCHIVE="Y"
    if [ -c /dev/tty ]; then
        read -p "Delete downloaded archive ($IMAGE_NAME) to save storage? (Y/n): " CLEAN_ARCHIVE < /dev/tty || CLEAN_ARCHIVE="Y"
    fi
    case "$CLEAN_ARCHIVE" in
        n*|N*)
            print_info "Retaining $IMAGE_NAME."
            ;;
        *)
            rm -f "$IMAGE_NAME" "$SHA_NAME"
            print_info "Cleaned up $IMAGE_NAME."
            ;;
    esac
fi

# ------------------------------------------------------------------------------
# 13. Completion Banner & Quick Start Guidance
# ------------------------------------------------------------------------------
echo ""
echo -e "${GREEN}${BOLD}"
cat << 'COMPLETE'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║         ✅ KALI NETHUNTER INSTALLATION COMPLETE! ✅           ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
COMPLETE
echo -e "${NC}"
echo -e "${BOLD}🚀 How to Use Kali NetHunter:${NC}"
echo ""
echo -e "  ${CYAN}${BOLD}[ CLI Mode ]${NC}"
echo -e "  • Start NetHunter CLI (User):  ${WHITE}nh${NC} or ${WHITE}nethunter${NC}"
echo -e "  • Start NetHunter CLI (Root):  ${WHITE}nh -r${NC} or ${WHITE}nethunter -r${NC}"
echo ""
echo -e "  ${GREEN}${BOLD}[ Mode 1: Termux-X11 Desktop (Fast 60fps) ]${NC}"
echo -e "  • Launch Desktop:              ${GREEN}nh-x11${NC} or ${GREEN}bash ~/start_nethunter_x11.sh${NC}"
echo ""
echo -e "  ${PURPLE}${BOLD}[ Mode 2: NetHunter KeX (VNC / RealVNC / RVNC / AVNC) ]${NC}"
echo -e "  • Set VNC Password:            ${PURPLE}nh kex passwd${NC}"
echo -e "  • Start VNC Server:            ${PURPLE}nh kex &${NC} (Connect to 127.0.0.1:5901)"
echo -e "  • Stop VNC Server:             ${PURPLE}nh kex stop${NC}"
echo ""
echo -e "${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}${BOLD}[!] ATTENTION ANDROID 12, 13, 14, 15, 16+ USERS:${NC}"
echo -e "If NetHunter exits with '[Process completed - signal 9]', run once via ADB/Shizuku:"
echo -e "  ${CYAN}adb shell device_config put activity_manager max_phantom_processes 2147483647${NC}"
echo -e "  ${CYAN}adb shell settings put global settings_enable_monitor_phantom_procs false${NC}"
echo -e "${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
