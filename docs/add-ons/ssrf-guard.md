# SSRF Guard: WebFetch and WebSearch Safety Hook

An optional PreToolUse hook that rejects recognized URL strings containing selected internal, private, and reserved destinations. It checks hook inputs for WebFetch/WebSearch. Its current protection limits are described below; it does not filter MCP traffic or provide network isolation.

[All add-ons](README.md) · [Access and trust](../security-model.md)

A Claude Code hook is a small script Claude Code runs automatically at set points in its workflow; a PreToolUse hook runs just before a tool call and can allow or block it. WebFetch and WebSearch are the built-in tools that retrieve web pages and run web searches. MCP (Model Context Protocol) servers are external services Claude Code can connect to for extra data and tools. I wrote this hook for Claude Code on Android and Termux, but its dependencies and hook behavior still need checking on your chosen platform and Claude release.

---

## What It Does

For WebFetch, the hook checks the URL. For WebSearch, a query without `://` passes as a plain search; otherwise the entire query is parsed as a URL. It does not extract a URL from surrounding prose. Recognized destinations include:

- **RFC 1918 private ranges** (the standard private IP blocks used on home and office networks): 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
- **Loopback**: 127.0.0.0/8, localhost, ::1
- **Link-local**: 169.254.0.0/16, fe80::/10
- **Carrier-grade NAT**: 100.64.0.0/10
- **Cloud metadata endpoints**: 169.254.169.254, metadata.google.internal, metadata.goog
- **IPv6 unspecified and ULA** (Unique Local Address, the IPv6 equivalent of a private range): ::, fc00::/7
- **Non-HTTP schemes**: file://, ftp://, gopher://, data://, javascript://, etc.
- **Reserved/documentation ranges**: 192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24, 198.18.0.0/15, 240.0.0.0/4

It also handles the IPv4 encoding forms that Node's URL parser normalizes at parse time (the WHATWG URL parser is the web standard implementation Node uses to interpret a URL string), before applying its literal-address rules. This normalizes the hook input; it does not prove that every upstream fetching implementation uses an identical parser:

- Short-form IPs (127.1 -> 127.0.0.1)
- Decimal IPs (2130706433 -> 127.0.0.1)
- Hex IPs (0x7f000001 -> 127.0.0.1)
- Octal IPs (0177.0.0.1 -> 127.0.0.1)
- Combined octal (017700000001 -> 127.0.0.1)
- IPv6-mapped IPv4 (::ffff:127.0.0.1)

If no block rule matches, the hook exits 0 (allow). That result is not proof the destination is safe. If blocked, it exits 2 with a JSON error on stderr explaining why.

---

## Installation

The canonical script lives at [`examples/ssrf-guard.sh`](../../examples/ssrf-guard.sh) in this repository. Copy or download it into your Claude Code hooks directory.

**This hook requires Bash, `jq`, and Node.js.** Node is a dependency of this optional example, not of the native Claude installation. In ordinary Termux, add the packages if needed:

```bash
pkg install jq nodejs
```

The pinned installer already supplies Node. If Claude runs inside Ubuntu or Debian instead, the hook and its dependencies must be installed and tested inside that guest, not only in host Termux.

### 1. Install the script

Choose **one** source. From a [reviewed repository checkout](skills.md#get-a-repository-checkout):

```bash
mkdir -p ~/.claude/hooks
cp examples/ssrf-guard.sh ~/.claude/hooks/ssrf-guard.sh
chmod +x ~/.claude/hooks/ssrf-guard.sh
```

Or download the public script, then read it before registering the hook:

```bash
mkdir -p ~/.claude/hooks
curl -fsSL https://raw.githubusercontent.com/ferrumclaudepilgrim/claude-code-android/main/examples/ssrf-guard.sh \
  -o ~/.claude/hooks/ssrf-guard.sh
chmod +x ~/.claude/hooks/ssrf-guard.sh
```

### 2. Register in settings.json

Merge this entry into your existing project `.claude/settings.json` or personal `~/.claude/settings.json`; retain other settings. Explicit `bash` avoids the direct-script shebang problem on native Path A:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "WebFetch|WebSearch",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$HOME/.claude/hooks/ssrf-guard.sh\""
          }
        ]
      }
    ]
  }
}
```

The `matcher` field ensures the hook only runs on WebFetch and WebSearch calls, not every tool invocation. `WebFetch|WebSearch` is a regular expression; the hook also re-checks the tool name on stdin and ignores anything else.

### 3. Verify dependencies

The script requires:

- bash (4.x or newer; Termux ships 5.x)
- jq (1.5 or newer for the `//` operator the script uses)
- Node.js (the script parses and normalizes URLs with Node's built-in `URL` class). Some install methods ship claude as a standalone binary without Node, so install Node yourself if `node` is not already on your PATH.
- grep and cut (standard on Linux and Termux)

On Termux:

```bash
pkg install nodejs jq -y
```

---

## Current status

This is a narrow URL-string example with synthetic parser tests, not a network boundary. Current [Claude tool documentation](https://code.claude.com/docs/en/tools-reference) already describes WebFetch refusing localhost/bare hostnames and reporting cross-host redirects. WebSearch returns search results rather than fetching their pages. Reassess what this extra hook adds on your release instead of assuming it protects phone networking.

**Integration gaps:** malformed JSON can cause an ordinary hook error; missing-script, interpreter, crash, and timeout behavior need testing through Claude. Current hooks support `onFailure: "block"` from **2.1.295+**; it is not available on pinned **2.1.112**. See the [hook failure policy](https://code.claude.com/docs/en/hooks#block-the-action-when-a-hook-fails).

The script's WebSearch rule can reject normal prose containing a URL because it parses the entire query as one URL. Its benefit for search-result safety is not established; review this behavior before matching WebSearch calls.

## Known Limitations

- **Tool coverage**: This hook handles only Claude Code `WebFetch` and `WebSearch` calls that reach it. It does not intercept Bash commands such as `curl` or `wget`, Git/package-manager traffic, local or remote MCP servers, browser activity, or another process's network requests. It is not an outbound firewall.
- **DNS and rebinding**: The hook never resolves the hostname. A hostname can resolve directly, or later change, to a private address without the URL-string check noticing. The tests also allow some reserved space such as IPv6 documentation range `2001:db8::/32`; this is not a complete reserved-address policy.
- **HTTP redirects**: this script does not follow or validate a redirect chain. Current WebFetch reports cross-host redirects for another fetch, which can trigger another hook call. That is upstream tool behavior, not protection implemented by this script; check your installed release.
- **Hostname-based private IPs**: Hostnames like `internal.corp` that resolve to private IPs via DNS are not blocked. The hook does not perform DNS resolution.
- **Encoding coverage**: The guard normalizes what Node's URL parser normalizes (short-form, decimal, hex, octal IPv4, IPv6 syntax, and single percent-encoding). Node's WHATWG parser percent-decodes the host, so a single percent-encoded internal host like `http://%31%32%37.1` resolves to `127.0.0.1` and is blocked. What it does not catch: some Unicode homoglyphs (characters that look like ordinary letters but have a different code point, such as a Cyrillic letter that resembles a Latin one). Most obvious homoglyphs normalize away (for example `ⓛocalhost` becomes `localhost` and is caught), but a Cyrillic homoglyph that maps to a punycode label (the ASCII encoding browsers use for non-ASCII domain names) would slip through if it pointed at an internal name.

---

## The Script

See [`examples/ssrf-guard.sh`](../../examples/ssrf-guard.sh) for the canonical implementation.

---

*Documentation reviewed: 2026-10-25. The executable example is unchanged; no new device tests were performed.*
