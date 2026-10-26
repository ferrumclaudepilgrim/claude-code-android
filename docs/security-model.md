# Security Model: Claude Code on Android

Running a coding agent on a personal phone puts a powerful shell next to personal files, accounts, sensors, and developer bridges. Keep the environment smaller than the task.

> [!TIP]
> **Start here:** coding needs neither phone permissions nor ADB. The short map below tells you what extra access changes. The rest is reference for when you add it.

[Install](install.md) · [Optional add-ons](add-ons/README.md) · [ADB setup](add-ons/adb-wireless.md)

## Trust Boundaries at a Glance

| Surface | What becomes reachable | Your choice |
|---|---|---|
| **Termux shell and files** | Projects, shell config, credentials, and network programs available to the Termux app identity | Keep project scope narrow; inspect consequential tool calls. |
| **Shared storage** | Android files exposed through a storage grant | Add only when needed; copy a single required file instead of exposing a collection where practical. |
| **Termux:API** | Permission-backed phone features | Install deliberately and grant only the needed permissions. |
| **ADB** | Selected system services, screen/input controls, settings, and diagnostics | Separate debug identity; pair only for tasks that need it. |
| **MCP, web, and shell networking** | Remote services and data entering or leaving the agent's context | Review each channel, its operator, and its access. |
| **Path A's DNS helper** | Runtime resolver queries default to Google DNS | Check the tradeoff if you depend on private or VPN-provided DNS. |

`install.sh` does not grant Android permissions, enable shared storage/ADB, configure MCP, or install optional hooks. **Its current recommended-tool bundle does include the Termux:API command package.** That does not install the companion app or grant permissions, but an existing companion's grants may already be usable. For a deliberate manual choice, see [optional API setup](install.md#termuxapi-explicit-optional-setup).

## Ordinary Termux Filesystem and Shell Access

Processes in Termux share its Android app identity. Claude can reach files and commands permitted by its tools: projects, shell startup files, tokens, SSH material, and other Termux data may be beside one another.

Android's app sandbox still restricts access to other apps' private data. Ordinary Termux is not root. Filesystem permissions, SELinux, and service policy differ by Android/OEM build; not every system command is available. See the [Termux execution environment](https://github.com/termux/termux-packages/wiki/Termux-execution-environment).

Claude Code permissions add checks inside Claude. Current Read/Edit rules also cover recognized shell file commands and redirections, but not every indirect access by Python or another subprocess. **This repository does not enable an OS sandbox by default.**

## Shared-Storage Exposure

`termux-setup-storage` requests Android storage access and creates links under `~/storage`. What becomes visible depends on the Android release and grants. Photos, downloads, documents, or backups may be included.

This is separate from installing Claude. Revoking a permission stops future access; it does not undo copies already made or data already sent.

## What Termux:API Permissions Expose

Termux:API needs a command package plus a companion Android app signed for the same Termux source. Its permissions belong to that companion, not one Claude session.

Depending on Android permissions and device support, commands can expose location, SMS, contacts, call history, camera, microphone, clipboard, notifications, sensors, and biometric prompts. Any process in the Termux environment can attempt the granted commands. Android may still deny a feature or impose background restrictions.

Claude Code itself does not require this integration. Revoke grants you no longer need. **Termux:API is not ADB**; disabling one does not disable the other.

## What ADB Adds

`adb shell` uses Android's separate `shell` debug identity. It can access selected system services that ordinary Termux cannot: package inspection, some logs/settings, screen capture, and input control. It is not root; SELinux, secure windows, provider permissions, and OEM policy still apply.

Wireless debugging opens a network listener and uses pairing keys. Pair on a trusted network, then disable it when finished. A compromised paired client remains a risk. Developer options alone do not enable ADB. Follow [ADB setup and limits](add-ons/adb-wireless.md) when you need it.

<a id="path-a-forces-google-dns-for-claude-codes-own-lookups"></a>

## Path A's DNS Resolver Default

Path A preloads `~/.local/share/claude/setdns.js` through `BUN_OPTIONS`. Its default is:

```javascript
require("dns").setServers(["8.8.8.8", "8.8.4.4"])
```

This works around an observed connectivity hang. It changes a resolver in Claude's bundled runtime, not Android's system DNS. Paths B/C do not use it; an existing nonempty helper is retained and can differ.

**Queries using that resolver go to Google instead of your configured private resolver.** This does not prove every network lookup uses it or that packets bypass a VPN tunnel. Node's [DNS reference](https://nodejs.org/api/dns.html#dnssetserversservers) distinguishes `resolve`/`reverse` from `lookup`; this repo's runner checks `dns.resolve4`, not every network path. Changing servers is possible, but an unreachable replacement can bring the hang back. See [DNS troubleshooting](troubleshooting.md#claude-hangs-on-checking-connectivity--etimeout--api-error-on-every-message).

## Path A Download Trust and Startup Probes

Path A downloads the binary and checksum manifest from Anthropic, verifies the hash, then patches the binary. This catches transfer corruption, not a compromised source serving both files. You also trust this repository's installer and launcher.

The wrapper's `--init-only` probe checks startup, not all features. A temporary HOME does not guarantee isolation: the working directory and variables such as `CLAUDE_CONFIG_DIR` remain inherited. Current upstream docs say this mode can run Setup and SessionStart hooks. Do not treat the probe as a sandbox. [CLI reference](https://code.claude.com/docs/en/cli-reference) · [Settings](https://code.claude.com/docs/en/settings).

## MCP, OAuth, Web, and Shell Networking

These are independent channels:

- **Local MCP:** another process with the files and environment available to its launch identity.
- **Remote MCP:** requests and tool data go to that server; review its operator and OAuth scopes.
- **OAuth:** browser sign-in may return to a temporary localhost listener. Termux, Ubuntu, and VM routing can differ.
- **Web tools:** WebFetch/WebSearch have their own permissions and hook behavior.
- **Bash:** curl, Git, SSH, package managers, runtimes, and custom programs can reach the network independently.

Filtering one channel does not filter the others. This repository provides no general outbound data boundary.

## Optional Controls and Their Limits

| Control | Helps with | Does not establish |
|---|---|---|
| [Agent permissions](add-ons/agent-permissions.md) | Separate responsibilities and narrow available tools | A role name or prompt does not enforce file/network scope. |
| [SSRF guard](add-ons/ssrf-guard.md) | Selected literal URL patterns | No DNS, redirect-chain, Bash, or MCP enforcement. |
| [Fingerprint gate](add-ons/fingerprint-gate.md) | Biometric confirmation for matched Bash strings | No coverage of unmatched forms, other tools, or all hook failures. |
| [Project instructions (`CLAUDE.md`)](add-ons/project-instructions.md) | Record your environment, scope, and preferences | Instructions are not runtime permission enforcement. |

The hook examples are optional and need integration/failure testing. Current Claude Code has [sandbox controls](https://code.claude.com/docs/en/sandboxing), but verify support on your Android path before claiming an OS boundary. The [permissions reference](https://code.claude.com/docs/en/permissions) is authoritative for your installed release.

## Recommended Setup for Minimal Risk

1. Start with a dedicated project in ordinary Termux; add access when a task needs it.
2. Keep storage grants, API permissions, ADB, and MCP as separate choices.
3. Read consequential commands and their targets before approval. External pages, repositories, and tool responses can contain prompt injection.
4. Avoid unattended jobs combining sensitive phone access with broad networking.
5. Keep recoverable backups outside the agent's writable scope.

Documentation reviewed: 2026-10-25. No new device or sandbox verification was performed.
