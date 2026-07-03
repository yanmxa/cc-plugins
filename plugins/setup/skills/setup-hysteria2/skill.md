---
name: setup-hysteria2
description: Install and configure Hysteria 2 — either a CLIENT on macOS (Homebrew binary, config, shortcut commands like hy2start/hy2stop/hy2log/proxyon, optional launchd service) or a SERVER on a Linux VPS over SSH (official installer, self-signed cert, systemd service, firewall, prints client credentials). Ask the user server-vs-client first. Use this skill when the user mentions hysteria2, hy2, proxy client/server setup, deploying a Hysteria2 server, or connecting to a Hysteria2 proxy on a new Mac.
allowed-tools: [Bash, Read, Write, Edit, AskUserQuestion]
---

# Setup Hysteria2 (server or client)

Two modes:
- **client** (default) — configure THIS Mac as a Hysteria2 client. Homebrew binary, config, shortcut commands, optional launchd service.
- **server** — SSH-deploy a Hysteria2 server to a Linux VPS: official installer + self-signed cert + systemd + firewall, then print client credentials to paste back.

## Step 0 — ask which mode

Before anything, use `AskUserQuestion`: **"Set up a Hysteria2 server or client?"**
- **Client (this Mac)** → the client flow below (`--client`, the default).
- **Server (a Linux VPS)** → the server flow (`--server`), see [Server mode](#server-mode).

## Server mode

SSH-deploys a Hysteria2 server to a Linux (Debian/Ubuntu) VPS. Needs **key-based SSH** access — run `ssh-copy-id <user>@<host>` once first (the plugin never handles passwords).

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-hysteria2.sh --server --host <ip> \
  [--ssh-user root] [--ssh-port 22] [--ssh-key <path>] [--server-port 443] [--sni bing.com]
```

It installs hysteria via the official installer, generates a self-signed cert (CN = `--sni`), writes `/etc/hysteria/config.yaml` with a **server-generated** password + `bing.com` masquerade, enables the `hysteria-server` systemd service, opens the port in ufw (UDP+TCP), and prints **server / auth / sni / pinSHA256** plus ready-to-paste snippets for both the standalone client and the sing-box `hy2` outbound. The password is generated on the server — never sent over the wire.

Then set up a client (below, or `setup-sing-box`) and paste the fields.

---

## Client mode

Configure this Mac as a Hysteria 2 client. Optionally runs as a launchd background service. Edit one YAML, run one command.

## File layout

```
~/.config/hysteria/
  config.yaml                       ← edit this (chmod 600, contains your auth)
  aliases.sh                        ← shell shortcuts
  hysteria.log / hysteria.err.log   ← runtime logs
~/Library/LaunchAgents/
  com.hysteria.client.plist         ← runs `hysteria client -c config.yaml`
                                      (ONLY in service mode — omitted in manual mode)
```

3–4 files (the plist exists only when you choose the launchd service), no wrappers, no env injection.

## Quick setup

**Step 1 — ask the user how it should run.** Before running the script, use `AskUserQuestion` to let the user choose the startup mode:

- **Auto-start service (launchd)** — starts automatically on login and is kept alive if it crashes. Best for a daily-driver machine. → pass `--service`
- **Manual only** — no launchd; the user starts/stops it themselves with `hy2start` / `hy2stop` (runs in the background for the current login session). Best for a shared/temporary machine or when the user wants full control. → pass `--no-service`

Recommend **Auto-start service** as the default.

**Step 2 — run the script with the chosen flag:**

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-hysteria2.sh --service      # or --no-service
```

If run non-interactively (e.g. orchestrated by `setup-macos`), the flag can be omitted and it defaults to `--service`.

The script:
- Installs `hysteria` via Homebrew
- Deploys `config.yaml` template (preserves existing — never overwrites real secrets)
- Deploys `aliases.sh`
- Generates the launchd plist **only in `--service` mode** (in `--no-service` mode it removes any pre-existing plist so the old service stops auto-starting)
- Adds `source aliases.sh` to `~/.zshrc.local`

## After setup — fill in 3 fields

```bash
hy2edit          # opens config.yaml in $EDITOR + auto-restarts on save
```

Edit these:
```yaml
server: your.server.com:443
auth: your_auth_token
tls:
  pinSHA256: your_cert_sha256
```

Then:
```bash
source ~/.zshrc
hy2start
hy2status        # verify running
proxyon          # set http/https/all_proxy in this shell
```

## Shortcut commands

### Service control
These auto-detect the mode: with a plist they drive launchd; without one they start/stop the process directly.

| Command | Action |
|---------|--------|
| `hy2start` | Start (launchd service, or background process in manual mode) |
| `hy2stop` | Stop (unload service if present, then kill the process) |
| `hy2restart` | Restart (`launchctl kickstart -k`, or stop+start in manual mode) |
| `hy2status` | PID + mode + listening ports |
| `hy2log` | Tail stdout + stderr (Ctrl+C to exit) |
| `hy2logs` | Last 50 lines of logs |
| `hy2edit` | Edit `config.yaml` + auto-restart |
| `hy2help` | Full command reference |

### Proxy control (current shell only)
| Command | Action |
|---------|--------|
| `proxyon` | Set `http_proxy` / `https_proxy` / `all_proxy` |
| `proxyoff` | Unset proxy env vars |
| `proxystatus` | Show current proxy state |
| `proxyip` | Compare direct vs. proxy egress IP |
| `proxyspeed` | Test proxy download speed |

### Combo
| Command | Action |
|---------|--------|
| `gohy2` | `hy2start` + `proxyon` + `proxyip` |
| `stophy2` | `hy2stop` + `proxyoff` |

## Default ports

SOCKS5: `127.0.0.1:1080`, HTTP: `127.0.0.1:1081`. To change, edit `config.yaml` AND update `HY2_SOCKS_PORT`/`HY2_HTTP_PORT` exports in `aliases.sh`.

## Security

- `config.yaml` is **chmod 600** — only your user can read it
- The setup script **never overwrites an existing config.yaml** (keeps your secrets safe across re-runs)
- `aliases.sh` and the plist ARE overwritten on re-run — they're managed code, not user data
- Re-running with `--no-service` removes the launchd plist; re-running with `--service` re-creates it
- The launchd service (when used) runs as your user, not root
