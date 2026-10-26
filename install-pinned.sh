#!/data/data/com.termux/files/usr/bin/bash
# claude-code-android: pinned install (native Termux, opt-in legacy path).
#
# Installs Claude Code 2.1.112, the last upstream version that ships a JS entry
# point and runs on Termux with no binary patching. Pins there and locks the pin
# against the in-process auto-updater. No glibc-runner, no patched binary, no
# auto-updating wrapper.
#
# This is the simplest, smallest path. The trade-off is that it stays at 2.1.112:
# you do not get newer claude features or fixes. If you want current claude, use
# install.sh (the default Path A) instead. This script is for people who want a
# minimal, no-shim install and are content to stay pinned.
#
# Re-run safe: every step is idempotent.
#
# Tracking the upstream issue: https://github.com/anthropics/claude-code/issues/50270

set -euo pipefail

CC_PIN="2.1.112"
CC_DIR="$PREFIX/lib/node_modules/@anthropic-ai/claude-code"

info(){ printf '\033[0;36m[info]\033[0m  %s\n' "$1"; }
ok(){   printf '\033[0;32m[ok]\033[0m    %s\n' "$1"; }
warn(){ printf '\033[0;33m[warn]\033[0m  %s\n' "$1" >&2; }
fail(){ printf '\033[0;31m[fail]\033[0m  %s\n' "$1" >&2; exit 1; }

# --- Preflight ---
[ -z "${PREFIX:-}" ] && fail "Run this inside Termux, not adb shell. Install Termux from F-Droid."
[ "$(uname -m)" = "aarch64" ] || fail "aarch64 only. uname -m reports: $(uname -m)"

# Android's low-memory killer can SIGKILL the process tree during a heavy install
# if this runs inside a claude session under memory pressure. A plain shell is safer.
if [ -n "${CLAUDE_CODE_EXECPATH:-}" ] || [ -n "${CLAUDECODE:-}" ]; then
  warn "You appear to be running inside a claude session; Android may kill the"
  warn "install under memory pressure. A plain Termux shell is safer."
  read -r -p "Continue anyway? [y/N] " LMK
  case "${LMK,,}" in y|yes) ;; *) fail "Stopped. Open a fresh Termux session and re-run." ;; esac
fi

