#!/data/data/com.termux/files/usr/bin/bash
# =====================================================================
# wifite32 Termux All-in-One Installer
# =====================================================================
# Installs wifite32 host controller + dependencies on Termux (Android)
# Supports: aarch64 (ARM64), arm (ARM32), x86_64, i686
# Tested on: Termux 0.118+ (F-Droid), Android 8+
# =====================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Config
REPO_URL="https://github.com/alphingj/wifite32.git"
INSTALL_DIR="$HOME/wifite32"
AIRCRACK_REPO="https://raw.githubusercontent.com/pitube08642/aircrack-ng-for-termux/main/dists/termux/aircrack-ng"

# Logging
log() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err() { echo -e "${RED}[-]${NC} $*"; }
info() { echo -e "${BLUE}[i]${NC} $*"; }

# Detect architecture
detect_arch() {
    local arch=$(uname -m)
    case "$arch" in
        aarch64) echo "aarch64" ;;
        armv7*|arm) echo "arm" ;;
        x86_64) echo "x86_64" ;;
        i686|i386) echo "i686" ;;
        *) err "Unsupported architecture: $arch"; exit 1 ;;
    esac
}

# Check if running in Termux
check_termux() {
    if [[ ! -d "/data/data/com.termux" && ! -d "/data/data/com.termux.api" ]]; then
        err "This script must run inside Termux"
        exit 1
    fi
    log "Termux environment detected"
}

# Check root
check_root() {
    if [[ $EUID -eq 0 || $(id -u) -eq 0 ]]; then
        ROOT=true
        log "Root access: YES"
    else
        ROOT=false
        warn "Root access: NO (USB serial may need root)"
    fi
}

# Update packages
update_packages() {
    log "Updating package lists..."
    pkg update -y && pkg upgrade -y
}

# Install core dependencies
install_core_deps() {
    log "Installing core dependencies..."
    pkg install -y python git wget curl unzip openssh tsu ethtool iw
}

# Install Python packages
install_python_deps() {
    log "Installing Python packages..."
    pip install --upgrade pip
    pip install pyserial scapy
}

# Install aircrack-ng (removed from Termux root-repo)
install_aircrack() {
    local arch=$(detect_arch)
    log "Installing aircrack-ng for $arch..."

    # Install build dependencies
    pkg install -y libc++ libnl libpcap libsqlite openssl pcre zlib

    local deb_url="${AIRCRACK_REPO}/binary-${arch}/aircrack-ng_3_1.7_${arch}.deb"
    local deb_file="/tmp/aircrack-ng_${arch}.deb"

    log "Downloading aircrack-ng package..."
    wget -q -O "$deb_file" "$deb_url" || {
        err "Failed to download aircrack-ng for $arch"
        warn "Try: pkg install root-repo && pkg install aircrack-ng"
        return 1
    }

    log "Installing aircrack-ng..."
    dpkg -i "$deb_file" || {
        err "dpkg install failed, trying apt fix..."
        apt install -f -y
        dpkg -i "$deb_file"
    }

    rm -f "$deb_file"
    log "aircrack-ng installed successfully"
}

# Clone wifite32
clone_repo() {
    if [[ -d "$INSTALL_DIR" ]]; then
        warn "Directory $INSTALL_DIR exists, updating..."
        cd "$INSTALL_DIR" && git pull
    else
        log "Cloning wifite32..."
        git clone "$REPO_URL" "$INSTALL_DIR"
    fi
}

# Fix USB permissions (requires root)
fix_usb_permissions() {
    if [[ "$ROOT" != true ]]; then
        warn "Skipping USB permission fix (requires root)"
        info "Run manually after install:"
        info "  su -c 'chmod 666 /dev/ttyUSB*'"
        return
    fi

    log "Fixing USB serial permissions..."
    for dev in /dev/ttyUSB* /dev/ttyACM*; do
        if [[ -e "$dev" ]]; then
            chmod 666 "$dev" 2>/dev/null && log "Fixed: $dev"
        fi
    done

    # Disable SELinux if enforcing
    if command -v getenforce &>/dev/null; then
        local se=$(getenforce)
        if [[ "$se" == "Enforcing" ]]; then
            setenforce 0 2>/dev/null && warn "SELinux set to Permissive"
        fi
    fi
}

