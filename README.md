# fip & fop — Universal Clipboard Utilities

**fip** (file in paste) and **fop** (file out paste) are portable, POSIX-compliant shell utilities for clipboard operations. Together they provide a complete clipboard workflow:

- **fip**: Copy file contents or stdin TO the clipboard
- **fop**: Paste clipboard contents TO stdout

These tools provide a unified interface across different Unix-like operating systems.

## Why fip & fop?

- **Unified commands** across all platforms instead of platform-specific tools
- **Complete workflow** - both copy and paste operations
- **No dependencies** - no interpreters (Python, Node.js, etc.) required
- **Lightweight** - two small shell scripts, well-commented
- **POSIX compliant** - works with any shell, not just bash

### Design Principles

- **Minimalism**: Do one thing well
- **Portability**: Work everywhere without modification
- **Simplicity**: Readable, maintainable code
- **No Dependencies**: Use only system tools

## Features

- **Cross-platform**: Works on Linux (X11/Wayland), macOS, and Windows Subsystem for Linux
- **Zero dependencies**: Uses only built-in system clipboard tools
- **POSIX compliant**: Written in portable shell script, works with any POSIX shell (sh, bash, dash, etc.)
- **Smart detection**: Automatically finds and uses the appropriate clipboard tool
- **Bidirectional**: Complete clipboard workflow with fip (copy) and fop (paste)
- **Flexible I/O**: Supports files, stdin, stdout, and pipes
- **Fast and lightweight**: Two single-file scripts, no build process required

## Supported Platforms

| Platform | Copy Tool | Paste Tool | Package Required |
|----------|-----------|------------|------------------|
| Linux (Wayland) | `wl-copy` | `wl-paste` | `wl-clipboard` |
| Linux (X11) | `xclip` | `xclip` | `xclip` |
| macOS | `pbcopy` | `pbpaste` | Built-in |
| WSL | `clip.exe` | `powershell.exe` | Built-in |

## Installation

### Quick Install (Recommended)

The installer automatically detects your platform, installs to the appropriate directory, and makes the tools globally available:

```bash
# One-line installer (installs both fip and fop globally)
curl -fsSL https://raw.githubusercontent.com/Blakemagne/fip/main/install.sh | sh

# Or with wget
wget -qO- https://raw.githubusercontent.com/Blakemagne/fip/main/install.sh | sh
```

After installation, you can use `fip` and `fop` from anywhere without `./` prefix.

### Manual Install

1. Clone the repository:
   ```bash
   git clone https://github.com/Blakemagne/fip.git
   cd fip
   ```

2. Make the scripts executable:
   ```bash
   chmod +x fip fop
   ```

3. Copy to a directory in your PATH:
   ```bash
   # User installation (recommended)
   mkdir -p ~/.local/bin
   cp fip fop ~/.local/bin/

   # System-wide installation (requires sudo)
   sudo cp fip fop /usr/local/bin/
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

**Copy to clipboard (fip):**
```bash
# Copy file contents
fip filename.txt

# Copy command output
ls -la | fip

# Copy text
echo "Hello, World!" | fip

# Show help
fip --help
```

**Paste from clipboard (fop):**
```bash
# Output to terminal
fop

# Save to file
fop > output.txt

# Append to file
fop >> notes.txt

# Pipe to command
fop | grep "search term"

# Show help
fop --help
```

### Real-World Examples

**Clipboard Workflows:**
```bash
# Copy code, then append notes
fip script.py
echo "\n# Notes: Fixed bug in line 42" | fip
fop > script-with-notes.py

# Share command output
pwd | fip
# On another terminal:
cd $(fop)

# Quick file transfer between directories
fip config.json
cd /another/directory
fop > config.json
```

**Common fip usage:**
```bash
# Copy SSH public key
fip ~/.ssh/id_rsa.pub

# Copy current directory
pwd | fip

# Copy git diff
git diff | fip

# Copy last command
history | tail -1 | fip
```

**Common fop usage:**
```bash
# Create file from clipboard
fop > newfile.txt

# Search clipboard contents
fop | grep -n "TODO"

# Process clipboard data
fop | jq '.items[] | .name'

# Count clipboard lines
fop | wc -l

# Use clipboard in commands (command substitution)
echo "$(fop)"
curl "$(fop)"
ssh "$(fop)"
cd "$(fop)"
```

## How It Works

### Clipboard Detection

Both tools automatically detect which clipboard utilities are available:

**fip (copy) checks for:**
1. **`wl-copy`** (Wayland) - For modern Linux desktops
2. **`xclip`** (X11) - For traditional Linux desktops
3. **`pbcopy`** (macOS) - Built into macOS
4. **`clip.exe`** (WSL) - Windows clipboard access

**fop (paste) checks for:**
1. **`wl-paste`** (Wayland) - Wayland clipboard reading
2. **`xclip -out`** (X11) - X11 clipboard reading
3. **`pbpaste`** (macOS) - Built into macOS
4. **`powershell.exe Get-Clipboard`** (WSL) - Windows clipboard access

### Technical Details

- **POSIX Compliance**: Uses only POSIX shell features, avoiding bash-specific syntax
- **Error Handling**: Exits immediately on errors with `set -e`
- **Security**: Uses `--` in `cat` command to prevent option injection
- **Exit Codes**: 
  - `0`: Success
  - `1`: Error (missing clipboard tool or invalid usage)

### Script Structure

Both scripts follow the same pattern:

1. **Shebang**: `#!/usr/bin/env sh` - Maximum portability
2. **Error Mode**: `set -e` - Fail fast on errors
3. **Detection**: Sequential checks for clipboard commands
4. **Help Flag**: `-h` or `--help` shows usage
5. **I/O Handling**: 
   - fip: Reads from file or stdin
   - fop: Writes to stdout only
6. **Execution**: Runs the appropriate clipboard command


## Alternatives

- `xsel` - More complex X11 clipboard tool
- `clipboard` - Node.js based cross-platform solution
- `cb` - Go-based clipboard manager
- Platform-specific tools (`pbcopy`, `xclip`, etc.) directly


## Author

Created by Blakemagne 
"stonks god"


## License

MIT License
