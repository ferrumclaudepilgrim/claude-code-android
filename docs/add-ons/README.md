# Build with Android

Get Claude running first. Then add the parts that help you build.

**Everything here is optional.** These guides are not another installation checklist, and the installer does not enable the hooks or copy skills into your projects.

## Help Claude understand your project

- **[Project instructions: `CLAUDE.md`](project-instructions.md):** record your setup, project scope, and preferences. Start with the template and keep only what fits.
- **[Skills and useful checks](skills.md):** add reusable task guidance, understand the included Termux skill, or choose a diagnostic for a specific problem.

## Choose tools and confirmations

- **[Agent permissions](agent-permissions.md):** give research, editing, and review the tools they need. Instructions and enforced permissions do different jobs.
- **[Fingerprint gate](fingerprint-gate.md):** an experimental biometric confirmation hook. Requires Termux:API; review its bypass and failure limits before using it.
- **[SSRF guard](ssrf-guard.md):** an example hook that checks selected web-tool URL strings. It does not contain shell networking or MCP traffic.

## Use phone capabilities

- **[ADB](adb-wireless.md):** connect to Android's debugging interface for operations ordinary Termux cannot perform. Pair deliberately and turn wireless debugging off when finished.
- **[Sensors](sensors.md):** compare access methods and dated device results. Available sensors and usable readings vary by phone.

> [!TIP]
> Start with one thing you want to build. Add instructions, tools, and phone access as that work needs them.

[Installation](../install.md) · [Access and trust](../security-model.md)
