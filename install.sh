#!/data/data/com.termux/files/usr/bin/bash
#######################################################
#  📱 ANDROID LINUX WITH GPU - Ultimate Installer v2.0
#  
#  Features:
#  - Overall progress percentage
#  - GPU acceleration auto-setup (Turnip/Zink)
#  - All hacking tools pre-installed
#  - One-click desktop launch
#  
#######################################################
# ============== CONFIGURATION ==============
TOTAL_STEPS=13
CURRENT_STEP=0
# ============== COLORS ==============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'
# ============== PROGRESS FUNCTIONS ==============
# Update overall progress
update_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    
    # Create progress bar
    FILLED=$((PERCENT / 5))
    EMPTY=$((20 - FILLED))
    
    BAR="${GREEN}"
    for ((i=0; i<FILLED; i++)); do BAR+="█"; done
    BAR+="${GRAY}"
    for ((i=0; i<EMPTY; i++)); do BAR+="░"; done
    BAR+="${NC}"
    
    echo ""
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  📊 OVERALL PROGRESS: ${WHITE}Step ${CURRENT_STEP}/${TOTAL_STEPS}${NC} ${BAR} ${WHITE}${PERCENT}%${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}
# Spinner animation for running tasks
spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r  ${YELLOW}⏳${NC} ${message} ${CYAN}${spin:$i:1}${NC}  "
        sleep 0.1
    done
    
    wait $pid
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        printf "\r  ${GREEN}✓${NC} ${message}                    \n"
    else
        printf "\r  ${RED}✗${NC} ${message} ${RED}(failed)${NC}     \n"
    fi
    
    return $exit_code
}
# Install package with progress
install_pkg() {
    local pkg=$1
    local name=${2:-$pkg}
    
    (yes | pkg install $pkg -y > /dev/null 2>&1) &
    spinner $! "Installing ${name}..."
}
# ============== BANNER ==============
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'BANNER'
    ╔══════════════════════════════════════╗
    ║                                      ║
    ║    🚀  ANDROID LINUX v2.1  🚀        ║
    ║                                      ║
    ║       THEVOIDKERNEL - YouTube        ║
    ║                                      ║
    ╚══════════════════════════════════════╝
    
