---
name: setup-vim
description: Install Neovim with kickstart.nvim (the community-maintained starter config) — full IDE setup with LSP, Telescope, Treesitter, autocompletion. Optional classic Vim fallback with vim-plug. Use this skill when the user mentions setting up vim, neovim, nvim, configuring vim, vim setup, editor setup, or wants Neovim on a new machine.
allowed-tools: [Bash, Read, Write, Edit]
---

# Setup Vim / Neovim

Install Neovim and deploy **kickstart.nvim** as the default config — the official starting-point recommended by the Neovim community. Single-file `init.lua` you can read, understand, and customize.

## What gets installed

### Neovim (default)
- **Neovim** via Homebrew
- **ripgrep + fd** (used by Telescope and treesitter for fast search)
- **kickstart.nvim** cloned to `~/.config/nvim/` (`.git` removed so it's yours to edit)

kickstart.nvim ships with:
- LSP setup (Mason for managing language servers)
- Treesitter (syntax + indentation)
- Telescope (fuzzy finder)
- nvim-cmp (completion)
- which-key (keybinding hints)
- gitsigns (git change indicators)
- A clean colorscheme (tokyonight)

All in **one readable `init.lua` file**.

### Vim (`--vim-only` fallback)
- **vim-plug** plugin manager (official curl install)
- Bundled `vimrc` with molokai theme, airline, polyglot

## Quick setup

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-vim.sh
```

Modes:
| Flag | Behavior |
|------|----------|
| (default) | Install Neovim + kickstart.nvim |
| `--neovim-only` | Same as default |
| `--vim-only` | Install classic Vim with vim-plug only |

The script backs up any existing `~/.config/nvim/` or `~/.vimrc` before overwriting.

## After install

Open `nvim` once — `lazy.nvim` auto-installs all plugins. To customize:
```bash
$EDITOR ~/.config/nvim/init.lua
```

The kickstart.nvim docs walk you through every section:
- https://github.com/nvim-lua/kickstart.nvim

## Why kickstart.nvim and not LazyVim/NvChad/...

- **Single file** — read the whole config in one sitting
- **No abstractions** — what you see is what runs
- **Officially blessed** by the neovim core team
- **Easy to delete** — if you outgrow it, you understand exactly what to keep

LazyVim / NvChad are great but opinionated and harder to debug if something breaks.

## Switching to a different distribution

```bash
rm -rf ~/.config/nvim
git clone https://github.com/LazyVim/starter ~/.config/nvim       # LazyVim
# or:
git clone https://github.com/NvChad/starter ~/.config/nvim        # NvChad
nvim   # auto-bootstraps
```
