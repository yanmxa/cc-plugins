# macOS Setup Plugin

A modular set of skills for bootstrapping a fresh macOS development environment. Each component is **standalone** — pick what you want, skip what you don't.

---

## All Components (9 total)

| ID | Installs | Files written | Independent? |
|----|----------|--------------|--------------|
| `brew` | Homebrew | `/opt/homebrew/` | ✅ |
| `zsh` | Oh My Zsh + plugins + powerlevel10k + uv + fnm + Go | `~/.zshrc`, `~/.env`, `~/.zshrc.local` | needs `brew` |
| `vim` | Neovim with full Lua config | `~/.config/nvim/`, `~/.vimrc` (fallback) | needs `brew` |
| `tmux` | tmux + TPM + Dracula theme | `~/.tmux.conf`, `~/.tmux/plugins/` | needs `brew` |
| `git` | git + gh + global config + SSH key | `~/.gitconfig`, `~/.gitignore_global`, `~/.ssh/id_ed25519` | needs `brew` |
| `ghostty` | Ghostty terminal + Nerd Font | `~/.config/ghostty/config` | needs `brew` |
| `docker` | OrbStack (replaces Docker Desktop) | `/Applications/OrbStack.app` | needs `brew` |
| `hysteria2` | Hy2 proxy client + launchd service | `~/.config/hysteria/`, plist, sources own aliases | needs `brew`, **self-wires into `~/.zshrc`** |
| `prefs` | 4 dev-friendly macOS defaults | `~/Library/Preferences/...` | ✅ standalone |

**The only hard dependency is `brew`** — every install component needs it. Beyond that, components are independent: install in any order, skip any you don't want.

---

## Three ways to install

### 1. Through Claude (interactive multi-select)

Just tell Claude what you want to do:

```
我想 setup 一台新 Mac
```

Claude reads `setup-macos/skill.md`, calls `AskUserQuestion` to multi-select components, gathers required pre-config (git name/email, hysteria2 server credentials), then runs everything.

### 2. Direct CLI with explicit components

```bash
# Pick exactly what you want
bash ~/.claude/plugins/setup/skills/setup-macos/scripts/setup-macos.sh \
  --components brew,zsh,git,docker

# Run everything
bash ~/.claude/plugins/setup/skills/setup-macos/scripts/setup-macos.sh --all

# See available components
bash ~/.claude/plugins/setup/skills/setup-macos/scripts/setup-macos.sh --list
```

### 3. CLI interactive (Y/n per component)

```bash
bash ~/.claude/plugins/setup/skills/setup-macos/scripts/setup-macos.sh
```

Prompts Y/n for each component with sensible defaults.

### 4. Run individual skills directly

Each component is standalone — invoke it without the orchestrator:

```bash
bash ~/.claude/plugins/setup/skills/setup-zsh/scripts/setup-zsh.sh
bash ~/.claude/plugins/setup/skills/setup-vim/scripts/setup-vim.sh
bash ~/.claude/plugins/setup/skills/setup-tmux/scripts/setup-tmux.sh
bash ~/.claude/plugins/setup/skills/setup-git/scripts/setup-git.sh
bash ~/.claude/plugins/setup/skills/setup-ghostty/scripts/setup-ghostty.sh
bash ~/.claude/plugins/setup/skills/setup-docker/scripts/setup-docker.sh
bash ~/.claude/plugins/setup/skills/setup-hysteria2/scripts/setup-hysteria2.sh
```

---

## Pre-install checklist

Only **2 components** require info to be gathered before running:

### git — needs identity
- Your name (e.g., `Meng Yan`)
- Your email (e.g., `you@example.com`)

You can pass them as arguments:
```bash
bash setup-git.sh "Your Name" "you@example.com"
```

Otherwise the script prompts. During install, `gh auth login` opens a browser for OAuth.

### hysteria2 — needs server credentials
- `server` — host:port of your Hy2 server
- `auth` — auth token / password
- `tls.pinSHA256` — SHA256 fingerprint of server cert

These are NOT prompted by the script — instead the template gets deployed and you edit `~/.config/hysteria/config.yaml` after install (`hy2edit`).