# --- Do not clobber a newer native install ---
if [ -d "$HOME/.local/share/claude/versions" ] && ls "$HOME/.local/share/claude/versions"/*.*.* >/dev/null 2>&1 \
   && [ -f "$PREFIX/bin/claude" ] && [ ! -L "$PREFIX/bin/claude" ]; then
  warn "A native (install.sh) claude install is already present."
  warn "Continuing installs the pinned $CC_PIN npm package and takes over the"
  warn "'claude' command. This is a downgrade."
  read -r -p "Replace it with the pinned install? [y/N] " DG
  case "${DG,,}" in y|yes) ;; *) fail "Stopped. Nothing changed." ;; esac
fi

ok "Running in Termux on aarch64"

# --- Pin a Termux mirror if none is selected (avoids an interactive stall) ---
if [ ! -e "$PREFIX/etc/termux/chosen_mirrors" ] && [ -e "$PREFIX/etc/termux/mirrors/default" ]; then
  ln -sf "$PREFIX/etc/termux/mirrors/default" "$PREFIX/etc/termux/chosen_mirrors" 2>/dev/null || true
fi

# --- Node.js ---
export DEBIAN_FRONTEND=noninteractive
APT_OPTS="-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"
info "apt-get update"
apt-get update $APT_OPTS >/dev/null || fail "apt-get update failed. If it stalls, run 'termux-change-repo', pick a mirror, then re-run."
info "apt-get full-upgrade (brings the base current so node links against a matching openssl)"
apt-get full-upgrade $APT_OPTS >/dev/null || fail "apt-get full-upgrade failed."
info "apt-get install nodejs"
apt-get install $APT_OPTS nodejs >/dev/null || fail "apt-get install nodejs failed."
NODE_V="$(node -v 2>/dev/null || true)"
[ -n "$NODE_V" ] || fail "node installed but cannot run (an openssl mismatch usually). Re-run; if it persists, 'apt-get full-upgrade' by hand."
ok "Node.js $NODE_V installed"

# --- Claude Code (pinned) ---
export TMPDIR="$PREFIX/tmp"   # npm needs a writable temp dir
[ -d "$CC_DIR" ] && chmod -R u+w "$CC_DIR" 2>/dev/null || true
# npm install -g creates $PREFIX/bin/claude. A non-npm regular file there (an
# install.sh native wrapper) makes npm abort with EEXIST, which leaves a crashing
# native install in place. Clear it first so the pinned package can own the
# command. A symlink (npm's own, on a re-run) is left for npm to replace.
if [ -e "$PREFIX/bin/claude" ] && [ ! -L "$PREFIX/bin/claude" ]; then
  rm -f "$PREFIX/bin/claude"
  info "cleared the existing native claude command so the pinned package can own it"
fi
info "installing Claude Code $CC_PIN (the last upstream version with a JS entry point)"
DISABLE_AUTOUPDATER=1 npm install -g "@anthropic-ai/claude-code@${CC_PIN}" || fail "npm install failed."
CLAUDE_VER="$(claude --version 2>/dev/null | head -1 || true)"
{ [ -n "$CLAUDE_VER" ] && [[ "$CLAUDE_VER" != *"not installed"* ]]; } || fail "claude did not launch after install. 'claude --version' returned: $CLAUDE_VER"
ok "Claude Code installed: $CLAUDE_VER"

# --- Grep tool: system ripgrep symlinked onto the vendored path ---
# The 2.1.112 JS bundle spawns vendor/ripgrep/arm64-android/rg, which upstream
# does not ship, so Grep/Glob fail with spawn ENOENT. Install system ripgrep and
# symlink it onto that path. On device, CLAUDE_CODE_USE_NATIVE_FILE_SEARCH=1 does
# not redirect the search on 2.1.112 (the bundle still spawns the missing vendored
# path); the symlink is what works. $CC_DIR is still writable here, before the pin
# lock below. This is the same fix as scripts/fix-ripgrep.sh, run at install time.
FIX_RG_URL="https://raw.githubusercontent.com/ferrumclaudepilgrim/claude-code-android/main/scripts/fix-ripgrep.sh"
info "wiring Claude Code's Grep tool to system ripgrep"
apt-get install $APT_OPTS ripgrep >/dev/null || warn "ripgrep install failed; to enable Grep/Glob later, run: curl -fsSL $FIX_RG_URL -o fix-ripgrep.sh && bash fix-ripgrep.sh"
RG_BIN="$(command -v rg || true)"
if [ -n "$RG_BIN" ]; then
  VENDOR_RG="$CC_DIR/vendor/ripgrep/arm64-android"
  mkdir -p "$VENDOR_RG"
  ln -sf "$RG_BIN" "$VENDOR_RG/rg"
  ok "Grep tool wired to system ripgrep ($RG_BIN)"
else
  warn "ripgrep not found after install; to enable Grep/Glob, run: curl -fsSL $FIX_RG_URL -o fix-ripgrep.sh && bash fix-ripgrep.sh"
fi

# --- Lock the pin against the in-process auto-updater (three layers) ---
# The updater re-fetches 'latest' on a timer and overwrites the install dir; a
# 2.1.113+ build has no JS entry point and breaks on Termux. All three layers
# are needed: the read-only dir alone is insufficient (the updater can chmod +w
# before writing), so the env var (every shell) and the settings.json key
# (inside a running session) are what actually hold the pin.
info "locking the install against the auto-updater"
chmod -R a-w "$CC_DIR"
ok "install directory is read-only"

BASHRC="$HOME/.bashrc"
[ -f "$BASHRC" ] || touch "$BASHRC"
if ! grep -q '^export DISABLE_AUTOUPDATER=1' "$BASHRC" 2>/dev/null; then
  echo 'export DISABLE_AUTOUPDATER=1' >> "$BASHRC"
fi
ok "DISABLE_AUTOUPDATER=1 in ~/.bashrc"

mkdir -p "$HOME/.claude"
SETTINGS="$HOME/.claude/settings.json"
node -e "
const fs = require('fs');
const p = '$SETTINGS';
let s = {};
try { s = JSON.parse(fs.readFileSync(p, 'utf8')); } catch (e) {}
s.env = s.env || {};
s.env.DISABLE_AUTOUPDATER = '1';
fs.writeFileSync(p, JSON.stringify(s, null, 2));
" || fail "settings.json merge failed."
ok "env.DISABLE_AUTOUPDATER=1 in ~/.claude/settings.json"

cat <<DONE

Done. Open a new Termux session, then run:  claude

  Pinned to $CC_PIN. To move to current claude later, run install.sh (the
  default Path A) for the patched native binary with an auto-updating wrapper.

DONE
