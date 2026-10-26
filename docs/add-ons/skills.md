# Skills and Scripts for Claude Code on Android

Help Claude understand the phone it is running on, then add useful checks and workflows. These are optional; get the [installation](../install.md) working first.

[All add-ons](README.md) · [Access and trust](../security-model.md)

## Help Claude understand your setup

A project `CLAUDE.md` supplies persistent instructions. A skill supplies guidance when its task is relevant. Use them for different jobs:

| Place | Put this there |
|---|---|
| Project `CLAUDE.md` | Verified Path A/B/C, project folder, host-versus-guest commands, preferred tools, and scope. Start with the [optional template](project-instructions.md). |
| `.claude/skills/NAME/SKILL.md` | Reusable guidance for a particular task. |
| `~/.claude/skills/NAME/SKILL.md` | A personal skill available across your projects on that device. |

Do not paste a full environment dump, tokens, account files, or pairing codes into instructions. Record a small set of useful facts and when you checked them.

### The included termux-safe skill

[`termux-safe`](../../.claude/skills/termux-safe/SKILL.md) helps avoid desktop-Linux assumptions about Termux paths, sudo/systemd, process limits, and native versus pinned installations. It is task guidance, not enforcement or live device detection.

**Known limit to review:** its low-port rule is too absolute for some current Termux builds. Prefer ports 1024+ for compatibility, but newer Android/kernel builds can allow lower ports. For command lookup, use the shell builtin `command -v`; `which` is also available as a package. Sources: [Termux low-port report](https://github.com/termux/termux-packages/issues/30246), [which package](https://github.com/termux/termux-packages/blob/master/packages/which/build.sh).

### When skills load

Current Claude Code normally sees skill descriptions first and loads a skill's body when invoked. Most skills can also be started with `/name`; this repo's `termux-safe` sets `user-invocable: false`, so it is hidden from that direct menu. Discovery is not proof that the instructions were used correctly.

Current upstream supports dynamic shell context in skills and SessionStart hooks that add context. Those execute code; they are not needed just to record environment facts. `CLAUDE_ENV_FILE` persists shell environment assignments, which is different from adding model context. Check feature availability on pinned `2.1.112` before using newer examples. [Skills](https://code.claude.com/docs/en/skills) · [Memory](https://code.claude.com/docs/en/memory) · [Hooks](https://code.claude.com/docs/en/hooks).

## Get a repository checkout

In ordinary Termux, install Git if needed, then clone the public repository and enter it:

```bash
pkg install git
git clone https://github.com/ferrumclaudepilgrim/claude-code-android.git
cd claude-code-android
```

Review files before running or copying them. The relative `scripts/`, `tests/`, `.claude/`, and `examples/` commands in these guides start from this repository root. Use an existing checkout if you already have one.

## Installing Skills Globally

From a reviewed clone of this repository, copy the skill to your personal skill directory. `-i` asks before overwriting existing files:

```bash
mkdir -p ~/.claude/skills
cp -r -i .claude/skills/termux-safe ~/.claude/skills/
```

Review its known limits above first. Project-local installation uses the project's `.claude/skills/` instead.

## Check or repair your setup

Run from a repository checkout after reading the script:

| Script | Use it for | Important limit |
|---|---|---|
| [`check-termux-env.sh`](../../scripts/check-termux-env.sh) | Termux / Path A and pinned-install diagnostics | Calls `claude --version`, which can trigger the wrapper's update/download/probe. **Not guaranteed read-only**, and not a Path B/C health check. Termux:API PASS checks command presence, not its companion or grants. |
| [`fix-ripgrep.sh`](../../scripts/fix-ripgrep.sh) | Pinned/older npm search failures | Can install ripgrep, unlock the vendor tree, write a symlink, and relock it. Use only for the [matching failure](../troubleshooting.md#grepglobslash-commands-fail-with-enoent-v2x-install). |

```bash
bash scripts/check-termux-env.sh
```

A warning about an optional API does not necessarily mean Claude is broken. Do not install phone integrations just to turn every diagnostic green.

## Post-install skills worth building next

**Proposals, not shipped features.** Start with a manually invoked setup check, then add separate workflows only where they earn their place:

| Idea | Useful result | Boundary |
|---|---|---|
| **Environment check** | Explain Path A/B/C, installed tools, storage, and likely next steps in plain language. | A genuinely read-only mode must avoid invoking the auto-updating wrapper. No environment/credential dumps. |
| **Battery and background work** | Choose between a normal session, screen-off SSH, or a long task; explain wake locks, child-process limits, and AVF Keep awake. | Show battery/heat costs and how to undo changes; do not silently change settings. |
| **Project starter** | Pick a project folder, language tools, and useful `CLAUDE.md` facts from what is actually installed. | Ask before packages or changes outside that project. |
| **Diagnose and recover** | Match a symptom to one procedure and explain what each recovery command changes. | No automatic wipes, reinstalls, or cache deletion. |
| **Review phone access** | Explain enabled storage/API/ADB/MCP access and which pieces a workflow needs. | Review first; do not read personal phone contents or enable permissions automatically. |

[Maintainer checks and saved results](../../.github/CONTRIBUTING.md#testing-and-verification) belong to contributor testing, not post-install setup.
