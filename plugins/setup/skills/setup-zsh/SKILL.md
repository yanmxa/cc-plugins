---
name: setup-zsh
description: Install and configure Zsh with Oh My Zsh, plugins, powerlevel10k theme, and modern CLI tools. Writes a self-contained ~/.zshrc with no external file dependencies. Use this skill when the user mentions setting up zsh, configuring zsh, installing oh-my-zsh, zsh setup, zsh plugins, shell setup, or wants to set up their shell environment on a new machine.
allowed-tools: [Bash, Read, Write, Edit]
---

# Setup Zsh

Set up a fully configured Zsh environment with Oh My Zsh, essential plugins, powerlevel10k theme, and modern CLI tools (fzf, zoxide). Produces a **self-contained `~/.zshrc`** with `command -v` guards for optional tools — no external file dependencies.

## What gets installed

- **Oh My Zsh** (if not already present)
- **Plugins**: zsh-autosuggestions, zsh-completions, zsh-syntax-highlighting, fzf-tab, z
- **fzf** (via Homebrew)
- **zoxide** (smart cd replacement)
- **uv** — Python package manager (replaces pyenv + pip + virtualenv)
- **fnm** — fast Node.js version manager (replaces nvm, Rust-based)
- **Go** (via Homebrew)
- **powerlevel10k** theme
- **Self-contained `~/.zshrc`** — inlines all config, backs up the existing one

## Environment isolation strategy

| Language | Tool | How isolation works |
|----------|------|---------------------|
| Python | uv | `UV_PYTHON_PREFERENCE=only-managed` — always uv-managed Python; `pip install` is intercepted and blocked |
| Node.js | fnm | reads `.node-version` / `.nvmrc` per project; `--use-on-cd` auto-switches |
| Go | built-in | `go.mod` handles per-project deps natively; binaries go to `$GOPATH/bin` |

### Python workflow (uv)

```bash
uv python install 3.12      # install a Python version
uv init myproject            # new project (creates pyproject.toml + .venv)
uv venv                      # create venv in existing dir
uv pip install requests      # install into active venv
uv tool install ruff         # install CLI tool in isolated env (not global)
uv run script.py             # run script with auto-managed deps
```

conda/miniforge is still supported: if `~/miniforge3/` or `~/miniconda3/` exists, it's sourced automatically.

### Node.js workflow (fnm)

```bash
fnm install 20               # install Node 20
fnm default 20               # set global default
echo "20" > .node-version    # fnm auto-switches when you cd into this dir
```

## Three-tier config layout

A clean separation between portable config, secrets, and machine-specific tweaks:

| File | Purpose | Tracked? |
|------|---------|----------|
| `~/.zshrc` | Main shell config — plugins, PATH, language runtimes, aliases | ✅ tracked (dotfiles) |
| `~/.env` | Environment variables, API keys, secrets — auto-exported on shell start | ❌ gitignored, chmod 600 |
| `~/.zshrc.local` | Machine-specific aliases / functions / work-only config | ❌ gitignored |

Both `~/.env` and `~/.zshrc.local` are sourced **after** the main config, so they can override anything. The setup script creates starter templates if missing (and never overwrites existing files).

### `~/.env` example

```bash
# Bare assignments — auto-exported (no `export` keyword needed)
OPENAI_API_KEY=sk-...
GITHUB_TOKEN=ghp_...
AWS_PROFILE=default
```

### `~/.zshrc.local` example

```bash
# Work-only aliases that don't belong in dotfiles
alias work-vpn='sudo openconnect vpn.company.com'
alias prod-db='psql -h prod.example.com -U admin'
```

## Self-contained .zshrc design

All guards are presence-based — missing tools are silently skipped:
- **Python**: `UV_PYTHON_PREFERENCE=only-managed` + `pip install` interceptor; conda sourced only if dir exists
- **Node.js**: fnm `--use-on-cd` for automatic per-project version switching
- **Go**: `GOPATH=$HOME/go` set only when `go` is available
- Optional tools (bun, cargo, gcloud) only activate when present
- Explicit history: 50k entries, dedupe, share across sessions

## Quick setup

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-zsh.sh
```

The script backs up any existing `~/.zshrc` before overwriting.

## Selective setup

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-zsh.sh --plugins-only
bash ${CLAUDE_SKILL_DIR}/scripts/setup-zsh.sh --theme-only
bash ${CLAUDE_SKILL_DIR}/scripts/setup-zsh.sh --tools-only
bash ${CLAUDE_SKILL_DIR}/scripts/setup-zsh.sh --env-only      # only create ~/.env, ~/.zshrc.local
```

## Plugins reference

| Plugin | Purpose |
|--------|---------|
| zsh-autosuggestions | Fish-like suggestions as you type |
| zsh-completions | Additional completion definitions |
| zsh-syntax-highlighting | Command syntax coloring |
| fzf-tab | Fuzzy completion with fzf |
| z | Directory frecency jumping |

## Built-in functions

| Function | Purpose |
|----------|---------|
| `mkcd <dir>` | mkdir + cd in one step |
| `extract <archive>` | Generic archive extractor (tar/zip/7z/rar/...) |