BANNER
    echo -e "${NC}"
    echo -e "${WHITE}         thevoidkernel - YouTube${NC}"
    echo ""
}
# ============== DEVICE DETECTION ==============
detect_device() {
    echo -e "${PURPLE}[*] Detecting your device...${NC}"
    echo ""
    
    DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
    DEVICE_BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
    ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    CPU_ABI=$(getprop ro.product.cpu.abi 2>/dev/null || echo "arm64-v8a")
    
    # Detect GPU type for driver selection
    GPU_VENDOR=$(getprop ro.hardware.egl 2>/dev/null || echo "")
    
    echo -e "  ${GREEN}📱${NC} Device: ${WHITE}${DEVICE_BRAND} ${DEVICE_MODEL}${NC}"
    echo -e "  ${GREEN}🤖${NC} Android: ${WHITE}${ANDROID_VERSION}${NC}"
    echo -e "  ${GREEN}⚙️${NC}  CPU: ${WHITE}${CPU_ABI}${NC}"
    
    # Determine GPU driver
    if [[ "$GPU_VENDOR" == *"adreno"* ]] || [[ "$DEVICE_BRAND" == *"samsung"* ]] || [[ "$DEVICE_BRAND" == *"Samsung"* ]] || [[ "$DEVICE_BRAND" == *"oneplus"* ]] || [[ "$DEVICE_BRAND" == *"xiaomi"* ]]; then
        GPU_DRIVER="freedreno"
        echo -e "  ${GREEN}🎮${NC} GPU: ${WHITE}Adreno (Qualcomm) - Turnip driver${NC}"
    else
        GPU_DRIVER="swrast"
        echo -e "  ${GREEN}🎮${NC} GPU: ${WHITE}Software rendering${NC}"
    fi
    
    echo ""
    sleep 1
}
# ============== STEP 1: UPDATE SYSTEM ==============
step_update() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Updating system packages...${NC}"
    echo ""
    
    (yes | pkg update -y > /dev/null 2>&1) &
    spinner $! "Updating package lists..."
    
    (yes | pkg upgrade -y > /dev/null 2>&1) &
    spinner $! "Upgrading installed packages..."
}
# ============== STEP 2: INSTALL REPOSITORIES ==============
step_repos() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Adding package repositories...${NC}"
    echo ""
    
    install_pkg "x11-repo" "X11 Repository"
    install_pkg "tur-repo" "TUR Repository (Firefox, VS Code)"
}
# ============== STEP 3: INSTALL TERMUX-X11 ==============
step_x11() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Termux-X11...${NC}"
    echo ""
    
    install_pkg "termux-x11-nightly" "Termux-X11 Display Server"
    install_pkg "xorg-xrandr" "XRandR (Display Settings)"
}
# ============== STEP 4: INSTALL DESKTOP ==============
step_desktop() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing XFCE4 Desktop...${NC}"
    echo ""
    
    install_pkg "xfce4" "XFCE4 Desktop Environment"
    install_pkg "xfce4-terminal" "XFCE4 Terminal"
    install_pkg "thunar" "Thunar File Manager"
    install_pkg "mousepad" "Mousepad Text Editor"
}
# ============== STEP 5: INSTALL GPU DRIVERS ==============
step_gpu() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing GPU Acceleration (Turnip/Zink)...${NC}"
    echo ""
    
    install_pkg "mesa-zink" "Mesa Zink (OpenGL over Vulkan)"
    
    if [ "$GPU_DRIVER" == "freedreno" ]; then
        install_pkg "mesa-vulkan-icd-freedreno" "Turnip Adreno GPU Driver"
    else
        install_pkg "mesa-vulkan-icd-swrast" "Software Vulkan Renderer"
    fi
    
    install_pkg "vulkan-loader-android" "Vulkan Loader"
    
    echo -e "  ${GREEN}✓${NC} GPU acceleration configured!"
}
# ============== STEP 6: INSTALL AUDIO ==============
step_audio() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Audio Support...${NC}"
    echo ""
    
    install_pkg "pulseaudio" "PulseAudio Sound Server"
}
# ============== STEP 7: INSTALL BROWSERS & APPS ==============
step_apps() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Applications...${NC}"
    echo ""
    
    install_pkg "firefox" "Firefox Browser"
    install_pkg "code-oss" "VS Code Editor"
    install_pkg "git" "Git Version Control"
    install_pkg "wget" "Wget Downloader"
    install_pkg "curl" "cURL"
}
# ============== STEP 8: INSTALL NETWORK TOOLS ==============
step_network_tools() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Network Scanning Tools...${NC}"
    echo ""
    
    install_pkg "nmap" "Nmap Network Scanner"
    install_pkg "netcat-openbsd" "Netcat"
    install_pkg "whois" "Whois Lookup"
    install_pkg "dnsutils" "DNS Utilities"
    install_pkg "tracepath" "Tracepath"
}
# ============== STEP 9: INSTALL SECURITY TOOLS ==============
step_security_tools() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Security Tools...${NC}"
    echo ""
    
    install_pkg "hydra" "Hydra Password Cracker"
    install_pkg "john" "John the Ripper"
    install_pkg "sqlmap" "SQLMap (SQL Injection)"
    
    # Python tools
    echo -e "  ${YELLOW}⏳${NC} Installing Python security libraries..."
    pip install requests beautifulsoup4 > /dev/null 2>&1
    echo -e "  ${GREEN}✓${NC} Python libraries installed"
}
# ============== STEP 10: INSTALL METASPLOIT ==============
# ============== STEP 11: INSTALL WINE (WINDOWS APPS) ==============
step_wine() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Wine (Windows Support)...${NC}"
    echo ""
    
    # Remove existing wine-stable to avoid conflicts
    (pkg remove wine-stable -y > /dev/null 2>&1) &
    spinner $! "Removing old Wine versions..."
    
    # Install Hangover
    install_pkg "hangover-wine" "Wine Compatibility Layer"
    install_pkg "hangover-wowbox64" "Box64 Wrapper"
    
    # Symlink wine binary
    ln -sf /data/data/com.termux/files/usr/opt/hangover-wine/bin/wine /data/data/com.termux/files/usr/bin/wine
    ln -sf /data/data/com.termux/files/usr/opt/hangover-wine/bin/winecfg /data/data/com.termux/files/usr/bin/winecfg
    
    # Apply registry fix for modern font smoothing
    echo -e "  ${YELLOW}⏳${NC} Applying Windows UI optimizations..."
    wine reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f > /dev/null 2>&1
    echo -e "  ${GREEN}✓${NC} UI optimized"
}
# ============== STEP 12: CREATE LAUNCHER SCRIPTS ==============
step_launchers() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Creating Launcher Scripts...${NC}"
    echo ""
    
    # GPU Configuration file
    mkdir -p ~/.config
    cat > ~/.config/hacklab-gpu.sh << 'GPUEOF'
