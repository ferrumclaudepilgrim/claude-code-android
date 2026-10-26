# Sensor Access from Termux

Native Android sensor access from Termux using the NDK (Native Development Kit) `ASensorManager` API. The evidence below comes from one Samsung Galaxy S26 Ultra running Android 16 in native Termux on ARM64. It describes that device, not every Android phone.

[All add-ons](README.md) · [Access and trust](../security-model.md)

> **Note:** The historical S26 Ultra program used `ASensorManager` from the Android NDK, loaded via `dlsym` at runtime. The checked-in passive probe below uses the API directly. It does not use the `termux-sensor` command, which relies on the Termux:API Java bridge. The two paths have different setup and security boundaries; this page does not benchmark them against each other.

---

## On This Page

- [Summary](#summary)
- [Four-device passive campaign](#four-device-passive-campaign)
- [Hardware inventory](#hardware-inventory)
- [Test results](#test-results)
- [Observations](#observations)
- [Vendor-specific sensors](#vendor-specific-sensors-samsung)
- [Methodology](#methodology)
- [Reproducing](#reproducing)

## Summary

**Nine standard sensor types returned data in the recorded native-Termux test** on a Samsung S26 Ultra (Android 16, ARM64), using a compiled C binary in native Termux linked against `-landroid -ldl`.

The repository now also includes a reproducible passive probe and a four-device evidence set. That newer campaign ran through Android's ADB `shell` identity, not Termux's app identity, so it answers a narrower question: which sensors the NDK interface enumerated and passively emitted through that debugging boundary.

## Four-Device Passive Campaign

On 2026-08-31, the same campaign build of `tests/sensor-probe.c` and AArch64 binary were run for five stationary seconds on four lab phones. No packages, Android permissions, or settings were added or changed. The checked-in probe now distinguishes sensor configuration errors from a configured sensor that emits no event; that reporting improvement was added after the captures and does not change their recorded verdicts.

| Device | Android / API | Sensors enumerated | Passive target result |
|---|---:|---:|---|
| Pixel 10 Pro | 17 / 37 | 42 | 10 PASS |
| Pixel 6 | 17 / 37 | 37 | 10 PASS |
| Moto G7 Power | 10 / 29 | 45 | 9 PASS; pressure NOT_PRESENT |
| Galaxy S7 | 8.0.0 / 26 | 35 | 10 PASS |

The ten targets were accelerometer, magnetometer, gyroscope, light, pressure, proximity, gravity, linear acceleration, rotation vector, and step counter. `PASS` means at least one event arrived during the passive window. `NOT_PRESENT` means that Android sensor type was absent. Motion-dependent and vendor-specific sensors were inventoried but not deliberately triggered.

See [`tests/results/sensors/`](../../tests/results/sensors) for the protocol, scope, build identifiers, raw inventories, sample counts, and verdict definitions. These results do not extend the original S26 Ultra native-Termux claim to the four lab phones: attempts to transfer the probe into their Termux app identity were unavailable or denied, and no device setup was changed to bypass that boundary.

---

## Hardware Inventory

45 sensors detected via ASensorManager on the test device (Samsung S26 Ultra, Android 16). Counts vary by device and enumeration API. The [historical AVF/ADB inventory below](#adb-inventory-from-the-avf-guide) lists 42 entries on a different device and Android build. These include fused/software entries, not necessarily 42 distinct physical sensors.

Key sensors:

| Type | Sensor | Status |
|------|--------|--------|
| 1 | Accelerometer | WORKS |
| 2 | Magnetometer | WORKS |
| 4 | Gyroscope | WORKS |
| 5 | Light (ALS, Ambient Light Sensor) | WORKS |
| 6 | Pressure (Barometer) | WORKS |
| 8 | Proximity | WORKS (event-driven, 1 sample per change) |
| 9 | Gravity (fused) | WORKS |
| 10 | Linear Acceleration (fused) | WORKS |
| 11 | Rotation Vector (fused) | Not tested |
| 19 | Step Counter | WORKS (cumulative since reboot, fires on step events) |

Device-specific sensors (tilt detector, pick-up gesture, auto-rotation, motion detect, etc.) were also present but not tested. The number and type of device-specific sensors will vary by manufacturer.

---

## Test Results

### Test 1: Multi-Sensor Quick Read (5 samples each)

All 8 quick-read sensor types returned data (step counter confirmed separately during walking test):

- **Accelerometer**: x=0.49, y=3.23, z=9.25 m/s^2 (phone tilted ~20 deg from vertical)
- **Magnetometer**: x=40.3, y=30.1, z=-36.0 uT (indoor magnetic field, stable)
- **Gyroscope**: x=0.02, y=-0.08, z=0.04 rad/s (slight rotation while held)
- **Light**: 1050-1341 lux (the SI unit for illuminance; bright indoor, fluctuating)
- **Pressure**: 1012.95 hPa (hectopascals, the standard meteorological unit; sea-level-equivalent indoor pressure)
- **Proximity**: 5.00 cm (binary sensor, max distance = nothing close)
- **Gravity**: x=0.94, y=3.14, z=9.24 m/s^2 (device orientation)
- **Linear Accel**: near zero (stationary baseline)

### Test 2: 30-Second Walking Capture

#### Accelerometer (301 recorded samples)

| Metric | Value |
|--------|-------|
| Samples | 301 |
| Mean magnitude | 9.824 m/s^2 |
| Min magnitude | 0.000 m/s^2 |
| Max magnitude | 10.763 m/s^2 |
| Range | 10.763 m/s^2 |

The magnitude oscillation (9.0 to 10.8) around gravity (9.81) is the classic walking signature: each footstrike creates a vertical acceleration spike.

#### Barometric Pressure (300 samples over 24 seconds)

| Metric | Value |
|--------|-------|
| Samples | 300 |
| Duration | 24.0 seconds |
| Mean | 1013.910 hPa |
| Min | 1013.537 hPa |
| Max | 1014.251 hPa |
| Range | 0.714 hPa |
| Net drift | -0.033 hPa |

The observed range was 0.714 hPa over 24 seconds, with a net change of -0.033 hPa. A short capture cannot separate environmental change, handling effects, and sensor drift, so treat this as a device-specific sample rather than a calibration result.

#### Gyroscope (291 samples over ~29 seconds)

| Metric | Value |
|--------|-------|
| Samples | 291 |
| Mean magnitude | 0.163 rad/s |
| Min magnitude | 0.003 rad/s |
| Max magnitude | 1.057 rad/s |
| Range | 1.053 rad/s |

Peak rotation of 1.057 rad/s (about 60 deg/s) indicates turns while walking.

---

## Observations

1. **Nine listed standard sensor types returned data from native Termux** using the ASensorManager NDK API loaded via `dlsym`. This run needed no JNI, root, or proot.

2. **Sensor rates:** the historical notes mix requested/event rates and captured sample counts, so they do not establish a reliable accelerometer or gyroscope delivery rate. Preserve the recorded counts above; measure timestamps on your device before relying on a rate. For unit reference, 125 Hz means 8 ms between events, not 10 ms.

3. **Proximity sensor** is event-driven (only fires on change), so it returned just 1 sample in 5 attempts. This is correct behavior.

4. **Step counter** reports cumulative steps since last reboot and only fires on step events. A longer capture during active walking would show incrementing values.

5. **The walking signature is clearly visible** in the accelerometer data: magnitude oscillates around 9.81 m/s^2 with each footstrike pushing it to ~10.8 and each flight phase dropping it below 9.0.

6. **Barometric pressure was readable** at 0.01 hPa resolution on this device. Floor-level detection would require calibration and longer testing that this capture did not perform.

---

## Vendor-Specific Sensors (Samsung)

The sensor reader supports vendor-specific sensor types (type IDs above 65536) via list-scan fallback when `getDefaultSensor` returns NULL. On my Samsung Galaxy S26 Ultra (Android 16), these Samsung-specific sensors were detected and resolved:

| Type ID | Name | Vendor | Status |
|---------|------|--------|--------|
| 65605 | Pocket Mode | Samsung | Resolved (event-driven, awaiting trigger) |
| 65644 | Drop Classifier | Samsung | Resolved (event-driven, awaiting trigger) |
| 65648 | Car Crash Detect | Samsung | Resolved (event-driven, awaiting trigger) |
| 65651 | Back Tap | Samsung | Resolved (event-driven, awaiting trigger) |
| 65655 | Elevator Detector | Samsung | Resolved (event-driven, awaiting trigger) |

Note: these are event-driven wakeup sensors. They resolve via the NDK API but only produce data when their physical trigger occurs (phone dropped, back tapped, elevator entered, etc.). Availability varies by device manufacturer and model. Non-Samsung devices will have different vendor-specific sensors or none.

---

## ADB Inventory from the AVF Guide

In the maintainer's **Pixel 10 Pro / Android 16 check on 2026-04-01**, `adb shell dumpsys sensorservice` listed 42 sensor entries. This is a historical inventory for that device and access route, not a required count or a promise of 42 working streams. It is separate from the later four-device NDK campaign. The categories recorded were:

| Category | Sensors | Example Chips |
|----------|---------|---------------|
| **Motion** | Accelerometer, gyroscope (calibrated + uncalibrated), linear acceleration, gravity, rotation vectors (3 types), orientation | ICM45631 (Invensense) |
| **Magnetic** | Magnetometer (calibrated + uncalibrated), geomagnetic rotation vector | MMC5616 (MEMSIC) |
| **Environmental** | Barometer, ambient light, color sensor, rear light | SPL07003 (Goermicro), TMD3743 (AMS), VD6282 (STMicro) |
| **Proximity/Gesture** | Proximity, tilt, lift to wake, significant motion, device orientation | TMD3743 (AMS), Google fusion |
| **Activity** | Step detector, step counter (require ACTIVITY_RECOGNITION permission) | Google fusion |
| **Temperature** | Gyro temperature, pressure temperature | Invensense, Goermicro |
| **Camera/System** | Camera V-Sync (4 instances), dynamic sensor manager, motion detect, stationary detect | Google, ICM45631 |

Sensors ranged from 10Hz (proximity) to 400Hz (accelerometer/gyroscope). Several were actively reporting data at the time of the query.

**Limitation:** `dumpsys sensorservice` shows which sensors exist, their sampling rates, and which are currently active, but does not expose raw X/Y/Z values in a pipeable format. See [pipeline limits](../avf-guide.md#needs-pipeline-work) before treating an inventory as a stream of usable readings.

## Methodology

The historical S26 Ultra program was compiled in native Termux, linked against `-landroid -ldl`. This describes that program, not the checked-in passive probe. At runtime it:

1. Loads `libandroid.so` via `dlopen`
2. Resolves `ASensorManager_getInstance`, `ASensorManager_getSensorList`, `ASensorManager_createEventQueue`, etc. via `dlsym`
3. Enumerates all available sensors
4. For each target sensor type, enables it, polls for events, and prints timestamped readings
5. Disables the sensor and moves to the next

No root permissions, no Java bridge, no proot environment required. The binary runs directly in the native Termux environment.

---

## Reproducing

The reproducible passive reader is [`tests/sensor-probe.c`](../../tests/sensor-probe.c), and its four-device results are under [`tests/results/sensors/`](../../tests/results/sensors). It inventories every sensor visible through `ASensorManager`, enables ten standard target types together, samples passively for five seconds, and writes one JSON document to standard output.

To build a reader of your own, you need:

```bash
pkg install clang -y
```

The recorded four-phone campaign used **NDK r29, Android API 26**, under the ADB `shell` identity; it did not verify execution inside each Termux app. The probe needs API-26-or-newer sensor headers. See the [build and execution evidence](../../tests/results/sensors/README.md).

The following native-Termux build is an **untested starting point**, not the command used for those captures. From a [repository checkout](skills.md#get-a-repository-checkout), with a compatible compiler target:

```bash
clang tests/sensor-probe.c -o sensor-probe -landroid -llog
./sensor-probe > sensor-result.json
```

The command does not request permissions or change settings. Review the JSON before sharing it; sensor names and build context can still reveal device details. The Android NDK sensor types are defined in `<android/sensor.h>`. Numeric standard type codes such as 1 for accelerometer and 2 for magnetometer are stable across Android versions.

---

*Historical S26 Ultra program: native Termux, March 2026. Checked-in probe campaign: four ADB-shell runs, 2026-08-31.*

*Documentation reviewed: 2026-10-25. No new sensor or Termux build tests were performed.*
