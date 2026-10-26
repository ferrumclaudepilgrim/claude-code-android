# Installing Claude Code on Android

A guide to installing and maintaining Claude Code (Anthropic's AI coding assistant) on Android. Three install paths: pick one. Path A is the smallest install and auto-updates through this repository's wrapper. Path B gives you a full Ubuntu environment. Path C runs a real Linux kernel through AVF (Android Virtualization Framework) on selected devices that expose Android's Linux development environment.

> [!TIP]
> Pick one path, install, then launch. The technical details are optional. Use the maintenance section for your path when you come back.

## On This Page

- [Prerequisites](#prerequisites)
- [Choose a path](#choose-your-path)
- [Path A: native Termux](#path-a-native-termux)
- [Path B: Ubuntu in Termux](#path-b-proot-distro-ubuntu)
- [Path C: Android's Linux VM](#path-c-avf-linux-vm-experimental)
- [Verify the installation](#verification)
- [Extend your setup](#extend-your-setup)

---

## Prerequisites

Before you begin, confirm you have the following:

| Component | Requirement |
|-----------|-------------|
| **Architecture** | aarch64 (64-bit ARM); once you have installed the terminal (see the Terminal row below), run `uname -m` in it to verify. If it returns `armv7l` or `armv8l`, Claude Code will not work on your device |
| **Device** | aarch64 Android device (ARM64) |
| **OS** | Android 8+ (Android 8 / 9 have OAuth caveats; OAuth is the browser-based login flow Claude Code uses to authenticate with Anthropic; see FAQ) |
| **Terminal** | For A/B, use [Termux from F-Droid](https://f-droid.org/en/packages/com.termux/) or [official GitHub releases](https://github.com/termux/termux-app/releases). F-Droid is an open-source Android app store. |
| **Subscription** | Claude Pro, Max, Team, Enterprise, or Console account (provides the API access Claude Code requires) |
| **Network** | Active internet connection (Claude Code streams from Anthropic's API) |
| **Node.js** | Required only for pinned `2.1.112`; its installer supplies it. Native A/B/C do not need a separate Node install. |
| **Termux:API** | Optional phone integration, not a Claude dependency. [Set it up separately](#termuxapi-explicit-optional-setup) if needed. |

> **Optional phone access:** shared storage, Termux:API, and ADB are separate choices. Claude works without them. Keep Termux and its companion apps from the same installation source. [Access and trust](security-model.md).

### If Android blocks the Termux APK

Pause and verify the download against the official [Termux installation sources](https://github.com/termux/termux-app#installation). Read the warning details; wording varies by Android and Play Protect version. An option to continue is not proof of safety. If the source is uncertain, stop and download again from F-Droid or the official Termux GitHub releases. Do not disable protection for all apps to get past one warning.

The upstream README currently describes Google Play as a separate experimental branch with limitations, rather than an abandoned distribution. This guide follows the F-Droid/GitHub route. Keep Termux and companion apps from the same source. Before switching sources, back up your Termux projects and configuration: uninstalling Termux can erase its private environment.

> **Path C (AVF) note:** The prerequisites above (Termux, Android 8+) are for Path A and Path B, which both run in Termux. Path C does not use Termux. It needs Developer options enabled and a build exposing **Linux development environment**; this repository has lab-tested Pixel 6 and Pixel 10 Pro devices. See [Choose Your Path](#choose-your-path) and [Path C](#path-c-avf-linux-vm-experimental).

---

## Choose Your Path

This guide covers three installation paths. Pick one before you start.

| | Path A: Native Termux | Path B: proot-distro Ubuntu | Path C: AVF Linux VM |
|---|---|---|---|
| **Best for** | Smallest install, latest claude, auto-updates | Full Ubuntu environment alongside Claude Code | Builds exposing Linux development environment; separate Linux kernel |
| **Setup time** | 5-10 min | ~10-15 min | ~20 min |
| **Disk usage** | ~280 MB base install; about 200 MB more if you accept recommended packages | ~2 GB | ~2 GB |
| **Ongoing maintenance** | Wrapper update and rollback | Ubuntu packages plus Anthropic's updater | Debian packages plus Anthropic's updater |
| **Install method** | Patched linux-arm64 binary via glibc-runner | Anthropic installer inside Ubuntu | Anthropic installer inside the VM |
| **Node.js required** | No for native; **yes for pinned `2.1.112`** (its installer supplies it) | No | No |
| **Device support** | Newer ARM64 lab phones; Android 8–10 use the pinned fallback | ARM64 lab phones, including older Android | Builds exposing Linux development environment; lab checks cover Android 17 |
| **Evidence** | Dated checks on newer lab phones | Dated lab observations, including older Android | Experimental; two named lab Pixels |

Setup times and disk sizes above are estimates, not benchmarks. Upstream binaries and package sizes change. Device support is bounded by the [dated observations](device-compatibility.md).

**glibc-runner** is a Termux package that provides a glibc-compatible dynamic linker so glibc binaries run in Termux's Bionic-based environment (Bionic is Android's C library, the counterpart to glibc on desktop Linux). Path A uses it to run the linux-arm64 claude binary.

**Disk space:** Path A's base estimate excludes a retained earlier binary and update-time downloads. See [cache sizes and retry controls](#what-the-wrapper-keeps-on-disk-and-how-to-reset-it) before installing on a nearly full phone.

[Jump to Path A](#path-a-native-termux) · [Jump to Path B](#path-b-proot-distro-ubuntu) · [Jump to Path C](#path-c-avf-linux-vm-experimental)

### Battery and background work

**If Termux stops when the screen turns off, start here.** These are separate controls:

| Control | When it helps | Tradeoff |
|---|---|---|
| **App battery setting** | Android pauses Termux in the background. Look for Unrestricted / Allow background activity in its app settings. | More battery use and heat; Android can still stop the app. |
| **Disable child process restrictions** | Available in Developer options on some builds; helps with Android's phantom child-process limit, especially proot and multi-process tools. | Allows more background processes. It does not replace the battery setting. |
| **Wake lock** | A screen-off SSH session or long task needs the CPU to stay awake. | Uses more battery; it does not stop Android killing Termux. |

In **Termux**, acquire a wake lock only for the session that needs it, then release it:

```bash
termux-wake-lock
```

Run your SSH session or long task. **When finished**, release the lock:

```bash
termux-wake-unlock
```

`tmux` or `nohup` can survive a terminal window closing, but not Android killing the app or rebooting. **Path C has its own [Keep awake setting](avf-guide.md#5-screen-off-stability-keep-awake).** Neither path needs wireless debugging for this.

---

## Environment Reference

<details>
<summary>Path A paths, if you need them</summary>

| Item | Location |
|---|---|
| Home | `$HOME`, normally `/data/data/com.termux/files/home` |
| Termux packages | `$PREFIX`, normally `/data/data/com.termux/files/usr` |
| Native binaries | `~/.local/share/claude/versions/` |
| Launcher | `$PREFIX/bin/claude` |
| Claude settings | `~/.claude/settings.json` |

Ordinary Termux has no Android root access or systemd. Paths B/C have their own Linux environment; label host-versus-guest commands when switching between them.

</details>

---

## Path A: Native Termux

Path A runs Anthropic's Linux ARM64 binary through Termux's `glibc-runner` compatibility layer. The launcher checks for updates on startup, normally once per day. This is a community workaround, not an official Android build.

### Step 1: Run install.sh

> [!IMPORTANT]
> **Android 8, 9, or 10? Use the pinned option below instead.** The current native binary failed on the older lab phones. You can also choose [Path B](#path-b-proot-distro-ubuntu).

<a id="android-8-9-and-10-pinned-fallback"></a>

<details>
<summary><strong>Android 8–10, or choosing fixed Claude Code 2.1.112</strong></summary>

**Reinstalling over an existing setup? Back up your Claude settings first.** The current pinned installer can replace a `settings.json` it cannot parse. Keep a separate copy of `~/.claude/settings.json` before rerunning it.

In ordinary **Termux**, run:

```bash
curl -fsSL https://raw.githubusercontent.com/ferrumclaudepilgrim/claude-code-android/main/install-pinned.sh -o install-pinned.sh
bash install-pinned.sh
```

**This route requires Node.js.** Its installer supplies Node.js and the pinned npm package. It has no native-binary wrapper and does not auto-update. Reopen Termux, run `claude`, and skip the current-installer commands below. [Try your first task](#try-one-small-task) after signing in.

`2.1.112` works on the Galaxy S7 (Android 8) and Moto G7 Power (Android 10) in the recorded checks, last rechecked on 2026-07-26 and 2026-07-27. It remains an option people use, not a retired path. The Android packaging regression behind the pin is tracked in [upstream issue #50270](https://github.com/anthropics/claude-code/issues/50270), still open when checked on 2026-10-25. A fixed Claude release can still be affected by changes to Node.js, Android, or sign-in services.

[Device results](device-compatibility.md#device-results) · [Pinned uninstall](#uninstalling-the-pinned-fallback)

</details>

For the **current native install**, open Termux and run:

```bash
curl -fsSL https://raw.githubusercontent.com/ferrumclaudepilgrim/claude-code-android/main/install.sh -o install.sh
bash install.sh
```

The installer starts with two yes/no questions:

- **Fresh Termux install?** Yes takes the package maintainer's config defaults during upgrades. No preserves your existing config files.
- **Install recommended packages?** Yes adds the common-tool bundle (about 200 MB). **The current installer still includes `termux-api` in that bundle.** To leave it out, answer **No** and choose from [Common packages](#recommended-common-packages) afterward. It does not install the companion app or grant Android permissions.

It normally continues without further input. If the native startup check definitely crashes, it asks whether to install the pinned fallback.

#### For the curious / developers:

**Ready to use it? [Skip to Step 2](#step-2-launch-claude).**

<details>
<summary>What install.sh changes</summary>

- Updates Termux packages, installs `curl` and `jq`, and enables the glibc package repository.
- Installs `glibc-runner` and `patchelf-glibc`, then downloads the current Linux ARM64 Claude binary. A recent binary is a few hundred megabytes; sizes change.
- Checks its SHA-256 against Anthropic's manifest, then patches its ELF interpreter to use glibc-runner. Both download and manifest come from Anthropic, so this checks transfer integrity rather than independently authenticating a compromised upstream.
- Creates the launcher at `$PREFIX/bin/claude` and merges `autoUpdates: false` into Claude settings. The wrapper handles updates; other settings are retained and stale `env.LD_PRELOAD` is removed.
- Writes a DNS preload using Google's `8.8.8.8` and `8.8.4.4` for the bundled runtime resolver. An existing nonempty helper is kept. Read the [DNS tradeoff](security-model.md#path-as-dns-resolver-default) if you use private or VPN-provided DNS.

Version discovery uses the npm registry; binaries and manifests come from `https://downloads.claude.ai/claude-code-releases/`. **The native route does not require Node.js.** The pinned route above does.

</details>

Estimated install time: **5–10 minutes**, depending on downloads and device speed. Optional tools and slow mirrors can take longer.

### Step 2: Launch claude

The wrapper lands at `$PREFIX/bin/claude`, which is already on your PATH, so you can start right away:

```bash
claude
```

On first launch, claude opens its welcome wizard (theme selection, project trust prompt), then walks you through OAuth. Authentication may fail to open a browser on Android 8 / 9; if so, copy the URL from the terminal and open it manually. [FAQ entry](faq.md#claude-prints-a-url-but-my-browser-doesnt-open).

[Try your first task](#try-one-small-task) in a separate practice folder.

### What the wrapper does on every launch (optional reading)

**It checks for updates, checks startup when needed, and launches Claude.**

1. **Update if due.** Normally checks once per day. One launch downloads while others use the cached version. Full binaries are checked and patched before adoption. Some network/checksum failures retry in about an hour; other failures wait for the daily check.
2. **Check startup if needed.** An unverified candidate gets a probe with a default 45-second timeout. Definite crashes are blocklisted; an inconclusive result is not a pass. Available cached candidates may be tried.
3. **Launch.** Loads the DNS helper, unsets Termux's incompatible `LD_PRELOAD`, then passes arguments and output through. A verified candidate skips the probe and interpreter recheck.

A startup probe is not a full feature test or an isolated sandbox. It uses a temporary HOME but can still inherit configuration or project hooks. See [probe limits](security-model.md#path-a-download-trust-and-startup-probes).

Force an update check:

```bash
claude --update-now
```

Update failures normally leave a cached binary available. **Recovery depends on a cached version that can run on this phone.**

### What the wrapper keeps on disk, and how to reset it

State lives in `~/.local/share/claude/versions/`:

| File | Purpose |
|---|---|
| Versioned binaries | After a successful update, keeps the newest and one earlier installed version. The earlier one is not guaranteed to work. |
| `.verified` | Remembers the last version that passed the startup probe. |
| `.blocklist` | Remembers versions that definitely crashed, so they are skipped. |

Each binary is a few hundred megabytes. An update downloads a candidate **before** pruning, so allow space for three binaries temporarily. There is currently no wrapper option to turn automatic downloads or the retained copy off. `DISABLE_AUTOUPDATER` does not disable this wrapper's update check.

**Retry a previously rejected version only when you mean to.** This command removes the entire list of remembered crash exclusions:

```bash
rm -f ~/.local/share/claude/versions/.blocklist
```

It does not delete binaries, settings, credentials, or conversations. Cached versions become eligible again on launch. A discarded download needs another update check; use `claude --update-now` if you want that check now. Clearing the list does not fix the original crash.

### Updating Claude Code (Path A)

Automatic. The wrapper checks for new versions on launch (once per 24 hours, or immediately with `--update-now`). You don't run anything to update.

Use `claude --update-now` to request a check sooner. There is currently no option to postpone or disable the wrapper's automatic checks.

### Upgrading from a pinned v2.x install

If you installed with an earlier version of this repo, you may be on the pinned npm install (Claude Code `2.1.112`, with the in-process auto-updater disabled). To move to the v2.9.0 architecture without losing your work, use the migration script:

```bash
curl -fsSL https://raw.githubusercontent.com/ferrumclaudepilgrim/claude-code-android/main/migrate.sh -o migrate.sh
bash migrate.sh
```

Close any running `claude` sessions first. The script refuses to run while one is active, because replacing the binary under a live session would corrupt it.

What it does:

- Backs up `~/.claude`, `~/.claude.json`, and `~/.bashrc` to a timestamped folder before changing anything, and writes a `restore.sh` that restores those backed-up user-data files. It does not reinstall the old executable; use the [pinned installer](#android-8-9-and-10-pinned-fallback) if you need to return to `2.1.112`.
- Downloads, checksum-verifies, patches, and launch-tests the latest claude binary, then removes the old pinned install and drops in the auto-updating wrapper. A definite probe crash stops migration before removal of the old install. An inconclusive probe can continue, so it does not prove startup. Failures after removal can require the timestamped backup and its `restore.sh`; keep them until you have checked the new setup.
- Merges `~/.claude/settings.json` in place. Existing hooks, permissions, and other settings remain, with two deliberate changes: `autoUpdates` becomes `false` and `env.LD_PRELOAD` is removed. If the settings file is a symlink, migration changes its target in place.

**Before restoring a migration backup:** `restore.sh` replaces the current `~/.claude` directory and overwrites the backed-up `.claude.json` and `.bashrc`. Save any work or configuration created since migration first. Restore does not undo package upgrades or executable changes. Backups retain symlinks, not external targets, so changes to a linked settings file outside the backup are not rolled back.

Migration retains your chats, sessions, login, custom agents, hooks, skills, and `CLAUDE.md`. Running `install.sh` on a pinned install detects it and points you here rather than replacing it.

### Uninstalling (Path A)

Remove the Path A launcher and downloaded versions while retaining your Claude settings, credentials, and local session history in `~/.claude`:

Close Claude sessions, then run in **ordinary Termux**:

```bash
rm -f "$PREFIX/bin/claude"
rm -f ~/.local/bin/claude
rm -rf ~/.local/share/claude
```

**Optional support-package removal:** only if no other tools need these packages:

```bash
pkg uninstall -y glibc-runner patchelf-glibc glibc-repo
```

The installer also added a PATH entry to `~/.bashrc` and changed `autoUpdates` in Claude settings. Those settings remain after executable removal; review them if you are replacing the setup.

For a full data purge, back up anything you need and then remove `~/.claude` and `~/.claude.json` separately. That deletes settings, credentials, hooks, skills, agents, project state, and local session history; it is not required to uninstall the executable.

---

### Uninstalling the pinned fallback

In **ordinary Termux**, close Claude sessions, unlock the pinned npm package, then remove it:

```bash
chmod -R u+w "$PREFIX/lib/node_modules/@anthropic-ai/claude-code"
npm uninstall -g @anthropic-ai/claude-code
```

This retains your Claude user data. Remove obsolete `DISABLE_AUTOUPDATER` entries from `~/.bashrc` and Claude settings only if you no longer need them. Keep Node.js if other tools use it.

---

## Recommended Common Packages

**Pick the tools you need.** This manual common-tool list leaves Termux:API out:

```bash
pkg install git gh wget jq python openssh tree proot proot-distro make clang file xxd htop bat fzf -y
```

| Package | What it's for |
|---|---|
| `git` | Repo operations |
| `gh` | GitHub CLI (issues, PRs, releases) |
| `wget` | HTTP downloads (some scripts assume it; `curl` is already present) |
| `jq` | JSON parsing in scripts |
| `python` | Python scripting and tools |
| `openssh` | SSH client (and server, if you want it) |
| `tree` | Directory visualization |
| `proot` | Runs a Linux userspace through syscall translation; used by `proot-distro`, not an OS security sandbox |
| `proot-distro` | Required for Path B (Ubuntu install). proot-distro is a Termux tool that runs full Linux distributions inside Termux via proot-based syscall translation. |
| `make` | Build automation |
| `clang` | C/C++ compiler |
| `file` | File-type identifier (`file path/to/x`) |
| `xxd` | Hex dump utility |
| `htop` | Interactive process monitor |
| `bat` | `cat` with syntax highlighting and paging |
| `fzf` | Fuzzy finder |

---

### Termux:API: explicit optional setup

Claude Code does not need this. If you want Android integrations such as battery readings, sensors, camera, or biometric prompts, deliberately add the command package:

```bash
pkg install termux-api
```

Also install the **Termux:API companion app from the same source as Termux** and grant only the Android permissions you need. The current installer also includes the command package if you accept its recommended-tool bundle. To leave it out, decline that bundle and use the manual package list above. [What those grants expose](security-model.md#what-termuxapi-permissions-expose).

---

## Verification

For **native Path A**, check the launcher location and reported version:

```bash
command -v claude
claude --version
```

The first should resolve to `$PREFIX/bin/claude`. The second can trigger the wrapper's normal update check before reporting the version. It confirms version output, not sign-in, search, or every feature. Launch `claude` and try a harmless task in your own project too.

### Try one small task

If Claude is already open, use `/exit` to return to your shell. Run this in the shell where you installed Claude: ordinary Termux for A, inside Ubuntu for B, or inside Debian for C. It creates a separate practice folder:

```bash
mkdir -p ~/claude-first-project
cd ~/claude-first-project
claude
```

After signing in, ask: **“Use your tools to show the current folder and list its files. Don't create or change anything.”** The result should name the practice folder; an empty file list is normal. This checks that Claude can respond and use a tool in your chosen environment, rather than only print its version.

If the setup is unclear, use [Which setup am I on?](troubleshooting.md#which-setup-am-i-on) before reinstalling. The [scripts guide](add-ons/skills.md#check-or-repair-your-setup) explains the existing diagnostics and their effects. Maintainer device tests are separate from ordinary setup checks.

---

<a id="tested-on"></a>

## Tested Devices

The canonical evidence table is **[Device Compatibility and Evidence](device-compatibility.md)**. It puts device methods and outcomes in one table, with lab, community, and contributor evidence clearly marked. Keeping the matrix there prevents this procedure from drifting away from the evidence.

[Submit a device report](https://github.com/ferrumclaudepilgrim/claude-code-android/issues/new?template=device_report.yml) if you have tested on hardware not listed there.

---

## Path B: proot-distro Ubuntu

A full Ubuntu Linux environment inside Termux, with standard `/tmp`, `/etc`, and glibc paths. Claude Code installs inside Ubuntu with Anthropic's native installer, without binary patching.

### When to use Path B

- You want a full Linux environment (apt, standard paths, /tmp works natively)
- You plan to run other Linux tools alongside Claude Code
- You prefer the upstream installer over the patched-binary approach

### Step 1: Set up Ubuntu

The manual setup notes record Pixel 10 Pro (Android 17) and Samsung Galaxy S26 Ultra (Android 16) checks dated 2026-05-16. No saved Path B transcript accompanies those notes; the [device evidence](device-compatibility.md#device-results) distinguishes them from the older saved environment checks.

**Update Termux:**

```bash
pkg upgrade -y
```

Termux selects a mirror automatically. This updates all base packages including openssl and curl. **This step is required.** If downloads still fail after updating, record the URL and error; an HTTP 403 can have several causes.

> You may be asked about config files (like OpenSSL). On a fresh install, choose "install the package maintainer's version."

**Install proot-distro:**

```bash
pkg install proot-distro -y
```

**Install Ubuntu:**

```bash
proot-distro install ubuntu
```

Downloads an Ubuntu image (Ubuntu 25.10 / Questing Quokka at the time I tested; proot-distro may pull a newer release in the future). Approximately 55MB.

**Enter Ubuntu:**

```bash
proot-distro login ubuntu
```

Your prompt changes to `root@localhost`. Commands now run inside Ubuntu; this does not grant Android root access.

> The warning `can't sanitize binding "/proc/self/fd/1"` appears during login. It is harmless; stdout works correctly.

**Update Ubuntu packages:**

```bash
apt update && apt upgrade -y
```

**This step is required.** Fresh Ubuntu packages are not up to date. The recorded setup updated these packages first; that does not establish the cause of every later HTTP 403.

**Install Claude Code:**

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

If you prefer to inspect the script before running it:

```bash
curl -fsSL https://claude.ai/install.sh -o install.sh && less install.sh && bash install.sh
```

Native installer. No Node.js required. Installs to `~/.local/bin/claude`.

**Add to PATH:**

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

### Step 2: Verify and launch

```bash
claude --version
```

Should print the installed version number. Check the version it reports; upstream installer defaults can change.

**Launch:**

```bash
claude
```

On first launch, claude triggers OAuth and tries to open a browser. If it opens, sign in and return to the terminal. If it does not, copy the URL from the terminal into your phone's browser manually.

Earlier dated maintainer notes describe browser auto-open on newer Android and manual URL entry on the Galaxy S7, and record end-to-end Path B checks on 2026-05-16. Separate per-device Path B run transcripts were not retained. Use the [device table](device-compatibility.md#device-results) for the source and scope of each result.

See [FAQ: Claude prints a URL but my browser doesn't open](faq.md#claude-prints-a-url-but-my-browser-doesnt-open).

[Try your first task](#try-one-small-task) inside Ubuntu.

### Path B trade-offs

Ubuntu uses more storage and has its own packages to maintain. In return, you get standard Linux paths and tools without patching Claude's binary. Compare all three paths in [Choose your path](#choose-your-path).

### Path B notes

- **Samsung One UI 8 users:** In my testing, Termux backgrounded under One UI 8 can slow down the proot session noticeably. Keep Termux in the foreground or split-screen for best performance. See also proot-distro issue [#567](https://github.com/termux/proot-distro/issues/567) if you want to track this upstream.
- **To re-enter Ubuntu after closing Termux:** just run `proot-distro login ubuntu` again. Your Ubuntu environment persists between sessions.

### Update Path B

**In Termux**, enter your existing Ubuntu environment:

```bash
proot-distro login ubuntu
```

**Inside Ubuntu**, update its packages and Claude:

```bash
apt update && apt upgrade -y
claude update
```

For an installer repair, rerun Anthropic's installer from Step 1 inside Ubuntu.

### Uninstall Path B

**Remove only Claude:** inside Ubuntu, after closing Claude sessions:

```bash
rm -f ~/.local/bin/claude
rm -rf ~/.local/share/claude
```

Ubuntu, its projects, and Claude's `~/.claude` / `~/.claude.json` user data remain.

**Remove Ubuntu too:** first back up projects stored in it. If you are still inside Ubuntu, return to Termux first:

```bash
exit
```

Then, **in Termux**, make an archive:

```bash
proot-distro backup --output ubuntu-backup.tar.gz ubuntu
```

Check that your backup is readable and stored somewhere you can recover it. Then, **in Termux**, `proot-distro remove ubuntu` deletes the entire Ubuntu filesystem. That includes projects and Claude user data stored only inside it. It is not needed to uninstall Claude.

### Verified Path B configuration

| Component | Version |
|-----------|---------|
| proot-distro | 4.38.0 |
| Guest OS | Ubuntu 25.10 (Questing Quokka) |
| Claude Code | Exact release not captured in this setup snapshot |
| Kernel | 6.12.30 (Android 16) |

---

*Path B last verified: 2026-05-16*

---

## Path C: AVF Linux VM (experimental)

Path C uses Android's Linux development environment. It boots a Debian virtual machine (VM): a separate Linux computer environment running inside your phone. Claude Code uses Anthropic's native installer there.

Prerequisites for Path C: **Developer options enabled** and a build exposing **Linux development environment**. The recorded lab observations cover Pixel 6 and Pixel 10 Pro on Android 17; do not infer support for every newer Pixel. Check the [AVF requirements](avf-guide.md#device-requirements).

> [!WARNING]
> Developer options expose advanced device controls. Enable only Linux development environment for this path; **USB debugging and wireless debugging are separate and not required**. Leave them off unless a task needs ADB. Availability depends on the device and build, not Android version alone. [Current Android requirements](https://source.android.com/docs/core/virtualization/usecases#linux_development_environment) checked 2026-10-25.

### Step 1: Set up the Linux environment

1. Settings > About phone > tap **Build number** 7 times to enable Developer options.
2. Settings > System > Developer options > **Linux development environment** > toggle on.
3. Open the Terminal app that appears on the home screen. Accept the Debian image download (several hundred megabytes; use WiFi).

### Step 2: Install and launch Claude

When the prompt shows `droid@debian:~$`, run **inside Debian**:

```bash
curl -fsSL https://claude.ai/install.sh | bash
export PATH="$HOME/.local/bin:$PATH"
claude
```

Add the PATH line to Debian's `~/.bashrc` if it is not already there. The [AVF installation section](avf-guide.md#claude-code-installation-inside-avf) includes the full procedure.

[Try your first task](#try-one-small-task) inside Debian.

For everything else (Memory size, Display resolution, Keep awake, Recovery, ADB hardware bridge (ADB, Android Debug Bridge, is a command-line tool for communicating with a connected Android device), known issues), see the dedicated guide: **[docs/avf-guide.md](avf-guide.md)**. Path C re-verified on Pixel 6 and Pixel 10 Pro running Android 17 on 2026-05-26.

### Update Path C

Inside the Debian VM, update system packages and request a Claude Code update with:

```bash
sudo apt update && sudo apt upgrade -y
claude update
```

For an installer repair, rerun Anthropic's installer inside Debian.

### Uninstall Path C

**Remove only Claude:** inside Debian, after closing Claude sessions:

```bash
rm -f ~/.local/bin/claude
rm -rf ~/.local/share/claude
```

This keeps the Debian environment, its projects, and Claude's `~/.claude` / `~/.claude.json` user data.

**Reset the Linux environment:** the Terminal app's **Settings → Recovery → Reset to initial version** action wipes and recreates the Debian VM. Back up guest projects first. **Remove backup data** is a separate destructive action for `/mnt/backup`. See [AVF recovery](avf-guide.md#recovery-and-backups) before using either control.

---

## Extend Your Setup

These are optional starting points for workflows beyond an interactive terminal session. Test them against your device, Android background limits, and Claude Code version before relying on them unattended.

### Cron-triggered headless sessions

This example runs in **ordinary Termux (Path A)**. Start the daemon, then open your crontab:

```bash
pkg install cronie
crond -s
crontab -e
```

In the editor, keep existing jobs and add the following. Replace `your-project` with your actual project folder. The environment lines are part of the crontab, so the daily job can find Termux's launcher and tools:

```cron
SHELL=/data/data/com.termux/files/usr/bin/bash
HOME=/data/data/com.termux/files/home
PREFIX=/data/data/com.termux/files/usr
TMPDIR=/data/data/com.termux/files/usr/tmp
PATH=/data/data/com.termux/files/usr/bin:/system/bin
0 9 * * * cd "$HOME/repos/your-project" && claude -p 'review recent changes and summarize' >> "$HOME/cron-output.log" 2>&1
```

This requests a review at 09:00 while the daemon is running. Check `~/cron-output.log` after a run; Android background limits can stop the job. [Cronie's crontab reference](https://github.com/cronie-crond/cronie/blob/master/man/crontab.5) describes environment entries separately from scheduled commands.

**Narrowing cron tools:** This example removes built-in web tools and blocks selected shell command patterns. It still allows Bash networking and is not a local-only sandbox:

```bash
claude -p "your prompt here" \
  --tools "Read,Write,Edit,Bash,Glob,Grep" \
  --disallowedTools "WebFetch,WebSearch,Bash(curl:*),Bash(wget:*)"
```

`--tools` limits built-in tools; configured MCP tools remain a separate channel. These rules block WebFetch, WebSearch, and the shown `curl`/`wget` command patterns, not all networking. Review web, MCP, and shell access separately. Removing Bash closes only shell networking; a Bash sandbox does not by itself establish an MCP boundary. Enforced restrictions must cover every channel the job can use.

Adding `crond -s` to `~/.bashrc` starts it when that shell opens, not at Android boot. For boot-time work, follow the optional [Termux:Boot setup](https://github.com/termux/termux-boot#usage). Android background limits still apply.

### Session resume

Resume a previous conversation:
```bash
claude --resume <session-id>
```

Session IDs are shown in `--output-format json` output and stored in `~/.claude/projects/`.

### Structured output

For scripting and automation:
```bash
claude -p "your prompt" --output-format json     # Full JSON with cost, tokens, session ID
claude -p "your prompt" --output-format stream-json --verbose  # Streaming JSON events
```

### Context management

Inside a running session, use `/compact` to compress the conversation context. This is useful during long sessions to stay within the context window.

---

## Why v2.9.0

The original native-Termux route pinned the JavaScript release `2.1.112`. The move to platform-native packaging in `2.1.113` left Android without a supported npm binary: [upstream issue #50270](https://github.com/anthropics/claude-code/issues/50270) remains open as checked on 2026-10-25.

Version 2.9.0 added the glibc-runner workaround for the Linux ARM64 binary, based on [the upstream discussion](https://github.com/anthropics/claude-code/issues/50270#issuecomment-4467292215). It brings current releases to compatible phones; it does not make them official Android builds. The Node-based pinned option remains available for older devices or people choosing that fixed release. See the [changelog](../CHANGELOG.md#290---2026-05-29) for the implementation history.

---

Documentation reviewed: 2026-10-25. Device observations retain their original dates; no new phone tests were performed.
