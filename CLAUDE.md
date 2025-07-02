# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains **fip** and **fop** - two POSIX-compliant shell utilities for cross-platform clipboard operations:

- **fip** (file in paste): Copy file contents or stdin to clipboard
- **fop** (file out paste): Paste clipboard contents to stdout

The tools automatically detect and use the appropriate clipboard backend for the current platform (Linux X11/Wayland, macOS, WSL).

## Development Commands

### Testing
The project uses manual testing with shell commands (no automated test framework):

```bash
# Test fip (copy to clipboard)
echo "test" | ./fip && echo "✓ fip stdin test passed"
echo "test" > /tmp/test.txt && ./fip /tmp/test.txt && echo "✓ fip file test passed"

# Test fop (paste from clipboard) 
echo "clipboard test" | ./fip
[ "$(./fop)" = "clipboard test" ] && echo "✓ fop test passed"

# Test round-trip functionality
echo "round trip" | ./fip
./fop > /tmp/roundtrip.txt
[ "$(cat /tmp/roundtrip.txt)" = "round trip" ] && echo "✓ Round-trip test passed"

# Test error handling
./fip nonexistent.txt 2>/dev/null || echo "✓ fip error handling passed"
./fop --invalid 2>/dev/null || echo "✓ fop error handling passed"
```

### Installation
Use the automated installer for deployment:
```bash
./install.sh
```

## Architecture

### Core Components

1. **fip** (`/fip`): Input script that detects platform and copies to clipboard
2. **fop** (`/fop`): Output script that detects platform and reads from clipboard  
3. **install.sh**: Cross-platform installer with platform detection

### Platform Detection Strategy

Both scripts use identical detection logic in this order:
1. **wl-copy/wl-paste** (Wayland) - Modern Linux
2. **xclip** (X11) - Traditional Linux  
3. **pbcopy/pbpaste** (macOS) - Built-in macOS tools
4. **clip.exe/powershell.exe** (WSL) - Windows Subsystem for Linux

### Code Patterns

- **POSIX compliance**: Uses `#!/usr/bin/env sh` and avoids bash-specific features
- **Error handling**: `set -e` for fail-fast behavior
- **Security**: Uses `--` in commands to prevent option injection
- **Portability**: Uses `command -v` for tool detection, `printf` over `echo`

### Key Design Principles

- Single-file executables with no dependencies
- Extensive pedagogical comments explaining POSIX shell patterns
- Cross-platform clipboard abstraction
- Unified interface across different OS clipboard tools