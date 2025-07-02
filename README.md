# fip — Universal Clipboard Tool

**fip** (file in paste) is a portable, POSIX-compliant shell utility for copying file contents or standard input to the system clipboard. It provides a unified interface across different Unix-like operating systems.

## Features

- **Cross-platform**: Works on Linux (X11/Wayland), macOS, and Windows Subsystem for Linux
- **Zero dependencies**: Uses only built-in system clipboard tools
- **POSIX compliant**: Written in portable shell script, works with any POSIX shell (sh, bash, dash, etc.)
- **Smart detection**: Automatically finds and uses the appropriate clipboard tool
- **Flexible input**: Accepts both file arguments and piped input
- **Fast and lightweight**: Single file, no build process required

## Supported Platforms

| Platform | Clipboard Tool | Package Required |
|----------|----------------|------------------|
| Linux (Wayland) | `wl-copy` | `wl-clipboard` |
| Linux (X11) | `xclip` | `xclip` |
| macOS | `pbcopy` | Built-in |
| WSL | `clip.exe` | Built-in |

## Installation

### Quick Install

```bash
# One-line installer
curl -fsSL https://raw.githubusercontent.com/Blakemagne/fip/main/install.sh | sh

# Or with wget
wget -qO- https://raw.githubusercontent.com/Blakemagne/fip/main/install.sh | sh
```

### Manual Install

1. Clone the repository:
   ```bash
   git clone https://github.com/Blakemagne/fip.git
   cd fip
   ```

2. Make the script executable:
   ```bash
   chmod +x fip
   ```

3. Copy to a directory in your PATH:
   ```bash
   # User installation (recommended)
   mkdir -p ~/.local/bin
   cp fip ~/.local/bin/

   # System-wide installation (requires sudo)
   sudo cp fip /usr/local/bin/
   ```

### Package Manager Installation

#### Arch Linux (AUR)
```bash
# Coming soon
```

#### Homebrew (macOS/Linux)
```bash
# Coming soon
```

## Usage

### Basic Usage

Copy a file to clipboard:
```bash
fip filename.txt
```

Copy command output to clipboard:
```bash
ls -la | fip
```

Copy text to clipboard:
```bash
echo "Hello, World!" | fip
```

### Real-World Examples

Copy your SSH public key:
```bash
fip ~/.ssh/id_rsa.pub
```

Copy the current directory path:
```bash
pwd | fip
```

Copy a config file:
```bash
fip /etc/nginx/nginx.conf
```

Copy git diff output:
```bash
git diff | fip
```

Copy system information:
```bash
uname -a | fip
```

Copy the last command from history:
```bash
history | tail -1 | fip
```

## How It Works

### Clipboard Detection

`fip` automatically detects which clipboard tool is available on your system, checking in this order:

1. **`wl-copy`** (Wayland) - For modern Linux desktops using Wayland
2. **`xclip`** (X11) - For traditional Linux desktops using X Window System
3. **`pbcopy`** (macOS) - Built into macOS
4. **`clip.exe`** (WSL) - For Linux running under Windows Subsystem for Linux

### Technical Details

- **POSIX Compliance**: Uses only POSIX shell features, avoiding bash-specific syntax
- **Error Handling**: Exits immediately on errors with `set -e`
- **Security**: Uses `--` in `cat` command to prevent option injection
- **Exit Codes**: 
  - `0`: Success
  - `1`: Error (missing clipboard tool or invalid usage)

### Script Structure

1. **Shebang**: `#!/usr/bin/env sh` - Uses env to find sh for maximum portability
2. **Error Mode**: `set -e` - Fail fast on any command error
3. **Detection**: Sequential checks for clipboard commands
4. **Input Handling**: Determines whether to read from file or stdin
5. **Execution**: Runs the appropriate clipboard command

## Troubleshooting

### No clipboard helper found

If you see this error, install the appropriate clipboard tool for your system:

**Linux (Wayland):**
```bash
# Debian/Ubuntu
sudo apt install wl-clipboard

# Fedora
sudo dnf install wl-clipboard

# Arch
sudo pacman -S wl-clipboard
```

**Linux (X11):**
```bash
# Debian/Ubuntu
sudo apt install xclip

# Fedora
sudo dnf install xclip

# Arch
sudo pacman -S xclip
```

### File not found

Ensure the file path is correct and you have read permissions:
```bash
ls -l filename.txt
```

### WSL clipboard issues

If `clip.exe` isn't working in WSL:
1. Ensure you're running WSL2 (not WSL1)
2. Try using the full path: `/mnt/c/Windows/System32/clip.exe`
3. Check that Windows paths are accessible

## Development

### Running Tests

```bash
# Basic functionality test
echo "test" | ./fip && echo "✓ Stdin test passed"
echo "test" > /tmp/test.txt && ./fip /tmp/test.txt && echo "✓ File test passed"

# Error handling test
./fip nonexistent.txt 2>/dev/null || echo "✓ Error handling test passed"
```

### Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Design Principles

- **Minimalism**: Do one thing well
- **Portability**: Work everywhere without modification
- **Simplicity**: Readable, maintainable code
- **No Dependencies**: Use only system tools

## Alternatives

- `xsel` - More complex X11 clipboard tool
- `clipboard` - Node.js based cross-platform solution
- `cb` - Go-based clipboard manager
- Platform-specific tools (`pbcopy`, `xclip`, etc.) directly

## Why fip?

- **One command** for all platforms instead of remembering different tools
- **No installation** of interpreters (Python, Node.js, etc.)
- **Lightweight** - just 92 lines of well-commented shell script
- **Educational** - Great example of portable shell scripting

## License

MIT License - see [LICENSE](LICENSE) file for details

## Author

Created by Blakemagne "stonks god"

## Acknowledgments

- Inspired by the Unix philosophy: "Do one thing and do it well"
- Thanks to the maintainers of `wl-clipboard`, `xclip`, and other clipboard tools