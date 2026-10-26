# FAQ

Start with what you see on the phone. These short answers point to the procedure to follow; you do not need to read every guide first.

## Installation

<a id="unsafe-app-blocked-when-installing-the-termux-apk"></a>

### Why does Android say “Unsafe app blocked” when I install Termux?

**Pause and check where the APK came from.** Compare the download with the official Termux sources, then read the warning's details. A familiar filename or an option to continue does not prove an APK is safe. If you cannot establish the source, stop and download from an official source instead.

Follow [What to do if Android blocks the Termux APK](install.md#if-android-blocks-the-termux-apk). Keep Termux and its companion apps from the same source so their signatures match.

<a id="installsh-hangs-or-fails-with-failed-to-fetch"></a>

### Why is install.sh stuck or showing “Failed to fetch”?

**Check the network, then try another Termux package mirror with `termux-change-repo`.** Package download failures often come from an unavailable mirror. A failure downloading Claude itself can have a different cause; note the URL and error before retrying.

Use [Termux package download failures](troubleshooting.md#termux-package-download-hangs-or-says-failed-to-fetch) for the steps, then rerun the installer once the package source works.

<a id="yinodz-prompt-during-pkg-upgrade"></a>

### Termux is asking Y/I/N/O/D/Z. What should I choose?

**Choose `N` or `O` to keep a configuration you already use; choose `D` if you want to compare it first.** `Y` or `I` replaces it with the package maintainer's version. `Z` opens a shell for inspection.

The prompt means an installed configuration file differs from the package's copy. On a genuinely fresh Termux install, the maintainer's version is a reasonable starting point. The installer's fresh/existing question chooses its configuration policy; see [the two installer questions](install.md#step-1-run-installsh).

### Which packages should I install after `install.sh`?

**Start with the packages the installer supplies; add tools when your project needs them.** Its optional common-tool set includes Git, Python, compilers, and the Termux:API command package. Installing that command package does not install its Android companion or grant new permissions, but existing companion permissions may already be usable.

The manual list leaves Termux:API out; the current installer bundle still includes it. For an explicit choice, answer No to the bundle and add only the tools you need. See [Recommended Common Packages](install.md#recommended-common-packages) list and [optional Android builder guides](add-ons/README.md#build-with-android).

<a id="which-install-do-i-have-pinned-or-the-native-v29x-setup"></a>

### How can I tell which setup I already have?

**Run the disk check in [Which setup am I on?](troubleshooting.md#which-setup-am-i-on).** Use ordinary Termux for that Path A check; Path B runs inside Ubuntu and Path C inside Android's Linux Terminal.

`claude --version` reports Anthropic's version, so it cannot identify this repository's launcher or pinned setup. Check before reinstalling or migrating.

## Choosing a Path

<a id="which-path-should-i-use"></a>

### Which installation path should I use?

**Start with Path A on a newer ARM64 phone; on Android 8–10, use the pinned fallback or Path B.** Path B supplies Ubuntu inside Termux. Path C is an experimental Debian VM available only when your Android build exposes it.

Compare the tradeoffs in [Choose your path](install.md#choose-your-path), then [check the evidence for your phone](device-compatibility.md). Android version alone does not establish compatibility.

### Can I run Path C (AVF) on my Samsung, OnePlus, or Snapdragon phone?

**Look for “Linux development environment” in Developer options.** If it is absent, choose Path A or B. The Android build decides availability; the chipset name or “Pixel 6 or newer” is not sufficient evidence.

See [AVF device requirements](avf-guide.md#device-requirements) and the dated [device observations](device-compatibility.md).

### Why does Path A need patchelf and glibc-runner?

**Use the Path A installer to set these up together.** It adapts Anthropic's Linux ARM64 binary to Termux's different runtime libraries. The program runs on the phone, but the compatibility layer is not official Android support.

The [Path A guide](install.md#path-a-native-termux) explains the binary patch, launcher, and DNS tradeoff.

<a id="i-set-up-path-a-with-an-older-version-of-this-repo-how-do-i-move-to-v290"></a>

### I have an older pinned install. Should I migrate?

**Check your phone's evidence before migrating.** The older lab phones still needed pinned Claude Code `2.1.112`. On a compatible phone, follow [Upgrading from a pinned v2.x install](install.md#upgrading-from-a-pinned-v2x-install), which backs up state before replacing the install.

A migration is different from a routine launcher refresh. Keep the backup and its restore instructions until you have confirmed your own setup works.

## OAuth and Browsers

<a id="claude-prints-a-url-but-my-browser-doesnt-open"></a>

### Why didn't the Claude sign-in page open?

**Copy the sign-in URL from your terminal into the phone's browser, finish signing in, then return to the terminal.** Automatic browser launch varies by Android version and install path. Keep sign-in URLs and codes private.

If it still fails, use [OAuth / authentication fails on first launch](troubleshooting.md#oauth--authentication-fails-on-first-launch) for the next checks.

### Do MCP OAuth callbacks work on Android?

**Use the authentication instructions for your MCP server and install path.** A browser login may need to return to a temporary localhost listener; routing between the browser, Termux, Ubuntu, or a VM can vary.

Start with [sign-in troubleshooting](troubleshooting.md#oauth--authentication-fails-on-first-launch). Review the server's scopes and credentials separately using [MCP, OAuth, web, and shell networking](security-model.md#mcp-oauth-web-and-shell-networking).

## Versions and Updates

### Why do I see two unrelated 2.x numbers?

**Use the repository version for launcher documentation and `claude --version` for Anthropic's release.** They identify different things and do not need to match. [Two version numbers](device-compatibility.md#two-version-numbers) explains how to read older evidence.

<a id="how-does-path-a-update"></a>

### How do I update without losing my setup?

**Identify your path, then follow its maintenance section.** Native Path A checks for updates on launch, normally once per day; `claude --update-now` asks for a check now. Refreshing the launcher and migrating an older pinned install are separate actions. Path B and Path C use Anthropic's updater inside their Linux environment.

Use [Path A updates](install.md#updating-claude-code-path-a), [Path B maintenance](install.md#update-path-b), or [Path C maintenance](install.md#update-path-c). Back up important projects before changing an installation; cached versions and migration backups are useful recovery aids, not a guarantee against data loss.

## Phone Access and Security

<a id="does-installing-this-grant-access-to-my-sms-camera-or-the-rest-of-android"></a>

### Does installing this give Claude access to my photos, messages, or camera?

**Review the access Termux and its companion apps already have.** The installer does not grant Android permissions, enable shared storage or ADB, or add MCP servers. It can install Termux:API's command package if you accept the common tools. With an already configured companion app, existing grants may make those commands usable.

Claude can use files and commands reachable through its allowed tools. Photos in shared storage, permission-backed API features, and ADB are different routes. Read [Understand access and trust](security-model.md) before enabling them; ordinary coding does not require them.

<a id="do-the-ssrf-and-fingerprint-examples-make-the-setup-sandboxed"></a>

### Do the optional security hooks make my phone sandboxed?

**Treat them as narrow, optional checks.** The SSRF hook covers recognized URL strings in selected web tools; the fingerprint example matches certain Bash command strings. Neither contains arbitrary shell programs, MCP traffic, or every way to reach files and the network.

Read [Optional controls and their limits](security-model.md#optional-controls-and-their-limits). Instructions in an agent prompt are different from tool permissions, and both differ from an operating-system sandbox.

---

Documentation reviewed: 2026-10-25. No new device tests were performed for this revision.