**All other components run without questions.**

---

## What each component leaves behind

### `brew`
- `/opt/homebrew/` (Apple Silicon)
- `~/Library/Caches/Homebrew/`

### `zsh` — three-tier shell config
| File | Tracked in dotfiles? | Purpose |
|------|---------------------|---------|
| `~/.zshrc` | ✅ yes | Generic — plugins, PATH, runtimes, aliases |
| `~/.env` | ❌ chmod 600 | Environment variables / API keys (auto-exported) |
| `~/.zshrc.local` | ❌ no | Machine-specific aliases / functions |

Plus language runtimes: `uv` (Python), `fnm` (Node.js), `go` (Go), all installed via brew, isolation-friendly defaults baked in (e.g., `pip install` is blocked globally to force venv use).

### `vim`
- `~/.config/nvim/` (full Lua config: telescope, treesitter, LSP, catppuccin, etc.)

### `tmux`
- `~/.tmux.conf` (Ctrl-a prefix, Dracula theme, vim-style splits)
- `~/.tmux/plugins/tpm/`

### `git`
- `~/.gitconfig` (identity, aliases, pull.rebase, push.autoSetupRemote, osxkeychain helper)
- `~/.gitignore_global` (`.env`, `*.pem`, `*_rsa`, `__pycache__`, etc.)
- `~/.ssh/id_ed25519` + `id_ed25519.pub`
- gh CLI authenticated with GitHub (uploads SSH key automatically)

### `ghostty`
- `~/.config/ghostty/config` (MesloLGL Nerd Font, Builtin Light, Cmd+D splits)

### `docker` (OrbStack)
- `/Applications/OrbStack.app`
- Auto-starts when you run any `docker` command

### `hysteria2`
- `~/.config/hysteria/config.yaml` (chmod 600 — your server / auth)
- `~/.config/hysteria/aliases.sh` — `hy2start`/`hy2stop`/`hy2log`/`hy2edit`/`proxyon`/`proxyoff`/...
- `~/Library/LaunchAgents/com.hysteria.client.plist` (launchd service, auto-start on login)
- Auto-wires into `~/.zshrc` so aliases load (independent of `zsh` component)

### `prefs` (4 settings only)
1. `Finder.AppleShowAllExtensions = true` — see file extensions
2. `Dock.show-recents = false` — no clutter from "recent apps"
3. `screencapture.location = ~/Desktop/screenshots/` — screenshots out of the way
4. `DSDontWriteNetworkStores = true` — no `.DS_Store` on SMB shares

---

## Recommended install order

If running everything manually, follow this order to minimize redundant prompts:

```
1. brew         (no deps)
2. zsh          (sets up ~/.env that other tools may want to use)
3. git          (needs name/email — interactive)
4. vim, tmux, ghostty, docker, hysteria2  (any order — independent)
5. prefs        (anytime, no install action)
```

The `setup-macos` orchestrator already runs them in this order.

---

## After install

Universal post-setup steps:

1. **Restart shell** — `source ~/.zshrc` (or open new terminal)
2. **Configure prompt** — `p10k configure`
3. **tmux plugins** — `tmux` then `prefix + I`
4. **Edit secrets** — fill in `~/.env` and (if installed) `~/.config/hysteria/config.yaml`
5. **Verify** — `git config --list --global`, `gh auth status`, `docker run hello-world`, `hy2start`

---

## Skill files

```
plugins/setup/
├── README.md                                  ← this file
├── skills/
│   ├── setup-macos/                           ← orchestrator (multi-select picker)
│   │   ├── skill.md
│   │   └── scripts/setup-macos.sh
│   ├── setup-zsh/                             ← shell + language runtimes
│   │   ├── SKILL.md
│   │   └── scripts/setup-zsh.sh
│   ├── setup-vim/
│   ├── setup-tmux/
│   ├── setup-git/                             ← git + gh + ssh
│   ├── setup-ghostty/                         ← terminal
│   ├── setup-docker/                          ← OrbStack
│   └── setup-hysteria2/                       ← proxy client
└── ...
```

Each skill's `skill.md` has detailed docs for that component.
