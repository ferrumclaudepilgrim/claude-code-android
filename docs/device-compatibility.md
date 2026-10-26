# Device Compatibility and Evidence

Find your phone, then check **which installer was used and who reported the result**. Lab checks and community reports share one table; neither is a promise that every later Claude release will run there.

[Choose a path](install.md#choose-your-path) · [Fix a problem](troubleshooting.md) · [Report your device](https://github.com/ferrumclaudepilgrim/claude-code-android/issues/new?template=device_report.yml)

## Two Version Numbers

Repository version `2.9.5` identifies these scripts and documents. `claude --version` identifies Anthropic's release, a separate number. A recorded Claude release says what was tested, not what a current native install will download. The pinned route stays on `2.1.112`.

## Read the methods

- **A native:** `install.sh` or `migrate.sh`, Linux ARM64 binary through glibc-runner and this repo's wrapper.
- **A pinned:** `install-pinned.sh`, Claude Code `2.1.112` through Node.js; no auto-updating wrapper.
- **B:** `proot-distro` Ubuntu in Termux, then Anthropic's native installer.
- **C:** Android Terminal's Debian VM through AVF, then Anthropic's native installer.

## Device results

**Lab** means a maintainer check. **Community** means a user's issue/comment. **Contributor** means testing described in a PR. The source column keeps dates and evidence limits visible.

| Device / Android | Evidence | Methods / installers tested | Recorded result | Source and date |
|---|---|---|---|---|
| **Pixel 10 Pro · 17** | **Lab** | A native: install/migrate; B; C | A launch, DNS and concurrent-update checks passed. B worked. C worked end to end. | [2.9.4 maintainer record](../CHANGELOG.md#294---2026-07-27), 2026-07-27; B manual setup notes dated [2026-05-16](install.md#step-1-set-up-ubuntu); [C check](avf-guide.md), 2026-05-26. No saved current A/B transcript. |
| **Pixel 6 · 17** | **Lab** | A native: fresh install; B; C | A fresh install, launch, DNS and concurrency checks passed. B worked. C worked end to end. | [2.9.4 record](../CHANGELOG.md#294---2026-07-27), 2026-07-27; B manual recheck 2026-07-27; [C check](avf-guide.md), 2026-05-26. The old Android 13 transcript is not evidence for these runs. |
| **Moto G7 Power · 10** | **Lab** | A native; A pinned; B | Current native failed to start. Pinned `2.1.112` works in the recorded checks, including search. B worked end to end in the maintainer's 2026-05-16 check. | [Native check](../CHANGELOG.md#294---2026-07-27), 2026-07-27; [pinned launch/search](../CHANGELOG.md#293---2026-07-01), 2026-07-01, manual recheck 2026-07-27. B: [dated maintainer record](https://github.com/ferrumclaudepilgrim/claude-code-android/blob/102f3f71463b3cf68d101878f460c0062a744436/docs/install.md#tested-on), 2026-05-16. No saved Path B run transcript retained. |
| **Galaxy S7 (SM-G930P) · 8.0.0** | **Lab** | A native migration; A pinned; B | Native migration aborted and preserved the pin. Pinned `2.1.112` works in recorded checks, including search. B worked; OAuth URL needed manual paste. | [Migration](../CHANGELOG.md#294---2026-07-27), 2026-07-27; [pinned launch/search](../CHANGELOG.md#293---2026-07-01), 2026-07-01, manual recheck 2026-07-26; B observation 2026-07-26. |
| **Galaxy S26 Ultra (SM-S948U) · 16** | **Lab** | A migration; B | A migration/wrapper worked. B native install worked. | [2.9.0 record](../CHANGELOG.md#290---2026-05-29), 2026-05-29; B procedure 2026-05-16; [model attribution](https://github.com/ferrumclaudepilgrim/claude-code-android/issues/3#issuecomment-4584853912). No saved Path B transcript. The [historical screenshot](../assets/screenshot-s26ultra.jpg) shows pre-2.9 Claude `2.1.79`; it does not establish these migration or native Path B results. |
| **Galaxy S23+ · 15** | **Lab** | B | Worked in the historical maintainer check. | 2026-03-19; [screenshot](../assets/screenshot-s23plus.jpg), no saved transcript. |
| **Lenovo Tab M10 · 10** | **Community** | A native | Failed with `Bad system call`. No reporter-confirmed fallback recovery recorded. | [Issue #5](https://github.com/ferrumclaudepilgrim/claude-code-android/issues/5), 2026-06-11. |
| **Honor X7d 4G · 15** | **Community** | A native wrapper | `2.1.181` crashed; the original reporter confirms `2.1.191` launches cleanly. | [Issue #6 confirmation](https://github.com/ferrumclaudepilgrim/claude-code-android/issues/6#issuecomment-4801770300), 2026-06-25. |
| **Pixel 8 Pro · 16** | **Community** | A native; F-Droid Termux 0.118.3 | `2.1.193` started, then reached `ETIMEOUT`. Issue closed; no original-reporter recovery confirmation found. | [Issue #7](https://github.com/ferrumclaudepilgrim/claude-code-android/issues/7), 2026-06-26. The Fold result below is a different device. |
| **Pixel 10 Pro Fold · 16** | **Contributor** | A native plus DNS preload | `2.1.195` reached an authenticated prompt after the fix; PR includes trace excerpts. | [PR #9](https://github.com/ferrumclaudepilgrim/claude-code-android/pull/9), reported 2026-06-29, merged 2026-07-01. Not a lab capture. |
| **Pixel 9 Pro XL · 17 / SDK 37** | **Community** | A native / glibc-runner; GitHub Termux 0.118.3 | `2.1.207` reported usable despite a cosmetic EACCES line; original reporter later confirms working. | [Issue #10](https://github.com/ferrumclaudepilgrim/claude-code-android/issues/10), 2026-07-13; [confirmation](https://github.com/ferrumclaudepilgrim/claude-code-android/issues/10#issuecomment-5160736200), 2026-08-02. |
| **Galaxy S23 Ultra · 16** | **Community** | A native `install.sh`; B in a separate report | A failed at the glibc package step; original reporter did not confirm recovery. Separately, B `2.1.232` reported fully working, with a keyboard-reopen workaround. | [A: issue #4](https://github.com/ferrumclaudepilgrim/claude-code-android/issues/4), 2026-06-05; [B: issue #12](https://github.com/ferrumclaudepilgrim/claude-code-android/issues/12), 2026-08-14, using Google Play Termux. Different users, not one before/after test. |

### How to Read the Results

Android 8/10 lab failures include system-call rejection; a wrapper cannot make an unsupported binary run. Use the pinned route or B for those devices. Missing Android 9 evidence is not a claim of a successful Android 9 test.

Path C requires Developer options and a build exposing **Linux development environment**. The two lab Pixels do not establish support for every Pixel, chipset, or newer phone. [Check AVF availability](avf-guide.md#device-requirements).

## What the saved test files prove

> [!NOTE]
> **Historical evidence, not today's acceptance tests.** The four saved `.txt` outputs date to 2026-05-16. They remain useful, but cover older environments and selected checks.

- [Pixel 10 Pro / Android 17](../tests/results/pixel-10-pro-android17.txt), [Moto G7 Power / Android 10](../tests/results/moto-g%287%29-power-android10.txt), and [S7 / Android 8](../tests/results/sm-g930p-android8.0.0.txt) show Claude help responding, not its exact version or an authenticated end-to-end run.
- [Pixel 6 / Android 13](../tests/results/pixel-6-android13.txt) says Claude and Ubuntu are absent. It is environment evidence, not proof of Path A/B working.
- All four skip Ubuntu checks because Ubuntu is absent in those captures.
- [Sensor captures](../tests/results/sensors/README.md) are separate 2026-08-31 ADB-shell observations, with their build/identity limits recorded.

Current host regression tests still check installer/wrapper behavior. They serve a different purpose from device captures; see [checks and scripts](../.github/CONTRIBUTING.md#testing-and-verification).

## Add or Update Evidence

Use the [device-report form](https://github.com/ferrumclaudepilgrim/claude-code-android/issues/new?template=device_report.yml). Include the device/model, Android version, `uname -m`, installer/path, Claude version, date, exact outcome, and workaround if any. Attach a redacted log or screenshot when available.

Remove account names, tokens, pairing codes, notifications, and private project data before sharing. Do not run the installer-changing device release runner as an ordinary health check.

Review scope: the repository's nine visible public issues and their comments, plus PRs #9 and #11, checked 2026-10-25. Discussions, deleted/private reports, attachment contents, and new device tests were not reviewed. Unknown dates/versions remain unknown; closing an issue alone is not a successful retest.
