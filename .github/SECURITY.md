# Security Policy

## Supported versions

I maintain this repo on my own, so only the current release line gets
security attention. Older versions do not.

| Version | Supported |
|---------|-----------|
| Latest release line (currently 2.9.x) | Yes |
| Anything older | No |

"Current" tracks whatever the latest published release is, so it moves as
new releases go out. If you are on an older version, update to the latest
release before reporting, in case the issue is already fixed.

## Reporting a vulnerability

Please report security issues privately through GitHub, not in a public issue.

1. Go to the repo's **Security** tab.
2. Click **Report a vulnerability** (under **Advisories**).
3. Describe what you found, with steps to reproduce if you have them.

That opens a private advisory that only you and I can see. GitHub's private
vulnerability reporting is the channel I use for this; there is no separate
security email. If you cannot use private reporting, open a normal issue that
says only that you have a security concern and asks me to open a private
channel. Do not put the details in a public issue.

## What to expect

I am one person doing this in my spare time, so I cannot offer a
service-level agreement or a guaranteed response time. Honestly:

- I read every report.
- I try to acknowledge a valid report within a week or so, but I cannot promise it.
- If I confirm an issue, I fix it in the current release line and credit you in
  the advisory if you want the credit.
- If I decide something is out of scope or not a vulnerability, I tell you why.

## Scope

This repo is documentation and install scripts, not a hosted service.

In scope:

- A script in this repo (`install.sh`, `install-pinned.sh`, `migrate.sh`, anything
  under `scripts/`; see the [install guide](../docs/install.md) and the
  [skills and scripts guide](../docs/add-ons/skills.md) for what each does)
  that could compromise a device or account when run as documented.
- Documentation that tells users to do something unsafe.
- A supply-chain or integrity problem in what these scripts download or how they
  verify it.

Out of scope:

- Bugs in Claude Code itself. Report those to Anthropic at
  [anthropics/claude-code](https://github.com/anthropics/claude-code).
- Bugs in Termux, proot-distro (the tool that installs a Linux distribution inside
  Termux), or other third-party tools. Report those to their own projects.
- Issues that require an already-compromised device or physical access.

Thanks for reporting responsibly.
