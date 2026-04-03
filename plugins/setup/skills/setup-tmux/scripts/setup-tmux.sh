#!/bin/bash
# Setup tmux with optimized configuration, TPM, and Dracula theme
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMUX_CONF="$HOME/.tmux.conf"
TPM_DIR="$HOME/.tmux/plugins/tpm"

echo "=== tmux Setup ==="

# 1. Check if tmux is installed
if ! command -v tmux &>/dev/null; then
  echo "tmux not found. Installing via Homebrew..."
  if ! command -v brew &>/dev/null; then
    echo "ERROR: Homebrew is required but not installed."
    echo "Install it from https://brew.sh"
    exit 1
  fi
  brew install tmux
  echo "tmux installed: $(tmux -V)"
else
  echo "tmux already installed: $(tmux -V)"
fi

# 2. Backup existing config if present
if [ -f "$TMUX_CONF" ]; then
  BACKUP="$TMUX_CONF.backup.$(date +%Y%m%d%H%M%S)"
  cp "$TMUX_CONF" "$BACKUP"
  echo "Existing config backed up to: $BACKUP"
fi

# 3. Copy optimized config
cp "$SCRIPT_DIR/tmux.conf" "$TMUX_CONF"
echo "Optimized tmux.conf installed."

# 4. Install TPM (Tmux Plugin Manager)
if [ -d "$TPM_DIR" ]; then
  echo "TPM already installed, updating..."
  git -C "$TPM_DIR" pull --quiet
else
  echo "Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi
echo "TPM ready."

# 5. Install plugins via TPM
echo "Installing tmux plugins..."
"$TPM_DIR/bin/install_plugins" 2>/dev/null || true

# 6. Reload config if tmux is running
if tmux list-sessions &>/dev/null; then
  tmux source-file "$TMUX_CONF"
  echo "Config reloaded in running tmux session."
else
  echo "No active tmux session. Config will apply on next start."
fi

echo ""
echo "=== Setup Complete ==="
echo "Key bindings:"
echo "  Prefix:       Ctrl-a"
echo "  Split horiz:  prefix + \\"
echo "  Split vert:   prefix + -"
echo "  Resize pane:  prefix + h/j/k/l"
echo "  Zoom pane:    prefix + m"
echo "  Switch pane:  Alt + arrow keys"
echo "  Reload conf:  prefix + r"