# Mobile HackLab - GPU Acceleration Config
export MESA_NO_ERROR=1
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_GLES_VERSION_OVERRIDE=3.2
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export TU_DEBUG=noconform
export MESA_VK_WSI_PRESENT_MODE=immediate
export ZINK_DESCRIPTORS=lazy
GPUEOF
    echo -e "  ${GREEN}✓${NC} GPU config created"
    
    # Add to bashrc
    if ! grep -q "hacklab-gpu.sh" ~/.bashrc 2>/dev/null; then
        echo 'source ~/.config/hacklab-gpu.sh 2>/dev/null' >> ~/.bashrc
    fi
    
    # Main Desktop Launcher - AUDIO FIXED
    cat > ~/start-hacklab.sh << 'LAUNCHEREOF'
#!/data/data/com.termux/files/usr/bin/bash
echo ""
echo "🚀 Starting Mobile HackLab Desktop..."
echo ""
# Load GPU config
source ~/.config/hacklab-gpu.sh 2>/dev/null
# Kill any existing sessions
echo "🔄 Cleaning up old sessions..."
pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 -f "xfce" 2>/dev/null
pkill -9 -f "dbus" 2>/dev/null
# === AUDIO SETUP ===
unset PULSE_SERVER
pulseaudio --kill 2>/dev/null
sleep 0.5
echo "🔊 Starting audio server..."
pulseaudio --start --exit-idle-time=-1
sleep 1
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null
export PULSE_SERVER=127.0.0.1
# === END AUDIO ===
# Start Termux-X11 server
echo "📺 Starting X11 display server..."
termux-x11 :0 -ac &
sleep 3
# Set display
export DISPLAY=:0
# Start XFCE Desktop
echo "🖥️ Launching XFCE4 Desktop..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📱 Open the Termux-X11 app to see desktop!"
echo "  🔊 Audio is enabled!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
exec startxfce4
LAUNCHEREOF
    chmod +x ~/start-hacklab.sh
    echo -e "  ${GREEN}✓${NC} Created ~/start-hacklab.sh"
    
    # Quick Tools Menu
    cat > ~/hacktools.sh << 'TOOLSEOF'
#!/data/data/com.termux/files/usr/bin/bash
while true; do
    clear
    echo ""
    echo "╔═══════════════════════════════════════════╗"
    echo "║     🔧 Mobile HackLab - Quick Tools       ║"
    echo "╠═══════════════════════════════════════════╣"
    echo "║  1) 🌐 Nmap - Network Scan                ║"
    echo "║  2) 💉 SQLMap - SQL Injection             ║"
    echo "║  3) 🔑 Hydra - Password Attack            ║"
    echo "║  4) 💀 Metasploit Console                 ║"
    echo "║  5) 🖥️  Start Desktop                     ║"
    echo "║  6) 🔍 Check GPU Status                   ║"
    echo "║  0) ❌ Exit                               ║"
    echo "╚═══════════════════════════════════════════╝"
    echo ""
    read -p "  Select option: " choice
    
    case $choice in
        1) 
            read -p "  Enter target IP/hostname: " target
            nmap -sV $target
            read -p "Press Enter to continue..."
            ;;
        2) 
            read -p "  Enter vulnerable URL: " url
            sqlmap -u "$url" --batch
            read -p "Press Enter to continue..."
            ;;
        3) 
            echo "  Example: hydra -l admin -P wordlist.txt 192.168.1.1 ssh"
            read -p "Press Enter to continue..."
            ;;
        4) 
            msfconsole
            ;;
        5) 
            bash ~/start-hacklab.sh
            ;;
        6)
            echo ""
            glxinfo | grep "renderer"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        0) 
            exit 0
            ;;
    esac
done
TOOLSEOF
    chmod +x ~/hacktools.sh
    echo -e "  ${GREEN}✓${NC} Created ~/hacktools.sh"
    
    # Desktop Shutdown Script
    cat > ~/stop-hacklab.sh << 'STOPEOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "Stopping Mobile HackLab..."
pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 -f "pulseaudio" 2>/dev/null
pkill -9 -f "xfce" 2>/dev/null
pkill -9 -f "dbus" 2>/dev/null
echo "Desktop stopped."
STOPEOF
    chmod +x ~/stop-hacklab.sh
    echo -e "  ${GREEN}✓${NC} Created ~/stop-hacklab.sh"
}
# ============== STEP 13: CREATE DESKTOP SHORTCUTS ==============
step_shortcuts() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Creating Desktop Shortcuts...${NC}"
    echo ""
    
    mkdir -p ~/Desktop
    
    # Firefox
    cat > ~/Desktop/Firefox.desktop << 'EOF'
