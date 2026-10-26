#!/usr/bin/env bash
# verify-claims.sh: Runs selected device evidence checks. It is not a
# comprehensive verification of every repository claim. Safe to re-run, but it
# replaces this device's result artifact under tests/results/.
#
# Every test produces one of three verdicts:
#   PASS   the claim is empirically true on this device
#   FAIL   the claim is empirically false on this device
#   SKIP   precondition not met (e.g., optional package not installed)
#
# Some checks target the optional pinned v2.x fallback and explicitly SKIP
# when that architecture is not installed.
#
# Usage: bash tests/verify-claims.sh
# Results: stdout + tests/results/<device>-android<version>.txt
#
# To contribute device data, submit your results file via pull request (PR).

set -uo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
HOME="${HOME:-/data/data/com.termux/files/home}"

# --- Device detection ---
DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null | tr ' ' '-' | tr '[:upper:]' '[:lower:]' || true)
if [ -z "$DEVICE_MODEL" ]; then
  DEVICE_MODEL=$(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r' | tr ' ' '-' | tr '[:upper:]' '[:lower:]' || true)
fi
DEVICE_MODEL="${DEVICE_MODEL:-unknown}"

ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null || true)
if [ -z "$ANDROID_VER" ]; then
  ANDROID_VER=$(adb shell getprop ro.build.version.release 2>/dev/null | tr -d '\r' || true)
fi
ANDROID_VER="${ANDROID_VER:-unknown}"

# --- Paths ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/results"
if ! mkdir -p "$RESULTS_DIR"; then
    printf 'HARNESS_ERROR: cannot create results directory: %s\n' "$RESULTS_DIR" >&2
    exit 2
fi
RESULTS_FILE="${RESULTS_DIR}/${DEVICE_MODEL}-android${ANDROID_VER}.txt"

# --- Counters ---
PASS_N=0
FAIL_N=0
SKIP_N=0
TOTAL=0

# --- Helpers ---
print_header() {
    local kernel date_str kernel_short
    kernel="$(uname -r 2>/dev/null || echo 'unknown')"
    date_str="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')"
    kernel_short="${kernel:0:40}"
    printf "╔══════════════════════════════════════════════════════╗\n"
    printf "║  claude-code-android : Claims Verification           ║\n"
    printf "║  Date: %-45s ║\n" "$date_str"
    printf "║  Kernel: %-43s ║\n" "$kernel_short"
    printf "╚══════════════════════════════════════════════════════╝\n"
}

print_claim() {
    local num="$1"
    local title="$2"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "CLAIM $num: $title"
}

verdict_pass() {
    PASS_N=$((PASS_N + 1)); TOTAL=$((TOTAL + 1))
    echo "  Verdict: PASS"
}

verdict_fail() {
    local reason="$1"
    FAIL_N=$((FAIL_N + 1)); TOTAL=$((TOTAL + 1))
    echo "  Verdict: FAIL. $reason"
}

verdict_skip() {
    local reason="$1"
    SKIP_N=$((SKIP_N + 1)); TOTAL=$((TOTAL + 1))
    echo "  Verdict: SKIP. $reason"
}

# Reset results file and tee everything to it
: > "$RESULTS_FILE" || {
    printf 'HARNESS_ERROR: cannot write results artifact: %s\n' "$RESULTS_FILE" >&2
    exit 2
}
exec > >(tee "$RESULTS_FILE") 2>&1

print_header

# ──────────────────────────────────────────────────────────────
# CLAIM 1: Claude Code's vendor dir has no native arm64-android ripgrep binary
# Source: docs/troubleshooting.md
# ──────────────────────────────────────────────────────────────
print_claim 1 "Claude Code does not bundle a native arm64-android ripgrep binary"
echo "  Test:  Inspect vendor/ripgrep/arm64-android/rg, should be missing or a user-created symlink"

CLAUDE_BIN="$(command -v claude 2>/dev/null || echo '')"
if [ -z "$CLAUDE_BIN" ]; then
    verdict_skip "claude not on PATH; cannot inspect vendor dir"
else
    VENDOR="$(dirname "$CLAUDE_BIN")/../lib/node_modules/@anthropic-ai/claude-code/vendor/ripgrep"
    if [ ! -d "$VENDOR" ]; then
        verdict_skip "vendor/ripgrep dir not at expected path: $VENDOR"
    else
        RG_PATH="$VENDOR/arm64-android/rg"
        echo "  Platform dirs present:"
        ls "$VENDOR" 2>/dev/null | sed 's/^/    /' | head -10
        if [ ! -e "$RG_PATH" ]; then
            echo "  Result: no arm64-android/rg present at all"
            verdict_pass
        elif [ -L "$RG_PATH" ]; then
            LINK="$(readlink "$RG_PATH" 2>/dev/null)"
            echo "  Result: arm64-android/rg is a symlink → $LINK (user-supplied recovery)"
            verdict_pass
        else
            SIZE="$(stat -c '%s' "$RG_PATH" 2>/dev/null || echo '?')"
            if [ "$SIZE" -gt 100000 ] 2>/dev/null; then
                verdict_fail "arm64-android/rg is a $SIZE-byte native binary; vendor now includes arm64-android"
            else
                echo "  Result: arm64-android/rg present but small ($SIZE bytes), likely a stub"
                verdict_pass
            fi
        fi
    fi
