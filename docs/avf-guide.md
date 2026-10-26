# Android Virtualization Framework (AVF): Path C

> **Experimental.** I have installed, configured, and used Claude Code inside the Android Virtualization Framework VM on Pixel 6 (Android 17) and Pixel 10 Pro (Android 17). This guide documents what I observed. Google's official AVF developer documentation lives at [source.android.com/docs/core/virtualization](https://source.android.com/docs/core/virtualization); user-facing behaviour described here was discovered on real devices.

> **Android 17 status (verified 2026-05-26):** The AVF path was retested end-to-end on Pixel 6 and Pixel 10 Pro running Android 17. Several things changed between Android 16 and Android 17 and this guide has been updated for the current behaviour:
>
> - Memory size, Display resolution, and Keep awake are adjusted in the Terminal app's gear-icon Settings under **Advanced**.
> - Keep awake keeps the VM running when the screen turns off. See the Screen-Off Stability section below.
> - SSH (Secure Shell) is not running by default. It is installed and can be enabled if you want it.
> - The Recovery section of Settings exposes "Reset to initial version" and "Remove backup data".
> - On Pixel 10 Pro, an additional **Graphics Acceleration** toggle (Software renderer or GPU-accelerated renderer) is available. Other Pixel models do not show this row.

![Status: Experimental](https://img.shields.io/badge/Status-Experimental-orange.svg)

---

## On This Page

- [What AVF is](#what-avf-is)
- [Device requirements](#device-requirements)
- [Set up the Linux VM](#setup-checklist)
- [Configure the VM](#vm-configuration)
- [Back up before recovery](#recovery-and-backups)
- [Install Claude Code](#claude-code-installation-inside-avf)
- [Tested capabilities](#what-i-observed-working)
- [ADB access](#adb-wireless-from-inside-the-vm)
- [Known issues and security](#known-issues)
- [Choose between Path A, B, and C](#comparison-path-a-vs-path-b-vs-path-c)
- [Technical details](#technical-details-for-the-curious)

## What AVF Is

In plain terms: Path C runs a real Linux computer inside your phone using Android's built-in virtualization. Everything below is detail for the curious; you do not need to understand it to use this path.

Android Virtualization Framework (AVF) is Android's framework for creating and managing virtual machines. On supported builds, the Terminal app boots a Debian VM with a real Linux kernel. Unlike proot-distro (Path B), which uses syscall translation, AVF runs an actual VM: `process.platform === "linux"`, native `/tmp`, no proot overhead.

The VM runs on crosvm (Chrome OS's virtual machine monitor), managed by Android's VirtualizationService, with pKVM (Android's paravirtualized KVM hypervisor) providing hardware-level isolation. Device I/O uses virtio (a standard interface for virtual devices). AOSP (Android Open Source Project) architecture reference: [source.android.com/docs/core/virtualization/architecture](https://source.android.com/docs/core/virtualization/architecture).

---

## Device Requirements

| Requirement | Details |
|-------------|---------|
| **Chipset** | Google Tensor on Pixel 6 and Pixel 10 Pro verified in my lab. Other devices and chipsets depend on their OEM build; see below. |
| **Android build** | Must expose Linux development environment; the lab observations below cover Android 17. Android version alone is not sufficient. |
| **Developer Options** | Must be enabled |
| **WiFi or data** | Required for the initial Debian image download (several hundred megabytes). Use WiFi. |

If your phone exposes Settings > System > Developer options > **Linux development environment**, the AVF Terminal path is available in that build. If the option is missing, this guide cannot enable it; availability may change with Android and OEM updates.

In my lab, this path is verified only on the two Tensor Pixels named above. Public reports indicate that stock Snapdragon and Samsung support varies by device and firmware because the Terminal app needs virtualization features the OEM must expose. Exynos-based Galaxy S26 and S26+ support has been reported in Samsung release material, while Snapdragon variants may differ. I do not own those models, so treat those statements as reported compatibility rather than first-hand evidence.

---

## Setup Checklist

Verified on Pixel 6 and Pixel 10 Pro running Android 17 on 2026-05-26.

### 1. Enable Developer Options

Settings > About phone > tap **Build number** 7 times.

> [!WARNING]
> Developer options are required for this path. Enable only Linux development environment; USB and wireless debugging are separate controls and are not required to install Claude here. Review unfamiliar settings before changing them. [Android's current setup documentation](https://source.android.com/docs/core/virtualization/usecases#linux_development_environment) was checked on 2026-10-25.

### 2. Enable Linux Development Environment

Settings > System > Developer options > **Linux development environment** > toggle ON.

If that toggle is not present, your device does not support this path.

### 3. Launch the Terminal App

A "Terminal" app appears on the home screen after step 2. Open it. On first launch, accept the prompt to download the Debian image. The download is several hundred megabytes; use WiFi.

When setup finishes, the app displays a shell prompt: `droid@debian:~$`. You are now inside the Linux VM.

### 4. Adjust Settings If You Want To

Tap the gear icon in the top right of the Terminal app to open Settings. The categories are:

- **Port control**: allow or deny ports that processes inside the VM open
- **Theming**: terminal color presets, plus import of custom themes
- **Advanced**: Display resolution, Memory size, Keep awake. On Pixel 10 Pro an additional Graphics Acceleration toggle appears.
- **Recovery**: "Reset to initial version" wipes the Debian image and re-downloads it. "Remove backup data" wipes `/mnt/backup`. [Back up projects first](#recovery-and-backups).

You can run Claude Code without changing any of these. The defaults work.

### 5. Screen-Off Stability (Keep Awake)

The VM is subject to Android's normal app-killing behaviour when the screen turns off. Android 17 adds a built-in mitigation in the Terminal app: Settings (gear) > Advanced > **Keep awake**.

Keep awake is a timer. The options are Off, 1 minute, 5 minutes, 10 minutes, 30 minutes, 1 hour, 2 hours, 6 hours, and 1 day. The in-app dialog warns: *"Enabling keep awake will significantly impact battery life as it prevents the device from sleeping."*

For short interactive sessions, leave it Off and keep the screen on. For long-running workloads, pick a value that matches how long you need the VM alive in the background.

The Terminal app's Activity (the on-screen window Android draws for the app) can still be recreated by Android in some cases (for example, when another app triggers a configuration change). Keep awake keeps the VM running but does not guarantee the terminal session UI stays continuous through every Android lifecycle event. If you need true long-running workloads, run them under `tmux` or `nohup` (tools that keep a process alive after its terminal window goes away) so they survive Activity recreation.

---

## VM Configuration

On Android 17, VM configuration is exposed in the Terminal app's gear-icon Settings under **Advanced**. The `/mnt` tree inside the VM contains `backup`, `build`, `shared`, and `ttyd` only.

The Advanced screen exposes:

| Control | What it does |
|---|---|
| **Display resolution** | Three presets: Full ("Performance might be degraded"), Half (labelled "Recommended" by the app), Quarter ("Quality might be degraded"). For CLI-only Claude Code use, the resolution does not matter. |
| **Memory size** | Integer megabyte input plus a slider. The code default is 1024 MiB ([AOSP `ConfigJson.kt`](https://android.googlesource.com/platform/packages/modules/Virtualization/+/refs/heads/main/android/TerminalApp/java/com/android/virtualization/terminal/ConfigJson.kt)). The slider maximum scales with the host device's total RAM (I observed roughly two-thirds of total). Changing this requires a Terminal restart. |
| **Keep awake** | Screen-off VM survival timer; see the Screen-Off Stability section above. |
| **Graphics Acceleration** | Software renderer or GPU-accelerated renderer. Only present on Pixel 10 Pro in my testing; absent on Pixel 6. Tied to whether the device ships the AVF graphics overlay. |

To apply changes, the Terminal app may prompt to restart the VM.

zram swap (compressed swap space held in RAM) is configured automatically inside the VM and scales with the memory allocation. No manual setup needed.

---

## Recovery and Backups

Before resetting, copy guest projects to a destination outside the VM, such as `/mnt/shared` or a backup location you control. `/mnt/shared` is Android shared storage: check the copy from Android's Files app before resetting. Do not leave credentials or private keys in an unprotected shared folder. A project's Git remote is another option only if it is the intended destination and every needed file is committed and pushed; uncommitted and ignored files need a separate backup.

In **Terminal Settings → Recovery**, **Reset to initial version** recreates the Debian guest and deletes files held only inside it. **Remove backup data** separately deletes `/mnt/backup`; that name is not proof your projects were backed up there. If the VM cannot start, do not reset while assuming its inaccessible files are safely copied elsewhere.

## Claude Code Installation Inside AVF

Once the Terminal app is running and you have a Debian shell:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Then fix your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Launch Claude Code:

```bash
claude
```

Authenticate via OAuth as normal.

Path C uses Anthropic's native updater. This repository's Path A wrapper and crash rollback do not apply. Run `claude update` for a manual update; rerun the installer only for installation repair. See [native updates](https://code.claude.com/docs/en/setup#auto-updates).

**Copy-paste warning:** The AVF terminal has unreliable copy-paste behavior. Long commands and multi-line commands frequently break when pasted. Type commands manually or verify pasted text character by character before running.

---

## What I Observed Working

These capabilities were confirmed through direct testing on my Pixel 10 Pro. Results on other devices may vary.

### Core Environment
- **Real Linux kernel.** No syscall translation, no proot overhead. `process.platform === "linux"`. The kernel build is in the 6.12.x line on my Android 17 devices.
- **Native `/tmp`.** A real, writable `/tmp` directory inside the VM.
- **Standard `apt` package management.** Full Debian 13 (trixie) package ecosystem. `sudo apt update` and `sudo apt upgrade` work normally, including systemd package updates.
- **Claude Code installs via the official Anthropic installer.** No npm, no Node.js version management, no ripgrep symlink needed.
- **Python 3 pre-installed.** Node.js, GCC, and make are NOT pre-installed; install with `sudo apt install`.
- **OpenSSH is installed but not running by default.** Review the [default account and SSH settings](#security-defaults-users-should-be-aware) before enabling remote access.
- **systemd fully functional.** Service management, timers, and journals all work. Updating systemd via apt worked without issues in my testing.

### Hardware and Performance
- **8 CPU cores visible** (1x Cortex-X4, 5x Cortex-A725, 2x Cortex-A520 on my Tensor G5 test device). Full big.LITTLE topology (ARM's mix of high-performance and low-power cores) exposed via `--host-cpu-topology`.
- **103 GB root disk.** Observed 552 MB/s sequential write and 4.2 GB/s sequential read using dd with default flags; the read figure includes page cache, so real disk throughput is lower. The original disk benchmark tool (fio) could not run due to a kernel limitation (see Known Issues).
- **zram swap** configured by default, scales proportionally with RAM allocation. No manual setup needed.

### Audio
- **Audio playback and recording partially verified.** PulseAudio 17.0 running as daemon, VirtIO SoundCard detected. Both playback (aplay, speaker-test) and capture (arecord) succeeded. Whether sound actually reached the phone speaker through AVF's audio routing pipeline was not conclusively verified.

### GUI Capability
- **Headless rendering works.** Firefox ESR (Extended Support Release) ran in headless mode and successfully rendered web pages to screenshot files.
- **Wayland compositor available.** (Wayland is a modern Linux display system.) cage (kiosk compositor) ran with the headless backend. wayvnc can serve the output over VNC (Virtual Network Computing, a remote-desktop protocol). Full interactive Firefox in a compositor crashed due to the software renderer's limitations, but headless screenshots worked.
- **Mesa/OpenGL/EGL (Embedded Graphics Library, the interface between OpenGL and the display system) stack pre-installed.** GPU device at `/dev/dri/card0` via virtio-gpu. The Terminal app exposes a Graphics Acceleration toggle (Software renderer or GPU-accelerated renderer) on Pixel 10 Pro; on Pixel 6 the row is absent and the VM uses the software renderer.

### Networking and Kernel Features
- **All 41 Linux capabilities present** in my testing (unrestricted VM).
- **iptables works** via `iptables-legacy` (not nftables; see Known Issues).
- **FUSE (Filesystem in Userspace), OverlayFS, BPF (Berkeley Packet Filter, a Linux kernel programmability subsystem), seccomp** all functional.
- **systemd-nspawn available** for lightweight containerization.
- **inotify, mmap, loop devices, ext4** all work as expected.
- **Ping works** using unprivileged ICMP (Internet Control Message Protocol) sockets.
- **TUN device available** at `/dev/net/tun` (TUN is a virtual network kernel interface; VPN support is possible).

### Android Storage Access
- `/mnt/shared` is the Android shared-storage volume (the same place Android's "Files" app reads from). Anything placed there from Android is visible inside the VM, and vice versa.
- `/mnt/backup` is used by the Terminal app's Recovery feature for backup data.

---

## ADB Wireless From Inside the VM

In my testing, ADB wireless debugging worked from inside the VM, connecting to the host phone. This provides access to battery status, thermal data, display info, logcat, dumpsys, and device management. These capabilities are not otherwise available from inside the isolated VM.

**How it worked in my testing:**

1. Enable Wireless Debugging on the phone (Settings > Developer options > Wireless debugging)
2. Tap "Pair device with pairing code" to get the pairing port and code
3. From inside the VM, pair using the phone's Wi-Fi IP (not localhost, not the virtual gateway):

```bash
adb pair <phone-wifi-ip>:<pairing-port> <code>
```

4. Scan for the connection port (it is different from the pairing port and rotates each session):

```bash
adb connect <phone-wifi-ip>:<connection-port>
```

**Pairing tip:** Use split-screen mode with Settings and Terminal side by side. The pairing code and port disappear when you leave the Wireless Debugging screen in Settings, so you need both visible simultaneously to enter the code before it expires.

**What I observed:**
- The connection uses the phone's Wi-Fi IP address, not `127.0.0.1` or the virtual network gateway
- Pairing codes expire quickly. Pair immediately after opening the dialog.
- ADB pairing survived VM restarts in my testing. Only the connection needed to be re-established (with a new port scan).
- The connection port rotates each Wireless Debugging session
- Once connected, commands like `adb shell dumpsys battery`, `adb shell dumpsys thermalservice`, and `adb logcat` all worked

**What ADB allowed in this test setup:**
- Battery status, thermal monitoring, display info
- Logcat (system logs from the Android host)
- App management (dumpsys, am, pm)
- Device settings (get/set system properties)
- Input injection (tap, swipe, text)
- The screen-off stability commands described in the Setup section
- Queries or actions involving sensors, location, camera, and screenshots through Android system interfaces (see next section). Availability and returned data depend on Android version, permissions, device state, and OEM policy.

---

## ADB Hardware Access

With ADB connected from inside the VM to the Android host, I tested access to phone hardware. This was observed in my testing on a single device.

### Sensors: check your device

Sensor counts and available readings vary by phone, Android build, permissions, and access method. The [sensor guide](add-ons/sensors.md#adb-inventory-from-the-avf-guide) owns the historical inventory, the four-device campaign, and the distinction between enumeration and usable readings. ADB access from this VM does not make Android sensors native Linux devices.

### GPS / Location

`adb shell dumpsys location | grep "last location"` returned location data including latitude/longitude coordinates with ~11.5m horizontal accuracy and sub-meter vertical accuracy. Both network and fused location providers were active.

### Camera

`adb shell am start -a android.media.action.IMAGE_CAPTURE` opened the camera app from inside the VM. The viewfinder was visible and a screenshot of it could be captured via `adb shell screencap`. Camera capabilities included front + rear cameras, up to 4032x3024 stills and 4K video, with multiple focus modes.

### Screenshots and Screen Recording

```bash
# Screenshot
adb shell screencap -p /sdcard/shot.png && adb pull /sdcard/shot.png

# Screen recording (3 seconds)
adb shell screenrecord --time-limit 3 /sdcard/vid.mp4 && adb pull /sdcard/vid.mp4
```

Both worked reliably in my testing. Screenshots ranged from 202KB to 777KB depending on content. Screen recordings transferred at ~80 MB/s to the VM.

### Input Injection

These are syntax examples, not recorded device values or ready-to-run commands. Replace the labels with your own screen coordinates and use a harmless test field first:

```text
adb shell input text "EXAMPLE_TEXT"
adb shell input tap X Y
adb shell input swipe START_X START_Y END_X END_Y DURATION_MS
```

All input injection commands worked in my testing. The device reported multitouch support with 10 touch slots and pressure sensitivity.

### Battery and WiFi

```bash
# Battery
adb shell dumpsys battery
# Returns: status, level (%), voltage (mV), temperature

# WiFi
adb shell dumpsys wifi | grep mWifiInfo
# Returns: frequency, link speed, signal strength, security type
```

Both returned detailed real-time data in my testing. Battery data included charge level, voltage, and temperature. WiFi data included connection frequency, link speeds (TX/RX), signal strength in dBm, and security protocol.

### Needs Pipeline Work

- **Live sensor value streaming:** enumeration is not a stream of readings. Use a device-supported Android API and verify emitted events under that execution identity; see the [sensor methods and evidence](add-ons/sensors.md). Polling an inventory or arbitrary input events is not a general sensor-reading solution.
- **Camera photo capture to file:** The camera app opens but programmatically taking a photo and saving it to a retrievable path needs either an intent with an output URI (`am start -a IMAGE_CAPTURE --eu output file:///sdcard/photo.jpg`) or the screencap workaround (captures whatever is on screen, including the viewfinder).
- **Clipboard read:** Content access restricted on Android 13+. May need accessibility service or specific permissions.

### ADB Command Reference

Reference syntax, not a sequence to paste. Choose the operation you need after connecting; replace uppercase labels with your own values. Camera and input commands act on the phone's current screen.

```text
# Sensor enumeration
adb shell dumpsys sensorservice

# GPS coordinates
adb shell dumpsys location | grep "last location"

# Camera launch
adb shell am start -a android.media.action.IMAGE_CAPTURE

# Screenshot
adb shell screencap -p /sdcard/shot.png && adb pull /sdcard/shot.png

# Screen recording
adb shell screenrecord --time-limit N /sdcard/vid.mp4 && adb pull /sdcard/vid.mp4

# Battery state
adb shell dumpsys battery

# Input injection
adb shell input text "EXAMPLE_TEXT"
adb shell input tap X Y

# WiFi info
adb shell dumpsys wifi | grep mWifiInfo
```

---

## Known Issues

| Issue | Impact | Workaround | Status |
|-------|--------|------------|--------|
| VM killed when screen off | Session lost, unsaved work gone | Settings > Advanced > Keep awake (timer up to 1 day); keep screen on for short sessions | Built-in mitigation on Android 17. Battery impact applies; see warning text in the in-app dialog. |
| Terminal Activity recreation | Terminal UI disrupted even when VM survives | Run long workloads under `tmux` or `nohup` so they survive Activity recreation | Some Android lifecycle events (configuration changes, accessibility services) recreate the Activity even with Keep awake on |
| Default Memory size may be low | Limits what can run concurrently | Settings > Advanced > Memory size; raise the value (slider scales with device RAM); restart Terminal to apply | Code default is 1024 MiB per AOSP. The slider exposes the safe range for your device. |
| Cellular data doesn't work by default | No network on mobile data | Settings > Apps > Terminal > enable "Unrestricted mobile data usage" > restart device. WiFi works without this step. | Google Issue Tracker #402523629 |
| Copy-paste unreliable | Multi-line commands break when pasted | Type manually or verify character by character | No fix known |
| `apt upgrade` can hang on TUI (text-based user interface) dialogs | Upgrade appears stuck indefinitely | Run with `DEBIAN_FRONTEND=noninteractive` or kill the blocking whiptail process | Observed during openssh-server post-install; whiptail required interactive input in a non-interactive shell |
| SysV IPC disabled in kernel | fio fails; some Python multiprocessing features unavailable | Use dd for disk benchmarks; use fork-based multiprocessing instead of shared memory | CONFIG_SYSVIPC is explicitly not set in the kernel. Hard wall. |
| nftables non-functional | Cannot use nft command despite kernel netfilter support | Use `iptables-legacy` instead: `sudo update-alternatives --set iptables /usr/sbin/iptables-legacy` | Kernel has CONFIG_NETFILTER=y but nftables operations return "Invalid argument" |
| No kernel module loading | Cannot extend kernel functionality at runtime | None (kernel is monolithic, /lib/modules/ is empty) | By design |
| "VM damaged" on unclean shutdown | Must reinstall entire VM | Commit/push work frequently; treat VM storage as ephemeral | By design. Terminal app marks any unclean shutdown as damaged. |
| Linux development environment option absent | Cannot use this Terminal path on that build | Use Path A or B | Availability depends on the device and build. Lab support here covers two named Pixels; a chipset name alone is not a support test. See [device requirements](#device-requirements). |
| No USB passthrough | Cannot access USB devices from VM | None | No USB host controller emulated by AVF |
| No phone sensors directly in VM | Camera, GPS, accelerometer, etc. not available inside VM natively | Optional ADB bridge; see the sensor guide for device-specific evidence | Sensors confirmed enumerable. Live value streaming needs pipeline work. |
| VM IP changes per boot | Scripts using hardcoded VM IPs break | Query IP dynamically at boot | Virtual network interface gets a new address each time |
| GPU acceleration limited | Pixel 10 Pro exposes a Graphics Acceleration toggle (GPU-accelerated renderer) in Settings > Advanced. Other Pixel models fall back to the software renderer. | CLI-only Claude Code use avoids the GPU entirely | Tied to the device's AVF graphics overlay package. Pixel 10 Pro ships it; Pixel 6 does not. |

---

## Security Defaults: Users Should Be Aware

The VM ships with defaults that prioritize convenience over security. In my testing on Android 17, I observed the following. Consider whether hardening is appropriate for your use case.

| Default | Detail | Suggested Hardening |
|---------|--------|---------------------|
| Default user password | The "droid" user (UID 1000) has a known default password set by cloud-init (the tool that does first-boot setup) | Change with `sudo passwd droid` |
| NOPASSWD sudo | The droid user has passwordless sudo | Add a password requirement if others share the device |
| No firewall configured | All iptables chains default to ACCEPT | Configure iptables-legacy rules (see Known Issues for nftables limitation) |
| SSH installed but inactive | OpenSSH is in the image but not started. If you enable it with `sudo systemctl enable --now ssh`, the default `sshd_config` permits password auth | Before enabling, set `PasswordAuthentication no` and use key-based auth |
| SSH key on shared storage | If you generate or move an SSH key into `/mnt/shared/`, any Android app with storage access can read it | Keep keys in the VM's `~/.ssh/`, not on shared storage |

The VM is on a virtual network not directly reachable from the internet. Only the Android host can reach it. The primary exposure vector is ADB wireless debugging on the Wi-Fi network, which requires explicit pairing.

---

## What Works Well

- **Real Linux kernel.** No syscall translation, no proot overhead. Native performance.
- **`process.platform === "linux"`.** No platform detection issues. Tools that check for Linux work without patching.
- **Native `/tmp`.** A real, writable `/tmp` directory inside the VM.
- **Standard package management.** `apt` works normally. Full Debian package ecosystem available. System packages including systemd can be updated without issues.
- **Claude Code installs via official installer.** No npm, no Node.js version management, no ripgrep symlink needed.
- **RAM is configurable.** Settings (gear) > Advanced > Memory size exposes an integer MB input and a slider scaled to your device's total RAM. The code default is 1024 MiB.
- **ADB bridge to phone.** In the recorded checks, wireless ADB from the VM exposed selected phone diagnostics and controls. Sensor evidence and limits live in the [sensor guide](add-ons/sensors.md).
- **Audio pipeline.** PulseAudio and the virtual sound device were detected; playback/capture commands succeeded. Actual phone-speaker routing was not conclusively verified.
- **GUI headless rendering.** Firefox screenshots, automated browser testing, and similar headless workflows work.
- **Isolation.** VM is separated from Android. Crashes don't affect the host OS.

---

## Comparison: Path A vs Path B vs Path C

Times and sizes are estimates. Use the [installation guide](install.md#choose-your-path) for current procedures and [device compatibility](device-compatibility.md) for dated results.

| | Path A (Native Termux) | Path B (Ubuntu in Termux) | Path C (AVF VM) |
|---|---|---|---|
| **Setup time** | 5-10 min | ~10-15 min (experienced) | ~20 min (experienced) |
| **Disk usage** | ~280 MB base | ~2 GB | ~2 GB (Debian image) |
| **Install method** | Patched linux-arm64 binary via glibc-runner; auto-updating wrapper | Official Anthropic installer | Official Anthropic installer |
| **Kernel** | Host Android Linux kernel; glibc compatibility layer | Host Android Linux kernel; proot translates selected system calls | Separate Linux guest kernel |
| **`/tmp` workaround** | Not needed | Not needed | Not needed |
| **Ripgrep** | Not needed (binary ships vendor/ripgrep/arm64-linux/rg) | Not needed | Not needed |
| **`process.platform`** | `"linux"` (the patched binary is the linux-arm64 build) | `"linux"` | `"linux"` |
| **RAM** | Shares device RAM | Shares device RAM | Configurable in Terminal app Settings > Advanced > Memory size. Code default is 1024 MiB; slider scales with device RAM. |
| **Termux API access** | Optional companion app and permissions | Optional host integration; permissions still required | No direct Termux:API; the separate ADB bridge has device-specific capabilities |
| **ADB self-connect** | Works (127.0.0.1) | Works (127.0.0.1) | Works (via Wi-Fi IP, observed in my testing) |
| **Device support** | Newer ARM64 lab phones; Android 8–10 lab phones needed pinned fallback | Recorded on ARM64 lab phones, including older Android | Android builds exposing the Linux environment toggle; Pixel 6 and Pixel 10 Pro lab checks |
| **Evidence** | Dated native and pinned lab checks | Dated lab observations | Experimental; two named lab Pixels |
| **Ongoing maintenance** | Wrapper checks, launcher refreshes, and recovery | Guest packages and Anthropic updater | Guest packages, Anthropic updater, and VM backups |
| **Audio** | Android permissions and capture backend apply | Host audio integration needed | PulseAudio + VirtIO commands tested; phone audio routing unverified |
| **GUI capability** | Limited | Limited | Headless rendering confirmed; interactive compositor possible |
| **Best for** | Most users; the default path, start here | Users who want a full Debian/Ubuntu userland | Experimenters with Pixel devices who want native Linux |

---

## When to Use AVF vs Termux

**Use Path C (AVF) when:**
- Your Android build exposes **Linux development environment**; the lab observations cover Pixel 6 and Pixel 10 Pro, not every newer Pixel
- You want a real Linux environment with native `/tmp` and `process.platform === "linux"`
- You want to set VM memory and display resolution from a UI rather than work around Android's defaults
- You want headless GUI rendering or systemd services; phone audio routing still needs verification
- You don't need direct Termux API access (the ADB bridge described above provides sensors, GPS, camera, and input access)
- You're comfortable with experimental software that may lose work on unexpected shutdown
- You want the cleanest Claude Code install experience (official installer, no workarounds)

**Use Path A or B (Termux) when:**
- You have any ARM64 Android 8+ device (Android 8 / 9 have OAuth caveats; see [FAQ](faq.md#claude-prints-a-url-but-my-browser-doesnt-open)) (Samsung, OnePlus, Pixel, etc.)
- You need Termux API features
- You prefer avoiding a separate VM lifecycle. Android can still kill Termux or its child processes; see [battery and background work](install.md#battery-and-background-work).
- You want a proven path that has been tested across multiple devices and Android versions

**Use both when:**
- You want AVF for pure Linux development and Termux for Android API integration
- They coexist on the same device without conflict

---

## Community Resources

| Resource | What |
|----------|------|
| [Android Authority: Memory fix](https://androidauthority.com/android-linux-terminal-memory-fix-3555799/) | zram + swap workaround for OOM (out-of-memory) kills |
| [Android Authority: Pixel 10 GPU acceleration](https://androidauthority.com/pixel-10-linux-apps-gpu-acceleration-3608754/) | GPU support status and device coverage |
| [Android Authority: Desktop Linux apps hands-on](https://androidauthority.com/run-desktop-linux-apps-on-android-how-to-3586539/) | Practical walkthrough of GUI apps in AVF |
| [lfdevs/run-linux-on-android-guide](https://github.com/lfdevs/run-linux-on-android-guide) | Community setup guide |
| [nixos-avf](https://github.com/nix-community/nixos-avf) | NixOS in AVF VM (actively maintained) |
| [Google Issue Tracker: AVF bugs](https://issuetracker.google.com/issues/new?component=190602&template=2068275) | File bugs (no dedicated AVF component; goes to generic Android Platform) |
| [SSH + Tailscale workaround](https://gist.github.com/aschober/eeb316027c5037fc3af5fb0327ab44fd) | Access VM from outside localhost |
| [gunyah-on-sd-guide](https://github.com/polygraphene/gunyah-on-sd-guide) | VMs on Snapdragon via Qualcomm's Gunyah hypervisor (non-stock firmware) |
| [Google source: AVF architecture](https://source.android.com/docs/core/virtualization/architecture) | Official AVF architecture documentation |
| [LPC 2025: "A Linux VM on Android via AVF"](https://news.ycombinator.com/item?id=46262802) | Most detailed technical presentation on AVF internals (Linux Plumbers Conference, Dec 2025) |

---

## Technical Details (For the Curious)

These details were observed during my testing session. They may be useful for advanced users or anyone trying to understand the VM's architecture.

### Virtual Hardware Inventory

The VM includes a rich set of virtual devices (enumerated via lspci):

- Intel 440FX host bridge (compatibility shim)
- Virtio 1.0 GPU (PCI ID 1AF4:1050)
- 3x Virtio console devices
- 2x Virtio block devices (root disk + config)
- Virtio RNG (hardware random number generator)
- 4x Virtio input devices (touchscreen, keyboard, mouse, trackpad)
- Virtio balloon (memory management)
- Virtio network device
- VirtIO SoundCard
- Virtio socket (vsock for VM-host communication)
- Virtio filesystem devices backing `/mnt/shared` (Android shared storage) and `/mnt/backup` (Recovery backup volume)
- PVPanic device (crash reporting)

### Kernel Details

- Linux kernel in the 6.12.x line on my Android 17 devices, built as part of the Android GKI (Generic Kernel Image, Google's standardized Android kernel)
- Monolithic kernel (no loadable modules, `/lib/modules/` empty)
- `CONFIG_SYSVIPC` and `CONFIG_POSIX_MQUEUE` explicitly disabled. Tools that need SysV IPC or POSIX message queues will fail; `fio` is the most common one. `dd` works for disk benchmarks.
- `CONFIG_BPF`, `CONFIG_NETFILTER`, `CONFIG_BRIDGE_NETFILTER`, `CONFIG_KVM`, `CONFIG_FUSE_FS`, `CONFIG_OVERLAY_FS`, `CONFIG_VETH` all enabled
- Seccomp available but not enforced
- No Yama ptrace restrictions

### Running Services

AVF-specific services I observed active on Android 17:
- `forwarder-guest-launcher`: port forwarding between VM and Android
- `storage-balloon-agent`: dynamic storage management
- `ttyd` + `ttyd_vsock_bridge` + `ttyd_uds`: web terminal via vsock (the Terminal app UI)
- `shutdown-runner`: graceful VM shutdown coordination
- `unattended-upgrades`: automatic security updates

OpenSSH, avahi-daemon, and exim4 are installed in the Debian image but not started by default. Enable them with `sudo systemctl enable --now <service>` if you need them.

### crosvm Launch Behaviour

The Terminal app launches the VM via Android's VirtualizationService, which in turn runs `crosvm` with the host CPU topology exposed, dynamic memory ballooning (page reporting) enabled, hugepages, and the host-side audio + filesystem vhost-user sockets wired up. USB passthrough and the kernel PMU (Performance Monitoring Unit) are both disabled. Memory size, display resolution, and graphics-acceleration backend reflect whatever you have set in Settings > Advanced; CID (Context Identifier, used by vsock for VM addressing) and TAP-interface (a virtual network interface) address are assigned per VM launch and are not user-configurable.

---

*Last updated: 2026-08-31. AVF path re-verified end to end on Pixel 6 (Android 17) and Pixel 10 Pro (Android 17) on 2026-05-26. Earlier baseline testing on Pixel 10 Pro, Android 16, dated 2026-04-01. AOSP architecture reference: [source.android.com/docs/core/virtualization](https://source.android.com/docs/core/virtualization). If you test on a different device, please [open an issue](https://github.com/ferrumclaudepilgrim/claude-code-android/issues/new?template=device_report.yml) with your results.*
