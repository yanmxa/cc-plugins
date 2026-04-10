---
name: setup-zsh
description: Install and configure Zsh with Oh My Zsh, plugins, powerlevel10k theme, and modern CLI tools. Use this skill when the user mentions setting up zsh, configuring zsh, installing oh-my-zsh, zsh setup, zsh plugins, shell setup, or wants to set up their shell environment on a new machine.
allowed-tools: [Bash, Read, Write, Edit]
---

# Setup Zsh

Set up a fully configured Zsh environment with Oh My Zsh, essential plugins, powerlevel10k theme, and modern CLI tools (fzf, zoxide).

## What gets installed

- **Oh My Zsh** (if not already present)
- **Plugins**: zsh-autosuggestions, zsh-completions, zsh-syntax-highlighting, fzf-tab, z
- **fzf** (via Homebrew if not present)
- **zoxide** (modern cd replacement)
- **powerlevel10k** theme
- **Custom env** sourced from `~/myconfig/env/zsh.sh` (aliases, functions)

## Quick setup

Run the bundled script which handles everything automatically — installing Oh My Zsh, cloning plugins, installing tools, and configuring `.zshrc`:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-zsh.sh
```

The script backs up any existing `~/.zshrc` before modifying.

## Manual / selective setup

If the user only wants part of the setup:

- **Plugins only**: Run with `--plugins-only` flag
- **Theme only**: Run with `--theme-only` flag
- **Tools only**: Run with `--tools-only` flag

## Plugins reference

| Plugin | Purpose |
|--------|---------|
| zsh-autosuggestions | Fish-like suggestions as you type |
| zsh-completions | Additional completion definitions |
| zsh-syntax-highlighting | Command syntax coloring |
| fzf-tab | Fuzzy completion with fzf |
| z | Directory frecency jumping |

## Customization

After setup, the user can modify `~/.zshrc` directly. Key config points:

- **Theme**: Change `ZSH_THEME` (default: `powerlevel10k/powerlevel10k`)
- **Plugins**: Edit the `plugins=(...)` line to add/remove plugins
- **Custom env**: `~/myconfig/env/zsh.sh` sources aliases and functions
- **zoxide**: Initialized via `eval "$(zoxide init zsh)"` in `.zshrc`
