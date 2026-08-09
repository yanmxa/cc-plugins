---
name: setup-shadowsocks
description: Install and configure Shadowsocks — client on macOS, server on Linux VPS, or diagnose both. Ask the user server-vs-client first.
allowed-tools: [Bash, Read, Write, Edit, AskUserQuestion]
---

# Setup Shadowsocks

Three things this skill does:

- **Client** — install + configure Shadowsocks on THIS Mac (sslocal + sing-box HTTP layer)
- **Server** — SSH-deploy to a Linux VPS (ssserver + systemd + firewall)
- **Diagnose** — check both ends, restart, fix issues

## Step 0 — ask

Always ask first: **client, server, or diagnose?**

## Client

One command:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-shadowsocks.sh --service   # or --no-service for manual
```

Installs `shadowsocks-rust` (Homebrew), deploys `~/.config/shadowsocks/config.json` + `aliases.sh` + `http-proxy.json` (sing-box mixed port for HTTP), optionally creates a launchd plist. Never overwrites an existing config.json.

After setup, fill in `server` and `password`, then:

```bash
source ~/.zshrc
ssstart && sson
```

Architecture:

```
sslocal(:1084)  ──SOCKS5──▶  sing-box(:1082)  ──HTTP+SOCKS5──▶  终端程序
```

### Commands

| Command | Action |
|---------|--------|
| `ssstart` / `ssstop` / `ssrestart` | Service control (launchd or manual) |
| `ssstatus` | PID + mode + SOCKS5:1084 + HTTP:1082 |
| `sslog` / `sslogs` | Tail / last 50 lines of logs |
| `ssedit` | Edit config.json + auto-restart |
| `sshelp` | Full command reference |
| `sson` / `ssoff` / `ssproxystatus` | Proxy env vars (HTTP_PROXY=http://:1082, ALL_PROXY=socks5://:1082) |
| `ssip` | Compare direct vs. proxy egress IP |
| `ssspeed` | Test proxy download speed |
| `goss` / `stopss` | Start+proxy+IP / Stop+unproxy |

Default: SOCKS5 `:1084` (sslocal), HTTP+SOCKS5 `:1082` (sing-box).

## Server

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-shadowsocks.sh --server --host <ip> \
  [--ssh-user root] [--ssh-port 22] [--ssh-key <path>] [--server-port 8388] [--method aes-256-gcm]
```

Requires key-based SSH (`ssh-copy-id` first). Installs shadowsocks-rust, writes `/etc/shadowsocks-rust/config.json` with server-generated password, enables systemd, opens firewall. Prints ready-to-paste client config.

## Diagnose

SS is simple — TCP-based, no complex protocol issues. Check:

```bash
ssstatus         # local: running? ports listening?
sslogs           # any errors?
nc -zv <server> 8388   # TCP reachable?
```

## Common fixes

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `Connection refused` | sslocal not running | `ssstart` |
| HTTP tools don't work | sing-box layer down | `ssrestart` (restarts both) |
| `timeout` | GFW blocked port/IP | Change server port or switch to hy2 |
| Method not supported | Old Python ss client | Use `shadowsocks-rust` (Homebrew) |
