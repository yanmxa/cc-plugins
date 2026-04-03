---
name: setup-tmux
description: Install and configure tmux on macOS with an optimized config, Dracula theme, TPM plugin manager, and vim-style keybindings. Use this skill when the user mentions setting up tmux, configuring tmux, installing tmux on Mac, tmux setup, tmux configuration, or wants to replicate their tmux environment on a new machine.
allowed-tools: [Bash, Read, Write, Edit]
---

# Setup tmux

Set up a fully configured tmux environment on macOS with an optimized configuration, Dracula theme, and essential plugins.

## What gets installed

- **tmux** (via Homebrew if not present)
- **TPM** (Tmux Plugin Manager)
- **Plugins**: vim-tmux-navigator, Dracula theme (cpu/ram/network status)
- **Optimized config** with these highlights:
  - Prefix: `Ctrl-a` (instead of default `Ctrl-b`)
  - Pane splitting: `prefix + \` (horizontal), `prefix + -` (vertical)
  - Vim-style pane resize: `prefix + h/j/k/l`
  - Alt+arrow pane switching (no prefix needed)
  - Native copy/paste with pbcopy (mouse select, double/triple-click)
  - Heavy pane borders with green active border
  - 50,000 lines history, auto-renumber windows
  - Ghostty hyperlinks passthrough, OSC 52 clipboard

## Quick setup

Run the bundled script which handles everything automatically — installing tmux, backing up any existing config, deploying the optimized config, installing TPM and plugins:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-tmux.sh
```

The script backs up any existing `~/.tmux.conf` before overwriting.

## Manual / selective setup

If the user only wants part of the config (e.g., just the keybindings or just the theme), read the bundled config at `${CLAUDE_SKILL_DIR}/scripts/tmux.conf` and apply only the relevant sections to their existing config.

## Key bindings reference

| Action | Binding |
|--------|---------|
| Prefix | `Ctrl-a` |
| Split horizontal | `prefix + \` |
| Split vertical | `prefix + -` |
| Resize pane | `prefix + h/j/k/l` |
| Zoom pane | `prefix + m` |
| Switch pane | `Alt + arrow keys` |
| Reload config | `prefix + r` |
| Paste | `prefix + p` |
| Create named window | `prefix + c` |

## Customization

After setup, the user can modify `~/.tmux.conf` directly. The config is structured with clear section comments. Common customizations:

- **Dracula plugins**: Change `@dracula-plugins` to add/remove status bar widgets (battery, git, gpu-usage, weather, time, etc.)
- **Pane borders**: Change `pane-border-lines` to `simple`, `double`, or `number`
- **Active border color**: Modify `pane-active-border-style` (current: bright green)
