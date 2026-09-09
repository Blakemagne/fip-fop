#!/usr/bin/env sh
# fip & fop installer script - installs clipboard utilities to user's local bin directory
# Usage: curl -fsSL https://raw.githubusercontent.com/Blakemagne/fip-fop/main/install.sh | sh
#
# ShellCheck: verified with `shellcheck -s sh`. Three rules are disabled file-wide
# because every occurrence was checked individually and found to be intentional.
# Keep this list tight -- if a NEW instance of one of these appears, re-verify it
# rather than assuming it is covered.
#
#   SC2059 (vars in a printf format string): the only interpolated values are the
#     colour variables, which hold tput output -- verified to be bytes ESC [ 3 2 m,
#     containing no % and no backslash. The four printf calls that DO interpolate
#     $HOME-derived data (via $INSTALL_DIR) were converted to format-plus-operands,
#     because a home directory containing % really would be mangled.
#   SC2088 (tilde does not expand in quotes): $RC_FILE is never used as a path. It
#     is only ever printed as advice, e.g. `source ~/.bashrc`, where a literal ~ is
#     correct -- the user's own shell expands it when they run the line.
#   SC1007 (space after =): a false positive on `CDPATH= cd -- ...`, the standard
#     idiom for clearing CDPATH for one command. Verified it works and that it is
#     load-bearing: with a hostile CDPATH set, `cd etc` resolves to $CDPATH/etc,
#     while the guarded form correctly resolves the intended path.
#   SC2016 (expressions do not expand in single quotes): that is the point. These
#     two lines print a PATH export for the user to copy, so $PATH must survive as
#     four literal characters rather than being expanded at print time.
#
# shellcheck disable=SC2059,SC2088,SC1007,SC2016

set -e

# Color codes for output (check if terminal supports colors)
# A stdout tty and a usable TERM are independent conditions, so `[ -t 1 ]` alone is
# not enough: under `set -e` an assignment's status IS the command substitution's
# status, so a failing tput (exit 1 on TERM=dumb, exit 2 on unset TERM) would abort
# the installer on its very first executable statement -- no output, non-zero exit,
# nothing installed. Real triggers: Emacs M-x shell (pty + TERM=dumb) and
# script-wrapped CI runners. The `|| VAR=""` is what neutralises that; the TERM
# tests just avoid five pointless execs. Same behaviour on BSD/macOS, where the
# `dumb` terminfo entry also has no setaf.
if [ -t 1 ] && [ -n "$TERM" ] && [ "$TERM" != dumb ] && command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 1 2>/dev/null)    || RED=""
    GREEN=$(tput setaf 2 2>/dev/null)  || GREEN=""
    YELLOW=$(tput setaf 3 2>/dev/null) || YELLOW=""
    BLUE=$(tput setaf 4 2>/dev/null)   || BLUE=""
    RESET=$(tput sgr0 2>/dev/null)     || RESET=""
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
            elif command -v xsel >/dev/null 2>&1; then
                success "Found xsel (X11)"
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
    # Match whole PATH components, not substrings. The previous `grep -q` matched
    # any component merely CONTAINING the target, so PATH=...:$HOME/.local/bin-old
    # suppressed the "not in your PATH" warning, and PATH=...:$HOME/binaries made
    # the installer silently create and install into a directory the user never
    # had. $HOME was also interpolated as a regex, so $HOME/Xlocal/bin matched the
    # .local pattern. Double-quoted text in a case pattern matches literally, which
    # removes the metacharacter problem too.
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) INSTALL_DIR="$HOME/.local/bin" ;;
        *":$HOME/bin:"*)        INSTALL_DIR="$HOME/bin" ;;
        *":/usr/local/bin:"*)
            if [ -w /usr/local/bin ]; then
                INSTALL_DIR=/usr/local/bin
            else
                INSTALL_DIR="$HOME/.local/bin"
                PATH_WARNING=1
            fi
            ;;
        *)
            # Default to ~/.local/bin even if not in PATH
            INSTALL_DIR="$HOME/.local/bin"
            PATH_WARNING=1
            ;;
    esac
}

# Locate fip/fop sitting next to this script, if there are any.
#
# The installer is used two ways: piped straight from the network
# (curl -fsSL .../install.sh | sh) and run from a checkout (./install.sh). Piped,
# there is nothing on disk to copy and the files must be downloaded. From a
# checkout, downloading would overwrite the working copy with whatever is on the
# remote -- silently reverting local edits that have not been pushed yet. Prefer
# the adjacent files whenever they exist.
find_local_source() {
    LOCAL_DIR=""

    # When piped, "$0" is the shell's name ("sh"), not a path to a readable file,
    # so this test is what distinguishes the two invocation styles.
    [ -f "$0" ] || return 0

    # CDPATH= keeps a user's CDPATH from redirecting the cd
    _dir=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd) || _dir=""
    if [ -n "$_dir" ] && [ -f "$_dir/fip" ] && [ -f "$_dir/fop" ]; then
        LOCAL_DIR="$_dir"
    fi
}