# Create run script
create_run_script() {
    local run_script="$HOME/wifite32-run.sh"
    cat > "$run_script" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# wifite32 Termux Runner

cd "$HOME/wifite32/host"

# Auto-fix USB permissions if root
if [[ $EUID -eq 0 ]] || [[ $(id -u) -eq 0 ]]; then
    for dev in /dev/ttyUSB* /dev/ttyACM*; do
        [[ -e "$dev" ]] && chmod 666 "$dev" 2>/dev/null
    done
fi

# Detect device
DEVICE="/dev/ttyUSB0"
if [[ ! -e "$DEVICE" ]]; then
    DEVICE="/dev/ttyACM0"
fi

if [[ ! -e "$DEVICE" ]]; then
    echo "No ESP32 found at $DEVICE"
    echo "Available devices:"
    ls -la /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || echo "None"
    echo "Usage: $0 [device]"
    exit 1
fi

echo "Using ESP32 at: $DEVICE"
python3 pywifite32.py "$@"
EOF
    chmod +x "$run_script"
    log "Created runner: $run_script"
}

# Create Termux widget shortcut
create_widget() {
    local widget_dir="$HOME/.shortcuts"
    mkdir -p "$widget_dir"
    cat > "$widget_dir/wifite32" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/wifite32/host"
python3 pywifite32.py
EOF
    chmod +x "$widget_dir/wifite32"
    log "Created Termux widget shortcut"
}

# Verify installation
verify_install() {
    log "Verifying installation..."

    # Check Python
    python3 --version

    # Check pyserial
    python3 -c "import serial; print('pyserial OK')"

    # Check aircrack-ng
    if command -v aircrack-ng &>/dev/null; then
        aircrack-ng -S 2>&1 | head -1
    else
        warn "aircrack-ng not in PATH"
    fi

    # Check ESP32 device
    if [[ -e /dev/ttyUSB0 ]] || [[ -e /dev/ttyACM0 ]]; then
        log "ESP32 device detected"
    else
        warn "No ESP32 device found (connect via USB OTG)"
    fi

    # Check repo
    if [[ -f "$INSTALL_DIR/host/pywifite32.py" ]]; then
        log "wifite32 host code found"
    else
        err "wifite32 host code missing"
    fi
}

# Main
main() {
    echo -e "${BLUE}"
    echo "======================================================================"
    echo "  wifite32 Termux All-in-One Installer"
    echo "  ESP32 WiFi Auditing Toolkit"
    echo "======================================================================"
    echo -e "${NC}"

    check_termux
    check_root

    info "Architecture: $(detect_arch)"
    info "Install directory: $INSTALL_DIR"

    update_packages
    install_core_deps
    install_python_deps
    install_aircrack
    clone_repo
    fix_usb_permissions
    create_run_script
    create_widget
    verify_install

    echo -e "\n${GREEN}======================================================================"
    echo "  Installation Complete!"
    echo "======================================================================${NC}"
    echo
    echo "Run wifite32:"
    echo "  $HOME/wifite32-run.sh"
    echo
    echo "Or from anywhere (add to PATH):"
    echo "  echo 'export PATH=\$HOME/wifite32/host:\$PATH' >> ~/.bashrc"
    echo "  source ~/.bashrc"
    echo
    echo "Termux Widget (requires Termux:Widget addon):"
    echo "  ~/.shortcuts/wifite32"
    echo
    echo "Connect ESP32 via USB OTG, grant USB permission when prompted."
    echo "If permission denied: su -c 'chmod 666 /dev/ttyUSB0'"
}

main "$@"