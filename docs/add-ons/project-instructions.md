# Optional Android `CLAUDE.md` Starter

This template helps Claude Code understand one Android setup and one project. It is optional: copy only useful sections, replace every placeholder, and delete instructions that do not match how you work.

[All add-ons](README.md) · [Access and trust](../security-model.md)

Save the result as `CLAUDE.md` in your project root. Project instructions can influence Claude's behavior, but they do not replace Claude Code's permissions or Android's security controls.

## Setup Record

```markdown
# Project instructions

## Android setup

- Installation path: PATH_A_NATIVE_TERMUX | PATH_A_PINNED_NODE | PATH_B_PROOT_UBUNTU | PATH_C_AVF
- Device model: YOUR_DEVICE_MODEL
- Android version/API: YOUR_ANDROID_VERSION_AND_API
- Termux source and version: YOUR_TERMUX_SOURCE_AND_VERSION
- Project directory: YOUR_PROJECT_DIRECTORY
- Last verified: YYYY-MM-DD
```

Choose one installation path. For Path C, remove the Termux source/version line unless you also use Termux separately:

- **Path A (native Termux):** Claude Code runs through this repository's patched native launcher. The [skills guide](skills.md) describes termux-safe and its known limits.
- **Path A (pinned Termux):** `install-pinned.sh` uses Node.js/npm for Claude Code `2.1.112`. There is no native-binary wrapper or automatic update.
- **Path B (proot Ubuntu):** Linux commands run inside the proot environment. Record which commands must instead run in the host Termux shell.
- **Path C (AVF):** Claude Code runs inside Android's Linux VM. Record whether shared storage, Keep awake, SSH, or wireless ADB is enabled.

Only keep facts you have verified on your device. Android versions, OEM battery controls, file-descriptor limits, background-process behavior, and available hardware integrations vary.

## Project Scope

```markdown
## Scope

- Work inside: YOUR_PROJECT_DIRECTORY
- Read-only supporting paths: OPTIONAL_PATHS_OR_NONE
- Do not access: OUT_OF_SCOPE_PATHS_OR_DATA
- Primary goal: WHAT_THIS_PROJECT_IS_FOR
- Current constraints: IMPORTANT_TECHNICAL_OR_PRODUCT_LIMITS
```

Avoid granting access to an entire home directory when the project needs only one repository. List shared-storage or device-data locations separately because they may contain personal information.

## Confirmation Boundaries

The examples below are intentionally conservative; edit them to match your workflow.

```markdown
## Confirmation boundaries

Claude may read project files, search the repository, and run non-mutating diagnostics when relevant to my request.

Editing project files and running tests are allowed only when my request calls for implementation.

Ask before:
- installing or removing packages
- changing files outside the project directory
- changing Termux, shell, Git, SSH, or Android settings
- enabling ADB, opening network listeners, or accessing device data
- committing, pushing, publishing, deleting, or contacting external services

Never include credentials, pairing codes, tokens, private keys, precise location, or unredacted device identifiers in files, logs, commits, or responses.
```

Be explicit about Git and remote actions if the repository is public, mirrored, or uses a private staging repository. Do not assume that permission to edit includes permission to commit or push.

## Path-Specific Notes

Keep only the block for your installation path and customize it. For Path A, record that commands run in ordinary Termux. The termux-safe skill adds guidance, with the known limits in the skills guide.

### Path B: Proot Ubuntu

```markdown
## Proot Ubuntu notes

- State whether each setup or diagnostic command runs in host Termux or inside Ubuntu.
- Do not assume proot provides hardware virtualization, systemd, root-equivalent Android access, or protection from Android process limits.
- Use explicit paths when passing files between Termux and Ubuntu.
```

### Path C: AVF

```markdown
## AVF notes

- This project runs inside Android's Linux VM.
- Shared storage path: YOUR_SHARED_STORAGE_PATH_OR_NONE
- Keep awake setting: YOUR_SETTING
- Wireless ADB: DISABLED | ENABLED_FOR_SPECIFIC_TASKS
- Treat ADB as privileged device access. Ask before pairing, connecting, changing settings, capturing the screen, injecting input, or reading Android system data.
```

## Quick Review Before Use

Before saving your `CLAUDE.md`, confirm that:

- every placeholder is replaced or removed;
- the selected Path A, B, or C matches the actual installation;
- commands distinguish Termux, proot Ubuntu, and AVF where needed;
- allowed directories are narrow and accurate;
- commit, push, ADB, device-data, and package-install boundaries match your intent; and
- no personal identifiers or secrets were copied into the file.

Revisit the file when you change installation paths, devices, repository remotes, or security boundaries.
