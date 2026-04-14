#!/bin/bash
# Setup Ghostty terminal with optimized configuration and Nerd Font
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config/ghostty"
CONFIG_FILE="$CONFIG_DIR/config"
FONT_NAME="MesloLGL Nerd Font"
FONT_DIR="$HOME/Library/Fonts"

echo "=== Ghostty Setup ==="

# --- 1. Check if Ghostty is installed ---
if [ -d "/Applications/Ghostty.app" ] || command -v ghostty &>/dev/null; then
  echo "Ghostty is installed."
else
  echo "Ghostty not found. Installing via Homebrew..."
  if ! command -v brew &>/dev/null; then
    echo "ERROR: Homebrew is required but not installed."
    echo "Install it from https://brew.sh"
    exit 1
  fi
  brew install --cask ghostty
  echo "Ghostty installed."
fi

# --- 2. Check and install Nerd Font ---
install_nerd_font() {
  echo ""
  echo "Checking for $FONT_NAME..."

  # Check if font is already installed (system or user fonts)
  if fc-list 2>/dev/null | grep -qi "MesloLGL Nerd Font"; then
    echo "$FONT_NAME already installed."
    return 0
  fi

  # Fallback: check font files directly
  if ls "$FONT_DIR"/MesloLGL*.ttf &>/dev/null 2>&1 || \
     ls /Library/Fonts/MesloLGL*.ttf &>/dev/null 2>&1; then
    echo "$FONT_NAME already installed."
    return 0
  fi

  echo "$FONT_NAME not found. Downloading..."

  local TEMP_DIR
  TEMP_DIR="$(mktemp -d)"
  local BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
  local ZIP_FILE="$TEMP_DIR/Meslo.zip"

  curl -fsSL "$BASE_URL/Meslo.zip" -o "$ZIP_FILE"
  echo "Extracting fonts..."
  unzip -qo "$ZIP_FILE" -d "$TEMP_DIR/fonts"

  # Install MesloLGL variants to user font directory
  mkdir -p "$FONT_DIR"
  local count=0
  for f in "$TEMP_DIR/fonts"/MesloLGL*.ttf; do
    [ -f "$f" ] || continue
    cp "$f" "$FONT_DIR/"
    count=$((count + 1))
  done

  # If no MesloLGL found, install all Meslo variants
  if [ "$count" -eq 0 ]; then
    for f in "$TEMP_DIR/fonts"/*.ttf; do
      [ -f "$f" ] || continue
      cp "$f" "$FONT_DIR/"
      count=$((count + 1))
    done
  fi

  rm -rf "$TEMP_DIR"
  echo "$count font files installed to $FONT_DIR"

  # Refresh font cache if fc-cache is available
  if command -v fc-cache &>/dev/null; then
    fc-cache -f "$FONT_DIR" 2>/dev/null || true
  fi

  echo "$FONT_NAME installed."
}

install_nerd_font

# --- 3. Backup existing config ---
echo ""
echo "Configuring Ghostty..."
mkdir -p "$CONFIG_DIR"

if [ -f "$CONFIG_FILE" ]; then
  BACKUP="$CONFIG_FILE.backup.$(date +%Y%m%d%H%M%S)"
  cp "$CONFIG_FILE" "$BACKUP"
  echo "Existing config backed up to: $BACKUP"
fi

# --- 4. Install optimized config ---
cp "$SCRIPT_DIR/config" "$CONFIG_FILE"
echo "Optimized config installed to: $CONFIG_FILE"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Key bindings:"
echo "  Split right:      Cmd + D"
echo "  Split down:       Cmd + Shift + D"
echo "  Close split:      Cmd + W"
echo "  Navigate splits:  Cmd + Alt + Arrow"
echo "  Resize splits:    Cmd + Ctrl + Arrow"
echo "  Equalize splits:  Cmd + Shift + ="
echo "  Quick terminal:   Ctrl + \`  (global)"
echo ""
echo "Restart Ghostty to apply changes."
