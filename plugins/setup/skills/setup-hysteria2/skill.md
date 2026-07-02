---
name: setup-hysteria2
description: Install and configure Hysteria 2 proxy client on macOS. Installs binary via Homebrew, deploys config, adds shortcut commands (hy2start, hy2stop, hy2log, hy2status, hy2restart, hy2edit, proxyon, proxyoff), and OPTIONALLY sets up a launchd auto-start service (asks the user first). Use this skill when the user mentions hysteria2, hy2, proxy client setup, hysteria proxy, or wants to configure a proxy on a new Mac.
allowed-tools: [Bash, Read, Write, Edit, AskUserQuestion]
---

# Setup Hysteria2 Client

Install and configure a Hysteria 2 client on macOS. Optionally runs as a launchd background service. Edit one YAML, run one command.

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