# Fetch one file from the project's raw URL, atomically.
#
# Never write the live destination directly: curl -o and wget -O truncate in place,
# so a connection dropped mid-body overwrites a working tool with a partial script
# that KEEPS the previous install's +x bit -- and roughly half of all cut points
# still parse cleanly and exit 0 without ever touching the clipboard, so
# `echo secret | fip` reports success while the clipboard is untouched. The wget
# branch is worse: it truncates before the HTTP status is known, so a plain 404
# destroys the file.
#
# Stage INSIDE the destination directory: mv is only atomic within one filesystem,
# and $TMPDIR is routinely a separate tmpfs from $HOME, where a cross-device mv
# degrades to copy+unlink and reopens the target with O_TRUNC -- reintroducing the
# exact partial-write window this is meant to close.
download_tool() {
    _name="$1"
    _dest="$2"
    _url="https://raw.githubusercontent.com/Blakemagne/fip-fop/main/$_name"
    _dir=$(dirname -- "$_dest")

    _tmp=$(mktemp "$_dir/.$_name.XXXXXX") || {
        error "cannot create a temp file in $_dir"
        exit 1
    }

    info "Downloading $_name..."
    _ok=0
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$_url" -o "$_tmp" || _ok=1
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$_url" -O "$_tmp" || _ok=1
    else
        rm -f "$_tmp"
        error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi

    if [ "$_ok" -ne 0 ] || [ ! -s "$_tmp" ]; then
        rm -f "$_tmp"
        error "download of $_name failed; $_dest left unchanged"
        exit 1
    fi

    # A captive portal or proxy can answer 200 with an HTML login page, which
    # curl -f will not reject. Anything that is not a script is not installable.
    # This is a corrupt-transfer guard, not an integrity control.
    case $(head -n 1 "$_tmp") in
        '#!'*) ;;
        *)
            rm -f "$_tmp"
            error "downloaded $_name is not a script; $_dest left unchanged"
            exit 1
            ;;
    esac

    # 755 explicitly, NOT `chmod +x`: mktemp creates 0600, so +x would yield 0711,
    # and a shell script needs READ permission to execute. get_install_dir can
    # select /usr/local/bin, where 0711 would break every other user on the box.
    chmod 755 "$_tmp"
    mv -- "$_tmp" "$_dest"
}

# Install fip and fop, from the local checkout when possible
install_tools() {
    find_local_source

    info "Creating installation directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"

    # Set FIPFOP_FORCE_DOWNLOAD=1 to fetch the published versions even from a checkout
    if [ -n "$LOCAL_DIR" ] && [ -z "$FIPFOP_FORCE_DOWNLOAD" ]; then
        info "Installing from local checkout: $LOCAL_DIR"
        for _name in fip fop; do
            # Refuse to copy a file onto itself, which would truncate it
            if [ "$LOCAL_DIR/$_name" -ef "$INSTALL_DIR/$_name" ] 2>/dev/null; then
                success "$_name already installed at $INSTALL_DIR/$_name"
                continue
            fi
            cp -- "$LOCAL_DIR/$_name" "$INSTALL_DIR/$_name"
            chmod +x "$INSTALL_DIR/$_name"
            success "$_name installed to $INSTALL_DIR/$_name"
        done
        return
    fi

    for _name in fip fop; do
        # download_tool chmods 755 and moves into place atomically
        download_tool "$_name" "$INSTALL_DIR/$_name"
        success "$_name installed to $INSTALL_DIR/$_name"
    done
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
                # $INSTALL_DIR is $HOME-derived, so it must be an ARGUMENT, never
                # part of the format: a home directory containing % or a backslash
                # would otherwise be mangled in the exact line the user is told to
                # copy verbatim (e.g. /home/us%ser prints as /home/user).
                printf '  %sset -x PATH $PATH %s%s\n' "$GREEN" "$INSTALL_DIR" "$RESET"
                printf "\n"
                info "Then reload your shell configuration:"
                printf "  ${GREEN}source $RC_FILE${RESET}\n"
                return
                ;;
            *)
                RC_FILE="~/.profile"
                ;;
        esac
        
        # Single-quoted format keeps $PATH literal for the user to paste
        printf '  %sexport PATH="$PATH:%s"%s\n' "$GREEN" "$INSTALL_DIR" "$RESET"
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
        printf '  %s%s/fip%s    # Copy to clipboard\n' "$GREEN" "$INSTALL_DIR" "$RESET"
        printf '  %s%s/fop%s    # Paste from clipboard\n' "$GREEN" "$INSTALL_DIR" "$RESET"
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