---
name: setup-sing-box
description: Install and configure a sing-box proxy client on macOS — one client that speaks BOTH Hysteria2 and Shadowsocks and switches between them. Installs binary via Homebrew, deploys a merged config, adds shortcut commands (sbstart, sbstop, sblog, sbstatus, sbrestart, sbedit, sbnode, sbon, sboff), and OPTIONALLY sets up a launchd auto-start service (asks the user first). Use this skill when the user mentions sing-box, singbox, a unified proxy client, switching between hysteria2 and shadowsocks, or wants one client for multiple protocols on a new Mac.
allowed-tools: [Bash, Read, Write, Edit, AskUserQuestion]
---

# Setup sing-box Client

Install and configure a sing-box client on macOS. One local proxy port fronts **both** a Hysteria2 and a Shadowsocks outbound — switch with `sbnode`, or let `auto` pick the fastest. Optionally runs as a launchd background service. Edit one JSON, run one command.

It coexists with `setup-hysteria2`: sing-box defaults to port **1082**, hysteria2 uses **1080/1081**, so both can run at once. (sing-box already includes a Hysteria2 outbound, so most people run *either* sing-box *or* the standalone hysteria2 client — not both.)

## File layout

```
~/.config/sing-box/
  config.json                        ← edit this (chmod 600, contains your auth)
  aliases.sh                         ← shell shortcuts
  sing-box.log / sing-box.err.log    ← runtime logs
~/Library/LaunchAgents/
  com.sing-box.client.plist          ← runs `sing-box run -c config.json`
                                       (ONLY in service mode — omitted in manual mode)
```

3–4 files (the plist exists only when you choose the launchd service), no wrappers, no env injection.

## Quick setup

**Step 1 — ask the user how it should run.** Before running the script, use `AskUserQuestion` to let the user choose the startup mode:

- **Auto-start service (launchd)** — starts automatically on login and is kept alive if it crashes. Best for a daily-driver machine. → pass `--service`
- **Manual only** — no launchd; the user starts/stops it themselves with `sbstart` / `sbstop`. Best for a shared/temporary machine or when the user wants full control. → pass `--no-service`

Recommend **Auto-start service** as the default.

**Step 2 — run the script with the chosen flag:**

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-sing-box.sh --service      # or --no-service
```

If run non-interactively (e.g. orchestrated by `setup-macos`), the flag can be omitted and it defaults to `--service`.

The script:
- Installs `sing-box` via Homebrew
- Deploys `config.json` template (preserves existing — never overwrites real secrets)
- Deploys `aliases.sh`
- Generates the launchd plist **only in `--service` mode** (in `--no-service` mode it removes any pre-existing plist)
- Adds `source aliases.sh` to `~/.zshrc.local`

## After setup — fill in 3 fields

```bash
sbedit           # opens config.json in $EDITOR, runs `sing-box check`, auto-restarts on save
```

Replace these placeholders (Hy2 and SS may point at different hosts — edit each `server` if so):
```jsonc
"server": "SERVER_HOST"        // both the hy2 and ss outbound
"password": "HY2_AUTH_TOKEN"   // in the hysteria2 outbound
"password": "SS_PASSWORD"      // in the shadowsocks outbound
```

Then:
```bash
source ~/.zshrc
sbstart          # start (validates config first)
sbstatus         # verify — shows current outbound + listening port
sbon             # set http/https/all_proxy → 127.0.0.1:1082 in this shell
```

## Shortcut commands

### Service control
These auto-detect the mode: with a plist they drive launchd; without one they start/stop the process directly.

| Command | Action |
|---------|--------|
| `sbstart` | Start (runs `sing-box check` first; launchd service or background process) |
| `sbstop` | Stop (unload service if present, then kill the process) |
| `sbrestart` | Restart (`launchctl kickstart -k`, or stop+start in manual mode) |
| `sbstatus` | PID + mode + current outbound + listening port |
| `sblog` | Tail stdout + stderr (Ctrl+C to exit) |
| `sblogs` | Last 50 lines of logs |
| `sbedit` | Edit `config.json` + validate + auto-restart |
| `sbhelp` | Full command reference |

### Outbound switching
| Command | Action |
|---------|--------|
| `sbnode` | Print the current default outbound |
| `sbnode ss` / `sbnode hy2` / `sbnode auto` | Switch default outbound + restart (`auto` = url-test fastest) |

### Proxy control (current shell only)
`sb`-prefixed so they don't clash with `setup-hysteria2`'s `proxyon`/`proxyoff`.

| Command | Action |
|---------|--------|
| `sbon` | Set `http_proxy` / `https_proxy` / `all_proxy` → sing-box mixed port |
| `sboff` | Unset proxy env vars |
| `sbproxystatus` | Show current proxy state |
| `sbip` | Compare direct vs. proxy egress IP (labels current outbound) |
| `sbspeed` | Test proxy download speed |

### Combo
| Command | Action |
|---------|--------|
| `gosb` | `sbstart` + `sbon` + `sbip` |
| `stopsb` | `sbstop` + `sboff` |

## Default port

Mixed (SOCKS5 + HTTP on one port): `127.0.0.1:1082`. To change, edit `listen_port` in `config.json` AND `SB_MIXED_PORT` in `aliases.sh`.

## Security

- `config.json` is **chmod 600** — only your user can read it
- The setup script **never overwrites an existing config.json** (keeps your secrets safe across re-runs)
- `aliases.sh` and the plist ARE overwritten on re-run — they're managed code, not user data
- `sbstart` / `sbedit` run `sing-box check` before (re)starting, so a bad edit never silently breaks the service
- The launchd service (when used) runs as your user, not root
- The Hysteria2 outbound uses `tls.insecure: true` to match a self-signed server (as deployed by `setup-hysteria2 --server`). sing-box has no SHA256 cert-pinning option, so pinning is not enforced client-side — the QUIC password still authenticates the server.

## Related

- `setup-hysteria2` — standalone Hysteria2 client, and the **server** side (`--server`) that this client's `hy2` outbound connects to
- `setup-shadowsocks` — the Shadowsocks **server** (`--server`) that this client's `ss` outbound connects to
