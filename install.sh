#!/usr/bin/env sh
# fip & fop installer script - installs clipboard utilities to user's local bin directory
# Usage: curl -fsSL https://raw.githubusercontent.com/Blakemagne/fip-fop/main/install.sh | sh

set -e

# Color codes for output (check if terminal supports colors)
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    RESET=$(tput sgr0)
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    RESET=""
fi

# Helper functions
info() {
    printf "${BLUE}==>${RESET} %s\n" "$1"
}

success() {
    printf "${GREEN}✓${RESET} %s\n" "$1"
}

warn() {
    printf "${YELLOW}!${RESET} %s\n" "$1"
}

error() {
    printf "${RED}✗${RESET} %s\n" "$1" >&2
}

# Detect OS and architecture
detect_platform() {
    OS="$(uname -s)"
    case "$OS" in
        Linux*)     PLATFORM="linux";;
        Darwin*)    PLATFORM="macos";;
        CYGWIN*|MINGW*|MSYS*) PLATFORM="windows";;
        *)          PLATFORM="unknown";;
    esac
    
    # Check for WSL
    if [ "$PLATFORM" = "linux" ] && grep -qi microsoft /proc/version 2>/dev/null; then
        PLATFORM="wsl"
    fi
}

# Check for required clipboard tools
check_clipboard_tools() {
    info "Checking for clipboard tools..."
    
    case "$PLATFORM" in
        linux)
            if command -v wl-copy >/dev/null 2>&1; then
                success "Found wl-copy (Wayland)"
            elif command -v xclip >/dev/null 2>&1; then
                success "Found xclip (X11)"
            else
                warn "No clipboard tool found"
                printf "\n"
                info "To install clipboard support:"
                printf "  ${YELLOW}# For Wayland:${RESET}\n"
                printf "  sudo apt install wl-clipboard    ${YELLOW}# Debian/Ubuntu${RESET}\n"
                printf "  sudo dnf install wl-clipboard    ${YELLOW}# Fedora${RESET}\n"
                printf "  sudo pacman -S wl-clipboard      ${YELLOW}# Arch${RESET}\n"
                printf "\n"
                printf "  ${YELLOW}# For X11:${RESET}\n"
                printf "  sudo apt install xclip           ${YELLOW}# Debian/Ubuntu${RESET}\n"
                printf "  sudo dnf install xclip           ${YELLOW}# Fedora${RESET}\n"
                printf "  sudo pacman -S xclip             ${YELLOW}# Arch${RESET}\n"
                printf "\n"
            fi
            ;;
        macos)
            if command -v pbcopy >/dev/null 2>&1; then
                success "Found pbcopy (built-in)"
            else
                error "pbcopy not found (should be built-in on macOS)"
            fi
            ;;
        wsl)
            if command -v clip.exe >/dev/null 2>&1; then
                success "Found clip.exe (WSL)"
            else
                warn "clip.exe not found"
                info "Make sure you're running WSL2 and Windows paths are accessible"
            fi
            ;;
    esac
}

# Determine installation directory
get_install_dir() {
    # Check if ~/.local/bin exists in PATH
    if echo "$PATH" | grep -q "$HOME/.local/bin"; then
        INSTALL_DIR="$HOME/.local/bin"
    elif echo "$PATH" | grep -q "$HOME/bin"; then
        INSTALL_DIR="$HOME/bin"
    elif echo "$PATH" | grep -q "/usr/local/bin" && [ -w "/usr/local/bin" ]; then
        INSTALL_DIR="/usr/local/bin"
    else
        # Default to ~/.local/bin even if not in PATH
        INSTALL_DIR="$HOME/.local/bin"
        PATH_WARNING=1
    fi
}

# Download and install fip and fop
install_tools() {
    FIP_URL="https://raw.githubusercontent.com/Blakemagne/fip-fop/main/fip"
    FOP_URL="https://raw.githubusercontent.com/Blakemagne/fip-fop/main/fop"
    
    info "Creating installation directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    
    # Install fip
    info "Downloading fip..."
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$FIP_URL" -o "$INSTALL_DIR/fip"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$FIP_URL" -O "$INSTALL_DIR/fip"
    else
        error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    info "Setting executable permissions for fip..."
    chmod +x "$INSTALL_DIR/fip"
    success "fip installed to $INSTALL_DIR/fip"
    
    # Install fop
    info "Downloading fop..."
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$FOP_URL" -o "$INSTALL_DIR/fop"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$FOP_URL" -O "$INSTALL_DIR/fop"
    else
        error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    info "Setting executable permissions for fop..."
    chmod +x "$INSTALL_DIR/fop"
    success "fop installed to $INSTALL_DIR/fop"
}

# Add directory to PATH if needed
update_path() {
    if [ -n "$PATH_WARNING" ]; then
        warn "$INSTALL_DIR is not in your PATH"
        printf "\n"
        info "Add the following line to your shell configuration file:"
        printf "\n"
        
        # Detect shell
        SHELL_NAME="$(basename "$SHELL")"
        case "$SHELL_NAME" in
            bash)
                RC_FILE="~/.bashrc"
                ;;
            zsh)
                RC_FILE="~/.zshrc"
                ;;
            fish)
                RC_FILE="~/.config/fish/config.fish"
                printf "  ${GREEN}set -x PATH \$PATH $INSTALL_DIR${RESET}\n"
                printf "\n"
                info "Then reload your shell configuration:"
                printf "  ${GREEN}source $RC_FILE${RESET}\n"
                return
                ;;
            *)
                RC_FILE="~/.profile"
                ;;
        esac
        
        printf "  ${GREEN}export PATH=\"\$PATH:$INSTALL_DIR\"${RESET}\n"
        printf "\n"
        info "Then reload your shell configuration:"
        printf "  ${GREEN}source $RC_FILE${RESET}\n"
    fi
}

# Verify installation
verify_installation() {
    if [ -z "$PATH_WARNING" ] && command -v fip >/dev/null 2>&1 && command -v fop >/dev/null 2>&1; then
        printf "\n"
        success "Installation complete! You can now use 'fip' and 'fop' from anywhere."
        printf "\n"
        info "Try it out:"
        printf "  ${GREEN}echo \"Hello, clipboard!\" | fip${RESET}     # Copy to clipboard\n"
        printf "  ${GREEN}fop > output.txt${RESET}                   # Paste from clipboard to file\n"
        printf "  ${GREEN}fip ~/.bashrc${RESET}                      # Copy file to clipboard\n"
        printf "  ${GREEN}fop | grep \"pattern\"${RESET}               # Search clipboard contents\n"
    else
        printf "\n"
        success "Installation complete!"
        printf "\n"
        info "To use the tools, run:"
        printf "  ${GREEN}$INSTALL_DIR/fip${RESET}    # Copy to clipboard\n"
        printf "  ${GREEN}$INSTALL_DIR/fop${RESET}    # Paste from clipboard\n"
    fi
}

# Main installation flow
main() {
    printf "${BLUE}fip & fop installer${RESET}\n"
    printf "===================\n\n"
    
    # Detect platform
    detect_platform
    info "Detected platform: $PLATFORM"
    
    # Check clipboard tools
    check_clipboard_tools
    
    # Get installation directory
    get_install_dir
    
    # Install both tools
    install_tools
    
    # Update PATH if needed
    update_path
    
    # Verify installation
    verify_installation
}

# Run main function
main