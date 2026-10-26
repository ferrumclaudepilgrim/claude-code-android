# Fingerprint Biometric Gate

An optional illustration of biometric confirmation for selected Claude Code Bash calls. A PreToolUse hook calls Termux:API's `termux-fingerprint` helper and can return a denial. The command matcher and failure handling need testing before you rely on them. This is not required for installation; start with the [security model](../security-model.md#optional-controls-and-their-limits).

[All add-ons](README.md) · [Access and trust](../security-model.md)

---

## What It Does

The inline example requests confirmation for literal command strings matching patterns such as:

- `git push` to any repository, public or private
- Creating pull requests
- Force-pushing, resetting, or deleting branches
- Any other operation you define as sensitive

When the handler reaches its denial branch, it returns blocking JSON. The matcher does not inspect repository visibility. Unmatched spellings, other tools, missing dependencies, hook-loading failures, and timeouts need separate failure-policy checks; do not assume every failure blocks.

---

## Requirements

1. **Termux:API package.** Install in Termux:
   ```sh
   pkg install termux-api
   ```

2. **Termux:API companion app.** Install from the same source as Termux: both F-Droid or both official GitHub builds. The package provides the CLI commands; the companion app provides the Android permissions bridge. Both are required. Without a working companion integration, the command cannot provide the expected authentication result.

3. **Source matching.** Termux and Termux:API must come from the same source (both F-Droid or both GitHub releases). Mixing sources causes signature mismatches and silent failures.

4. **A registered fingerprint** on the device (Settings > Security > Fingerprint).

> **Verify it works** before wiring it into hooks:
> ```sh
> termux-fingerprint
> ```
> Touch the sensor. A working setup returns JSON output containing `"auth_result": "AUTH_RESULT_SUCCESS"`.

---

## Setup

**Source locations:** [`examples/fingerprint-gate.sh`](../../examples/fingerprint-gate.sh) contains the authentication helper and an optional approval-cache helper. It is not the full Claude Code hook. Step 2 below is a separate inline integration illustration. These examples have not been verified together as one implementation; failure behavior and bypasses need integration testing before you rely on them.

### Step 1: Create the gate function

Create a file that any hook can source. Put it wherever makes sense for your setup. `~/.claude/hooks/` is a natural choice if you keep your hooks there.

**`~/.claude/hooks/fingerprint-gate.sh`**

> **Dependency:** This uses `jq` to parse JSON. Install it with `pkg install jq` if you don't have it.

```sh
#!/usr/bin/env bash
# Fingerprint biometric gate. Source this file, then call require_fingerprint.

require_fingerprint() {
  if ! command -v termux-fingerprint >/dev/null 2>&1; then
    echo "termux-fingerprint not found. Install: pkg install termux-api" >&2
    echo "Also install the Termux:API companion app from the same source as Termux." >&2
    return 1
  fi

  local result
  result=$(termux-fingerprint)

  local auth_result
  auth_result=$(echo "$result" | jq -r '.auth_result // ""')

  if [ "$auth_result" = "AUTH_RESULT_SUCCESS" ]; then
    echo "Fingerprint verified." >&2
    return 0
  else
    echo "Fingerprint denied. Operation blocked." >&2
    return 1
  fi
}
```

### Step 2: Create a hook script

Create a hook that sources the gate and checks for sensitive operations. This example matches literal `git push`, selected destructive Git commands, and `gh pr create` strings. It does not query whether a repository is public:

**`~/.claude/hooks/pre-tool-use-fingerprint-gate.sh`**

```sh
#!/usr/bin/env bash
# Block sensitive git operations without fingerprint approval

# Source the gate function
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/fingerprint-gate.sh"

# Read the JSON payload Claude Code sends on stdin
INPUT=$(cat)

# Extract tool name and command from JSON
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Only gate Bash tool calls
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

# Check for sensitive git operations
case "$COMMAND" in
  *"git push"*|*"git push --force"*|*"git reset --hard"*|*"git branch -D"*|*"gh pr create"*)
    echo "Sensitive operation detected: requesting fingerprint approval..." >&2
    if require_fingerprint; then
      exit 0  # Approved
    else
      echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "Fingerprint authentication failed. Operation blocked."}}'
      exit 0
    fi
    ;;
  *)
    exit 0  # Not a sensitive operation, allow it
    ;;
esac
```

