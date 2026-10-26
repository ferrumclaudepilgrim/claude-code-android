# ADB Wireless Self-Connect on Android

Connect your phone to itself over ADB (Android Debug Bridge, the standard tool for sending commands to an Android device). No computer and no USB cable are required. ADB adds selected Android debugging capabilities that the ordinary Termux app identity cannot use. It does not grant root, defeat every app protection, or make results identical across Android builds.

[All add-ons](README.md) · [Access and trust](../security-model.md)

Read the [layered security model](../security-model.md#what-adb-adds) before enabling wireless debugging on a personal phone.

## On This Page

- [Decide whether you need ADB](#decide-whether-you-need-adb)
- [Compare capabilities](#before-and-after)
- [Set up and connect](#setup)
- [Use the connection](#after-connecting)
- [Reconnect](#connection-persistence)
- [Understand the security tradeoff](#security)
- [Choose ADB or Termux:API](#when-to-use-adb-vs-termuxapi)
- [Troubleshoot](#troubleshooting)

---

## Decide Whether You Need ADB

Claude Code does not require ADB. Use wireless debugging only when a task needs an ADB-only capability such as screenshots, input injection, package inspection, or selected system settings. If Termux already provides the command you need, or Termux:API provides it with a specific Android permission, leave wireless debugging off.

ADB and Termux:API are only two optional access routes. Shared storage, MCP servers, OAuth callbacks, web tools, shell networking, and credentials in the current environment remain separate surfaces. See the [security model](../security-model.md) for the complete set of trust boundaries.

Selected Android services reject the Termux app identity. The following are examples of restricted operations, not proof every system binary is blocked; access depends on Android and OEM policy. See the official [Termux execution environment](https://github.com/termux/termux-packages/wiki/Termux-execution-environment) reference:

```
/system/bin/screencap   → Operation not permitted
/system/bin/settings    → Operation not permitted
/system/bin/pm          → Operation not permitted
/system/bin/dumpsys     → Operation not permitted
```

ADB wireless debugging provides a separate route. The phone connects to itself via `127.0.0.1`, and `adb shell` runs as Android's `shell` debug identity, which can call many system services and binaries that the Termux app UID cannot. The Termux session calls `adb`, which talks to the ADB daemon running on the same device. SELinux, platform permissions, secure-window flags, and vendor policy still apply.

**Requires:** WiFi (Android checks for a WiFi association, not internet access). Does not require root.

> This is the pairing-code wireless-debugging workflow documented for Android 11+ phones. Menus, ports, and connection persistence vary by Android build and ADB version; see the [Android ADB reference](https://developer.android.com/tools/adb). This is not a fresh self-connect test on every supported release.

---

## Before and After

<a id="capabilities-that-require-adb"></a>

### Capabilities available through ADB

| Capability | Termux (no ADB) | With ADB | Risk/Exposure |
|------------|-----------------|----------|---------------|
| Screenshot | Blocked | `adb shell screencap` | Captures visible content unless the app or device marks the window secure |
| System settings (brightness, DND) | Blocked | `adb shell settings get/put` | Can modify device configuration |
| Calendar events | Blocked | `adb shell content query` | May expose calendar data on builds whose provider permits the `shell` identity |
| Installed apps list | Blocked | `adb shell pm list packages` | Full app inventory visible |
| Full battery details | Blocked | `adb shell dumpsys battery` | Device state information |
| Touch/key injection | Blocked | `adb shell input tap/swipe/text` | Can operate many UI surfaces; secure/system surfaces may reject input |
| Process list | Visibility restricted by Android | `adb shell ps -A` (broader process view) | May expose process and app activity; visibility varies |
| Activity manager | Partial | `adb shell am start/force-stop` | Can launch or stop many apps, subject to platform restrictions |
| Device properties | Many properties readable with `getprop`; others restricted | `adb shell getprop` | Hardware and build identifiers |

### Capabilities that work without ADB (Termux API)

| Capability | Termux (no ADB) | With ADB |
|------------|-----------------|----------|
| Battery % (basic) | `termux-battery-status` | Both work |
| Camera capture | `termux-camera-photo` | Both work |
| TTS | `termux-tts-speak` | Both work |
| Clipboard | `termux-clipboard-get/set` | Both work |
| GPS location | `termux-location` | Both work |
| SMS | `termux-sms-list/send` | Both work |
| Notifications | `termux-notification-list` | Both work |
| Background scheduling | `crond` (a background task scheduler) / job-scheduler | Both work |
| Volume control | `termux-volume` | Both work |
| Vibration | `termux-vibrate` | Both work |
| Wifi info | `termux-wifi-connectioninfo` | Both work |
| Sensors | `termux-sensor` | Both work |

The first group describes an ADB route, not a claim that every listed capability is impossible through all other APIs. Device properties are an explicit example available in ordinary Termux too. The second group uses Termux:API without ADB, but still depends on the companion app, Android permission grants, and version-specific background restrictions.

> **Note:** The Termux API rows require the **Termux:API companion app** installed from the same source as Termux (both from F-Droid, the open-source Android app store, or both from GitHub). Mixing sources causes signature mismatches and silent failures.

---

## Setup

### Prerequisites

Install `android-tools` in Termux:

```sh
pkg install android-tools
```

### Step 1: Enable developer options

Go to **Settings → About phone → Software information**, tap **Build number** 7 times. Developer options is now unlocked.

### Step 2: Enable wireless debugging

Go to **Settings → Developer options → Wireless debugging** and toggle it on. You'll see a confirmation dialog. Accept it.

### Step 3: Open the pairing dialog

Inside Wireless debugging, tap **Pair device with pairing code**. A dialog appears with a temporary pairing code and a pairing port. The pairing port is different from the connection port used in Step 5.

Keep Settings and Termux in split-screen if possible so the dialog stays open. Do not save or share the pairing code in screenshots or logs.

### Step 4: Pair

In **Termux**, enter the pairing port shown on your phone:

```bash
read -r -p "Pairing port shown in Settings: " pairing_port
adb pair "127.0.0.1:$pairing_port"
```

ADB prompts for the temporary pairing code. Type the code from Settings; it is not part of the command or this guide. A successful result says the device was paired.

**If pairing reports a protocol fault:** reopen the pairing dialog, check its current port, and retry. See [troubleshooting](#troubleshooting).

### Step 5: Connect

After pairing, return to the main Wireless debugging screen. Read its **IP address & Port** connection port, then enter that port in Termux:

```bash
read -r -p "Connection port shown in Settings: " connection_port
adb connect "127.0.0.1:$connection_port"
```

A successful result says `connected to` followed by the address you entered.

Verify it's working:

```sh
adb shell getprop ro.build.version.release
```

This should return your Android version number.

---

## After Connecting

### Take a screenshot

```sh
adb shell screencap /sdcard/screen.png
adb pull /sdcard/screen.png ~/screen.png
```

### Read system settings

```sh
# Get current brightness
adb shell settings get system screen_brightness

# Get DND mode
adb shell settings get global zen_mode
```

### Query calendar

```sh
NOW=$(date +%s%3N)
adb shell content query --uri content://com.android.calendar/events \
  --projection title:dtstart:dtend:description \
  --where "dtstart\>$NOW"
```

### List installed apps

```sh
adb shell pm list packages
# Third-party only:
adb shell pm list packages -3
```

### Inject input

**These are syntax examples, not recorded device values or ready-to-run commands.** Replace the uppercase labels with coordinates for your own screen. Input goes to the focused app, so use a harmless test field first.

```text
adb shell input tap X Y
adb shell input text "EXAMPLE_TEXT"
adb shell input swipe START_X START_Y END_X END_Y DURATION_MS
```

The swipe example is a general gesture, not a lock-screen bypass.

---

## Connection Persistence

The ADB connection may drop on screen lock, app switch, or reboot, depending on the device. The paired key usually persists, so reconnecting normally does not require a new pairing. After a reboot:

1. Re-enable Wireless debugging (it toggles off on reboot on some devices).
2. Note the new connection port (it changes on each enable).
3. Run `adb connect 127.0.0.1:<new-port>`.

There is a catch when you try to automate this. Reading the port with `adb shell` requires ADB to already be connected, so it cannot bootstrap the first connection of a session. After a reboot you still read the new port from the Wireless debugging screen by hand. Once you are connected, this command confirms the active port:

```sh
adb shell settings get global adb_wifi_port
```

The port is only stable within a session. If your automation needs ADB, check the connection at the start of each run.

---

## Without WiFi

ADB wireless debugging requires WiFi association. Android checks whether the wifi radio is connected to an access point, not whether the internet is reachable. A router with no internet connection works.

**What works without WiFi (Termux API, no ADB required):** all the Termux API capabilities listed in the "Capabilities that work without ADB" table above. None of them need a network connection.

**Approaches for ADB without a router:**

1. **Phone hotspot:** enable your phone's mobile hotspot. The AP interface typically gets a static IP (often `192.168.43.1`). `adbd` (the on-device ADB daemon) binds to all interfaces. After enabling hotspot, pair and connect using that IP rather than `127.0.0.1`. Untested across all devices; your AP interface IP may differ.

2. **Session persistence after WiFi drop:** some users report that an established ADB connection survives a WiFi drop in the same session (the radio goes down but the TCP connection stays alive briefly). Not reliable across reboots or long gaps.

---

## Security

### What the attack surface looks like

Wireless debugging enabled means your device is listening for ADB connections on a WiFi-routable port. Anyone on the same WiFi network can attempt to pair.

**Mitigations Android provides:**
- Pairing requires a code displayed on-screen. Remote attackers cannot see your screen.
- Each pairing is explicit; you approve it by opening the pairing dialog.
- The connection is tied to the paired key. Without pairing first, a connection attempt fails.

**What to watch for:**
- Public WiFi networks (cafes, hotels, airports): disable Wireless debugging when you're on networks you don't control. Anyone on the same subnet could attempt to pair.
- Shared home networks with untrusted devices: same consideration.
- The connection port changes on each session, which slightly reduces attack surface, but determined local network attackers can scan for it.

### Practical security posture

I suggest limiting ADB wireless debugging to a trusted network and turning it off when you finish. Pairing and authorized keys make opportunistic access harder, but they do not close the network listener or protect against a compromised paired client.

For public WiFi: disable Wireless debugging. Re-enable when you're back on a trusted network.

### What ADB shell can access

`adb shell` runs as Android's `shell` identity. It has system-facing debugging permissions that ordinary apps do not, but it is less privileged than root and remains constrained by SELinux and platform policy. It can inspect many system services and selected logs, query or change some settings, inject input into many surfaces, and attempt content-provider queries. On current stock devices it is still blocked from most private app data, protected partitions, hardware-backed Keystore secrets, secure windows, and other restricted services. Exact behavior varies by Android and vendor build.

---

## When to use ADB vs Termux:API

These are different access mechanisms with different security postures. Pick the lighter-weight one when it's enough.

| You want to... | Use | Why |
|---|---|---|
| Battery status, notifications, clipboard, vibration, TTS, GPS, camera | **Termux:API** | App-level permission, per-permission grants, no network-accessible port |
| Read SMS or contacts | **Termux:API** (with explicit Android permission grant) | ADB also works but requires the wireless port to be open |
| Take a screenshot outside Termux | **ADB** | Subject to secure-window and device-policy restrictions |
| Inject touch/swipe/text into other apps | **ADB** | Subject to secure/system-surface restrictions |
| Query `dumpsys`, full process list, system settings | **ADB** | Termux's app sandbox blocks these |
| Read system logs (logcat) | **ADB** | Same reason |
| Attempt to read calendar events | **ADB** content-provider query (Termux:API does not expose calendar) | Provider access varies by Android build |
| Run cron-style automation without UI access | Either, neither requires UI | n/a |

If you only need the Termux:API category, do not enable wireless debugging. The pairing-code requirement provides reasonable protection on trusted networks, but the simplest security posture is "the port is closed." Pair only when you actually need the ADB-only capabilities.

Neither choice controls shared-storage access, MCP servers, OAuth callbacks, WebFetch/WebSearch, or network commands run through Bash. Review those separately in the [layered security model](../security-model.md).

If you need both: enable ADB only while you're actively using its capabilities, then toggle it off in Developer Options.

---

## Troubleshooting

**`adb: command not found`**
```sh
pkg install android-tools
```

**`error: protocol fault (couldn't read status message): Success`**
Run the `adb pair` command again. Known bug in ADB 35.x (reports as version 1.0.41 in `adb version` output), usually resolves on retry.

**`failed to connect to 127.0.0.1:<port>: Connection refused`**
Wireless debugging may have toggled off (happens on some devices after screen lock). Go back to Developer options, toggle it back on, get the new port, reconnect.

**Pairing dialog dismissed before you got the port**
Open the dialog again. A new code and port will be generated. The old pairing (if you had one) is not affected.

**`adb shell screencap` returns empty or corrupted file**
Some devices need the path specified differently:
```sh
adb shell screencap -p /sdcard/screen.png
```

**Connection drops frequently**
Android may be toggling WiFi sleep. Go to **Developer options → WiFi scan throttling** (disable) and ensure the screen-off WiFi setting does not put the radio to sleep.

---

## Summary

ADB wireless self-connect gives Termux-based tools a separate route to selected Android debugging APIs that the Termux app sandbox cannot use directly. Setup takes about five minutes on devices that support wireless debugging. Once paired, reconnecting is usually a single command. Termux:API features remain a separate, app-permission-based surface; ADB adds to them rather than replacing them.

---

*Documentation reviewed: 2026-10-25. No new pairing or device test was performed.*