fi

# ──────────────────────────────────────────────────────────────
# CLAIM 2: File descriptor limits are queryable
# Source: docs/troubleshooting.md (EMFILE: too many open files error section)
# ──────────────────────────────────────────────────────────────
print_claim 2 "File descriptor limits are queryable on this device (varies by device/Android)"
echo "  Test:  ulimit -n (soft) and ulimit -Hn (hard) both return positive integers"

FD_SOFT="$(ulimit -n 2>/dev/null || echo '')"
FD_HARD="$(ulimit -Hn 2>/dev/null || echo '')"
echo "  Evidence: soft=$FD_SOFT  hard=$FD_HARD"

if [ -n "$FD_SOFT" ] && [ -n "$FD_HARD" ] && [ "$FD_SOFT" -gt 0 ] 2>/dev/null && [ "$FD_HARD" -gt 0 ] 2>/dev/null; then
    verdict_pass
else
    verdict_fail "could not read file descriptor (FD) limits"
fi

# ──────────────────────────────────────────────────────────────
# CLAIM 3: the v2.x pinned install locks the Claude Code install directory read-only
# Source: install-pinned.sh, docs/install.md
# ──────────────────────────────────────────────────────────────
print_claim 3 "[v2.x architecture] the pinned install locks the Claude Code install directory read-only (auto-updater protection)"
echo "  Test:  Inspect permissions on the install dir; expect dr-x------ (no write bit)"

CC_INSTALL_DIR="$PREFIX/lib/node_modules/@anthropic-ai/claude-code"
if [ ! -d "$CC_INSTALL_DIR" ]; then
    verdict_skip "claude-code not at $CC_INSTALL_DIR (v2.x npm path absent; this claim targets the v2.x install architecture)"
else
    PERMS=$(stat -c '%A' "$CC_INSTALL_DIR" 2>/dev/null)
    echo "  Permissions: $PERMS"
    if echo "$PERMS" | grep -qE '^dr-x'; then
        echo "  Result: v2.x install dir is read-only; auto-updater cannot overwrite the pinned install"
        verdict_pass
    else
        verdict_fail "install dir is writable ($PERMS); auto-updater can clobber the pin; re-run install-pinned.sh"
    fi
fi

# ──────────────────────────────────────────────────────────────
# CLAIM 4: Path B (Ubuntu installer) installs claude binary
# Source: docs/install.md (Path B)
# ──────────────────────────────────────────────────────────────
print_claim 4 "Path B: Anthropic install.sh inside proot-distro Ubuntu installs claude binary"
echo "  Test:  If Ubuntu rootfs present, look for claude binary in standard paths"

UBUNTU_ROOT="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"
if [ ! -d "$UBUNTU_ROOT" ]; then
    verdict_skip "proot-distro Ubuntu not installed (this is fine for Path A users)"
else
    CLAUDE_PATHS=(
        "$UBUNTU_ROOT/root/.local/bin/claude"
        "$UBUNTU_ROOT/home/user/.local/bin/claude"
        "$UBUNTU_ROOT/usr/local/bin/claude"
    )
    FOUND_AT=""
    for p in "${CLAUDE_PATHS[@]}"; do
        if [ -e "$p" ] || [ -L "$p" ]; then FOUND_AT="$p"; break; fi
    done
    if [ -n "$FOUND_AT" ]; then
        echo "  claude binary in Ubuntu: $FOUND_AT"
        verdict_pass
    else
        echo "  Searched: ${CLAUDE_PATHS[*]}"
        verdict_fail "Ubuntu rootfs present but no claude binary in standard install paths"
    fi
fi

# ──────────────────────────────────────────────────────────────
# CLAIM 5: claude CLI accepts --tools flag
# Source: docs/agent-permissions.md
# ──────────────────────────────────────────────────────────────
print_claim 5 "claude CLI accepts --tools for restricting tool access (cron safety)"
echo "  Test:  claude --help should mention --tools"

if [ -z "$(command -v claude 2>/dev/null)" ]; then
    verdict_skip "claude not on PATH"
else
    if claude --help 2>&1 | grep -q -- '--tools'; then
        echo "  --tools flag present in help output"
        verdict_pass
    else
        verdict_fail "--tools flag not found in claude --help"
    fi
fi

