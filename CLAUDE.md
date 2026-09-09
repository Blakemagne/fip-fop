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
- **Byte fidelity**: Content is staged through a `mktemp` file, never a shell
  variable. `$(...)` strips trailing newlines and shell variables cannot hold NUL
  bytes, so a variable round trip silently corrupts anything but short ASCII text.

### Wayland Constraints (non-obvious — read before editing)

These do not apply to the macOS or WSL backends, which is why the original
WSL-era implementation looked correct but misbehaved on Wayland:

1. **wl-copy daemonizes and inherits file descriptors.** A Wayland clipboard is
   owned by a live client, so `wl-copy` forks a resident process to serve the data.
   That child inherits whatever stdout/stderr it was given. If they are a *pipe*,
   the daemon holds the write end open forever and any reader hangs — so
   `fip | anything` and `$(fip)` would never return. `fip` therefore invokes the
   backend as `>/dev/null 2>"$ERR"`. A regular file is fine (it blocks no reader),
   which is how stderr is still captured for error reporting. `xclip` behaves the
   same way; `clip.exe` and `pbcopy` exit immediately and never showed this.

2. **A clipboard offer carries multiple MIME types at once.** Bare `wl-paste`
   takes the *first* type offered, and browsers list `text/html` first — so `fop`
   would emit raw markup. `fop` reads `wl-paste --list-types` and explicitly asks
   for whichever `text/plain*` variant is advertised (the spelling varies between
   `text/plain` and `text/plain;charset=utf-8`), falling back to the default offer
   for non-text clipboards such as images.

3. **`--no-newline`** stops `wl-paste` appending a trailing newline the source
   never had.

4. **Beware `[ ... ] && cmd` as a script's final statement.** If the test fails,
   the list's status is non-zero and becomes the script's exit status, breaking
   callers running under `set -e`. Use an `if` block instead.

5. **The MIME type from `--list-types` is attacker-controlled.** Any local process
   can advertise a clipboard offer whose type is literally
   `text/plain --watch /path/evil`. That sorts ahead of the real `text/plain`, wins
   `head -n 1`, and — if interpolated into an unquoted command string — word-splits
   into `wl-paste`'s `--watch` *option*, executing the attacker's program and
   leaving a resident watcher that re-fires on every clipboard change. This was a
   live vulnerability, reproduced end to end. `fop` therefore carries its backend
   argv in the positional parameters (`set -- ...` then `"$@"`) and filters the
   type through `grep -v '[^A-Za-z0-9/.+;=_-]'`. **Never** put `$PLAIN_TYPE` in an
   unquoted string. The filter must *skip* a hostile type rather than blank
   `PLAIN_TYPE`, or the fallback reintroduces the `text/html` bug exactly when
   attacked. `fip` has no such exposure — its `CLIP_CMD` holds only literals — which
   is why the two scripts legitimately differ here.

### Other invariants worth not breaking

- **Backend detection is gated on `WAYLAND_DISPLAY` / `DISPLAY`, then repeated
  ungated as a tail.** The gate fixes X11 boxes that merely have wl-clipboard
  installed; the ungated tail preserves `wl-copy`'s documented fallback to
  `$XDG_RUNTIME_DIR/wayland-0` under cron, systemd user units, and pre-compositor
  tmux servers. Removing either half regresses real setups.
- **Emptiness is judged from the staged file (`[ ! -s ]`), not the backend's exit
  status.** `pbpaste`, `Get-Clipboard`, and `xclip -o` / `xsel -b -o` on an unowned
  selection all exit 0 with no output, so status-based detection worked only on
  Wayland.
- **Content previews are gated on `[ -t 2 ]`.** These tools carry passwords; an
  ungated preview writes them into logs, scrollback, and CI output.
- **Traps list `EXIT HUP INT QUIT TERM`.** dash and busybox ash do not run the EXIT
  trap on an untrapped fatal signal; bash does, which hides the leak on Arch.
- **WSL CR stripping is a separate step, never a pipeline.** A pipeline's status is
  its last command's and `tr` always succeeds, so piping through it would
  permanently mask backend failures. POSIX sh has no `pipefail`.
- **`install.sh` stages downloads inside `$INSTALL_DIR`, not `$TMPDIR`.** `mv` is
  atomic only within a filesystem, and `/tmp` is routinely a separate tmpfs.
  It uses `chmod 755`, not `chmod +x` — `mktemp` creates 0600 and `+x` yields 0711,
  which lacks the read permission a shell script needs to execute.

### Key Design Principles

- Single-file executables with no dependencies
- Extensive pedagogical comments explaining POSIX shell patterns
- Cross-platform clipboard abstraction
- Unified interface across different OS clipboard tools