---
name: termux-safe
description: Android/Termux constraints reference. Prevents Claude Code from suggesting commands that fail silently on Android (sudo, systemd, non-Termux paths, etc.).
user-invocable: false
disable-model-invocation: false
# No allowed-tools field: this skill is content-only and grants no additional tool access.
---

# Android / Termux Environment Constraints

> **Scope and when this applies.** These constraints apply when you are executing inside Termux on Android, regardless of how Claude Code itself was packaged. The load-bearing runtime signal is `$PREFIX === "/data/data/com.termux/files/usr"`. If that environment variable points at Termux's prefix, you are in Termux and these constraints apply, even if `process.platform` reports `"linux"` (it will report `"linux"` if Claude Code was installed via this repo's v2.9.0 Path A, which runs the linux-arm64 binary patched via glibc-runner; it will report `"android"` only on older Path A v2.x installs that used the JS bundle). If `$PREFIX` is unset or points at `/usr`, you are inside a chroot-like sandbox (for example, a Linux rootfs running under `proot-distro`, Path B) or inside a hypervisor-managed Linux VM (Path C), and standard Linux conventions apply; most of this file does not.

If the runtime signals indicate the in-Termux case, the constraints below produce **silent failures, not errors.** Every suggestion must account for them.

## Hard Rules: Never Suggest These

- **No `sudo`.** Root does not exist. No `su`, no `doas`, no privilege escalation of any kind.
- **No `systemctl` or `systemd`.** Android does not use systemd. No `journalctl`, no `service`, no unit files.
- **No standard Linux paths.** `/usr/bin`, `/etc`, `/var` do not exist or are not writable. Termux paths:
  - Home: `/data/data/com.termux/files/home`
  - Prefix: `/data/data/com.termux/files/usr`
  - Binaries: `$PREFIX/bin`
  - Config: `$PREFIX/etc`
- **No ports below 1024.** No root = no binding to 80, 443, etc. Use 1024+.
- **Prefer `pkg` over `apt`.** Both work, but `pkg` auto-updates the package index before installing.
- **No Docker, no containers.** The kernel does not support them without root.

## Silent Failure Modes

- **Node.js is not required by this repo's `install.sh`.** The patched linux-arm64 claude binary is self-contained. If Node is installed separately on native Termux, prefer v25+: v24 had a documented startup hang on ARM64 that was resolved in v25.
- **File descriptor limits vary by device.** Check with `ulimit -n`. Avoid spawning many concurrent processes.
- **Android can stop background work.** Its phantom process controls can kill excess child processes, and battery and background policies can suspend or kill Termux. Keep concurrent subagents and child processes modest. Where Developer options offers "Disable child process restrictions", turning it on helps with the first limit. `tmux` or `nohup` keep work running when a terminal window closes, but not after Android kills Termux or the phone reboots.
- **`process.platform` reporting varies by install path.** On Path A v2.9.0 (the linux-arm64 binary patched via glibc-runner), Node.js reports `process.platform === "linux"` even though you are inside Termux. On older Path A v2.x (the JS-bundle npm install) it reports `"android"`. On Path B (proot-distro Ubuntu) and Path C (AVF), it reports `"linux"` and you are not in Termux. The reliable cross-path signal that you are still in Termux is `$PREFIX === "/data/data/com.termux/files/usr"`.
- **`#!/usr/bin/env` scripts fail under the Path A launcher.** When the Bash tool runs a script directly and its first line is `#!/usr/bin/env bash` (or `python3`, `node`), it exits with "bad interpreter": Android has no `/usr/bin/env`, and Claude Code's subprocesses do not carry Termux's fix for it. Run the interpreter explicitly: `bash ./script.sh`, `python ./script.py`. Tools called by name and `#!/bin/sh` scripts are unaffected.
- **Prefer `command -v` to check command availability.** It is a shell builtin. `which` is available with `pkg install which`, but this repo's installers do not explicitly install it.

## Package Installation

Prefer `pkg` (auto-updates the index before install). `apt` and `apt-get` also work but skip the auto-update:
```bash
pkg install <package> -y
pkg upgrade
pkg search <query>
```

## When Unsure

If you're about to suggest a command that assumes standard Linux, stop and verify it works on Termux first. When in doubt, prefix with `command -v <tool> >/dev/null 2>&1` to check availability.
