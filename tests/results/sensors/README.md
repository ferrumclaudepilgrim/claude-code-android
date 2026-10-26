# Passive Sensor Evidence

These files record stationary, read-only runs of the campaign build of `tests/sensor-probe.c`. The same AArch64 binary was built with Android NDK r29 at API 26 and used on every device. Its SHA-256 was `3545fb5718ac09fff58e12c5c1180431861c8c082dcc14c07fafd681a711cb07`. The checked-in source now reports sensor enable or rate failures as `CONFIG_ERROR`; that stricter reporting was added after these four captures, none of which contained a zero-event target requiring reclassification.

Run date: 2026-08-31.

## Scope

- Execution identity: Android's ADB `shell` identity.
- Sampling: five passive seconds with no requested motion or environmental changes.
- No packages, companion apps, permissions, or Android settings were installed or changed.
- Device serials and other unique identifiers are not recorded.
- A `PASS` means the sensor emitted at least one event during the stationary window.
- `NOT_PRESENT` means the requested standard type was not in the inventory.
- `NOT_TRIGGERED` means the type was present and configured but emitted no event during the passive window. It is not a failure.
- `CONFIG_ERROR` means the probe could not enable the sensor or set its event rate; treat it as a harness or access-boundary error, not a sensor result.

These runs confirm that the NDK sensor interface was enumerable and readable through the ADB `shell` boundary on these devices. They do not establish that the same binary runs under Termux's app identity. Termux `run-as` was unavailable on three phones; the Pixel 6 exposed `run-as`, but its private directories rejected the temporary copy. No permissions or device setup were changed to bypass that boundary.

## Runs

| Device | Android / API | Build | Inventory | Passive target result |
|---|---:|---|---:|---|
| Pixel 10 Pro | 17 / 37 | `CP31.260623.012` | 42 | 10 PASS |
| Pixel 6 | 17 / 37 | `CP31.260623.012` | 37 | 10 PASS |
| Moto G7 Power | 10 / 29 | `QCOS30.85-18-9` | 45 | 9 PASS, pressure NOT_PRESENT |
| Galaxy S7 | 8.0.0 / 26 | `G930PVPSBCTA1` | 35 | 10 PASS |

The raw JSON files contain sensor names, vendors, Android type IDs, resolutions, minimum delays, passive sample counts, and verdicts. Vendor-specific and motion-triggered sensors were enumerated only; none was intentionally triggered.
