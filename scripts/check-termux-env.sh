#!/usr/bin/env bash
# check-termux-env.sh: Diagnose your Android/Termux environment for
#                     Claude Code on Android.
#
# NOT the same as `claude doctor`. The built-in `claude doctor` checks
# Claude Code's own runtime health. This script checks the Termux side:
# install integrity, the wrapper, Termux:API, file-descriptor limit,
# background process count, storage.
#
# Auto-detects whether you are running the Path A launcher (patched
# linux-arm64 binary + auto-updating wrapper) or the pinned install (npm
# Claude Code 2.1.112). Checks adjust accordingly.
#
# Use this when something is wrong and you want to know which Termux
# constraint is biting you, or after a fresh install to sanity-check.
# Safe to run repeatedly; read-only.
#
# Usage:
#   bash scripts/check-termux-env.sh
#
# Exit codes:
#   0 = all FAIL=0 (WARN allowed; advisory only)
#   1 = one or more FAIL items

set -uo pipefail

FAILS=0
WARNS=0
PASSES=0

row() {
  local n="$1"
  local check="$2"
  local status="$3"
  local detail="$4"
  printf '| %2s | %-32s | %-4s | %s\n' "$n" "$check" "$status" "$detail"
  case "$status" in
    PASS) PASSES=$((PASSES+1)) ;;
    WARN) WARNS=$((WARNS+1)) ;;
    FAIL) FAILS=$((FAILS+1)) ;;
  esac
}

# --- Detect install type ---
# Filesystem-only signals (no string-matching against wrapper contents):
#   v2.9.0 install: $HOME/.local/share/claude/versions/ exists AND
#                   $PREFIX/bin/claude exists AND is a regular file
#                   (the wrapper script), not a symlink.
#   v2.x install:   $PREFIX/lib/node_modules/@anthropic-ai/claude-code/
#                   exists (the npm-installed package), and $PREFIX/bin/claude
#                   is a symlink into it.
INSTALL_TYPE=unknown
V3_BINARY_DIR="$HOME/.local/share/claude/versions"
V3_WRAPPER="$PREFIX/bin/claude"
V2_INSTALL_DIR="$PREFIX/lib/node_modules/@anthropic-ai/claude-code"

if [ -d "$V3_BINARY_DIR" ] && [ -f "$V3_WRAPPER" ] && [ ! -L "$V3_WRAPPER" ]; then
  INSTALL_TYPE=v2.9.0
elif [ -d "$V2_INSTALL_DIR" ]; then
  INSTALL_TYPE=v2.x
elif command -v claude >/dev/null 2>&1; then
  INSTALL_TYPE=unknown-but-claude-on-path
fi

echo "Claude Code Android: Environment Diagnostic"
echo "Date: $(date -u '+%Y-%m-%d %H:%M:%SZ')"
case "$INSTALL_TYPE" in
  v2.9.0) INSTALL_LABEL="Path A launcher" ;;
  v2.x) INSTALL_LABEL="pinned install" ;;
  unknown-but-claude-on-path) INSTALL_LABEL="not recognized (claude is on PATH)" ;;
  *) INSTALL_LABEL="none found" ;;
esac
echo "Install type detected: $INSTALL_LABEL"
echo ""
printf '| %2s | %-32s | %-4s | %s\n' '#' Check Status Detail
printf '| %2s-+-%-32s-+-%-4s-+-%s\n' '--' '--------------------------------' '----' '------------------------------'

# --- 1. claude on PATH and version ---
CC_VER="$(claude --version 2>/dev/null | head -1 || echo NOT_FOUND)"
if [ "$CC_VER" = NOT_FOUND ]; then
  row 1 "claude on PATH" FAIL "claude not on PATH (run install.sh)"
else
  row 1 "claude --version" PASS "$CC_VER"
fi

# --- 2. Wrapper integrity (v2.9 specific) ---
if [ "$INSTALL_TYPE" = v2.9.0 ]; then
  if [ -x "$V3_WRAPPER" ]; then
    row 2 "wrapper at \$PREFIX/bin/claude" PASS "auto-updating wrapper installed"
  else
    row 2 "wrapper at \$PREFIX/bin/claude" FAIL "wrapper missing or not executable"
  fi
elif [ "$INSTALL_TYPE" = v2.x ]; then
  # v2: check install-dir read-only lock
  if [ -d "$V2_INSTALL_DIR" ] && [ "$(stat -c '%A' "$V2_INSTALL_DIR" 2>/dev/null | cut -c1-4)" = "dr-x" ]; then
    row 2 "install dir read-only (pinned)" PASS "auto-updater cannot overwrite"
  else
    row 2 "install dir read-only (pinned)" WARN "directory writable; the auto-updater can clobber the pin"
  fi
else
  row 2 "install integrity" WARN "install type not recognized; manual inspection recommended"
fi

