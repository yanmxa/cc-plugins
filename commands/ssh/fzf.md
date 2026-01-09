---
argument-hint: [install|uninstall|status]
description: Install ssh-fzf - interactive SSH/SCP commands with fzf
allowed-tools: [Bash]
---

Manage ssh-fzf installation in shell config.

## Commands After Install

- `ss` - SSH connect with fzf server selection
- `sc` - SCP upload/download with fzf
- `sk` - Setup passwordless SSH (ssh-copy-id)
- `s`  - Show help

## Implementation

```bash
SCRIPT="$HOME/.claude/scripts/ssh-fzf.sh"
SHELL_CONFIG="$HOME/.zshrc"
SOURCE_LINE='[ -f "$HOME/.claude/scripts/ssh-fzf.sh" ] && source "$HOME/.claude/scripts/ssh-fzf.sh"'

case "${1:-install}" in
  install|i)
    if ! command -v fzf &>/dev/null; then
      echo "Error: fzf required. Install: brew install fzf"
      exit 1
    fi
    if grep -q "ssh-fzf.sh" "$SHELL_CONFIG" 2>/dev/null; then
      echo "Already installed in $SHELL_CONFIG"
    else
      echo "" >> "$SHELL_CONFIG"
      echo "# ssh-fzf - Interactive SSH commands" >> "$SHELL_CONFIG"
      echo "$SOURCE_LINE" >> "$SHELL_CONFIG"
      echo "Installed. Run: source ~/.zshrc"
    fi
    ;;
  uninstall|rm)
    if grep -q "ssh-fzf.sh" "$SHELL_CONFIG" 2>/dev/null; then
      grep -v "ssh-fzf" "$SHELL_CONFIG" > "${SHELL_CONFIG}.tmp"
      mv "${SHELL_CONFIG}.tmp" "$SHELL_CONFIG"
      echo "Removed from $SHELL_CONFIG"
    else
      echo "Not installed"
    fi
    ;;
  status|s)
    echo "Script: $SCRIPT"
    grep -q "ssh-fzf.sh" "$SHELL_CONFIG" && echo "Status: Installed" || echo "Status: Not installed"
    ;;
esac
```
