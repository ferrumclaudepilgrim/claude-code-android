# Troubleshooting Claude Code on Android

This guide covers problems specific to running Claude Code on **aarch64/ARM64 Android 8+ with Termux** (Path A and Path B), plus a Path C section below that does not use Termux. Path A, B, and C are the three install methods described in the [README](../README.md#choose-an-install-path): Path A (native Termux), Path B (proot-distro Ubuntu), and Path C (the Android Virtualization Framework, or AVF, a real Linux VM built into newer Android). Android 8 / 9 have OAuth caveats (see [FAQ](faq.md#claude-prints-a-url-but-my-browser-doesnt-open)). Each entry starts with the error you see, then the fix, then the explanation.

> **Document authority:** This page is canonical for symptoms, diagnosis, and recovery. Setup and removal procedures stay in [install.md](install.md); device observations stay in [device compatibility](device-compatibility.md).

If you haven't installed yet, see [install.md](install.md) first. For an Android warning while installing the Termux APK, use [the source and warning checks](install.md#if-android-blocks-the-termux-apk).

**Which version do I have?** Some entries below are labelled by version, for example "(v2.x install)" or "(v2.9.1+)". Those refer to *this repo's* install (currently 2.9.x), which is a different number from Claude Code's own version (currently 2.1.x). Note that `claude --version` reports Claude Code's number (2.1.x), not this repo's, so it does not tell you which setup you have. For a one-command check that does, see [Which setup am I on?](#which-setup-am-i-on) below.

---

## Find a Problem

- [Identify your setup](#which-setup-am-i-on)
- [Launch and update failures](#claude-crashes-immediately-on-launch)
- [Connectivity and sign-in](#claude-hangs-on-checking-connectivity--etimeout--api-error-on-every-message)
- [Path B and Node.js](#proot-distro-issues)
- [Processes, battery, and background limits](#process-killed-randomly)
- [Tools, hooks, voice, and PDFs](#claude-cant-find-a-tool-jq--git--python--)
- [ADB wireless debugging](#adb-wireless-debugging)
- [Path C and AVF](#path-c-avf-experimental)

---

### Which setup am I on?

This repo's own version (currently 2.9.x) is a different number from Claude Code's own version (currently 2.1.x); the two are unrelated. `claude --version` reports Claude Code's number (2.1.x) on every setup, so it does not tell you which of this repo's installs you have. For native or pinned Path A, run the following in ordinary Termux to check the known install locations. It does not identify every custom install. For Path B, enter Ubuntu with `proot-distro login ubuntu`; Path C runs in Android's Linux Terminal.

```bash
if [ -d "$PREFIX/lib/node_modules/@anthropic-ai/claude-code" ]; then
  echo "pinned install (Claude Code 2.1.112 via npm; treat as a v2.x setup)"
elif ls "$HOME/.local/share/claude/versions/"*.*.* >/dev/null 2>&1; then
  echo "native Path A install (the v2.9.x auto-updating wrapper)"
else
  echo "no recognized claude install found here"
fi
```

If it prints **pinned install**, follow the entries labelled "(v2.x install)" and the [pinned upgrade path](install.md#upgrading-from-a-pinned-v2x-install). If it prints **native Path A install**, you are on the v2.9.x setup and can skip the "(v2.x install)" entries.

---

### Claude crashes immediately on launch

**Applies to Path A (native Termux).**

**You see:** one of these the instant you run `claude`, often right after it had been working fine:

```
Bad system call
```

or

```
oh no: Bun has crashed. This indicates a bug in Bun, not your code.
```

or a `Segmentation fault` message that links to `bun.report`. Tellingly, `claude --version` still prints a version, but `claude` on its own dies straight away.

**What happened:** Claude Code auto-updated itself to a release that does not run on Android. Claude Code is a single native program, and a recent build of it asks Android for something Android does not allow, so it stops the moment it starts. This is a bug in that release, not in your phone, and not anything you did.

**Fix it:**

**On Android 8, 9, or 10:** the Android 8 and Android 10 lab phones failed to launch the current native binary. Re-running the same installer does not resolve that compatibility failure. Install the pinned version instead, an older Claude Code that runs on these devices:

**Keep a separate copy of `~/.claude/settings.json` first.** The pinned installer can replace a settings file it cannot parse. It does not change your login.

```bash
curl -fsSL https://raw.githubusercontent.com/ferrumclaudepilgrim/claude-code-android/main/install-pinned.sh -o install-pinned.sh
bash install-pinned.sh
```

Parseable settings are merged with the pinned updater setting. (Not sure which Android version you are on? Settings > About phone > Android version.)

**On Android 11 or newer, with the current native setup:** re-run this repo's installer. It refreshes the launcher in place and normally reuses an existing cached binary. Your login and other settings remain; `autoUpdates` becomes `false` and `env.LD_PRELOAD` is removed.

```bash
curl -fsSL https://raw.githubusercontent.com/ferrumclaudepilgrim/claude-code-android/main/install.sh -o install.sh
bash install.sh
```

Then start Claude Code the normal way. The refreshed launcher tests startup for versions it has not already verified, and tries available saved versions if a check detects a crash. Recovery depends on a usable saved version and does not cover every failure during use. If it still crashes, use the pinned command above or [Path B](install.md#path-b-proot-distro-ubuntu).

If you are still on the older pinned install (Claude Code `2.1.112` with the auto-updater off), `install.sh` will point you to `migrate.sh` instead. Follow the [migration steps](install.md#upgrading-from-a-pinned-v2x-install) on a phone that can run the current native binary.

**If you then see `no working claude binary found`:** your phone has no good version saved to fall back to. Install the pinned version with the `install-pinned.sh` command shown above, an older Claude Code that does not have this problem.

The pinned version is a safety net, not a one-way street: once a working Claude Code release is out for your phone, use the [migration steps](install.md#upgrading-from-a-pinned-v2x-install) to move back to the current, self-healing setup.

Running Claude Code inside proot-distro Ubuntu (Path B) is another way around it; see the [install guide](install.md).

<details>
<summary><strong>Why it happens (background, optional)</strong></summary>

Two different failures produce these messages. `Bad system call` is Android's seccomp filter (a kernel feature that blocks a program from making system calls it is not allowed to) doing its job: the native binary issues a low-level system call the filter does not allow, and Android stops it. Which call trips it is version specific (an Android 10 build has died on `statx`, a newer native build on `pidfd_open`). `Segmentation fault` or `oh no: Bun has crashed` on newer phones is a different problem: it is a null pointer crash inside Termux's `glibc-runner` shim for `epoll_pwait2`, which the Bun 1.4 runtime calls at startup, not a blocked system call. In both cases `claude --version` survives because it exits before it reaches the crash; a real launch does not. The launcher in v2.9.2 and later checks versions it has not already verified and tries saved versions if a startup check detects a crash; recovery depends on a usable saved version. The Bun side is fixed upstream in oven-sh/bun#32490 (the runtime issues a raw system call to skip the shim).

</details>

---

### Update says "checksum mismatch" or stays on an older version

**Applies to Path A (native Termux).**

**You see:** running `claude` prints an update line to stderr and keeps running the version you already had, for example:

```
sha256sum: .../versions/2.1.203.tmp: No such file or directory
[claude] update: checksum mismatch on 2.1.203, using cached
```

or `[claude] update: download incomplete, using cached`. Claude still starts on the cached version; it just does not move up to the new release.

**What happened:** the downloaded file was incomplete or did not match the manifest. On launchers before 2.9.4, concurrent launches could collide during a download and delay the next check until the following day. The current launcher uses a lock and schedules another check in about an hour after download or checksum failure. A mismatch alone does not establish whether the fault is local or upstream.

**Fix it:** force one clean update, in a single terminal with no other `claude` running:

```bash
claude --update-now
```

That requests another download and verification; the launcher adopts the candidate only if its checks allow it. If it still reports a problem, refresh the launcher itself, which also delivers the 2.9.4 launcher that takes a lock so two launches can no longer collide:

```bash
curl -fsSL https://raw.githubusercontent.com/ferrumclaudepilgrim/claude-code-android/main/install.sh -o install.sh
bash install.sh
```

Refreshing the native launcher retains your login and other settings, sets `autoUpdates: false`, and removes stale `env.LD_PRELOAD`. The launcher discards failed candidate downloads. If the mismatch repeats, save the error and report it; do not bypass verification.

---

### EACCES error printed at startup

**Applies to Path A (native Termux).**

**You see:** an error line on startup mentioning `Cannot read directory`, while Claude Code itself works normally:

```
$ claude --version
2.1.207 (Claude Code)
error: Cannot read directory "/": EACCES
```

It shows up on `claude`, `claude --version`, and `claude mcp list`, but not on `claude --help`. Claude runs fine, sessions work, and the exit code is `0`.

**What happened:** the launcher loads a small DNS helper at startup. While resolving where that file lives, the runtime walks up the folders above it, one at a time, until it reaches the top of the filesystem. Android does not let an app read that top-level folder, so the runtime reports the refusal and carries on. It is noise, not a failure: nothing is broken and nothing is skipped.

**Fix it:** this is fixed in 2.9.4, which loads the helper by a path relative to where you are, so the walk never happens. Refresh the launcher:

```bash
curl -fsSL https://raw.githubusercontent.com/ferrumclaudepilgrim/claude-code-android/main/install.sh -o install.sh
bash install.sh
```

Your login and settings are kept. If the line still appears afterwards, it is still harmless, and the DNS fix keeps working either way; the launcher falls back to the absolute path when it cannot work out a relative one.

---

### Claude hangs on "Checking connectivity" / ETIMEOUT / 'API error' on every message

**You see:** Claude starts, then hangs on `Checking connectivity...` and fails with:

```
Unable to connect to Anthropic services
Failed to connect to api.anthropic.com: ETIMEOUT
```

even though `curl https://api.anthropic.com/` connects fine over both IPv4 and IPv6. It is often **intermittent** (fine one launch, hung the next) and is unrelated to your Claude Code version or to running as root. (On an already-logged-in session it may instead surface as an API error when you send a message.)

**Fix:** Update to the latest `install.sh` (or just re-run if using the curl + bash command). The launcher now points Claude Code's DNS resolver at a working nameserver automatically: it writes a tiny `setdns.js` next to the binary and loads it with `BUN_OPTIONS=--preload` on every launch (no binary patching, no extra permissions, no daemon). To confirm it's in place:

```bash
cat ~/.local/share/claude/setdns.js   # -> require("dns").setServers(["8.8.8.8", ...])
```

This DNS procedure is for the **native Path A wrapper**. Pinned Node installs and Paths B/C use different runtimes; do not add a global `BUN_OPTIONS` export to fix those paths. Refresh the wrapper rather than maintaining a separate preload in your shell profile.

**Heads up on DNS:** the default preload configures the runtime resolver with Google's `8.8.8.8` / `8.8.4.4`. Queries using that resolver do not use your private, VPN-provided, or Pi-hole DNS server. This does not change Android's system DNS or prove that traffic bypasses a VPN tunnel. To change the configured servers, edit `setServers([...])` in `~/.local/share/claude/setdns.js`; refreshes retain a nonempty helper. See [DNS scope and tradeoffs](security-model.md#path-a-forces-google-dns-for-claude-codes-own-lookups).

<details>
<summary><strong>Why it happens (background, optional)</strong></summary>

Claude Code is built with Bun, whose DNS resolver (c-ares) reads `/etc/resolv.conf` to find a nameserver. On Android `/etc` is a read-only link to `/system/etc` with no `resolv.conf`, so c-ares falls back to its built-in default `127.0.0.1:53`, where nothing is listening. The glibc resolver Termux ships *does* work (it reads `$PREFIX/glibc/etc/resolv.conf`, where `$PREFIX` is Termux's own install directory), but Bun uses both, and under the burst of name lookups at startup the dead-loopback queries time out and starve the working path. `curl` is unaffected because it uses Android's own (bionic/netd) resolver. The preload calls `dns.setServers()` to hand c-ares a live nameserver before the first lookup, so it never hits the dead loopback.

</details>

---

### Unsupported architecture: armhf

**You see:**

```
Unsupported architecture: armhf. Only amd64, arm64 are supported.
```

**Fix:** None. Claude Code requires a 64-bit (arm64/aarch64) operating system. Your device is running a 32-bit OS.

Check your architecture:

```bash
uname -m
```

If the output is `armv7l` or `armv8l`, your device cannot run Claude Code. This is a hard requirement with no workaround.

**Why this happens:** Some budget Android phones (Samsung Galaxy A13 5G, A02S, M13 5G, and others) ship with a 32-bit Android OS on 64-bit hardware. The phone's marketing materials may say "64-bit processor" but the OS runs in 32-bit mode. Claude Code checks `process.arch` at startup and rejects anything other than `arm64` or `x64`.

**Affected devices include:** Samsung Galaxy A13, A02S, M13 5G, A10, A6, and similar budget models from 2018-2023. Any phone where `uname -m` returns `armv7l` is affected regardless of the CPU's theoretical capability.

---

### Claude Code won't start, no error (v2.x install)

**You see:** The command returns immediately to your shell prompt. No output, no error, no crash log.

```
$ claude
$
```

**Affected:** v2.x users on the pinned 2.1.112 npm install. The v2.9.0 install (current `install.sh`) does NOT exhibit this symptom: it runs the linux-arm64 native binary directly under glibc-runner (a Termux package providing a glibc-compatible dynamic linker for Linux binaries) rather than the npm-installed JS bundle.

**Cause (v2.x):** The in-process auto-updater replaced the pinned 2.1.112 install with a 2.1.113+ build that has no android-arm64 binary. The replaced binary loads but exits before producing output. The `chmod -R a-w` lock applied by the v2.x `install.sh` should prevent this; if the install dir is no longer read-only, the lock was undone.

**Recovery (v2.x):** On a phone that can run the current native binary, follow the [migration steps](install.md#upgrading-from-a-pinned-v2x-install), which back up your setup before replacing the old install. On Android 8, 9, or 10, use the [pinned fallback](install.md#android-8-9-and-10-pinned-fallback) or [Path B](install.md#path-b-proot-distro-ubuntu) instead. Or, if you must stay on v2.x, manually reinstall 2.1.112:

```bash
chmod -R u+w $PREFIX/lib/node_modules/@anthropic-ai/claude-code/ 2>/dev/null
DISABLE_AUTOUPDATER=1 npm install -g @anthropic-ai/claude-code@2.1.112
chmod -R a-w $PREFIX/lib/node_modules/@anthropic-ai/claude-code/
```

If bare `claude` exits silently after manually reinstalling 2.1.112, confirm `ls -la $PREFIX/lib/node_modules/@anthropic-ai/claude-code` shows `dr-x------`.

---

### Claude Code exits: "native binary not installed" (historical / v2.x context)

**You see:**

```
$ claude
Error: claude native binary not installed.

Either postinstall did not run (--ignore-scripts, some pnpm configs)
or the platform-native optional dependency was not downloaded
(--omit=optional).
```

**Affected:** Users on a v2.x install whose pinned 2.1.112 was clobbered by the in-process auto-updater pulling a 2.1.113+ build (no android-arm64 binary). The v2.9.0 install does not exhibit this: it runs the linux-arm64 native binary directly via glibc-runner.

**Cause:** Upstream regression introduced in `@anthropic-ai/claude-code` 2.1.113. Versions 2.1.113 and later switched from a bundled `cli.js` JavaScript entry point to a platform-native binary wrapped by an optional-dependency dispatcher; android-arm64 is not in the dispatcher's PLATFORMS map. Tracked upstream at [anthropics/claude-code#50270](https://github.com/anthropics/claude-code/issues/50270).

**Recovery (recommended):** On a phone that can run the current native binary, follow [Upgrading from a pinned v2.x install](install.md#upgrading-from-a-pinned-v2x-install). Close all Claude sessions first and run the migration from ordinary Termux. It backs up your setup before replacing the old install; do not remove the npm install or delete your settings first.

**Android 8, 9, or 10?** Use the [pinned fallback](install.md#android-8-9-and-10-pinned-fallback) or [Path B](install.md#path-b-proot-distro-ubuntu) instead.

**Recovery (stay on v2.x):**

```bash
chmod -R u+w $PREFIX/lib/node_modules/@anthropic-ai/claude-code/ 2>/dev/null
DISABLE_AUTOUPDATER=1 npm install -g @anthropic-ai/claude-code@2.1.112
chmod -R a-w $PREFIX/lib/node_modules/@anthropic-ai/claude-code/
echo 'export DISABLE_AUTOUPDATER=1' >> ~/.bashrc
```

The `chmod -R a-w` was load-bearing under v2.x: the in-process auto-updater re-fetched `latest` on a timer and silently overwrote the install dir. v2.9.0 sidesteps the entire mechanism (`autoUpdates: false` in settings.json + a wrapper at `$PREFIX/bin/claude`, where `$PREFIX` is Termux's package prefix directory, outside the npm tree).

**Path B (proot-distro Ubuntu) was never affected** by this regression. Inside the Ubuntu guest, `process.platform === 'linux'` matches the upstream `linux-arm64` native binary directly.

---

### Termux package download hangs or says "Failed to fetch"

**You see:** `pkg update`, `pkg upgrade`, or an installer step waits for a long time, then prints `Failed to fetch` for a Termux repository URL.

**Cause:** The configured Termux package mirror is slow, unavailable, or unreachable from the current network. This failure occurs before Claude Code is downloaded.

**Recovery:** Stop the stalled command with Ctrl+C if necessary, then run:

```bash
termux-change-repo
```

Select another official mirror, let `pkg update` complete, and rerun the installer command from [install.md](install.md#path-a-native-termux). If `termux-change-repo` is missing or package behavior remains inconsistent, confirm that Termux came from an upstream-supported source; see [Termux from Google Play has issues](#termux-from-google-play-has-issues).

---

### Claude can't find a tool (jq / git / python / ...)

**You see:** Claude tries to run `jq`, `git`, `python`, `gh`, `openssh`, `tree`, etc. and the command fails with `command not found`. Tool calls fail repeatedly with the same kind of error.

**Cause:** This is a vanilla Claude Code in an environment it is not used to. `install.sh` installs the claude binary and the glibc-runner/patchelf-glibc support it needs (glibc-runner provides a glibc-compatible dynamic linker for Linux binaries; patchelf-glibc is a Termux-packaged patchelf utility for modifying ELF binary metadata so they resolve against it). It does not install nodejs or most developer tools. Beyond what Termux core ships (`unzip`, `tar`, `gzip`, `less`, `nano`), most tools Claude reaches for are not present.

**Fix:** Install the **[Recommended Common Packages](install.md#recommended-common-packages)** in install.md (one `pkg install` line). Also consider injecting them into your `CLAUDE.md` or an environment hook so Claude knows what's available. Without that, expect recurring tool failures and barriers.

---

### OAuth / authentication fails on first launch

**You see:** The OAuth (browser-based login) flow fails, hangs, or the browser never opens. You may see:

```
Error: Failed to open browser
```

Or the auth URL prints to the terminal but nothing happens when you visit it, or the redirect back to `localhost` fails with a connection refused error.

**Fix:**

1. Install `termux-open-url` to enable browser integration:
   ```bash
   pkg install termux-tools -y
   ```
   Then retry `claude`; it should open your system browser for OAuth.

2. If the browser opens but the redirect fails, copy the auth URL manually from the terminal into your browser.

3. If you choose a direct API key, it uses Console/API billing, separate from a Pro or Max subscription. Review [authentication choices](https://code.claude.com/docs/en/authentication) first. To avoid putting the key in shell history, enter it at a hidden Bash prompt:
   ```bash
   read -r -s -p 'Anthropic API key: ' ANTHROPIC_API_KEY
   printf '\n'
   export ANTHROPIC_API_KEY
   ```
   This exports the key for this shell session. Do not paste it into a report or commit it to a project.

**Cause:** Termux has no system browser integration by default. The login redirect URL may not reach Termux because `localhost` inside Termux and `localhost` from the Android browser are not always the same network context.

**Android-version note:** Auto-open behavior varies by Android version. On Android 10 and newer the system browser generally opens on its own when claude triggers OAuth. On Android 8 and 9 it may not: if the browser does not open, copy the URL from the terminal and paste it into your phone's browser manually. See [FAQ: Claude prints a URL but my browser doesn't open](faq.md#claude-prints-a-url-but-my-browser-doesnt-open).

---

### proot-distro issues

**You see:** Inside a `proot-distro` guest (Ubuntu, Debian, etc.), Claude Code produces no output or hangs.

```
$ proot-distro login ubuntu
root@localhost:~# claude
█
```

**Version check:** A TCGETS2 ioctl bug that previously broke stdout in guest distros with glibc 2.41+ was fixed in proot 5.1.107-66 (October 2025). The [device table](device-compatibility.md#device-results) records this repo's Path B observations and dates; an old environment capture is not a later guest-install test. Start by updating proot in **host Termux**:

```bash
pkg upgrade proot proot-distro -y
```

**If it still hangs after updating proot:**

1. Check your proot version. Must be 5.1.107-66 or later:
   ```bash
   dpkg -s proot | grep Version
   ```

2. Test with a simple command instead of interactive login:
   ```bash
   proot-distro login ubuntu -- sh -c 'echo hello'
   ```

3. If the simple command works but interactive login hangs, the issue may be terminal initialization. Try:
   ```bash
   proot-distro login ubuntu -- bash --norc --noprofile
   ```

**The warning `can't sanitize binding "/proc/self/fd/1"`** appears during proot-distro login and is harmless. stdout works correctly despite this message.

**Note:** proot-distro is a valid alternative to the native Termux approach. See [install.md, Path B](install.md#path-b-proot-distro-ubuntu) for the full setup guide. However, for Claude Code alone, the native Termux approach (Path A) is lighter and faster.

---

### Node.js v24 hangs

**Affected:** the pinned `2.1.112` JS install, which runs on system Node. The Path A native binary ships its own runtime and no Node, so `node -v` and this hang do not apply to it.

**You see:** Claude Code hangs on startup with Node.js v24. The process appears to start but never becomes interactive.

```
$ node -v
v24.x.x
$ claude
█
```

There is no error message. The process appears to start but never becomes interactive.

**Fix:** The v24 hang is specific to v24. Upgrade Node to v25 or later:

```bash
pkg upgrade nodejs -y
node -v  # should show v25.x.x or higher
```

If `pkg upgrade` doesn't move you to v25, check that your Termux package repositories are current. The F-Droid version of Termux ships v25+ in its default repo. As a fallback, use Path B (proot-distro Ubuntu), where this constraint does not apply.

**Cause:** The hang is specific to v24, not Termux generally. Node.js v24+ inside proot-distro Ubuntu does not exhibit this behavior in testing. v25 resolves it.

---

### Process killed randomly

**You see:** Claude Code or its subprocesses die mid-session. No error, no crash; the process just disappears. Your terminal may show:

```
[Process completed (signal 9) - press Enter]
```

Or the Claude Code session simply vanishes and you're back at your shell prompt.

**Fix:**

1. Minimize background apps while using Claude Code.
2. Limit concurrent subagents and child processes.
3. If your device exposes it, enable the developer option that disables the child-process restriction:

   **Settings -> Developer Options -> Disable child process restrictions** (toggle on)

   If you don't see Developer Options, go to **Settings -> About phone** and tap **Build number** seven times.

4. Open Android's app battery settings for Termux and look for **Battery optimization**, **App battery usage**, **Unrestricted**, or **Allow background activity**. Names and locations vary by Android version and manufacturer. If Termux:API is involved, review its companion app separately. Relaxing these limits can increase battery use and heat and is not a guarantee that Android will keep the process alive.

**Cause:** Android can stop work for more than one reason. Its phantom process controls can kill excess child processes, while battery and background policies can suspend or kill the Termux app. The **Disable child process restrictions** option addresses the former, not battery optimization.

**Session persistence with tmux:** Install tmux (`pkg install tmux`) and run Claude Code inside a tmux session (`tmux new -s claude`). This can preserve a session when you close the terminal window or Android recreates its activity. It cannot preserve the session if Android kills the Termux process or the phone reboots. If the process is still alive, reopen Termux and run `tmux attach -t claude` to resume.

---

### EMFILE errors

**You see:**

```
Error: EMFILE: too many open files, open '/data/data/com.termux/files/home/...'
```

or

```
Error: EMFILE, too many open files
```

**Fix:**

- Check your limit: `ulimit -n`. This varies by device and Android version; newer devices report tens of thousands, older ones can be lower.
- Avoid spawning unnecessary background processes.
- Close unused terminal sessions.
- If running multiple tools simultaneously, reduce parallelism.
- Restart Claude Code to release leaked file descriptors.

**Cause:** EMFILE means the process ran out of file descriptors. The limit varies by device and Android version. If you hit this, reduce concurrent operations or check if leaked FDs are the real issue (`ls /proc/$$/fd | wc -l`).

---

### npm install fails silently (your own packages, not Claude Code)

**You see:** You run your own `npm install -g <some-package>` and npm appears to finish without complaint, but the package is not actually installed. This is for your own npm work; `install.sh` in this repo handles the Claude Code install correctly without any extra setup.

**Check the temporary directory in ordinary Termux.** If npm is using an unwritable location, set a Termux-owned temporary path and retry the package you meant to install:

```bash
export TMPDIR="$PREFIX/tmp"
```

This matches the pinned installer's temporary-directory setting. `install.sh` uses the native binary and does not set up an npm shell environment. A silent failure can have other causes; retain npm's output and exit status rather than assuming this fixes every package. If you set a custom npm prefix, confirm that it is a writable directory you own.

---

### Grep/Glob/slash commands fail with ENOENT (v2.x install)

**You see:**

```
spawn /data/data/com.termux/files/usr/lib/node_modules/@anthropic-ai/claude-code/vendor/ripgrep/arm64-android/rg ENOENT
```

Search tools (Grep, Glob) and slash commands that depend on them crash immediately. Claude Code may fall back to slower methods or simply fail the operation.

**Affected:** v2.x installs only. On v2.9.0, the linux-arm64 native binary ships `vendor/ripgrep/arm64-linux/rg` and reports `process.platform === 'linux'`, so it finds its bundled rg on the first try. No env var or symlink needed.

**Recovery (v2.x / pinned 2.1.112):** Run `scripts/fix-ripgrep.sh`. It installs system ripgrep and symlinks it onto the exact vendored path Claude Code looks for, unlocking and relocking the folder it writes to as it goes:

```bash
curl -fsSL https://raw.githubusercontent.com/ferrumclaudepilgrim/claude-code-android/main/scripts/fix-ripgrep.sh -o fix-ripgrep.sh
bash fix-ripgrep.sh
```

Re-run after a Claude Code update; the symlink does not survive updates.

**Cause:** The v2.x / pinned 2.1.112 install uses the npm-distributed JS bundle whose vendored ripgrep set has no `arm64-android` build, so the search tool spawns a path that does not exist. On 2.1.112 the `CLAUDE_CODE_USE_NATIVE_FILE_SEARCH=1` env var does not redirect the search, so the symlink onto the vendored path is the fix.

### Custom agents (v2.x)

If custom agents defined in `.claude/agents/` fail to load on v2.x, it is the same root cause: Claude Code's file search cannot find the agent definition files on `arm64-android`. The ripgrep symlink above resolves agent loading as well. v2.9.0 does not exhibit this issue.

---

### `#!/usr/bin/env` scripts fail with "bad interpreter" (v2.9.1+)

**You see:**

```
/usr/bin/env: bad interpreter: No such file or directory
```

A script that claude's Bash tool runs **directly** and whose first line is `#!/usr/bin/env bash` (or `python3`, `node`, and so on) exits 126. This shows up with some project scripts and `node` CLI shims.

**Affected:** v2.9.1 and later. The install no longer sets `env.LD_PRELOAD` in `~/.claude/settings.json`, because that preload broke claude's own bundled grep, rg, and ugrep. Android has no `/usr/bin/env`; Termux's `termux-exec` preload is what rewrites `/usr/bin/env` to Termux's own `env`, and claude's subprocesses no longer carry that preload. This is a deliberate trade-off in favour of search working.

**Work around it:** run the interpreter explicitly instead of executing the file:

```bash
bash ./script.sh      # instead of ./script.sh
python ./script.py    # instead of ./script.py
node ./tool.js        # instead of ./tool.js
```

Tools called by name (`grep`, `git`, `python`, `node`) and `#!/bin/sh` scripts are unaffected, and a normal Termux shell outside claude is unaffected.

---

### Voice mode not functional

**You see:**

```
Voice mode requires SoX for audio recording. Install SoX manually:
```

The `/voice` command refuses to start.

**Fix for that missing-recorder error (ordinary Termux):**

```bash
pkg install sox
```

Installing SoX supplies the `rec` recorder; it does not prove that Android is delivering microphone audio. Current [Claude dictation documentation](https://code.claude.com/docs/en/voice-dictation) describes a native Linux recorder with `arecord` or SoX fallback. Android is still a community setup, so check your own installed version and capture path.

**Check microphone permission separately.** For the supported matching-source Termux setup, the [Termux:API companion declares microphone permission](https://github.com/termux/termux-api/blob/master/app/src/main/AndroidManifest.xml) for the shared app identity. Follow [optional Termux:API setup](install.md#termuxapi-explicit-optional-setup), then review **Settings → Apps → Termux:API → Permissions → Microphone**. Menus vary by build; do not assume Termux itself will offer that permission.

**Earlier Android 16 failures are not a universal current blocker.** In my [2026-08-15 five-device retest](https://github.com/termux/termux-packages/pull/29074#issuecomment-5304389028), updated packages captured changing microphone audio on all five phones, including the Android 16 S26 Ultra. Those were bounded audio-capture checks, not verification of every Claude `/voice` configuration.

The [AAudio](https://github.com/termux/termux-packages/pull/29074) and [Oboe](https://github.com/termux/termux-packages/pull/29319) proposals remain open as checked on 2026-10-25; they are alternative audio work, not a required pending fix for every phone. Text-to-speech is a separate feature and does not establish that voice recording works. No new voice tests were performed for this documentation revision.

---

### Hooks on Termux native

**Recorded observation:** SessionStart and PreToolUse command hooks ran in the earlier Termux JavaScript setup. That is separate from current native Path A, which uses a Linux binary. Check hooks on the installation you actually use; a platform label does not establish that a hook ran.

You can verify the platform identifier (informational, not a blocker):

```
$ node -e "console.log(process.platform)"
android
```

This `node -e` check needs a separate Node install (the pinned `2.1.112` JS path or Termux's own `nodejs`). The Path A native binary reports `process.platform === "linux"` internally and ships no Node, so the check does not apply to it. Hook execution still depends on the interpreter, PATH, and failure policy. For direct scripts on native Path A, use an explicit `bash` invocation as described above.

If your hooks are not firing on Termux:

1. Confirm the hook command path resolves on Termux (`$HOME` and `$PREFIX` expand inside the JSON config; absolute paths also work)
2. Set `timeout` explicitly in the hook entry (some hooks fail silently without one)
3. Verify hook exit codes (PreToolUse: `2` = block, `0` = allow; non-zero non-2 = non-blocking error)
4. For PreToolUse/PostToolUse, confirm the matcher pattern (regex) actually matches the tool name
5. Check `~/.claude/logs/` if present

---

### Termux from Google Play has issues

**You see:** If you installed Termux from a source that turned out to be outdated or limited, packages may fail to install, repositories may be missing, or the app may behave unexpectedly:

```
E: Unable to locate package nodejs
```

You may also see apt report that a repository "does not have a Release file," which means the build is pointing at a package source it can no longer reach.

**Fix:** Back up your Termux projects and configuration first: uninstalling can erase its private environment. Follow the [source and backup guidance](install.md#if-android-blocks-the-termux-apk), then reinstall from one of these sources:

- [F-Droid](https://f-droid.org/en/packages/com.termux/)
- [Termux GitHub releases](https://github.com/termux/termux-app/releases) (direct APK, an Android app package file)

After installing, run:

```bash
pkg update && pkg upgrade -y
```

**Cause:** The upstream Termux maintainers describe the Google Play build as an experimental branch with missing functionality and bugs (see [github.com/termux/termux-app](https://github.com/termux/termux-app)); they recommend F-Droid or their GitHub releases for most users. If you have package-source or version issues with the Google Play build, switching to F-Droid or GitHub releases is the upstream-recommended fix.

---

### PDF reading fails ("pdftoppm is not installed")

**You see:**

```
pdftoppm is not installed
```

The `Read` tool returns this error when you try to read a `.pdf` file, even after running `pkg install poppler`.

**Check the tools in the same environment where Claude runs.** In ordinary Termux, install Poppler and the [packaged `which` command](https://github.com/termux/termux-packages/blob/master/packages/which/build.sh), then check that both resolve:

```bash
pkg install poppler which
command -v pdftoppm
command -v which
```

Restart Claude in that environment and try a non-sensitive PDF. If both commands resolve but `Read` still fails, record your installation path, Claude version, and exact error. These package checks do not prove that every PDF reader/runtime combination works.

For text extraction alone, Poppler also supplies `pdftotext`: `pdftotext file.pdf -` prints the text to your terminal. Replace `file.pdf` with your own filename.

**Why check both?** A missing executable or a different PATH can make tool detection fail even after a package was installed elsewhere. Termux has a real `which` package; do not overwrite its executable with a custom shim. Path B and C need their tools inside Ubuntu or Debian, not only in host Termux.

---

### `claude doctor` crashes

**You see:**

```
Raw mode is not supported on the current process.stdin
```

`claude doctor` outputs this error and exits without completing any checks.

**Fix (not yet confirmed on all devices):** Run `claude doctor` in a direct interactive Termux session. Not backgrounded, not piped, not launched from within Claude Code itself:

```bash
# Open a fresh Termux terminal session and run:
claude doctor
```

If you are running it from inside a Claude Code session via the Bash tool, that won't work. The Bash tool does not provide a raw-mode terminal.

**Cause:** The `claude doctor` command uses the Ink library (a React-based terminal UI renderer) to render its output. Ink requires raw mode stdin. Termux provides raw mode in interactive sessions but not in piped or backgrounded contexts.

**Status:** Cosmetic. `claude doctor` is a diagnostic tool, not required for normal Claude Code operation. This repo ships a separate Termux-side check: [`scripts/check-termux-env.sh`](../scripts/check-termux-env.sh). It is not equivalent to `claude doctor`; it calls `claude --version`, which can trigger wrapper updates. Review its [effects and limits](add-ons/skills.md#check-or-repair-your-setup) before running it.

---

## Upstream Issues

Known issues filed against the Claude Code repository that affect Android/Termux users:

| Issue | Description | Status | Notes |
|-------|-------------|--------|-------|
| [#50270](https://github.com/anthropics/claude-code/issues/50270) | 2.1.113+ broken on Termux/Android: native binary requires glibc, no JS fallback | Open | v2.9.0 install in this repo runs the linux-arm64 native binary directly under Termux's glibc-runner; see [README](../README.md#path-a-native-termux) |
| [#16615](https://github.com/anthropics/claude-code/issues/16615) | Platform detection: `android` not recognized | Closed (not planned) | Historic. Path A v2.9.0 ships the linux-arm64 binary which reports `process.platform === 'linux'`, sidestepping the detection problem entirely |
| [#13021](https://github.com/anthropics/claude-code/issues/13021) | Missing arm64-android ripgrep binary | Closed | v2.x / pinned 2.1.112: symlink system rg onto `vendor/ripgrep/arm64-android/rg` (`scripts/fix-ripgrep.sh`); the env var does not redirect the search on 2.1.112. v2.9.0 install: not applicable. The linux-arm64 binary ships `vendor/ripgrep/arm64-linux/rg` and uses it |

---

## ADB Wireless Debugging

Setting up ADB over WiFi (pairing errors, dropped connections after screen lock or reboot, and reconnecting) has its own guide: see **[adb-wireless.md](add-ons/adb-wireless.md)**, which includes a Troubleshooting section for the common pairing and connection problems.

---

## Path C: AVF (Experimental)

Path C runs Claude inside Android's Debian VM. The Path A wrapper, blocklist, and cached-binary recovery do not apply there. This path remains experimental; the recorded end-to-end checks cover Pixel 6 and Pixel 10 Pro on Android 17, dated 2026-05-26.

| What you see | Where to go next |
|---|---|
| No Linux development environment toggle | Check [device requirements](avf-guide.md#device-requirements). Availability depends on the build; use A or B if it is absent. |
| Claude fails inside Debian | Use [Path C maintenance and repair](install.md#update-path-c), inside the VM. Do not run the Termux migration script there. |
| VM stops when the screen turns off | Check [Keep awake](avf-guide.md#5-screen-off-stability-keep-awake). It uses more battery; `tmux` can preserve a session through terminal recreation, not a VM shutdown. |
| “VM damaged” or considering a reset | Read [Recovery](avf-guide.md#recovery-and-backups) first. Reset recreates the guest and can delete projects stored inside it; back up what you can before proceeding. |
| Cellular networking, audio, or Linux tool limitations | Use the [AVF known issues](avf-guide.md#known-issues) and [tested capabilities](avf-guide.md#what-i-observed-working). A working audio command does not establish phone microphone or speaker routing. |

The [AVF guide](avf-guide.md) owns setup, feature observations, and default-account/SSH hardening. Keep recovery here tied to those procedures rather than following a second installation checklist.

---

*Documentation reviewed: 2026-10-25. Device observations retain their original dates; no new phone tests were performed.*
