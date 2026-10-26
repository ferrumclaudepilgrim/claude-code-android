# Changelog

## [Unreleased]

(No unreleased changes yet.)

## [2.9.5] - 2026-10-25

This update reorganizes the guides, consolidates device reports, and tightens maintainer checks. Device results retain their recorded dates and testing boundaries.

### Added

- A device compatibility and evidence table combines dated maintainer checks, contributor evidence, and community reports, including the Galaxy S23 Ultra Path B report in issue #12. Reported workarounds remain distinct from fixed defects.
- A passive Android sensor probe and saved results from four lab phones. The results separate sensor availability from observed events and record the ADB-shell test boundary.
- A release checklist and an automated metadata consistency check for the README badge, the device compatibility page, and the changelog.

### Changed

- Repository version: `2.9.4` to `2.9.5`; Anthropic's Claude Code version and the `2.1.112` fallback are separate.
- Optional guides now live together under `docs/add-ons/`, reached through Build with Android. The `CLAUDE.md` starter is `project-instructions.md`; the old constitution, fingerprint, and SSRF locations are removed. The wireless ADB guide is now [here](docs/add-ons/adb-wireless.md). Historical release entries retain their original wording and link destinations.
- The README and contribution guidance use simpler, evidence-first language and describe Android limitations without comparing the project to unrelated repositories.
- The install, wireless ADB, AVF, sensor, security, troubleshooting, skills, and starter-template guides have clearer navigation and tighter scope. The install guidance now covers Android battery and background restrictions without implying that one menu path fits every device.
- Bug reports now request redacted Termux and install-path diagnostics appropriate to the reported setup.
- `tests/verify-claims.sh` is described as a selected-check harness rather than proof of every documentation claim.
- The termux-safe skill covers the `#!/usr/bin/env` limitation under the Path A launcher and recommends the shell builtin `command -v` while identifying `which` as an available package. The skills guide retains the caveat about its existing low-port rule.
- The `CLAUDE.md` starter drops the Termux rules the termux-safe skill already covers, and its optional subagent section.
- `scripts/check-termux-env.sh` labels its checks for what they measure and no longer cites a fixed process limit. Every check and exit code is unchanged.

### Removed

- The general-purpose `minimum-viable` and `scope-framing` skills, which were not specific to Android.
- `scripts/config-validator.sh`, a general `.claude/` folder checker with nothing Android-specific.

### Fixed

- The Moto G7 Power Path B result retains the dated 2026-05-16 maintainer record; missing separate transcripts do not negate that record.
- The link checker explicitly excludes the obsolete local ADB target retained in the immutable 2.0.0 changelog entry; all other changelog links remain in scope.
- Verification scripts now return distinct non-zero statuses for failed checks and harness errors, and the mutation suite protects those exit-code semantics.
- Security examples no longer imply that blocking a few commands removes all network access.
- `install-pinned.sh` and the troubleshooting guide now give a working way to run `fix-ripgrep.sh` on a pinned install. The earlier advice pointed to a folder that users who downloaded the installer alone did not have, and the manual steps could not write to the locked install folder.
- Earlier wording about verifying all documentation claims is clarified: the harness checks selected claims, and its results do not establish every documented behavior.

## [2.9.4] - 2026-07-27

A reliability release for the installer and the launcher, with a documentation pass alongside it.

Three things could go wrong on a real phone. On a device where the current Claude Code cannot start at all, `install.sh` ran its launch probe as a bare command under a shell setting that exits on any failure, so it stopped right there, before writing the launcher, the settings, or the PATH entry. The user got a raw `Killed` and no working `claude` command instead of the explanation the script was written to give. Android 8 and 10 are where that fired, and a healthy install passes straight through it, so it sat unseen. Separately, the daily update check staged every download to one shared file with no lock, so two ordinary launches inside the same few-minute window could delete each other's download, report a false "checksum mismatch", and leave the device a version behind until the next day. And every launch printed `error: Cannot read directory "/": EACCES`, because loading the DNS helper by its absolute path made the runtime walk up the folders above it until it reached the top of the filesystem, which Android does not let an app read. That last one was cosmetic throughout. Thanks to @Tanbeer191, who found both its cause and its fix.

Verified across four devices. On the Moto G7 Power (Android 10), where the binary genuinely cannot start, a fresh install classifies the crash, writes the launcher, settings, and PATH entry, and finishes with the explanation and a working way forward. On the Galaxy S7 (Android 8), the migration aborts on that same crash and leaves the existing pinned install running. On the Pixel 6 and Pixel 10 Pro (Android 17), the startup error is gone, name resolution returns a real address, and two simultaneous launches leave no false "checksum mismatch" and no partial download behind. The Pixel 6 also ran a full install from scratch.

### Added

- A single-updater lock and a per-process staging path in the launcher (`install.sh` and `migrate.sh`), so two launches inside the download window no longer race on a shared file.
- Enforcement that `install.sh` and `migrate.sh` stay byte-identical where they must. Both scripts mark the shared sections with `SYNC:BEGIN` and `SYNC:END`, and `scripts/check-sync.sh` fails when they drift. Thanks to @doomcrew328.
- An offer to install the working pinned release. When the installer finds that the current Claude Code cannot run on this device, it now offers to fetch and run `install-pinned.sh` for you rather than leaving you to do it by hand, and it names the upstream issue so you can see why. Declining, or a failure in that optional step, leaves the completed install alone. A non-interactive install prints the command instead of prompting.
- A mutation harness (`tests/mutation-check.sh`) that applies eleven known regressions to temporary copies and requires each to be caught, so a suite that has stopped protecting the code cannot pass unnoticed.
- Regression suites for the launcher's update path and the install-time probe classification (`tests/wrapper-update-tests.sh`, `tests/installer-smoke-tests.sh`). Both fail against the previous release.
- CI now runs shell syntax, ShellCheck, the sync check, all three suites, and the mutation harness on every push and pull request.
- A troubleshooting entry for the startup EACCES line, which was reported but undocumented.
- GitHub issue forms for bug reports and device reports, scoped to the failure classes this repo actually sees, so a report arrives with the device, Android version, install path, and exact error instead of free text.
- A "Related projects" section pointing to other ways to run Claude Code on Android, so a reader can pick the one that fits their device.
- A returning-user recovery callout near the top of the README for the "it worked yesterday, now it crashes or hangs" case.
- Path C (Android Virtualization Framework) device support in the README, kept clearly separate from the Termux paths.

### Changed

- CONTRIBUTING is now a full contribution guide, including the automated checks to run before opening a pull request and the byte-identical rule the two installers follow.
- The "question or success story" link on the issue chooser now goes to Discussions. It pointed at a documentation page, which left anyone with a question nowhere to go, since blank issues are disabled.
- The security policy is rewritten for a solo public repo, with the current nested hooks schema in the permission-guard docs.
- The README and install guides are shorter and less dense: a single maintainer note at the top, jargon glossed in place, and Path B standardized to "proot-distro Ubuntu". The device table drops a column that repeated a date already shown in the row, which also stops it overflowing on a phone.
- The Path A disk figure now says what a device actually uses. The stated base covered a fresh install only, while the launcher keeps the previous binary for rollback, so real use is roughly double that once the first update lands.
- install.md's description of what the launcher does on each launch matches what it does, including the update lock and the difference between a crash and a probe that could not finish.
- `VERSION`: 2.9.3 -> 2.9.4.

### Fixed

