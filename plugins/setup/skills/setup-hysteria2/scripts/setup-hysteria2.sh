#!/bin/bash
# Setup Hysteria2 client on macOS — install binary, deploy config + plist + aliases
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HY2_DIR="$HOME/.config/hysteria"
HY2_CONFIG="$HY2_DIR/config.yaml"
HY2_ALIASES="$HY2_DIR/aliases.sh"
HY2_PLIST="$HOME/Library/LaunchAgents/com.hysteria.client.plist"

echo "=== Hysteria2 Setup ==="

# --- 1. Install hysteria binary ---
if ! command -v hysteria &>/dev/null; then
  if command -v brew &>/dev/null; then
    echo "  Installing hysteria via Homebrew..."
    brew install hysteria
  else
    echo "ERROR: Homebrew not found. Install from https://brew.sh first."
    exit 1
  fi
else
  echo "  hysteria already installed: $(hysteria version 2>/dev/null | head -1 || echo 'present')"
fi
HYSTERIA_BIN="$(command -v hysteria)"

# --- 2. Create config dir ---
mkdir -p "$HY2_DIR"

# --- 3. Deploy config (preserve existing — never overwrite real secrets) ---
if [ -f "$HY2_CONFIG" ]; then
  echo "  $HY2_CONFIG already exists, leaving alone."
else
  cp "$SCRIPT_DIR/config.yaml.template" "$HY2_CONFIG"
  chmod 600 "$HY2_CONFIG"
  echo "  Deployed config → $HY2_CONFIG (chmod 600)"
  echo "  ⚠️  Edit it: hy2edit"
fi

# --- 4. Deploy aliases (always overwrite — this is managed code) ---
cp "$SCRIPT_DIR/aliases.sh" "$HY2_ALIASES"
chmod 755 "$HY2_ALIASES"
echo "  Deployed aliases → $HY2_ALIASES"

# --- 5. Generate launchd plist ---
mkdir -p "$HOME/Library/LaunchAgents"
sed -e "s|__HOME__|$HOME|g" \
    -e "s|__HYSTERIA_BIN__|$HYSTERIA_BIN|g" \
    "$SCRIPT_DIR/com.hysteria.client.plist.template" > "$HY2_PLIST"
echo "  Generated plist → $HY2_PLIST"

# --- 6. Wire aliases into shell (self-sufficient: works without setup-zsh) ---
ZSHRC="$HOME/.zshrc"
ZSHRC_LOCAL="$HOME/.zshrc.local"
[ ! -f "$ZSHRC_LOCAL" ] && touch "$ZSHRC_LOCAL"
[ ! -f "$ZSHRC" ]       && touch "$ZSHRC"

# 6a. Append source line to ~/.zshrc.local (idempotent)
if grep -qF "$HY2_ALIASES" "$ZSHRC_LOCAL" 2>/dev/null; then
  echo "  Aliases already sourced in ~/.zshrc.local"
else
  {
    echo ""
    echo "# Hysteria 2 client shortcuts"
    echo "[ -f $HY2_ALIASES ] && source $HY2_ALIASES"
  } >> "$ZSHRC_LOCAL"
  echo "  Added source line to ~/.zshrc.local"
fi

# 6b. Ensure ~/.zshrc sources ~/.zshrc.local (idempotent — works without setup-zsh)
if grep -qF '.zshrc.local' "$ZSHRC" 2>/dev/null; then
  echo "  ~/.zshrc already sources ~/.zshrc.local"
else
  {
    echo ""
    echo "# Source machine-local config (added by setup-hysteria2)"
    echo '[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"'
  } >> "$ZSHRC"
  echo "  Wired ~/.zshrc.local into ~/.zshrc"
fi

echo ""
echo "=== Hysteria2 Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Edit config (set server / auth / pinSHA256):"
echo "       hy2edit         # opens \$EDITOR + auto-restarts on save"
echo ""
echo "  2. Reload shell + start:"
echo "       source ~/.zshrc"
echo "       hy2start        # launchd background service"
echo "       hy2status       # verify"
echo "       proxyon         # set http/https/all_proxy in this shell"
echo ""
echo "  Help: hy2help"