# ──────────────────────────────────────────────────────────────
# CLAIM 6: termux-sensor enumerates device sensors
# Source: docs/adb-wireless.md, docs/security-model.md
# ──────────────────────────────────────────────────────────────
print_claim 6 "termux-sensor lists device sensors when Termux:API is functional"
echo "  Test:  Run 'termux-sensor -l' with 5s timeout; expect JSON output"

if [ -z "$(command -v termux-sensor 2>/dev/null)" ]; then
    verdict_skip "termux-sensor not on PATH (termux-api package not installed)"
else
    SENSOR_OUT=$(timeout 5 termux-sensor -l 2>&1 || true)
    if echo "$SENSOR_OUT" | grep -q '"sensors"'; then
        echo "  Output: $(echo "$SENSOR_OUT" | head -3 | tr '\n' '|')"
        verdict_pass
    else
        echo "  Output: $(echo "$SENSOR_OUT" | head -3)"
        verdict_skip "termux-sensor returned no JSON (Termux:API companion app may not be running)"
    fi
fi

# ──────────────────────────────────────────────────────────────
# ──────────────────────────────────────────────────────────────
# ──────────────────────────────────────────────────────────────
# ──────────────────────────────────────────────────────────────
# ──────────────────────────────────────────────────────────────
# CLAIM 7: Termux:API returns valid JSON for battery status
# Source: docs/adb-wireless.md, docs/constitution-template.md
# ──────────────────────────────────────────────────────────────
print_claim 7 "termux-battery-status returns valid JSON (Termux:API companion working)"
echo "  Test:  Run termux-battery-status with 8s timeout; expect JSON with 'percentage'"

if [ -z "$(command -v termux-battery-status 2>/dev/null)" ]; then
    verdict_skip "termux-battery-status not on PATH (termux-api package not installed)"
else
    BAT=$(timeout 8 termux-battery-status 2>&1 || true)
    if echo "$BAT" | grep -q '"percentage"'; then
        echo "  JSON returned with percentage field"
        verdict_pass
    else
        echo "  Output: $(echo "$BAT" | head -3)"
        verdict_skip "no JSON returned (Termux:API companion app must be installed AND open at least once)"
    fi
fi

# ──────────────────────────────────────────────────────────────
# CLAIM 8: xdg-open is a symlink to termux-open
# Source: termux-tools package (provides the xdg-open shim); browser-launch
#         context in docs/troubleshooting.md (OAuth section)
# ──────────────────────────────────────────────────────────────
print_claim 8 "xdg-open is a symlink to termux-open (OAuth/browser-launch compatibility)"
XDG="$PREFIX/bin/xdg-open"
if [ ! -e "$XDG" ]; then
    verdict_skip "xdg-open not present at $XDG (termux-tools package not installed)"
elif [ -L "$XDG" ]; then
    TARGET="$(readlink "$XDG" 2>/dev/null)"
    echo "  $XDG → $TARGET"
    if [ "$TARGET" = "termux-open" ]; then
        verdict_pass
    else
        verdict_fail "symlink target is '$TARGET', expected 'termux-open'"
    fi
else
    verdict_fail "$XDG exists but is not a symlink"
fi

# ──────────────────────────────────────────────────────────────
# CLAIM 9: termux-fingerprint is on PATH for biometric auth
# Source: docs/fingerprint-gate.md
# ──────────────────────────────────────────────────────────────
print_claim 9 "termux-fingerprint is available on PATH for biometric authentication"
FP="$(command -v termux-fingerprint 2>/dev/null)"
if [ -n "$FP" ]; then
    echo "  Found: $FP"
    verdict_pass
else
    verdict_skip "termux-fingerprint not on PATH (termux-api package not installed)"
fi

# ──────────────────────────────────────────────────────────────
# CLAIM 10: Device architecture is aarch64
# Source: README, docs/install.md, docs/troubleshooting.md
# ──────────────────────────────────────────────────────────────
print_claim 10 "Device architecture is aarch64 (Claude Code requirement)"
ARCH="$(uname -m 2>/dev/null || echo 'unknown')"
echo "  uname -m: $ARCH"
if [ "$ARCH" = "aarch64" ]; then
    verdict_pass
else
    verdict_fail "architecture is '$ARCH', not aarch64. Claude Code will not run"
fi

# ──────────────────────────────────────────────────────────────
# SUMMARY
# ──────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  PASS: $PASS_N/$TOTAL"
echo "  FAIL: $FAIL_N/$TOTAL"
echo "  SKIP: $SKIP_N/$TOTAL"
echo ""
echo "Results saved to tests/results/$(basename "$RESULTS_FILE")"
echo ""
echo "Notes:"
echo "  PASS: claim empirically verified on this device."
echo "  FAIL: claim empirically does not hold on this device. Either the device differs"
echo "         from the doc's assumptions, or the doc is wrong. Submit a device report."
echo "  SKIP: precondition not met (e.g., optional package not installed, companion app"
echo "         not running). Re-run after installing the relevant package to test."

[ "$FAIL_N" -eq 0 ] || exit 1
exit 0