- `install.sh` and `migrate.sh` no longer exit before finishing when the launch probe reports a crash or a timeout. On a device that cannot run the current release, the install now runs to completion, writes the launcher and settings, and ends with a message saying plainly that this release will not run here, where to go instead, and not to start claude. It exits successfully, because nothing about the install failed. Previously the script stopped at the probe, left no working `claude` command at all, and then reported failure with advice that could not help on that device.
- The startup `Cannot read directory "/": EACCES` line is gone. It was cosmetic, and the DNS fix it came from keeps working either way.
- Launching Claude twice inside the download window no longer strands the update or reports a false "checksum mismatch".
- A launch probe that times out no longer permanently rejects a good build. The self-heal separates a definite crash, which is recorded and rolled back, from an inconclusive result, which is retried and never recorded as bad, and falls back to the best non-crashing build rather than refusing to launch. It decides which happened by how long the probe ran rather than by an exit code, because the exit status for a killed process is not the same across the tools different Android builds ship.
- A download interrupted part-way no longer sits on the device. The launcher clears abandoned staging files on its next update check, and both installers now remove the partial file when a download fails outright, which matters most on the nearly full devices where downloads fail in the first place.
- `install.sh` removes the staged binary when patching fails, matching what `migrate.sh` already did. Thanks to @doomcrew328.
- The pinned-install search recovery names the ripgrep symlink as the primary fix, scoped to pinned installs, and points at the correct upstream issue (anthropics/claude-code#13021).
- Corrected the phantom-process comment and the install-type label in the environment check script, the source attributions in the verification harness, and the One UI 8.5 timeline and Tensor G5 core topology in the AVF guide.

## [2.9.3] - 2026-07-01

A DNS reliability release. It works around a Bun bug that makes Claude Code hang on "checking connectivity" and fail with ETIMEOUT on Termux, and it makes search work out of the box on the pinned install for older devices.

Why the DNS fix is needed: Claude Code is a Bun binary, and on Linux Bun's DNS resolver defaults to c-ares, which reads `/etc/resolv.conf`. Termux has no `/etc/resolv.conf`, so c-ares falls back to a resolver at `127.0.0.1:53` where nothing is listening, and lookups fail. Because the binary is the linux-arm64 build, Bun treats the environment as Linux and takes that c-ares path rather than Android's system resolver. glibc's own `getaddrinfo` reads the resolver config Termux provides and works, which is why the failure is intermittent and shows up under load. Upstream: the c-ares behavior is oven-sh/bun#24970 (open); the proposed fix to default to `getaddrinfo` on Linux, oven-sh/bun#29231, was closed unmerged when its Zig implementation was dropped in Bun's move to Rust; the slow-fail to ETIMEOUT is tracked in the fix PR oven-sh/bun#32165 (open).

Verified on 2026-07-01 across four devices. On the Pixel 10 Pro and Pixel 6 (Android 17, native 2.1.197 with the preload), name resolution no longer touches the dead `127.0.0.1:53` loopback and a real authenticated turn reaches the server; search works. On the Moto G7 Power (Android 10) and Galaxy S7 (Android 8), the pinned 2.1.112 install runs and search works through the ripgrep symlink. The self-healing launcher from 2.9.2 was re-confirmed on both native devices: a planted crashing version is smoke-tested, recorded as bad, and rolled back with no user action.

### Fixed

- Claude Code no longer hangs on "checking connectivity" or fails with ETIMEOUT because of Bun's DNS resolver. `install.sh` and `migrate.sh` install a small preload that points Bun's resolver at a working nameserver (8.8.8.8 / 8.8.4.4) before Claude starts, so name resolution no longer falls back to the dead `127.0.0.1:53` loopback. It touches nothing in the binary. Thanks to @Tanbeer191 for the root cause and the fix (issue #7, PR #9).
- Search (Grep and Glob) works out of the box on the pinned install. `install-pinned.sh` installs system ripgrep and symlinks it onto the vendored path Claude Code looks for (`vendor/ripgrep/arm64-android/rg`), which upstream does not ship. Previously the pinned install left search failing with `spawn ENOENT` until the user ran `scripts/fix-ripgrep.sh` by hand.

### Changed

- The troubleshooting guide's search recovery now points at the ripgrep symlink, which is what works on the pinned 2.1.112 install. The `CLAUDE_CODE_USE_NATIVE_FILE_SEARCH` env var does not redirect the bundled search on 2.1.112 (verified on device); the symlink onto the vendored path is the fix.
- `VERSION`: 2.9.2 -> 2.9.3.

### Added

- A troubleshooting entry for the DNS hang and ETIMEOUT, with the upstream Bun references.

## [2.9.2] - 2026-06-18

A resilience release for the auto-updating wrapper. It makes the wrapper refuse to run, and refuse to promote, a Claude Code binary that crashes on this device, and it rolls a device back to the last working version automatically. The trigger was Claude Code 2.1.181, which bundles an unreleased Bun 1.4 that segfaults at launch on Android (issue #6). It is the same class of failure as the Android 10 problem (issue #5): a newer syscall the native binary uses, blocked by Android's per-app seccomp filter.

Why this is needed: the native binary runs under that seccomp filter, which blocks syscalls it does not allowlist. On Android 10 the binary issues `statx` and dies with SIGSYS. On newer devices Bun 1.4 issues `epoll_pwait2` and dies with SIGSEGV. In both cases the binary passes `claude --version` but crashes on full launch, so the previous wrapper auto-updated to it and then could not start. Upstream: oven-sh/bun#32489 and #32490 (unmerged at the time of this release).

Verified on 2026-06-18. On a device carrying both a working 2.1.176 and a crashing 2.1.181, the wrapper rolled back to 2.1.176 on launch with no user action, recorded the bad version so it is not re-downloaded, and a second launch ran the verified-good binary with no re-test. The launch probe was confirmed to trip both failure modes: the `epoll_pwait2` crash on a current device and the `statx` crash on Android 10. The selection loop was exercised against empty, all-broken, stale-pointer, and corrupt-file states.

### Fixed

- The wrapper no longer leaves a device stuck on a crashing auto-update. On launch it smoke-tests the version it is about to run (a short `--init-only` probe under a timeout). If that binary dies by a fatal signal, hangs, fails to execute, or prints a runtime crash banner, the wrapper records it as bad and falls back to the next-highest installed version that launches. A device that auto-updated to a broken release recovers on the next launch with no user action.
- `install-pinned.sh` now recovers a device that already has a crashing native install. Previously the pinned `npm install` aborted with `EEXIST` because the native launcher file was still at `$PREFIX/bin/claude`, leaving the crash in place; the script now clears that file first so the pinned package can take over the `claude` command. This is the fallback the troubleshooting guide points to when no working binary is left.

### Added

- A smoke test before a downloaded update is promoted. The wrapper runs the same launch probe on the freshly downloaded, patched binary before swapping it in. A binary that crashes is discarded, the working binary is kept, and the bad version is recorded so it is not downloaded again.
- An install-time smoke test in `install.sh`. After installing, it runs the launch probe; if the latest release crashes on this device it says so and points to `install-pinned.sh` or proot, instead of leaving a crash on first launch.
- Re-running `install.sh` on a device that already has the v2.9 launcher now refreshes the launcher in place (skipping the package install and binary download) instead of exiting with nothing to do. This is how an existing install receives the self-healing launcher: the daily auto-update refreshes the binary, not the launcher, so re-running the installer is what delivers a launcher change to a device that is already set up.

### Changed

- `VERSION`: 2.9.1 -> 2.9.2.

## [2.9.1] - 2026-05-30

A bug-fix release for the v2.9.0 Path A architecture. No architecture change. It makes `install.sh` and `migrate.sh` work on a device that already had claude, brings back claude's bundled grep, rg, and ugrep, and stops the package step from printing a warning on every call. It also adds an opt-in pinned installer for people who want the smallest setup.

Verified on 2026-05-30, all on Android 17. A fresh `install.sh` on a Google Pixel 6 ran end to end: claude launches, and grep, rg, and ugrep all work. On a Google Pixel 10 Pro, `migrate.sh` converted an official native install and `install.sh` installed in place over a leftover config, both keeping login and settings. On the Pixel 6, `install-pinned.sh` then `migrate.sh` took a pinned 2.1.112 install up to the 2.9.x wrapper. Older devices (Galaxy S7, Moto G7 Power) are not re-verified.

### Fixed

- claude's bundled grep, rg, and ugrep work again. `install.sh` and `migrate.sh` no longer write `env.LD_PRELOAD` into `~/.claude/settings.json`. That preload leaked into claude's subprocess environment, where claude's own grep/rg/ugrep re-exec the native binary directly. The glibc loader then rejected the bionic preload, and every search failed with "invalid ELF header". There is a trade-off: without the preload, claude's subprocesses also lose termux-exec, so a directly-run `#!/usr/bin/env ...` script cannot find its interpreter (Android has no `/usr/bin/env`). Search working was the higher priority. Running an interpreter explicitly (`bash file`, `python file`, `node file`) and tools called by name are unaffected.
- `install.sh` no longer refuses on a device that previously ran claude. It classifies the current state and either installs fresh, installs in place while preserving `~/.claude` (sessions, login, settings), routes a pinned npm install to `migrate.sh`, or exits if the current wrapper is already present. The earlier "this installer is fresh-only" failure fired whenever `~/.claude` existed, even after claude had been removed.
- `migrate.sh` recognizes and converts an official native claude install (a versioned binary with a `~/.local/bin` launcher and no wrapper) in place, instead of refusing it as an install it did not create.
- `migrate.sh` no longer ends with a false failure when it migrates a claude that was installed but never launched. The final session-count step ran `ls` on a `~/.claude/projects` directory that does not exist yet and aborted under `set -e`, after the migration had already finished. It now reports zero sessions and completes normally.

### Changed

- The scripted package steps use `apt-get` instead of `pkg`, so the install no longer prints apt's "does not have a stable CLI interface" warning on every call.
- A Termux mirror is selected automatically only when none is set, so a brand-new Termux does not stall the unattended install on a mirror prompt. It never overrides a mirror you already chose.
- `install.sh` (and `install-pinned.sh`) warn before installing if launched inside a running claude session, where Android's low-memory killer can end the install.
- `VERSION`: 2.9.0 -> 2.9.1.

### Added

- `install-pinned.sh`: an opt-in installer that pins Claude Code `2.1.112` (the last upstream version with a JS entry point) and locks the pin. No binary patching and no auto-updating wrapper. It is for people who want the smallest, simplest install and are content to stay pinned. `install.sh` is still the default for current claude.

## [2.9.0] - 2026-05-29

Path A architectural switch from the pinned 2.1.112 npm install to a patched native linux-arm64 binary with an auto-updating wrapper. Also rolls up the Path C (Android Virtualization Framework, AVF) refresh for Android 17 and a Path B walk-through clarification originally drafted under [Unreleased].

The Path A change is empirically motivated. The v2.x install pinned `@anthropic-ai/claude-code@2.1.112` (the last upstream version to ship a JS entry point) and defended that pin with `chmod -R a-w` on the install directory plus `DISABLE_AUTOUPDATER=1` in shell env and `~/.claude/settings.json`. Tracking upstream at [anthropics/claude-code#50270](https://github.com/anthropics/claude-code/issues/50270). The v2.9.0 install runs the same linux-arm64 native binary that PC users run, by patching the binary's ELF interpreter via Termux's `glibc-runner` and `patchelf-glibc`. The approach was originally described by gtbuchanan in [a comment on the upstream issue](https://github.com/anthropics/claude-code/issues/50270#issuecomment-4467292215); this repo's `install.sh` adapts it with empirical verification, an auto-updating wrapper, and the two interactive prompts.

Verified end-to-end on Pixel 10 Pro (Android 17) on 2026-05-28. v2.9.0 retests on Pixel 6, Moto G7 Power, and Galaxy S7 are pending. Path B and Path C are independent of the Path A change and unaffected.

### Path A: new architecture

- `install.sh` rewritten. Two yes/no questions up front (Q1: fresh Termux, choice of `--force-confnew` vs `--force-confold` for the upgrade pass. Q2: install recommended packages, the 17-package kit). After the questions, install runs unattended. End state:
  - Patched linux-arm64 claude binary at `~/.local/share/claude/versions/<version>`
  - Auto-updating wrapper at `$PREFIX/bin/claude`
  - `~/.claude/settings.json` with `autoUpdates:false` and `env.LD_PRELOAD` for subprocess shebang resolution
  - `~/.local/bin/claude` launcher pointing at the wrapper, and `~/.local/bin` appended to PATH in `~/.bashrc`. This is the native-install layout Claude Code expects; providing it silences the binary's "Native installation ... not in your PATH" startup notices at the source, rather than matching their text.
- Wrapper behavior on each launch: query npm registry once per 24h for the latest version (or immediately with `claude --update-now`), if newer download + verify checksum + patchelf + atomic swap into versions/, keep the previous version for rollback and remove older ones (N-1 retention). Self-heal the binary's ELF interpreter if anything outside the wrapper replaced it. Unset `LD_PRELOAD` before exec so the glibc binary doesn't crash on libtermux-exec's unversioned `libc.so` dependency.
- All-failure-modes (network, checksum mismatch, patchelf error): wrapper prints a one-line warning to stderr and falls through to launch the cached binary. The user's session never breaks because of an update problem.

### Migration from a pinned v2.x install

- `migrate.sh` added: upgrades an existing pinned install (the npm `@anthropic-ai/claude-code` package) to the v2.9.0 architecture without data loss. It backs up `~/.claude`, `~/.claude.json`, and `~/.bashrc` (with a generated `restore.sh`) before any change. It downloads, checksum-verifies, and patches the new binary before removing the old pin, so a mid-run failure leaves the old install intact. It installs the wrapper and merges `~/.claude/settings.json` in place, preserving existing keys and following a symlinked settings file rather than replacing it. It refuses to run while a `claude` session is active.
- `install.sh` is now existing-install aware: it detects a pinned v2.x install and routes the user to `migrate.sh` rather than overwriting it, and detects an already-installed v2.9.0 wrapper and exits without changes.

### Removed (Path A architectural)

- `@anthropic-ai/claude-code@2.1.112` npm pin: replaced by the native binary path described above.
- `chmod -R a-w` lock on the install directory: no longer needed. The wrapper is the only mutator of the binary directory and the binary path is under `~/.local/share/` rather than `$PREFIX/lib/node_modules/`.
- `DISABLE_AUTOUPDATER=1` in `~/.bashrc`: the wrapper handles updates instead.
- The April 18 upstream-regression recovery procedure: no longer applicable (the v2.9.0 install runs the linux-arm64 binary directly; there is no pin to clobber).
- The Path A `pkg install ripgrep` + `CLAUDE_CODE_USE_NATIVE_FILE_SEARCH=1` workaround: the linux-arm64 binary reports `process.platform === 'linux'` and ships `vendor/ripgrep/arm64-linux/rg`, so the Grep / Glob tools work out of the box. `scripts/fix-ripgrep.sh` is vestigial under the new architecture and is no longer referenced from user-facing docs.

### Changed

- `README.md` Path A section rewritten around `install.sh` + `claude`. Path A footprint figures stated honestly: the linux-arm64 binary download is ~233 MB and the recommended packages add ~200 MB, so the base install is ~280 MB and a full install with the recommended kit is ~480 MB. Version badge bumped to 2.9.0. Last Verified bumped to 2026-05-29. Device Compatibility table calls out which rows are v2.9.0-verified and which are pending v2.9.0 retest.
- `docs/install.md` Path A walkthrough rewritten. Path B and Path C sections retained largely as-is; the Path B verification footer remains 2026-05-16.
- `docs/troubleshooting.md`: April 18 regression entries removed; OAuth entries retained; the Grep/Glob ENOENT entry updated to note that the v2.9.0 install does not exhibit the original bug.
- `VERSION`: 2.8.1 -> 2.9.0.

### Rolled up from [Unreleased] (pre-v2.9.0 work)

- `README.md` Path B Ubuntu setup walkthrough fleshed out: the `proot-distro login ubuntu` step is now followed by a note that the download can take a few minutes, the `root@localhost.` prompt that signals completion, and the inside-Ubuntu install steps laid out as a separate block.
- `README.md` Path C now ships an inline Quick Install matching the shape of Path A and Path B: how to check for support, where to toggle Linux development environment, what to expect in the Terminal app, and the install line for Claude Code inside the VM.
- `docs/avf-guide.md` substantially rewritten for Android 17 reality. Memory size, Display resolution, and Keep awake are now documented as Terminal app Settings (gear icon) under Advanced, rather than file edits. The Recovery section (Reset to initial version, Remove backup data) is documented for the first time. Graphics Acceleration is described as a Pixel 10 Pro toggle, not a universal default. AOSP architecture reference linked.
- `docs/avf-guide.md` Screen-Off Stability section rewritten around Settings > Advanced > Keep awake (preset timer up to one day) instead of the older ADB whitelist commands.
- `docs/avf-guide.md` Security Defaults table now reflects that SSH is installed but not started by default; the exim4 row is gone since exim4 is not running by default either.
- `docs/avf-guide.md` Known Issues, Comparison, and Technical Details sections updated to match the above.
- `docs/troubleshooting.md` Path C section synchronized with the avf-guide rewrite.
- `docs/install.md` Path C entry under "Devices verified" extended to cover Pixel 6 and Pixel 10 Pro on Android 17.
- `README.md` "Device Compatibility" footnote now records Path C re-verification on Pixel 6 and Pixel 10 Pro running Android 17 on 2026-05-26.
- TMPDIR / proot-as-Claude-requirement obsolete instructions removed across `docs/install.md`, `docs/troubleshooting.md`, `scripts/check-termux-env.sh`, `.claude/skills/termux-safe/SKILL.md`, `docs/constitution-template.md`, `docs/skills.md`, `.github/ISSUE_TEMPLATE/bug_report.md`, and `tests/verify-claims.sh`. Empirical verdicts on individual claims in `tests/results/*.txt` are unchanged from the 2026-05-16 test run; only the claim index shifted.
- `README.md` Prerequisites moved above Quick Install. "Before You Start" section names the three things a first-time reader has to do before any command can succeed: confirm aarch64 / Android 8+, hold a Claude account, install Termux from F-Droid. Delegates F-Droid and Termux install steps to upstream maintainers rather than reinventing them.
- `README.md` device compatibility table: a "Test artifact" column was added so each row's claim of "verified" can be checked against an on-disk file. The four devices with `tests/results/*.txt` artifacts link to their result file. Samsung Galaxy S26 Ultra and Galaxy S23+ are marked doc-only (no current `tests/results/` file): the S23+ row dates to the 2026-03-19 cycle that pre-dates the current `verify-claims.sh` artifact regime, and the S26 Ultra's v2.9.0 verification was a manual `migrate.sh` run on 2026-05-29, which produces no `verify-claims.sh` transcript.
- `docs/troubleshooting.md` EMFILE entry: "measured 32,768 on Android 16 / kernel 6.12" reattributed to the actual measurements in `tests/results/` (Pixel 10 Pro Android 17 and Pixel 6 Android 13).
- `docs/install.md` Prerequisites and Environment Reference: the "Android 14/15 use 5.10-6.6, Android 16 uses 6.12" kernel mapping replaced with the empirical per-Android-version kernel observations from the four test-artifact devices in this repo.

### Notes

- Tests directory `tests/results/*.txt` artifacts are from the v2.x pinned install. v2.9.0 retest transcripts will be added per device as they are produced. The Pixel 10 Pro v2.9.0 install was verified on 2026-05-28 manually; a deterministic `verify-claims.sh` transcript for the v2.9.0 architecture is a follow-up item.
- `scripts/fix-ripgrep.sh` is left in the repo for users on a v2.x install who still need it. It is no longer referenced from user-facing docs and is not exercised by the v2.9.0 install path.
- `scripts/check-termux-env.sh` updated to auto-detect v2.9.0 vs v2.x install layouts via filesystem signals (presence of `~/.local/share/claude/versions/` plus a non-symlink wrapper at `$PREFIX/bin/claude` indicates v2.9.0; presence of `$PREFIX/lib/node_modules/@anthropic-ai/claude-code/` indicates v2.x). Replaces the previous grep-based detection that searched the wrapper for a marker string the install.sh wrapper never writes.
- AOSP source for the Terminal app's memory default (`ConfigJson.kt`, `memory_mib: Int = 1024`) is cited in the avf-guide. The Pixel 10 Pro on this hardware ships an OEM overlay that adds the Graphics Acceleration toggle but does not change the memory default.

## [2.8.1] - 2026-05-17

Hotfix. The v2.8.0 install was empirically broken: the `chmod -R a-w` lock on the install dir is necessary but not sufficient. Within minutes of starting a real claude session on a fresh v2.8.0 install (verified on Pixel 6 / Android 13), the in-process auto-updater chmod'd the dir writable and clobbered the 2.1.112 pin with 2.1.143 -- the broken android-arm64 version. claude then exited with `Error: claude native binary not installed`.

The v2.7.0 install kept two additional layers that v2.8.0 incorrectly removed as "belt-and-braces": `DISABLE_AUTOUPDATER=1` in `~/.bashrc` (every shell that launches claude inherits the env) and merged into `~/.claude/settings.json` (inside a running claude session this is what stops the in-process updater from firing). Empirically those layers were load-bearing. v2.8.1 restores them. The chmod still matters as a final defense, but every layer is needed.

### Fixed
- `install.sh` writes `export DISABLE_AUTOUPDATER=1` to `~/.bashrc` (idempotent: only if not already present; creates the file if missing)
- `install.sh` merges `"env": {"DISABLE_AUTOUPDATER": "1"}` into `~/.claude/settings.json` using Node (preserves all existing keys including hooks; no jq dependency needed since Node is already installed)
- v2.8.0 CHANGELOG framing on which layers were load-bearing was empirically wrong. v2.8.0 entry left as-is per CHANGELOG-history convention; this entry corrects the framing.

### Added
- `docs/install.md` "Recommended Common Packages" section: one-liner `pkg install` for the 17 packages Claude Code typically reaches for that vanilla Termux + `install.sh` does not provide (`git`, `gh`, `jq`, `python`, `openssh`, `tree`, `proot`, `termux-api`, `proot-distro`, `make`, `clang`, `file`, `xxd`, `htop`, `bat`, `fzf`, `wget`). What's already in vanilla Termux is listed too (`rg`, `curl`, `unzip`, `tar`, `gzip`, `less`, `nano`) so the user knows which holes are real.
- README callout after Path A pointing users to the common-packages section -- a "vanilla Claude Code in an environment it is not used to" warning that also recommends injecting the list into `CLAUDE.md` or an environment hook to prevent recurring tool failures.
- `docs/faq.md` "Which packages should I install after `install.sh`?" entry pointing to the install.md section.
- `docs/troubleshooting.md` "Claude can't find a tool (jq / git / python / ...)" entry covering the symptom-shaped path to the install.md section.

### Notes
- A backup tag `backup/pre-v2.8.1` was created on `main` before this release for rollback
- The bare-minimum `pkg install` principle still holds: `install.sh` still only installs `nodejs`. The added layers are file edits in `$HOME`, not new system packages.

## [2.8.0] - 2026-05-16

Audit-driven cleanup release. Documentation tightened to match empirical device behavior. Test suite rewritten to produce deterministic PASS/FAIL/SKIP verdicts; verified end to end on four lab devices spanning Android 8, 10, 13, and 17 Beta. FAQ added for decision-shaped questions; troubleshooting refined for symptom-shaped entries with cross-links between the two. The Path A pin to 2.1.112 against upstream regression [#50270](https://github.com/anthropics/claude-code/issues/50270) remains in effect. Path B continues to install upstream-latest claude inside proot-Ubuntu cleanly.

This change is a major shift to `install.sh` and the user-facing instructions around it. The goal is to bring the install down to the bare minimum needed for Claude Code to run successfully without persistent error inside Termux. It does not install packages or dependencies a standard Claude Code user would use -- common ones like `git`, GitHub CLI (`gh`), `curl`, `ripgrep`, `termux-api`, and `jq` are NOT installed. Install whatever you need yourself with `pkg install <name>`. After running `install.sh`, you type `claude` -- the same command you would on a PC. If you have an error with this update, please [open an issue](https://github.com/ferrumclaudepilgrim/claude-code-android/issues/new?template=bug_report.md) immediately. The previous v2.7.0 `install.sh` is preserved at [v2.7.0/install.sh](https://github.com/ferrumclaudepilgrim/claude-code-android/blob/v2.7.0/install.sh) for comparison.

### Added
- `docs/faq.md` covering install gotchas (Play Protect on Termux APK install, mirror selection, the `Y/I/N/O/D/Z` dpkg prompt), path-choice decisions, and the Android-version OAuth auto-open cutoff (verified on Android 8 / 10 / 13 / 17 Beta)
- `scripts/` directory with three deterministic bash diagnostics: `check-termux-env.sh` (full environment probe, 13 checks), `fix-ripgrep.sh` (recovery for the missing arm64-android ripgrep binary), `config-validator.sh` (audit a `.claude/` directory)
- `.gitattributes` pinning `*.md`, `*.txt`, `*.yml`, `*.yaml`, `*.json`, `LICENSE` to LF; image assets explicitly marked binary
- `tests/results/` device files written by the new `verify-claims.sh` on Pixel 10 Pro (Android 17 Beta), Pixel 6 (Android 13), Moto G7 Power (Android 10), Galaxy S7 (Android 8)
- `release-check.sh` at repo root: mechanical pre-release sanity checks (VERSION / CHANGELOG / README / SECURITY consistency, backup-tag presence, em-dash absence, current-tag absence). Exit 0 on PASS, non-zero on FAIL. Run before every release push

### Changed
- `tests/verify-claims.sh` rewritten: 13 deterministic claims, each returning PASS, FAIL, or SKIP only. Methodology corrected for `/tmp` writability tests, proot bind-mount roundtrip, and doc-existence checks. Output format intended for end-user contribution
- `README.md` restructured for scannability: Quick Install moved to the top of the page; verbose sections relocated to `docs/`; April-18 recovery banner kept above the fold with a deep link
- `docs/install.md` -- Path C added as a third column in the path-comparison table; April-18 recovery procedure consolidated here; OAuth section captures the empirical Android-version auto-open cutoff; Step 1 distinguishes MVP-required packages from the recommended general kit
- `docs/skills.md` -- reflects current set: one Android-specific skill (`termux-safe`) and two workflow skills (`minimum-viable`, `scope-framing`); deterministic checks now live under `scripts/`
- `docs/troubleshooting.md` -- Hooks-section anchor corrected in the table of contents; OAuth entry gains the Android-version auto-open cutoff and a cross-link to the FAQ
- `docs/faq.md` Path B size and native-binary detail (no Node required) clarified
- `docs/avf-guide.md` Android 17 Beta status note refreshed
- `docs/adb-wireless.md` gains a decision table for "When to use ADB vs Termux:API"
- `docs/fingerprint-gate.md` adds a callout on case-pattern bypass vectors and safer-shape alternatives for biometric gate scripts
- `install.sh` header documents scope and package set
- `.github/CONTRIBUTING.md` example-skill reference updated to point at a current skill
- `assets/logo.jpg` replaced with `assets/logo.png` (transparent PNG)

### Fixed
- `tests/verify-claims.sh` no longer returns `CANNOT TEST` for claims that the test methodology was failing to exercise; the rewrite uses appropriate proot-wrapped subshells and repo-rooted doc-path checks
- README maintenance row in the path-comparison table no longer references the obsolete ripgrep symlink re-fix step; the env var `CLAUDE_CODE_USE_NATIVE_FILE_SEARCH=1` (which users can set in their own `~/.bashrc`) makes the symlink unnecessary anyway
- README docs-table skill-count drift removed

### Removed

- `install.sh` no longer installs `git`, `curl`, `proot`, `ripgrep`, `termux-api`, or `jq`; only `nodejs` is installed. Users who want those packages can `pkg install` them directly. The full kit is recommended in `docs/install.md` Step 1 for general use.
- `install.sh` no longer writes a `claude-android` alias, no longer exports `TMPDIR` / `CLAUDE_CODE_USE_NATIVE_FILE_SEARCH` / `DISABLE_AUTOUPDATER` to `~/.bashrc`, no longer creates the ripgrep symlink, and no longer merges `~/.claude/settings.json`. The load-bearing protection is the `chmod -R a-w` on the install directory; the rest were belt-and-braces in earlier versions.
- The `claude-android` alias is no longer the documented launch command. Users run bare `claude` (empirically verified across Android 8 / 10 / 13 / 17 Beta on 2026-05-16). If you used the alias in a prior version, remove it from `~/.bashrc` to avoid drift.

### Notes
- A backup tag `backup/pre-v2.8.0` was created on `main` before this release for rollback
- Disk-usage numbers in path-comparison tables are approximate ranges, not freshly measured; a follow-up release may refresh them with on-device `du -sh` data
- Upstream Termux issues referenced in docs (proot-distro #567, termux-packages #29319) are not re-verified in this release

## [2.7.0] - 2026-04-18

Emergency release pinning Path A (native Termux) install to `@anthropic-ai/claude-code@2.1.112`, the last upstream version that ships the bundled `cli.js` JavaScript entry point. Versions 2.1.113 and later switched to a platform-native binary distribution that excludes android-arm64; on native Termux those versions install but `claude` exits immediately with `Error: claude native binary not installed`. Tracked upstream at [anthropics/claude-code#50270](https://github.com/anthropics/claude-code/issues/50270). The in-process auto-updater also re-fetches `latest` on a timer **inside running sessions**, so the pin must be defended with `DISABLE_AUTOUPDATER=1` plus a load-bearing `chmod -R a-w` on the install directory. Path B (proot-distro Ubuntu) is unaffected: `process.platform === 'linux'` matches the published `linux-arm64` native binary. Path C (AVF) is unaffected for the same reason.

If you installed using v2.6.0 or earlier and your `claude` is now broken, re-run the new `install.sh` or follow the recovery steps in the README and `docs/troubleshooting.md`.

### Fixed
- **Path A install no longer ships a working CLI without intervention**: upstream `@anthropic-ai/claude-code` 2.1.113 (April 17–18) and 2.1.114 dropped the bundled `cli.js` entry and switched `bin/claude.exe` to a platform-native binary stub. The android-arm64 native binary is not in the published optional-dependencies list. Postinstall on native Termux finds no matching platform package, leaves the 500-byte error stub in place, and every `claude` invocation prints `Error: claude native binary not installed`. v2.6.0 of this guide shipped `npm install -g @anthropic-ai/claude-code` with no version pin, so anyone running it after April 17–18 hit the broken state. v2.7.0 pins to `2.1.112`.
- **Auto-updater clobbers manual downgrade**: Claude Code's in-process updater re-fetches `latest` on a timer inside running sessions. A user who manually downgrades to 2.1.112 sees the pin silently re-overwritten with 2.1.114 within minutes. Fix: `DISABLE_AUTOUPDATER=1` in shell env and `~/.claude/settings.json`, plus `chmod -R a-w` on the install dir. The `chmod` is the load-bearing one. The env reduces but does not stop the attempt.
- **`cli-wrapper.cjs` references in install.sh, README, and `docs/install.md` are now incorrect for 2.1.113+ and were used by v2.6.0**: the wrapper in 2.1.113+ is a strict platform dispatcher with `process.exit(1)` on unsupported platforms (including android), not a JS fallback. v2.7.0 removes those references and uses the bundled `cli.js` entry exposed by the `claude` symlink in 2.1.112.

### Changed
- **`install.sh` rewritten**: pins `CC_PIN="2.1.112"`, installs with `DISABLE_AUTOUPDATER=1` in env, applies `chmod -R a-w` on `$PREFIX/lib/node_modules/@anthropic-ai/claude-code/` after install, adds `DISABLE_AUTOUPDATER=1` to `~/.bashrc`, merges `env.DISABLE_AUTOUPDATER` into `~/.claude/settings.json` via jq (preserving any existing config). Detects existing installs and recovers idempotently: chmod +w → reinstall pin → chmod -R a-w. Re-running the script is the supported recovery path.
- **`docs/install.md`**: Step 3 documents the version pin, the auto-updater env, the chmod, and links to upstream `#50270`. Step 4 launches via `proot -b $PREFIX/tmp:/tmp claude` (the bundled cli.js entry exposed by the `claude` symlink in 2.1.112), not through `cli-wrapper.cjs`. Step 5 alias updated. "Updating Claude Code" section explains the chmod dance required to upgrade past the pin. "Uninstalling" section adds the chmod -R u+w prerequisite.
- **README**: Path A code blocks updated to the pinned form. Footer version bumped to 2.7.0. Version badge bumped to 2.7.0.
- **Step 1 dependencies**: added `jq` to the `pkg install` line in install.sh and `docs/install.md` (used for safely merging `~/.claude/settings.json` without clobbering existing config).

### Added
- **README top-of-page warning banner** linking to recovery instructions for visitors who hit the regression.
- **README "April 18 upstream regression: Path A recovery" section** under Path A: explains the upstream change, the auto-updater clobber behavior, the recovery steps, and the upgrade path forward.
- **`docs/troubleshooting.md` entry "Claude Code exits: 'native binary not installed'"**: full diagnostic, both Path A (pin) and Path B (proot-ubuntu) fixes, and the upgrade-later path.
- **CHANGELOG note** that Path A is now in a maintenance-only state on the upstream side. The strategic move toward Path B (proot-distro Ubuntu) as the primary recommended path is planned for a future release.

### Notes
- Path B (proot-distro Ubuntu) and Path C (AVF) are unaffected by the upstream regression. Both run `process.platform === 'linux'` which matches the published `linux-arm64` native binary; `npm install -g @anthropic-ai/claude-code` (no pin) works normally inside the Ubuntu guest.
- The pinned 2.1.112 install was verified end-to-end on Samsung Galaxy S26 Ultra (Android 16, kernel 6.12, Node v25.8.2) on 2026-04-18: install + chmod + auto-updater protection + `claude --version` returns `2.1.112 (Claude Code)`.
- A backup tag `backup/pre-v2.7.0` was created on `main` before this release for rollback.
- This guide does not redistribute Anthropic's claude-code package or vendor any binary content; pinning a published npm version and locking permissions on the install directory uses normal npm and POSIX mechanisms.

## [2.6.0] - 2026-04-18

Documentation refresh plus security hardening. Corrects stale claims, migrates docs URLs following Anthropic's domain move, updates Path A install instructions for upstream npm package restructure, corrects the hooks-on-Termux section to reflect current behavior, adds an audio-backend section covering `/voice` mode on vendor-broken devices, and adds an Android 17 Beta status note to the AVF guide. Rewrites `examples/ssrf-guard.sh` to close real bypasses in the previous regex-based implementation, adds a 47-case test harness, and adds `.gitattributes` so shell scripts stay LF on Windows checkouts (CRLF breaks them on Termux).

### Fixed
- OWASP LLM Top 10 citation in `docs/agent-permissions.md` (Excessive Agency is LLM08, not LLM06)
- Anthropic pricing URL in README migrated from `anthropic.com/pricing` to `claude.com/pricing`
- Uncited "approximately 1-2%" prompt injection rate removed from `docs/security-model.md`; replaced with "non-zero risk" framing
- `dd` benchmark in `docs/avf-guide.md` qualified to note that the read figure includes page cache and overstates real disk throughput
- Claude Code version reference refreshed in `.claude/skills/doctor/SKILL.md` example output
- Hooks-on-Termux section in `docs/troubleshooting.md` corrected. Earlier wording stated PreToolUse/PostToolUse hooks did not fire on `process.platform === "android"`; that is no longer accurate. Replaced with concrete debugging steps. Reference to upstream issue #16615 retained as historical context.
- **`examples/ssrf-guard.sh` rewritten to close real bypasses.** The previous regex-based IPv4 check required four dotted octets, so short-form IPs (`http://127.1/`) and mixed-format IPs (decimal `2130706433`, hex `0x7f000001`) passed through to loopback. A prompt-injected WebFetch call using any of those forms would reach internal services. The rewrite offloads URL parsing to Node's `new URL()` (the same RFC 3986 normalization Claude Code's WebFetch uses internally), then applies private-range checks on the normalized hostname. Covers short-form IPv4, decimal, hex, IPv4-mapped IPv6, cloud metadata aliases, case-sensitive hostnames, and malformed URLs. WebSearch bare queries (no `://`) now pass through instead of being blocked as missing-scheme. DNS-rebinding limitation remains and is documented in the header.
- Subscription tier list in README and `docs/install.md` expanded from "Pro or Max" to match upstream's documented list (Pro, Max, Team, Enterprise, or Console/API account).
- `docs/install.md` softened "preferred installation method" to "recommended installation method" to match upstream wording exactly.

### Changed
- All Anthropic Claude Code docs URLs migrated from `docs.anthropic.com/en/docs/claude-code/*` to `code.claude.com/docs/en/*` (Anthropic moved the docs domain). Affects README.md, `.github/CONTRIBUTING.md`, `docs/agent-permissions.md`, `docs/skills.md`.
- Path A install method updated to route Claude Code through the `cli-wrapper.cjs` JavaScript fallback. Anthropic restructured the `@anthropic-ai/claude-code` npm package so the CLI is delivered via platform-specific optional native binaries; android-arm64 is not in that distribution list. The install completes but bare `claude` errors with "claude native binary not installed." The same package ships `cli-wrapper.cjs`, a JavaScript fallback launcher; invoking it through Node works on android-arm64. The existing proot tmp wrapper is retained. Affects README, `install.sh`, `docs/install.md`.
- README intro updated from "two ways" to "three ways" to reflect Path C/AVF documentation already present.
- Footer dates refreshed on `docs/install.md`, `docs/security-model.md`, `docs/avf-guide.md`.
- README "Last Verified" badge updated to `2026-04-18`; Version badge updated to `2.6.0`.

### Added
- New README section "Audio: /voice mode and the chain underneath" documenting the SoX → PulseAudio → backend → mic chain. Identifies vendor-device failures at the SLES backend layer (termux/termux-packages#28861, termux/termux-packages#27978, termux/termux-packages#27367, termux/termux-packages#26871) and points to termux/termux-packages#29319 (Oboe package + PulseAudio Oboe modules) as the fix path. Includes the user opt-in steps for after the PR lands. Caveat noted that Claude Code's own SoX detection on Termux is a separate concern.
- Android 17 Beta status note at the top of `docs/avf-guide.md`. Existing Android 16 content retained as baseline reference; A17 Beta not re-verified end-to-end in this cycle.
- `tests/ssrf-guard-tests.sh`: 47-case test harness for the SSRF guard. Feeds JSON PreToolUse payloads covering short-form IPs, private ranges, cloud metadata, IPv6 forms, bad schemes, WebSearch queries, and edge cases. Used to prove the previous guard had real bypasses and that the rewrite closes them.
- `.gitattributes` pinning `*.sh` to LF line endings. Windows checkouts would otherwise get CRLF, which breaks the scripts when they land on Termux (bash errors on `$'\r'` at end of lines).

### Notes
- Path A cli-wrapper.cjs workaround verified on a current Termux install where Claude Code is actively running through it.
- Path B (proot-distro Ubuntu + official curl|bash installer) documentation not freshly re-verified end-to-end in this update; matches Anthropic's current upstream guidance for linux-arm64.
- Per-device verification dates in the README compatibility table left unchanged; individual devices not re-tested in this cycle.
- SSRF guard rewrite tested on-device with 47 test cases; all pass. Previous implementation failed 7. Test harness at `tests/ssrf-guard-tests.sh` verifies this.

## [2.5.1] - 2026-04-03

### Added
- **Security model document** (`docs/security-model.md`) -- centralized threat model covering Termux:API permission exposure, ADB capability escalation, the critical difference between app-level and shell-level access, threat scenarios in plain language, existing mitigations, and a minimal-risk setup checklist
- **README security notice** -- visible before Prerequisites, links to security model
- **Termux:API permission scoping guidance** in install guide -- only grant the permissions your workflow requires
- **Download-then-inspect alternative** in install guide Path B -- inspect the install script before running it
- **shellcheck CI workflow** -- runs on push and PR for install.sh and verify-claims.sh
- **Markdown link checker CI workflow** -- checks for broken links across all documentation
- **Executable hook examples** -- `examples/ssrf-guard.sh` and `examples/fingerprint-gate.sh` adapted from documentation into standalone runnable files

### Changed
- **ADB capabilities table** -- added risk/exposure column so capabilities include security context
- **SSRF guard and fingerprint gate docs** -- reference examples/ files as canonical script location
- **Skills documentation** -- Android-specific and general-purpose workflow skills separated with descriptive intros
- **README navigation bar** -- added Security Model link
- **Version badge** updated to 2.5.1

### Security
- Security audit found users could complete installation and grant full device access (SMS, contacts, GPS, camera, screen capture, input injection) without encountering a security warning. This release adds the security model, README warning, permission scoping guidance, and risk context to the ADB capabilities table.


## [2.5.0] - 2026-04-02

### Added
- **Path C -- AVF (Android Virtualization Framework)** documented as experimental third installation path. Claude Code installed and used for real work inside an AVF VM on a Pixel 10 Pro (Android 16). Full setup checklist, VM configuration, ADB hardware bridge, security defaults, and three-path comparison included. See `docs/avf-guide.md`.
- VM configuration section documenting writable `vm_config.json` with configurable RAM (`memory_mib`), memory balloon control (`auto_memory_balloon`), and boot timeout
- ADB wireless debugging from inside the VM documented with pairing workflow, port scanning, split-screen pairing tip, and screen-off stability commands (semi-fix)
- ADB hardware bridge section: 42 sensors enumerable, GPS coordinates accessible, camera launchable with viewfinder capture, screenshots and screen recording, input injection (tap/swipe/text), battery state, WiFi info, plus command reference
- Security defaults section covering default passwords, SSH config, firewall state, shared storage SSH key exposure, and hardening suggestions
- Technical details appendix: virtual hardware inventory (15 virtio devices), kernel config findings (CONFIG_SYSVIPC disabled, BPF/FUSE/OverlayFS enabled), running services (7 AVF-specific), crosvm launch parameters
- AVF section added to README Quick Start with inline setup commands, key capabilities, and limitations summary
- Three-path comparison table in README (Path A / Path B / Path C) replacing the two-path table, including RAM, ADB hardware bridge, and audio columns
- Path C column added to device compatibility table
- Community resources section in AVF guide: 10 curated links covering memory fixes, GPU status, setup guides, bug filing, and Snapdragon alternatives
- Navigation bar updated with AVF guide link

### Changed
- Troubleshooting "Paths We're Watching" section upgraded from "Not Recommended Yet" to "Experimental, Tested on Pixel" with verified capabilities, known issues, and security notes
- Known issues table expanded with: `apt upgrade` hang on TUI dialogs, SysV IPC disabled, nftables non-functional, Terminal Activity recreation, VM IP rotation, GPU acceleration limited to Pixel 10
- Version badge updated to 2.5.0
- Last verified badge updated to April 2026
- Device compatibility table expanded with Path C column

### Community
- AVF testing performed on a single Pixel 10 Pro. All findings framed as observations from our test device, not universal claims. Google's AVF documentation remains extremely limited -- most capabilities and limitations were discovered empirically. Screen-off stability improved with ADB hardening but remains a semi-fix. Copy-paste reliability in the Terminal app remains the largest UX friction point.

## [2.4.0] - 2026-03-28

### Added
- Termux:API elevated to required dependency with source-matching warning (F-Droid+F-Droid or GitHub+GitHub)
- Fingerprint biometric gate documentation for securing sensitive operations
- Vendor-specific Samsung sensor types documented (elevator detector, back tap, car crash detect, pocket mode, drop classifier)
- install.sh: architecture check (aarch64 required), pkg update before install, termux-api package
- CLAUDE_CODE_USE_NATIVE_FILE_SEARCH=1 documented as durable ripgrep fix (survives updates)
- "From the developer" tip at top of README
- Third device screenshot (Samsung Galaxy S23+)
- Session persistence note (crond, Termux:Boot, shell scripts)
- Cron proot wrapper note for Path A users
- 8 new test claims in verify-claims.sh (cron, sensors, SSRF, agent permissions, Termux:API, xdg-open, fingerprint, architecture)
- Supported versions table in SECURITY.md
- verify-claims.sh reference in CONTRIBUTING.md
- Issue template chooser (config.yml disables blank issues)
- docs/skills.md created (workflow skills moved from README)

### Changed
- ADB capability table: process inspection corrected from "Blocked" to "Termux processes only"
- MCP section: corrected xdg-open claim (exists as symlink to termux-open; OAuth localhost redirects still fail)
- Time estimates qualified with "(experienced)" across all installation paths
- "Why This Is Hard" section condensed from 4 subsections to 5 bullet points
- Path B "Most users should start here" callout added
- Security warning moved from README top to ADB section (contextually appropriate)
- Agent roster replaced with summary + link to docs/agents.md
- Workflow skills moved to docs/skills.md, README keeps Android skills only
- "Our Story" link removed from top navigation bar
- Known Constraints "No systemd" row expanded with crond, Termux:Boot, termux-job-scheduler
- /doctor skill disambiguated from built-in `claude doctor` command
- termux-safe skill: "No apt" corrected to "Prefer pkg over apt"
- README reduced from 416 to ~382 lines

### Fixed
- install.sh: missing pkg update before package install
- Calendar query example in ADB docs (projection delimiter, shell escaping)
- Screenshot file extension mismatch (pixel10pro was PNG with .jpg extension)
- verify-claims.sh FD limit test no longer hardcodes ~1024
- PR #31701 status updated to "Closed (not merged)" in upstream issues table
- Troubleshooting count updated from "17+" to "20+"

### Community
- AAudio source module PR (termux-packages#29074) -- adds module-aaudio-source.c to PulseAudio, enabling microphone input via AAudio on Android 12+ where OpenSL ES input was removed. Approved by robertkirkman, hardware-tested on 32-bit ARM Android 8 and 64-bit ARM Android 13. Awaiting maintainer merge.
- CUPS fix PR (termux-packages#29123) -- fixes three bugs making CUPS nonfunctional on fresh Termux installs: (1) web UI returns 403 on static assets because package builder strips world-read permissions, (2) Add Printer crashes cupsd due to missing spool directory, (3) policy engine denies admin operations because SystemGroup directive was removed. Approved by TomJo2000. Awaiting maintainer merge.

## [2.3.0] - 2026-03-25

### Added

- **Cron session safety flags** -- headless `claude -p` sessions can now be locked to local-only tools using `--tools` and `--disallowedTools`. Blocks web access and network commands entirely, making scheduled autonomous sessions safe by default.
- **Custom agent loading fix documented** -- custom agents fail to load due to the same ENOENT root cause as ripgrep. Permanent fix: set `CLAUDE_CODE_USE_NATIVE_FILE_SEARCH=1` in your shell profile. Also added to the existing ENOENT entry as an alternative to the symlink.
- **Sensor API documentation** -- 9 of 11 standard Android sensor types confirmed working via NDK ASensorManager from Termux (compiled C binary, not the `termux-sensor` Java API). Accelerometer, gyroscope, magnetometer, barometer, and 5 others respond correctly. Light and proximity vary by device.
- **PulseAudio AAudio source module status** -- [PR #29074](https://github.com/termux/termux-packages/pull/29074) submitted to termux-packages for Android 16 microphone input. Replaces the broken `module-sles-source` with an AAudio-based module. Validated on all 4 architectures (aarch64, arm, i686, x86_64). Voice output via `termux-tts-speak` is unaffected.
- **SSRF guard hook** -- new `docs/ssrf-guard.md` documents a PreToolUse hook that blocks WebFetch requests to private IP ranges (127.x, 10.x, 192.168.x, etc.) and all non-HTTP/HTTPS schemes (`content://`, `file://`, `ftp://`, etc. are blocked implicitly). Prevents server-side request forgery from MCP servers or tools.
- **Agent permission matrix** -- new `docs/agent-permissions.md` documents the principle that no single agent should hold both web access and file-write permissions simultaneously (OWASP LLM06). Includes a generic permission matrix and implementation guidance.
- **Constitution template refreshed** -- three new constraints added: cron sandboxing, Termux API availability, and ADB self-connect. Native Termux documented as a viable primary environment alongside proot-distro Ubuntu.

### Changed

- **Node v25 hang resolution** -- removed hedging ("appears related to TMPDIR write permissions") from README, install.md, and troubleshooting.md. The v24 hang was specific to v24, not Termux generally. v25 resolves it.
- **Path A upgraded** -- reclassified from "Lightweight Alternative" to "Fully Viable with Node v25+." Path B (proot-distro Ubuntu) remains recommended for maximum compatibility, but Path A is no longer second-class.
- **Constitution template modernized** -- native Termux presented as a viable primary option (not just proot), `CLAUDE_CODE_TMPDIR` documented as `/tmp` alternative.
- **agents.md and story.md** -- updated runtime references to acknowledge both native Termux and proot-distro Ubuntu.

### Fixed

- **Claude Code version reference** -- removed pinned version `2.1.79` from verified config table in install.md. The native installer always fetches current; pinning a stale version is misleading.
- **Capability table row count** -- "bottom 13 rows" corrected to 12 and "top 8" corrected to 9 in adb-wireless.md (was a miscount, not a duplicate row).
- **ADB version label** -- clarified that ADB 35.x reports as version `1.0.41` in actual output.
- **Mermaid flowchart rendering** -- fixed node labels with slashes being parsed as shape syntax, which caused the decision flowchart to fail on GitHub.
- **agents.md link** -- corrected broken link.
- **EXIF metadata stripped** -- removed EXIF metadata from screenshot images.

---

## [2.2.0] - 2026-03-22

### Changed

- **Repo restructured** -- docs moved from root to `docs/` directory (install, troubleshooting, adb-wireless, agents, constitution-template, story). Community files (CONTRIBUTING, CODE_OF_CONDUCT, SECURITY) moved to `.github/`. Root now contains only README, CHANGELOG, LICENSE, VERSION, and install.sh.
- All internal links updated throughout.

### Added

- **Cron-triggered headless sessions** -- `claude -p` runs successfully from crond on Android. Enables scheduled, autonomous Claude Code sessions without a terminal open. Verified with CLAUDE.md loading correctly from the working directory.
- **Session resume** -- `claude --resume <session-id>` restores prior sessions. Session IDs visible in JSON output.
- **/compact autocompaction** -- context compaction works as expected inside running sessions.
- **Structured output** -- `--output-format json` and `stream-json` verified working on Android. Useful for scripting Claude Code into pipelines.
- **MCP server support** -- `claude mcp list` confirmed working on Android. Test device showed 5 remote servers (Cloudflare connected; Google Calendar, Gmail, Canva, Cloudinary require OAuth). Your server list depends on your Claude account integrations.

---


## [2.1.0] - 2026-03-22

### Added

- MCP remote HTTP server support verified on Android -- Cloudflare Workers tested; no local install required, works immediately after `claude mcp add`
- MCP local stdio server support verified on ARM64 -- `npx`-based servers spawn and respond correctly (tested with `@modelcontextprotocol/server-memory`)
- PDF reading support -- requires `pkg install poppler` and a `which` shim; Termux does not ship the `which` binary, which Claude Code uses to detect `pdftoppm`
- Image reading verified working -- PNG and JPG files readable via the Read tool with no additional setup
- Expanded feature test matrix -- verified on this release: MCP (both transports), PDF reading, image reading, plugins (claude-hud), hooks (all 4 types), custom skills, custom agents (6 concurrent on Opus), StatusLine API, git worktrees
- Known issues documented -- `claude doctor` crashes due to Ink raw mode stdin requirement in Termux; `process.platform === "android"` breaks code that expects `"linux"` (workaround: run inside proot-distro Ubuntu)
- Known MCP limitation documented -- OAuth flows fail in Termux terminal (no browser redirect available via `xdg-open`); remote and stdio transports are unaffected

### Fixed

- Node.js version language corrected in 3 files (CONSTITUTION-TEMPLATE.md, termux-safe skill, doctor skill) -- v25+ is confirmed working; v24 hang is historical context, not a current blocker

### Changed

- Version badge updated to 2.1.0

---

## [2.0.1] - 2026-03-21

### Security

- **Scrubbed device UIDs from test results**: `tests/results/s26ultra-android16.txt` contained real Android UID values in directory listings. Replaced with `<uid>` placeholders throughout. UIDs are not secrets but are device-specific identifiers that belong to the device owner, not the public record.
- **Sanitized `verify-claims.sh` to prevent future UID leaks**: The script now strips numeric UIDs from `ls -la` output before writing to results files. Future runs on any device will not capture owner UIDs.

### Fixed

- **Screenshot alt text corrected in README**: Updated alt text on header screenshots to match the actual device shown in each image.
- **Concurrency limit inconsistency**: STORY.md stated the historical limit of 3 (from before stress testing), CONSTITUTION-TEMPLATE.md still advised a limit of 2. Both now reflect the current tested limit of 6, consistent with CLAUDE.md and INSTALL.md.
- **Issue #16615 status in TROUBLESHOOTING.md**: The upstream issues table listed `#16615` (Platform detection: `android` not recognized) as open. Status corrected to `Closed (not planned)`.
- **Stale self-reported path in test results**: `tests/results/s26ultra-android16.txt` contained a "Results written to:" line with a device-specific absolute path. Replaced with a relative path that is valid on any clone.

---

## [2.0.0] - 2026-03-21

### Added

- **ADB wireless self-connect**: Claude Code on Android can now use ADB wireless
  debugging to connect to its own device via `adb pair/connect 127.0.0.1`. This
  unlocks system capabilities that SELinux blocks from Termux directly: `screencap`,
  `settings get/put` (including DND zen_mode), `content query` (calendar, contacts),
  `pm list packages`, `dumpsys`, `input tap/swipe/text`, `am start/force-stop`,
  `ps -A`, and `getprop`. No root required. No third-party automation app required.
  See [ADB-WIRELESS.md](docs/adb-wireless.md) for the full setup guide.

- **Agent concurrency limit raised to 6**: Stress testing with 6 simultaneous
  Claude Opus agents on mid-range Android hardware (8-core Snapdragon, 11 GB RAM)
  produced negligible load: +0.02 load average, -172 MB RAM (down, not up), +4.7°C
  temperature rise. The practical ceiling is API rate limits, not device hardware.
  Users running Claude Code agents can safely run up to 6 concurrently without thermal
  or memory concern on comparable devices. Adjust based on your hardware.

- **`CLAUDE_CODE_TMPDIR` environment variable**: An alternative to the proot bind
  mount workaround for TMPDIR. Setting `export CLAUDE_CODE_TMPDIR=/data/data/com.termux/files/home/tmp`
  (or any writable path) in your shell profile before launching Claude Code resolves
  the write-permission error without requiring proot. Documented in INSTALL.md Path A.

- **Security model documented**: Wireless debugging enabled as a permanent state
  introduces a security surface: any device on the same WiFi network can attempt ADB
  pairing. Mitigations documented: pairing code required for all new connections,
  connection is localhost-only from the Termux side, and wireless debugging can be
  toggled off when not in use. See ADB-WIRELESS.md §Security.

### Changed

- **Path B (proot-distro Ubuntu) is now the recommended path.** The primary Quick
  Start in INSTALL.md now leads with Path B. Path A (native Termux) remains fully
  documented as an alternative for users who prefer minimal setup or cannot run
  proot-distro.

- **`process.platform` behavior clarified**: Inside proot-distro Ubuntu, Claude Code
  sees `process.platform === "linux"`. In native Termux, it sees `"android"`. Many npm
  packages and tools branch on this value. Users experiencing tool failures in native
  Termux may find them resolved inside the Ubuntu guest. This is now documented
  explicitly in INSTALL.md.

- **Node v24 language softened**: The v24 hang is documented as "may hang on launch,
  likely related to TMPDIR write permissions" rather than a hard incompatibility. Users
  who have resolved TMPDIR (via bind mount or `CLAUDE_CODE_TMPDIR`) may find v24 works.
  The recommendation is still v20 LTS or the version Anthropic's installer provides.
  Node v24+ inside proot-distro Ubuntu is not subject to the same TMPDIR constraint and
  has not shown the hang behavior in testing.

### Community

- Thanks to u/Historical-Lie9697 for a detailed challenge to the proot behavior,
  Node v24 hang, and ripgrep bundled binary claims. The challenge prompted the testing
  that produced this release. All three claims were re-evaluated; the proot and ripgrep
  findings were updated, and the Node v24 language was softened accordingly.

---

## [1.2.0] - 2026-03-20

### Features

- **Path B promoted to recommended Quick Start.** README rewritten to lead with proot-distro Ubuntu: no /tmp workaround needed, native installer, cleaner environment. Path A (native Termux) presented as the lightweight alternative with a comparison table showing tradeoffs.
- **All three device screenshots in README.** S26 Ultra, Pixel 10 Pro, and S23+ screenshots displayed with captions identifying each device.
- **Images moved to `assets/` directory.** Consistent naming: `assets/screenshot-s26ultra.jpg`, `assets/screenshot-pixel10pro.jpg`, `assets/screenshot-s23plus.jpg`, `assets/logo.jpg`.
- **Remote Control section added.** Documents Anthropic's official mobile interface (launched Feb 2026) as an alternative to running Claude Code locally, with guidance on when to use each approach.
- **AVF "Paths We're Watching" section.** TROUBLESHOOTING.md now documents Android Virtualization Framework limitations (RAM allocation, NAT networking, crash data loss, Snapdragon not supported) with a contribution hook for experimenters.
- **Per-device test results structure.** `tests/results/<device>.txt` replaces the single `verification-results.txt`. `verify-claims.sh` auto-generates device-specific filenames from `getprop ro.product.model` and `ro.build.version.release`.
- **CONSTITUTION-TEMPLATE routing decision tree.** Seven-step decision tree added to help users determine which agent or tool handles a given task.
- **armhf/32-bit architecture documentation.** Budget Samsung phones (A13 and similar) ship 32-bit Android on 64-bit hardware. Claude Code requires arm64. Added architecture check to Prerequisites and a new TROUBLESHOOTING entry with affected device list and `uname -m` diagnostic.

### Bug Fixes

- **TMPDIR persistence fix in Path A Step 2.** `export TMPDIR=$PREFIX/tmp` now written to `.bashrc` inline during install, not left as a manual step.
- **Subagent EACCES note corrected.** Previous note said proot "may not fix" subagent task directory failures. Verified on device: the proot bind mount resolves EACCES for subagent task directories completely. Documentation corrected.
- **Skills link corrected.** CONTRIBUTING.md linked to `agentskills.io` (the base spec); corrected to `docs.anthropic.com` (Claude Code's own skills documentation).
- **`termux-safe` scope note added.** Skill header now states this skill applies to native Termux only, not proot-distro Ubuntu sessions.
- **Path A launch warning added.** After `npm install -g @anthropic-ai/claude-code`, users who type bare `claude` get a silent failure. Step 4 now marked Required and includes an explicit warning to use the proot launch command, not bare `claude`.
- **`install.sh` shebang fixed.** Changed from hardcoded Termux path to `#!/usr/bin/env bash` for correct behavior when inspected on non-Termux systems.
- **Orphaned Pixel screenshot deleted.** `Pixel-10-Pro-Quick-Install.png` was never referenced in any document and has been removed.
- **AVF RAM claim hedged.** Changed from "hard 4GB cap" to "~4GB default allocation". No hard architectural limit found in AOSP docs; this appears to be a crosvm default, not a ceiling.

### Community Feedback

- **Issue templates updated.** Bug report template now includes install path (A or B), TMPDIR value, and CLAUDE_CODE_TMPDIR value as diagnostic fields. Device report template asks which path(s) were tested.
- Both armhf/32-bit and Path A launch issues were reported by real users within the first hour of going live and addressed same day.

## [1.1.0] - 2026-03-19

### Major UX Overhaul

- Added Prerequisites section with F-Droid/Termux installation walkthrough
- Added "Choose Your Path" decision point at top of INSTALL.md
- Added "What to Do First" orientation section after Quick Start
- Path B rewritten with exact verified sequence (every step tested on fresh devices)
- Device table redesigned with feature columns and "Last Verified" dates
- Three devices verified: Samsung Galaxy S26 Ultra, Google Pixel 10 Pro, Samsung Galaxy S23+
- Added `CLAUDE_CODE_TMPDIR` as documented alternative to proot
- Native installer note clarified (doesn't work in native Termux, works in Path B)

### Bug Fixes

- Fixed kernel prerequisite excluding Android 14/15 users (was 6.12.x, now varies)
- Fixed "Problem 3 is Android 16-specific" (Node v24 hang affects all ARM64)
- Aligned curl across Quick Start, INSTALL.md, and install.sh
- Stripped private repo paths from verification scripts
- Fixed `which` to `command -v` for portability
- Fixed CODE_OF_CONDUCT contact method
- Fixed install.sh shebang for desktop inspection
- Removed stale FD limit claims (~1024 → varies by device)
- Fixed duplicate EMFILE "Cause" paragraph with contradictory numbers

### Verification

- Added `tests/verify-claims.sh`: automated verification of all documentation claims
- Verification results linked from device table and INSTALL.md

## [1.0.0] - 2026-03-19

### First Stable Release

- One-command installer (`install.sh`): installs packages, Claude Code, ripgrep fix, and shell alias in one pass
- Terminal screenshot proving Claude Code runs natively on Samsung Galaxy S26 Ultra

## [0.4.0] - 2026-03-19

### Repo Quality Pass

- Fixed false proot-distro claim in CONSTITUTION-TEMPLATE.md (was shipping wrong info to every user who copied it)
- Added "Keeping It Running" section to INSTALL.md (update, ripgrep re-fix, uninstall)
- Added shields.io badges to README (license, Android version, Node.js version, Claude Code version, last verified date)
- Populated device compatibility table with verified device (Samsung Galaxy S26 Ultra) and common devices as "untested"
- Added `disable-model-invocation: true` to `/fix-ripgrep` skill (prevents auto-invocation of a skill that installs packages)

## [0.3.0] - 2026-03-19

### Documentation Correction: proot-distro Works on Android 16

Previous documentation incorrectly stated that proot-distro was broken on Android 16 due to a "kernel-level restriction" with "no fix inside the guest distro." This was wrong.

**What actually happened:** A TCGETS2 ioctl bug in proot broke stdout in guest distros using glibc 2.41+. This was fixed in proot 5.1.107-66 (October 2025). Current proot versions (5.1.107-70+) handle guest distros correctly on kernel 6.12.

**What changed:**
- Corrected all false claims about proot-distro being broken
- Added Path B installation guide (proot-distro Ubuntu) as a valid alternative
- Documented native installer (`curl -fsSL https://claude.ai/install.sh | bash`) for Path B
- Updated TROUBLESHOOTING.md proot-distro entry with current status and upgrade instructions
- Verified: Ubuntu 25.10 installs, Claude Code 2.1.79 runs via native installer inside guest

### Two Installation Paths

Users now have a documented choice:
- **Path A (Native Termux):** 4 commands, ~2 min, lighter; recommended for most users
- **Path B (proot-distro Ubuntu):** Full Linux env, no /tmp workaround needed, native installer; for users who want a complete Linux environment

## [0.2.0] - 2026-03-18

### Skills: First Android/Termux Skills in the Ecosystem

- `/doctor`: full environment diagnostic (Node, proot, TMPDIR, ripgrep, phantom killer, storage)
- `/fix-ripgrep`: detect and fix missing arm64-android ripgrep binary (Grep/Glob ENOENT fix)
- `termux-safe`: auto-loaded constraints preventing sudo, wrong paths, silent failures

### Improvements

- Broadened support from Android 16 to Android 14+
- Added 4 new troubleshooting entries: OAuth, voice mode, ripgrep ENOENT, hooks/platform detection
- Added upstream issues table to TROUBLESHOOTING.md
- Added table of contents to TROUBLESHOOTING.md
- Fixed logo identity leak (pilgrim-logo.jpg → logo.jpg)
- Added CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md, CHANGELOG.md, PR template

## [0.1.0] - 2026-03-18

### Initial Public Release

- README with 4-command Quick Start
- Full step-by-step install guide (INSTALL.md)
- Troubleshooting reference with 13 entries (TROUBLESHOOTING.md)
- CLAUDE.md constitution template for Android/Termux (CONSTITUTION-TEMPLATE.md)
- Issue templates for bug reports and device compatibility
- MIT license

### Tested On
- Samsung Galaxy S26 Ultra, Android 16, kernel 6.12.x, Node.js v25.8.1