This illustration uses JSON on stdout with exit 0: a `hookSpecificOutput` object with `"permissionDecision": "deny"` blocks the tool call. Exit codes also matter. For PreToolUse, exit 2 blocks and reports stderr; exit 1 is normally a nonblocking error. See the current [Claude Code hooks reference](https://code.claude.com/docs/en/hooks). In particular, do not translate the helper's return 1 into `exit 1` and assume that blocks a Claude Code tool call.

Make it executable:

```sh
chmod +x ~/.claude/hooks/fingerprint-gate.sh
chmod +x ~/.claude/hooks/pre-tool-use-fingerprint-gate.sh
```

**Matcher limitations:** the `case` statement inspects the raw command string, not shell execution. Double spaces (`git  push`), variables (`g=git; "$g" push`), aliases, scripts, and other tools can avoid the literal patterns. Some expressions still contain a matched literal and will be gated; do not assume every expansion bypasses it.

Splitting a string with `set --` is not a shell parser. A Git credential helper also does not cover local resets/deletions or every authentication route. This example is a reminder during normal use, not a boundary against arbitrary shell execution. Do not rely on the optional cache helper as evidence of fresh owner approval; a writable sentinel can be created by another process.

### Step 3: Register the hook in Claude Code settings

Merge this hook entry into your existing settings; do not replace unrelated settings. Use an explicit `bash` interpreter on Path A, where the native launcher unsets Termux's execution preload:

**`~/.claude/settings.json`**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$HOME/.claude/hooks/pre-tool-use-fingerprint-gate.sh\""
          }
        ]
      }
    ]
  }
}
```

Verify the hook in a harmless test before relying on it. Current Claude Code supports `onFailure: "block"` for hook startup/errors/timeouts from **2.1.295 onward**; the pinned `2.1.112` fallback does not have that setting. This example has not been integration-tested as a fail-closed control. [Failure policy](https://code.claude.com/docs/en/hooks#block-the-action-when-a-hook-fails).

Each matcher entry holds a `hooks` array. Every item in it needs `"type": "command"` and a `command` pointing at your script. The `matcher` field controls which tool triggers the hook. Setting it to `"Bash"` means the hook only fires for shell commands. You can also use `"*"` to fire on every tool call, or name a specific tool like `"Write"`.

---

## Troubleshooting

**`termux-fingerprint: command not found`**
```sh
pkg install termux-api
```
Then install the Termux:API companion app from the same source as Termux.

**Fingerprint prompt never appears**
Check that the command package and companion app are installed and working, and that Termux and the companion came from the same source. Do not uninstall Termux as the first diagnostic step: it can erase projects and configuration. Before switching sources, use the [Termux backup and source guidance](../install.md#if-android-blocks-the-termux-apk).

**`jq: command not found`**
```sh
pkg install jq
```

**Hook doesn't fire**
Check that `settings.json` is valid JSON and the hook path is correct. Test the hook directly:
```sh
echo '{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}' \
  | bash ~/.claude/hooks/pre-tool-use-fingerprint-gate.sh
```

**Fingerprint works in terminal but not in hooks**
Hooks run in a subprocess. The `termux-fingerprint` binary needs to be on PATH in that context. Try using the full path: `/data/data/com.termux/files/usr/bin/termux-fingerprint`.

---

## Security Notes

- This helper requests local authentication and receives a result; it does not handle fingerprint templates. An approved operation can still send other data over the network.
- The [Termux:API implementation](https://github.com/termux/termux-api/blob/master/app/src/main/java/com/termux/api/apis/FingerprintAPI.java) uses AndroidX BiometricPrompt. Verify the result and integration on your device.
- The gate is only as strong as your hook configuration. If a command can bypass the hook (e.g., by not matching the `case` pattern), it won't be gated.
- This is a speed bump for autonomous AI operations, not a security boundary. A determined attacker with device access has other vectors. Its purpose is ensuring the device owner approves consequential actions before they happen.

---

*Documentation reviewed: 2026-10-25. No new device, biometric, or hook-failure tests were performed.*
