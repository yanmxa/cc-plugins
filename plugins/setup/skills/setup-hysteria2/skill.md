---
name: setup-hysteria2
description: Install and configure Hysteria 2 — client on macOS, server on Linux VPS, or diagnose both. Ask the user server-vs-client first.
allowed-tools: [Bash, Read, Write, Edit, AskUserQuestion]
---

# Setup Hysteria 2

Three things this skill does:

- **Client** — install + configure hysteria on THIS Mac, with shell aliases to control it
- **Server** — SSH-deploy hysteria to a Linux VPS (binary + self-signed cert + systemd + firewall)
- **Diagnose** — check both ends and fix common issues (port blocked by GFW, stale process, etc.)

## Step 0 — ask

Always ask first: **client, server, or diagnose?**

## Client

One command:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-hysteria2.sh --service   # or --no-service for manual
```

This installs hysteria (Homebrew), deploys `~/.config/hysteria/config.yaml` + `aliases.sh`, optionally creates a launchd plist. Never overwrites an existing config.yaml.

After setup, fill in `server`, `auth`, `tls.pinSHA256` in config.yaml, then:

```bash
source ~/.zshrc
hy2start && hy2on
```

Architecture:

```
sing-box(:1081)  ──SOCKS5──▶  hysteria(:1080)  ──QUIC──▶  服务器
 HTTP+SOCKS5 统一口            SOCKS5 only
```

### Commands

| Command | Action |
|---------|--------|
| `hy2start` / `hy2stop` / `hy2restart` | Service control (launchd or manual) |
| `hy2status` | PID + mode + listening ports |
| `hy2log` / `hy2logs` | Tail / last 50 lines of logs |
| `hy2edit` | Edit config.yaml + auto-restart |
| `hy2diag` | Full diagnostic: local + remote (SSH) + proxy test |
| `hy2restart-all` | Restart both server (SSH) and client |
| `hy2help` | Full command reference |
| `hy2on` / `hy2off` / `hy2proxystatus` | Proxy env vars → `HTTP_PROXY=http://:1081`, `ALL_PROXY=socks5://:1081` |
| `hy2ip` | Compare direct vs. proxy egress IP |
| `hy2speed` | Test proxy download speed |
| `gohy2` / `stophy2` | Start+proxy+test / Stop+unset proxy |

### SSH config (for hy2diag / hy2restart-all)

| Env var | Default |
|---------|---------|
| `HY2_SSH_HOST` | auto from config.yaml `server` field |
| `HY2_SSH_USER` | `root` |
| `HY2_SSH_PORT` | `22` |
| `HY2_SSH_KEY` | (optional) path to private key |
| `HY2_SSH_PASS` | (optional) password (needs expect or sshpass) |

Default ports: SOCKS5 `:1080`, HTTP `:1081`.

## Server

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-hysteria2.sh --server --host <ip> \
  [--ssh-user root] [--ssh-port 22] [--ssh-key <path>] [--server-port 443] [--sni bing.com]
```

Requires key-based SSH (`ssh-copy-id` first). Installs hysteria, generates self-signed cert, writes `/etc/hysteria/config.yaml`, enables systemd, opens firewall. Prints ready-to-paste client credentials.

## Diagnose

When something's wrong, run `hy2diag` (after `source ~/.zshrc`). It checks:

- Local client: PID, ports, version, recent errors
- Network: UDP reachability to server
- Remote server (via SSH): systemd, version, firewall, logs, outbound test
- Proxy: live CONNECT test

For SSH to server, set one of: `HY2_SSH_KEY` (key path), `HY2_SSH_PASS` (password, needs expect or sshpass). Server address is read from config.yaml automatically.

`hy2restart-all` restarts both server (SSH) and client in one go.

## Common fixes

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `connected to server` then 30s timeout | Port blocked by GFW DPI | Change to non-443 port (e.g. 8443) |
| Client stuck at "client mode" | v2.12.x macOS binary bug | Pin to v2.8.2: download to `~/.local/bin/hysteria` |
| Server outbound TCP all timeout | hysteria process stale >2w | `systemctl restart hysteria-server` |