[Desktop Entry]
Name=Firefox
Comment=Web Browser
Exec=firefox
Icon=firefox
Type=Application
Categories=Network;WebBrowser;
EOF
    
    # VS Code
    cat > ~/Desktop/VSCode.desktop << 'EOF'
[Desktop Entry]
Name=VS Code
Comment=Code Editor
Exec=code-oss --no-sandbox
Icon=code-oss
Type=Application
Categories=Development;
EOF
    
    # Terminal
    cat > ~/Desktop/Terminal.desktop << 'EOF'
[Desktop Entry]
Name=Terminal
Comment=XFCE Terminal
Exec=xfce4-terminal
Icon=utilities-terminal
Type=Application
Categories=System;TerminalEmulator;
EOF
    
    # Metasploit
    cat > ~/Desktop/Metasploit.desktop << 'EOF'
[Desktop Entry]
Name=Metasploit
Comment=Exploitation Framework
Exec=xfce4-terminal -e msfconsole
Icon=utilities-terminal
Type=Application
Categories=Security;
EOF
    
    # HackTools Menu
    cat > ~/Desktop/HackTools.desktop << 'EOF'
[Desktop Entry]
Name=HackTools Menu
Comment=Quick Security Tools
Exec=xfce4-terminal -e "bash ~/hacktools.sh"
Icon=security-high
Type=Application
Categories=Security;
EOF
    
    # Windows File Explorer
    cat > ~/Desktop/Windows_Explorer.desktop << 'EOF'
[Desktop Entry]
Name=Windows Explorer
Comment=Windows File Manager
Exec=wine winefile
Icon=folder-windows
Type=Application
Categories=System;
EOF
    # Wine Config
    cat > ~/Desktop/Wine_Config.desktop << 'EOF'
[Desktop Entry]
Name=Wine Config
Comment=Windows Settings
Exec=wine winecfg
Icon=wine
Type=Application
Categories=Settings;
EOF
    chmod +x ~/Desktop/*.desktop 2>/dev/null
    echo -e "  ${GREEN}✓${NC} Desktop shortcuts created"
}
# ============== COMPLETION ==============
show_completion() {
    echo ""
    echo -e "${GREEN}"
    cat << 'COMPLETE'
    
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║         ✅  INSTALLATION COMPLETE!  ✅                        ║
    ║                                                               ║
    ║              🎉 100% - All Done! 🎉                           ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
    
COMPLETE
    echo -e "${NC}"
    
    echo -e "${WHITE}📱 ANDROID LINUX GPU ACCELERATION is ready!${NC}"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}🚀 TO START THE DESKTOP:${NC}"
    echo -e "   ${GREEN}bash ~/start-hacklab.sh${NC}"
    echo ""
    echo -e "${WHITE}🔧 FOR QUICK TOOLS MENU:${NC}"
    echo -e "   ${GREEN}bash ~/hacktools.sh${NC}"
    echo ""
    echo -e "${WHITE}🛑 TO STOP THE DESKTOP:${NC}"
    echo -e "   ${GREEN}bash ~/stop-hacklab.sh${NC}"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}📦 INSTALLED TOOLS:${NC}"
    echo -e "   • Nmap, Netcat, DNS tools"
    echo -e "   • SQLMap, Hydra, John the Ripper"
    echo -e "   • Metasploit Framework"
    echo -e "   • Firefox, VS Code, Git"
    echo -e "   • Windows Compatibility (Wine/Hangover)"
    echo -e "   • XFCE4 Desktop + GPU Acceleration"
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  📺 Subscribe: https://www.youtube.com/@thevoidkernel${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}⚡ TIP: Open Termux-X11 app first, then run start-hacklab.sh${NC}"
    echo ""
}
# ============== MAIN INSTALLATION ==============
main() {
    show_banner
    
    echo -e "${WHITE}  This script will install a complete Linux desktop with${NC}"
    echo -e "${WHITE}  hacking tools and GPU acceleration on your Android phone.${NC}"
    echo ""
    echo -e "${GRAY}  Estimated time: 15-30 minutes (depends on internet speed)${NC}"
    echo ""
    echo -e "${YELLOW}  Press Enter to start installation, or Ctrl+C to cancel...${NC}"
    read
    
    # Run all steps
    detect_device
    step_update
    step_repos
    step_x11
    step_desktop
    step_gpu
    step_audio
    step_apps
    step_network_tools
    step_security_tools
    step_metasploit
    step_wine
    step_launchers
    step_shortcuts
    
    # Show completion
    show_completion
}
# ============== RUN ==============
main
