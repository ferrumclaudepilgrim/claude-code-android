# Claude Code on Android

<p align="center">
  <img src="assets/logo.png" alt="Ferrum Flux Fenice phoenix logo" width="120">
</p>

<p align="center">
  <strong>Native, on-device Claude Code for your Android phone. No root, no cloud VM.</strong>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/Android-8%2B-brightgreen.svg" alt="Android 8+">
  <img src="https://img.shields.io/badge/Repo-2.9.5-blue.svg" alt="Repository version 2.9.5">
</p>

<p align="center">
  <a href="#quick-install">Install</a> · <a href="#choose-an-install-path">Paths</a> · <a href="#what-you-can-do-with-it">What it does</a> · <a href="#device-compatibility">Devices</a> · <a href="#security-on-a-personal-phone">Security</a> · <a href="#troubleshooting-and-recovery">Fix</a>
</p>

## Quick Install

<a id="before-you-start"></a>

**Before you start:** you need [Termux from F-Droid or GitHub](https://github.com/termux/termux-app#installation) (not Google Play), a 64-bit phone (once Termux is open, `uname -m` should print `aarch64`), and a Claude subscription or Console/API account. Full list: [prerequisites](docs/install.md#prerequisites).

Open Termux and run:

```bash
curl -fsSL https://raw.githubusercontent.com/ferrumclaudepilgrim/claude-code-android/main/install.sh -o install.sh
bash install.sh
```

It asks two quick yes/no questions, then runs on its own. When it finishes, open a new Termux session (or close and reopen Termux) and run:

```bash
claude
```

Want to read the script before it runs? Open [`install.sh`](install.sh) here, or run `less install.sh` after the first command.

> [!IMPORTANT]
> **Android 8, 9, or 10?** Run the same two commands with [`install-pinned.sh`](install-pinned.sh) in place of `install.sh`, or use [Path B](docs/install.md#path-b-proot-distro-ubuntu).

> [!TIP]
> **Need a hand?** Start with [troubleshooting and recovery](#troubleshooting-and-recovery), or the [FAQ](docs/faq.md) for common install questions.

<!-- LOCKED: Maintainer-approved wording for Paths A, B, and C. Do not edit without Erin's OK. -->

## Choose an Install Path

### Path A: Native Termux

Path A is the quickest and lightest way to run Claude Code on your phone. Install time depends on your network; expect about 5 to 10 minutes on a good connection.

"Native" means it runs on your phone, not on a remote machine. Anthropic doesn't publish an Android version, so Path A runs their official Linux version through a small Termux compatibility layer that this repo sets up and keeps updated ([upstream issue](https://github.com/anthropics/claude-code/issues/50270)).

<details>
<summary><strong>How updates work, and the DNS tradeoff</strong></summary>

The `claude` command this repo installs (the launcher) checks for a new Claude Code once a day. It checks new versions for startup crashes, keeps a previous one as a backup when available, and tries saved versions if a startup check detects a crash. It cannot recover without a usable saved version or catch every failure during use. To check right away, run `claude --update-now`.

Path A also points Claude Code's DNS resolver at Google's `8.8.8.8` and `8.8.4.4` by default to avoid a known connection hang. Lookups using that resolver go to Google instead of your VPN's or Pi-hole's DNS server; that does not mean they bypass your VPN tunnel. The rest of your phone is unchanged. [Why, and how to change it](docs/security-model.md#path-a-forces-google-dns-for-claude-codes-own-lookups).

</details>

[Full Path A guide](docs/install.md#path-a-native-termux)

### Path B: proot-distro Ubuntu

Path B gives you a more conventional Linux setup: Ubuntu running inside Termux, with Claude Code installed by Anthropic's own installer and no Path A launcher in between. It is significantly heavier: about 2 GB of storage, and it uses more of your phone's resources, such as memory and storage, while it runs.

[Full Path B guide](docs/install.md#path-b-proot-distro-ubuntu)

<a id="path-c-avf-linux-vm-pixel-6-with-android-16-experimental"></a>

### Path C: AVF Linux VM (experimental)

Path C is for phones that show Android's **Linux development environment** option. It runs a real Debian Linux virtual machine built into Android, with no Termux involved. It was tested on Pixel 6 and Pixel 10 Pro running Android 17. There are a few other devices that potentially have it. [Here](docs/avf-guide.md#device-requirements) is where you can find out if yours can run AVF.

To check your phone, turn on Developer options and look for **Settings → System → Developer options → Linux development environment**. No toggle? Use Path A or B.

[Full Path C guide](docs/avf-guide.md)

<!-- END LOCKED -->

<a id="whats-in-this-repo"></a>
<a id="mcp-voice-pdf-adb"></a>

## What You Can Do With It

This project helps you run the Claude Code CLI on an Android device. At its base it is very close to the standard experience. On my S26 Ultra I have run 4+ sessions at once, all doing work on the phone, several ultracode (multi-agent) workflows at the same time, and even compiled C and C++ audio code right on the device.

That last part is why this project exists. Claude Code's voice mode only recorded silence on my Android 16 phone, so I wrote a microphone module for Termux's audio system, built it on the phone, and voice mode worked. That work turned into two pull requests to Termux: microphone input and Google's Oboe audio library, which I first built in C++ on the phone.

With a little tinkering and persistence you can do so much more. Termux already connects Claude Code to a lot of Android once you give it things like file access or the microphone. If that isn't enough, and I'm sure it isn't, which is why you are here, the real integration starts with [Termux:API](https://github.com/termux/termux-api) and [ADB](docs/add-ons/adb-wireless.md). Remember, it is an agent, so [read the safety section](#security-on-a-personal-phone) before you give it more access.

A few things I have experimented with:

- **Geofence alerts:** a heads-up when I drive within a set distance of a place.
- **Voice chat:** I talk, a Termux skill turns it into text for Claude Code, and the reply is read back in the voice I picked.
- **Notification triage:** catching notifications from apps that spam, and turning them into summaries and suggestions. You can even have it turn them off for you, if you really want to.

The point: with the right, and fairly cheap, Android device, anybody can run command-line Claude Code and take it as far as they want.

**Start here:**

- **Install or update:** [full install guide](docs/install.md).
- **Need a hand?** [Troubleshooting and recovery](docs/troubleshooting.md) · [FAQ](docs/faq.md).
- **Check a phone:** [device evidence and community reports](docs/device-compatibility.md).
- **Go further:** [Build with Android](docs/add-ons/README.md#build-with-android).

## Device Compatibility

Compatibility comes from real phones, not Android version numbers.

- Current Path A runs on the Pixel 10 Pro, Pixel 6, and Galaxy S26 Ultra.
- The Moto G7 Power (Android 10) and Galaxy S7 (Android 8) can't run the current version and use the pinned fallback, an older Claude Code (`2.1.112`) that stays put. Path B works on both.
- Path C works on the Pixel 6 and Pixel 10 Pro (Android 17).

Dates, saved results, and community reports: **[Device compatibility and evidence](docs/device-compatibility.md)**. Tested another phone? [Send a device report](https://github.com/ferrumclaudepilgrim/claude-code-android/issues/new?template=device_report.yml).

## Security on a Personal Phone

Don't skim this, but don't let it cause panic either. Be smart when working with AI agents, especially near sensitive information.

Claude Code is an agent. It reads files, runs commands, and goes online on its own, on a device that holds your photos, messages, and accounts. **Anything you let Termux reach, Claude Code can reach too.**

What can actually go wrong:

- A web page, repo, or MCP server hides instructions telling Claude to read your files and send them somewhere. This is called prompt injection.
- With storage access plus internet access, it can upload your photos, downloads, or documents.
- Termux:API permissions (SMS, location, microphone, notifications) stay open to everything in Termux until you turn them off in Android settings.
- ADB lets it tap, type, and take screenshots in many other apps, and wireless debugging opens a port other devices on your Wi-Fi can reach.
- Path A points Claude Code's DNS resolver at Google by default, so lookups using it skip your VPN's or Pi-hole's DNS server. That does not mean they bypass your VPN tunnel.
- Path A trusts this repo's launcher to download and patch each new Claude Code for you. It checks that the download arrived intact, but it can't prove the source wasn't tampered with.

Start safe:

- Grant nothing extra until a task needs it, and take it back when you are done.
- Keep projects in their own folder.
- Leave wireless debugging off, and never turn it on over public Wi-Fi.
- Only connect MCP servers you trust.
- Read what Claude wants to run before approving anything that touches your files, ADB, logins, or uploads.

The installer turns none of this on for you. The full picture is in the **[security model](docs/security-model.md)**.

## Troubleshooting and Recovery

**[troubleshooting.md](docs/troubleshooting.md) should be your first stop** for any problem. It covers launch crashes, update warnings, the "Checking connectivity" hang, sign-in trouble, 32-bit phones, Ubuntu (Path B) issues, missing tools, PDFs, hooks, and AVF.

Coming back to an older install?

- **Not sure what you have?** Run the [quick check](docs/troubleshooting.md#which-setup-am-i-on).
- **Path A from this repo:** run the [install commands](#quick-install) again to get the newest launcher. Your login and settings stay.
- **The old pinned install (Claude Code 2.1.112 through npm):** use the [migration steps](docs/install.md#upgrading-from-a-pinned-v2x-install) instead of reinstalling over it.

Reporting a bug? The [bug form](https://github.com/ferrumclaudepilgrim/claude-code-android/issues/new?template=bug_report.yml) asks for your path, Android version, `uname -m`, Claude Code version, and the exact error.

<a id="alternative-remote-control"></a>
<a id="other-projects-other-ways-in"></a>

## Community, Ecosystem, and Related Projects

Here are a few of the many amazing tools, software, and things I like. I have also included a few related projects, because I am a firm believer in looking around.

<a id="built-on-and-assisted-by"></a>

Built on and assisted by:

- **Claude Code** by [Anthropic](https://www.anthropic.com): [anthropics/claude-code](https://github.com/anthropics/claude-code)
- **Termux** and its [glibc-packages](https://github.com/termux/glibc-packages), which provide the Android terminal and compatibility components used by Path A
- **gtbuchanan's patched-binary approach**, first shared on [anthropics/claude-code#50270](https://github.com/anthropics/claude-code/issues/50270#issuecomment-4467292215) and extended here with verification, update, rollback, and recovery behavior
- **Google ARTEMIS**: [google/artemis](https://github.com/google/artemis), Google's open-source Android automation agent, now the controller in my lab experiments
- **OpenAI Codex**: [openai/codex](https://github.com/openai/codex) (Don't judge me. You can't be model dependent!)

Other ways to run Claude Code on Android:

- [gtbuchanan/claude-code-termux](https://github.com/gtbuchanan/claude-code-termux) packages the same patched-binary idea as an apt `.deb`. The approach used here started with gtbuchanan's work.
- [Ishabdullah/claude-code-termux](https://github.com/Ishabdullah/claude-code-termux) covers the older npm route, the same family as this repo's pinned fallback.

If you already have a computer that runs Claude Code, Anthropic's official [Remote Control](https://code.claude.com/docs/en/remote-control) is an option: the work runs on that computer and your phone is the screen. Its functionality, or lack thereof, is one of the main reasons I began looking for this route.

This project is listed in [Awesome Claude Code's Documentation, Knowledge & Learning collection](https://github.com/hesreallyhim/awesome-claude-code#documentation-knowledge--learning).

## Contributing

Found a bug, tested another phone, or improved a workaround?

- [Open a bug report](https://github.com/ferrumclaudepilgrim/claude-code-android/issues/new?template=bug_report.yml)
- [Submit a device report](https://github.com/ferrumclaudepilgrim/claude-code-android/issues/new?template=device_report.yml)
- Ask a question or tell me it worked in [Discussions](https://github.com/ferrumclaudepilgrim/claude-code-android/discussions)
- Read [CONTRIBUTING.md](.github/CONTRIBUTING.md) before opening a pull request

## From the Maintainer

Ferrum_Flux_Fenice here, aka Erin. I use Path A on my own phone. The pushes have slowed mostly because the setup has become stable, but I am still trying to make this a lasting repository that helps people run the real tool, understand the compromises, and recover when Android or an upstream release behaves differently.

If something is broken or you have evidence from another device, open an issue or pull request. I enjoy putting time forward, learning, and helping others. I maintain this alone and I am not a security professional, so treat the documentation as evidence-backed guidance rather than a canonical guarantee; verify what matters for your own phone and data.

[@ferrumclaudepilgrim](https://github.com/ferrumclaudepilgrim) · Ferrum_Flux_Fenice · Erin

<a id="license"></a>

## Attribution and License

MIT licensed. See [LICENSE](LICENSE).

> This is an independent community project. It is not affiliated with or endorsed by Anthropic, Google, or OpenAI. Claude Code is a product of Anthropic.
