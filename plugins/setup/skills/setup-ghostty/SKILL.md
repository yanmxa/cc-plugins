---
name: setup-ghostty
description: Install and configure Ghostty terminal on macOS with Nerd Font, optimized keybindings, and split pane support. Use this skill when the user mentions setting up ghostty, configuring ghostty, installing ghostty, ghostty setup, ghostty config, or wants to set up their terminal on a new machine.
allowed-tools: [Bash, Read, Write, Edit]
---

# Setup Ghostty

Set up a fully configured Ghostty terminal on macOS with MesloLGL Nerd Font, split pane keybindings, and an optimized config.

## What gets installed

- **Ghostty** (via Homebrew cask if not present)
- **MesloLGL Nerd Font** (downloaded from nerd-fonts releases if not found)
- **Optimized config** with these highlights:
  - Font: MesloLGL Nerd Font, size 14
  - Theme: Builtin Light
  - Split panes: `Cmd+D` (right), `Cmd+Shift+D` (down)
  - Navigate splits: `Cmd+Alt+Arrow`
  - Resize splits: `Cmd+Ctrl+Arrow`
  - Global quick terminal: `Ctrl+\``
  - Copy-on-select, 50k scrollback, cursor block (no blink)
  - macOS tabs titlebar style

## Quick setup

Run the bundled script which handles everything automatically — checking Ghostty, installing the font, backing up existing config, and deploying the optimized config:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-ghostty.sh
```

The script backs up any existing `~/.config/ghostty/config` before overwriting.

## Manual / selective setup

If the user only wants part of the config, read the bundled config at `${CLAUDE_SKILL_DIR}/scripts/config` and apply only the relevant sections to their existing config.

## Key bindings reference

| Action | Binding |
|--------|---------|
| Split right | `Cmd + D` |
| Split down | `Cmd + Shift + D` |
| Close split | `Cmd + W` |
| Navigate splits | `Cmd + Alt + Arrow` |
| Resize splits | `Cmd + Ctrl + Arrow` |
| Equalize splits | `Cmd + Shift + =` |
| Increase font | `Cmd + =` |
| Decrease font | `Cmd + -` |
| Reset font | `Cmd + 0` |
| Quick terminal | `Ctrl + \`` (global) |

## Customization

After setup, edit `~/.config/ghostty/config` directly. Common customizations:

- **Theme**: Change `theme` to any built-in theme (`ghostty +list-themes` to see all)
- **Font**: Change `font-family` and `font-size`
- **Padding**: Adjust `window-padding-x` and `window-padding-y`
- **Keybindings**: Add or modify `keybind` lines
