---
name: setup-vim
description: Install and configure Neovim (or Vim) with a full IDE setup including LSP, Telescope, Treesitter, and custom keybindings. Use this skill when the user mentions setting up vim, neovim, nvim, configuring vim, vim setup, editor setup, or wants to deploy their editor config on a new machine.
allowed-tools: [Bash, Read, Write, Edit]
---

# Setup Vim / Neovim

Set up a fully configured Neovim environment with a Lua-based config, or a classic Vim setup with vim-plug and molokai theme.

## What gets installed

### Neovim (default)
- **Neovim** (via Homebrew if not present)
- **Full Lua config** from `~/myconfig/neovim/nvim/` deployed to `~/.config/nvim/`
- Includes: Telescope, Navigator, LSP, Treesitter, catppuccin theme, nvim-tree, barbar tabs, auto-pairs, auto-save, gitsigns, which-key, and more

### Vim (fallback)
- **vim-plug** plugin manager
- **molokai** theme, vim-polyglot syntax, vim-airline status bar
- Custom IJKL navigation keybindings (Dvorak-friendly)

## Quick setup

Run the bundled script:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-vim.sh
```

Options:
- Default: installs Neovim and deploys full Lua config
- `--vim-only`: sets up classic Vim with vim-plug and bundled vimrc
- `--neovim-only`: only installs/updates Neovim config (skip Vim)

The script backs up any existing config before overwriting.

## Custom keybindings (Vim mode)

The bundled vimrc uses remapped navigation (Dvorak-style):

| Action | Binding |
|--------|---------|
| Up / 5 up | `i` / `I` |
| Down / 5 down | `k` / `K` |
| Left (word back) | `j` / `J` (B) |
| Right (word end) | `l` / `L` (E) |
| Insert | `h` / `H` |
| Top of file | `Space + i` |
| Bottom of file | `Space + k` |
| Save | `S` |
| Quit | `Q` |
| Split right/left | `sl` / `sj` |
| Split up/down | `si` / `sk` |

## Customization

- **Neovim**: Edit files in `~/.config/nvim/lua/plugins/` to add/remove plugins
- **Vim**: Edit `~/.vimrc` to customize; run `:PlugInstall` to install new plugins