# --- 3. Binary location (v2.9 specific) ---
if [ "$INSTALL_TYPE" = v2.9.0 ]; then
  if [ -d "$V3_BINARY_DIR" ]; then
    LATEST_BIN=$(
      for cand in "$V3_BINARY_DIR"/*; do
        [ -e "$cand" ] || continue
        name=$(basename "$cand")
        [[ "$name" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && printf '%s\n' "$name"
      done | sort -V | tail -1
    )
    if [ -n "$LATEST_BIN" ] && [ -f "$V3_BINARY_DIR/$LATEST_BIN" ]; then
      row 3 "patched binary present" PASS "$V3_BINARY_DIR/$LATEST_BIN"
    else
      row 3 "patched binary present" FAIL "$V3_BINARY_DIR exists but no versioned binary inside"
    fi
  else
    row 3 "patched binary present" FAIL "$V3_BINARY_DIR does not exist"
  fi
fi

# --- 4. settings.json autoUpdates flag (v2.9 specific) ---
SETTINGS="$HOME/.claude/settings.json"
if [ "$INSTALL_TYPE" = v2.9.0 ]; then
  if [ -f "$SETTINGS" ]; then
    if grep -q '"autoUpdates":[[:space:]]*false' "$SETTINGS"; then
      row 4 "autoUpdates disabled" PASS "settings.json has autoUpdates:false"
    else
      row 4 "autoUpdates disabled" WARN "settings.json missing autoUpdates:false; wrapper still works but in-process updater may interfere"
    fi
  else
    row 4 "autoUpdates disabled" WARN "$SETTINGS not found"
  fi
fi

# --- 5. patchelf + glibc-runner (v2.9 specific) ---
if [ "$INSTALL_TYPE" = v2.9.0 ]; then
  if [ -x "$PREFIX/glibc/bin/patchelf" ] && [ -f "$PREFIX/glibc/lib/ld-linux-aarch64.so.1" ]; then
    row 5 "glibc-runner + patchelf" PASS "both present"
  else
    row 5 "glibc-runner + patchelf" FAIL "missing; reinstall via install.sh"
  fi
fi

# --- 6. Termux packages ---
# Confirms Termux's own tools are installed. It cannot tell where Termux was
# installed from; the Termux maintainers recommend F-Droid or GitHub releases.
TERMUX_VER="$(pkg show termux-tools 2>/dev/null | awk -F: '/^Version:/ {print $2; exit}' | tr -d ' ' || true)"
if [ -n "$TERMUX_VER" ]; then
  row 6 "Termux packages found" PASS "termux-tools $TERMUX_VER"
else
  row 6 "Termux packages found" WARN "could not read the termux-tools version (the Termux maintainers recommend F-Droid or GitHub releases)"
fi

# --- 7. fd limit ---
FD_LIMIT="$(ulimit -n)"
if [ "$FD_LIMIT" -ge 1024 ] 2>/dev/null; then
  row 7 "File descriptor limit" PASS "$FD_LIMIT"
else
  row 7 "File descriptor limit" WARN "$FD_LIMIT (may limit heavy I/O)"
fi

# --- 8. Background process count ---
# Counts the processes visible from Termux. Android can stop excess child
# processes (its phantom process controls); the exact limit varies by device.
BG_COUNT="$(ps -o pid= 2>/dev/null | wc -l)"
if [ "$BG_COUNT" -lt 25 ] 2>/dev/null; then
  row 8 "Background process count" PASS "$BG_COUNT running"
else
  row 8 "Background process count" WARN "$BG_COUNT running; Android may stop extra processes (see troubleshooting)"
fi

# --- 9. Storage ---
FREE_MB="$(df -m "$HOME" 2>/dev/null | awk 'NR==2 {print $4}')"
if [ -n "$FREE_MB" ] && [ "$FREE_MB" -ge 500 ] 2>/dev/null; then
  row 9 "Storage free" PASS "${FREE_MB}M available in \$HOME"
else
  row 9 "Storage free" WARN "${FREE_MB:-?}M (under 500MB is tight)"
fi

# --- 10. Termux:API ---
if command -v termux-battery-status >/dev/null 2>&1; then
  row 10 "Termux:API installed" PASS "termux-battery-status on PATH"
else
  row 10 "Termux:API installed" WARN "missing (notifications, clipboard, sensors, etc. will not work)"
fi

# --- Summary ---

echo ""
echo "Summary: $PASSES PASS, $WARNS WARN, $FAILS FAIL"
if [ "$FAILS" -gt 0 ]; then
  echo ""
  echo "One or more checks FAILED. Fix recommendations:"
  if [ "$INSTALL_TYPE" = v2.9.0 ]; then
    echo "  - If 'claude on PATH' failed: re-run install.sh"
    echo "  - If 'patched binary present' failed: re-run install.sh"
    echo "  - If 'glibc-runner + patchelf' failed: pkg install glibc-runner patchelf-glibc"
  else
    echo "  - If 'claude on PATH' failed: run install.sh"
  fi
  exit 1
fi
exit 0
