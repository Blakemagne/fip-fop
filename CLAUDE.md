# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`fip` is a portable POSIX-compliant shell utility that copies file contents or stdin to the system clipboard across Linux (X11/Wayland), macOS, and WSL.

## Development Commands

### Running the Script
```bash
# Copy file contents to clipboard
./fip filename

# Copy stdin to clipboard
echo "text" | ./fip
command | ./fip
```

### Making Script Executable
```bash
chmod +x fip
```

### Testing Clipboard Functionality
```bash
# Test with a file
echo "test content" > test.txt
./fip test.txt

# Test with stdin
echo "test from stdin" | ./fip

# Verify clipboard detection
sh -c 'command -v wl-copy || command -v xclip || command -v pbcopy || (grep -qi microsoft /proc/version && command -v clip.exe) || echo "No clipboard tool found"'
```

## Architecture Notes

This is a single-file utility with:
- No build process or dependencies beyond system clipboard tools
- Automatic clipboard backend detection in order: wl-copy → xclip → pbcopy → clip.exe
- POSIX sh compliance for maximum portability
- Error handling with `set -e` and informative error messages

The script structure:
1. Clipboard backend detection (lines 6-18)
2. Input handling for file or stdin (lines 20-28)
3. All clipboard commands are executed via shell variable expansion

## Key Implementation Details

- Uses `command -v` for portable command detection
- WSL detection via `/proc/version` grep pattern
- Handles file arguments with `--` to prevent option injection
- Exit codes: 0 for success, 1 for errors (missing clipboard tool or invalid usage)