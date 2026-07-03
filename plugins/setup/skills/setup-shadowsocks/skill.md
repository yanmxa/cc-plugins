---
name: setup-shadowsocks
description: Install and configure Shadowsocks — either a CLIENT on macOS (shadowsocks-rust sslocal, config, shortcut commands like ssstart/ssstop/sslog/sson, optional launchd service) or a SERVER on a Linux VPS over SSH (shadowsocks-rust ssserver, systemd service, firewall, prints ss:// link + credentials). Ask the user server-vs-client first. Use this skill when the user mentions shadowsocks, ss, sslocal, ssserver, deploying a shadowsocks server, or connecting to a shadowsocks proxy on a new Mac.
allowed-tools: [Bash, Read, Write, Edit, AskUserQuestion]
---

# Setup Shadowsocks (server or client)

Two modes:
- **client** (default) — configure THIS Mac as a Shadowsocks client (shadowsocks-rust `sslocal`). Homebrew binary, config, shortcut commands, optional launchd service.
- **server** — SSH-deploy a Shadowsocks server to a Linux VPS: `ssserver` + systemd + firewall, then print the `ss://` link + credentials.

For a single client that speaks **both** Shadowsocks and Hysteria2 with a switch, use `setup-sing-box` instead of this client.

## Step 0 — ask which mode

Before anything, use `AskUserQuestion`: **"Set up a Shadowsocks server or client?"**
- **Client (this Mac)** → the client flow below (`--client`, the default).
- **Server (a Linux VPS)** → the server flow (`--server`), see [Server mode](#server-mode).

## Server mode

SSH-deploys a shadowsocks-rust server to a Linux (Debian/Ubuntu) VPS. Needs **key-based SSH** access — run `ssh-copy-id <user>@<host>` once first (the plugin never handles passwords).

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-shadowsocks.sh --server --host <ip> \
  [--ssh-user root] [--ssh-port 22] [--ssh-key <path>] [--server-port 8388] [--method aes-256-gcm]
```

It downloads shadowsocks-rust, installs `ssserver`, writes `/etc/shadowsocks-rust/config.json` with a **server-generated** password, enables the `shadowsocks-rust` systemd service, opens the port in ufw (TCP+UDP), and prints **server / port / method / password** plus an `ss://` link and a ready-to-paste sing-box `ss` outbound. The password is generated on the server — never sent over the wire.

Then set up a client (below, or `setup-sing-box`) and paste the fields.

---

## Client mode

Configure this Mac as a Shadowsocks client (`sslocal`, SOCKS5). Optionally runs as a launchd background service. Edit one JSON, run one command. Default local port **1084**, so it coexists with `setup-hysteria2` (1080/1081) and `setup-sing-box` (1082).

## File layout

```
~/.config/shadowsocks/
  config.json                          ← edit this (chmod 600, contains your secrets)
  aliases.sh                           ← shell shortcuts
  shadowsocks.log / shadowsocks.err.log ← runtime logs
~/Library/LaunchAgents/
  com.shadowsocks.client.plist         ← runs `sslocal -c config.json`
                                         (ONLY in service mode — omitted in manual mode)
```

## Quick setup

**Step 1 — ask the user how it should run** (client mode). Use `AskUserQuestion`:

- **Auto-start service (launchd)** — auto-starts on login, kept alive on crash. → `--service`
- **Manual only** — start/stop with `ssstart` / `ssstop`. → `--no-service`

Recommend **Auto-start service** as the default.

**Step 2 — run the script:**

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-shadowsocks.sh --service      # or --no-service
```

The script installs `shadowsocks-rust` via Homebrew, deploys `config.json` (preserves existing), deploys `aliases.sh`, generates the launchd plist (service mode only), and sources the aliases from `~/.zshrc.local`.

## After setup — fill in 2 fields

```bash
ssedit           # opens config.json in $EDITOR + auto-restarts on save
```

Replace `SERVER_HOST` and `SS_PASSWORD` (from the server deploy output). Then:

```bash
source ~/.zshrc
ssstart          # start
ssstatus         # verify
sson             # set SOCKS5 proxy → 127.0.0.1:1084 in this shell
```

## Shortcut commands

### Service control (auto-detect launchd service / manual)
| Command | Action |
|---------|--------|
| `ssstart` / `ssstop` / `ssrestart` | Start / stop / restart |
| `ssstatus` | PID + mode + listening port |
| `sslog` / `sslogs` | Tail logs / last 50 lines |
| `ssedit` | Edit `config.json` + auto-restart |
| `sshelp` | Full command reference |

### Proxy control (current shell only)
`ss`-prefixed so they don't clash with `setup-hysteria2` / `setup-sing-box`.

| Command | Action |
|---------|--------|
| `sson` / `ssoff` | Set / unset SOCKS5 proxy env (`socks5h://127.0.0.1:1084`) |
| `ssproxystatus` | Show current proxy state |
| `ssip` | Compare direct vs. proxy egress IP |
| `ssspeed` | Test proxy download speed |
| `goss` / `stopss` | Start+proxy+IP / stop+unproxy |

> `sslocal` is **SOCKS5-only**. For apps that need an HTTP proxy, use `setup-sing-box` (mixed SOCKS+HTTP port).

## Default port

SOCKS5: `127.0.0.1:1084`. To change, edit `local_port` in `config.json` AND `SS_SOCKS_PORT` in `aliases.sh`.

## Security

- `config.json` is **chmod 600**; the setup script never overwrites an existing one
- `aliases.sh` and the plist ARE overwritten on re-run (managed code)
- Server mode uses **key-based SSH only**; the server password is generated on the VPS and returned, never sent over the wire
- The launchd service (when used) runs as your user, not root

## Related

- `setup-sing-box` — one client for BOTH Shadowsocks and Hysteria2 (recommended client)
- `setup-hysteria2` — Hysteria2 client, and its `--server` deploy
