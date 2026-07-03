#!/bin/bash
# Setup sing-box client on macOS — a single client that speaks BOTH Hysteria2 and
# Shadowsocks (switchable). Installs binary, deploys config + aliases, and
# (optionally) a launchd auto-start service.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SB_DIR="$HOME/.config/sing-box"
SB_CONFIG="$SB_DIR/config.json"
SB_ALIASES="$SB_DIR/aliases.sh"
SB_PLIST="$HOME/Library/LaunchAgents/com.sing-box.client.plist"

# --- Parse args: choose whether to install the launchd auto-start service ---
# --service     (default) install launchd plist → auto-start on login + KeepAlive
# --no-service  skip launchd → start/stop manually via sbstart / sbstop
INSTALL_SERVICE=1
for arg in "$@"; do
  case "$arg" in
    --service)             INSTALL_SERVICE=1 ;;
    --no-service|--manual) INSTALL_SERVICE=0 ;;
    -h|--help)
      cat <<'USAGE'
Usage: setup-sing-box.sh [--service | --no-service]

  --service     (default) install a launchd service so sing-box auto-starts on
                login and is kept alive if it crashes.
  --no-service  do NOT install launchd. You start/stop it yourself with
                sbstart / sbstop (runs in the background for the login session).
USAGE
      exit 0 ;;
    *) echo "Unknown option: $arg (use --service or --no-service)" >&2; exit 1 ;;
  esac
done

echo "=== sing-box Client Setup ==="
if [ "$INSTALL_SERVICE" -eq 1 ]; then
  echo "  Mode: launchd service (auto-start on login)"
else
  echo "  Mode: manual (no launchd auto-start)"
fi

# --- 1. Install sing-box binary ---
if ! command -v sing-box &>/dev/null; then
  if command -v brew &>/dev/null; then
    echo "  Installing sing-box via Homebrew..."
    brew install sing-box
  else
    echo "ERROR: Homebrew not found. Install from https://brew.sh first."
    exit 1
  fi
else
  echo "  sing-box already installed: $(sing-box version 2>/dev/null | head -1 || echo 'present')"
fi
SINGBOX_BIN="$(command -v sing-box)"

# --- 2. Create config dir ---
mkdir -p "$SB_DIR"

# --- 3. Deploy config (preserve existing — never overwrite real secrets) ---
if [ -f "$SB_CONFIG" ]; then
  echo "  $SB_CONFIG already exists, leaving alone."
else
  cp "$SCRIPT_DIR/config.json.template" "$SB_CONFIG"
  chmod 600 "$SB_CONFIG"
  echo "  Deployed config → $SB_CONFIG (chmod 600)"
  echo "  ⚠️  Edit it: sbedit  (fill SERVER_HOST / HY2_AUTH_TOKEN / SS_PASSWORD)"
fi

# --- 4. Deploy aliases (always overwrite — this is managed code) ---
cp "$SCRIPT_DIR/aliases.sh" "$SB_ALIASES"
chmod 755 "$SB_ALIASES"
echo "  Deployed aliases → $SB_ALIASES"

# --- 5. Generate launchd plist (service mode only) ---
if [ "$INSTALL_SERVICE" -eq 1 ]; then
  mkdir -p "$HOME/Library/LaunchAgents"
  sed -e "s|__HOME__|$HOME|g" \
      -e "s|__SINGBOX_BIN__|$SINGBOX_BIN|g" \
      "$SCRIPT_DIR/com.sing-box.client.plist.template" > "$SB_PLIST"
  echo "  Generated launchd plist → $SB_PLIST (auto-start on login)"
else
  # Manual mode: remove any pre-existing plist so the old service stops auto-starting.
  if [ -f "$SB_PLIST" ]; then
    launchctl unload "$SB_PLIST" 2>/dev/null || true
    rm -f "$SB_PLIST"
    echo "  Removed existing launchd plist (manual mode) → $SB_PLIST"
  else
    echo "  Skipped launchd plist (manual mode)"
  fi
fi

# --- 6. Wire aliases into shell (self-sufficient: works without setup-zsh) ---
ZSHRC="$HOME/.zshrc"
ZSHRC_LOCAL="$HOME/.zshrc.local"
[ ! -f "$ZSHRC_LOCAL" ] && touch "$ZSHRC_LOCAL"
[ ! -f "$ZSHRC" ]       && touch "$ZSHRC"

# 6a. Append source line to ~/.zshrc.local (idempotent)
if grep -qF "$SB_ALIASES" "$ZSHRC_LOCAL" 2>/dev/null; then
  echo "  Aliases already sourced in ~/.zshrc.local"
else
  {
    echo ""
    echo "# sing-box client shortcuts"
    echo "[ -f $SB_ALIASES ] && source $SB_ALIASES"
  } >> "$ZSHRC_LOCAL"
  echo "  Added source line to ~/.zshrc.local"
fi

# 6b. Ensure ~/.zshrc sources ~/.zshrc.local (idempotent — works without setup-zsh)
if grep -qF '.zshrc.local' "$ZSHRC" 2>/dev/null; then
  echo "  ~/.zshrc already sources ~/.zshrc.local"
else
  {
    echo ""
    echo "# Source machine-local config (added by setup-sing-box)"
    echo '[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"'
  } >> "$ZSHRC"
  echo "  Wired ~/.zshrc.local into ~/.zshrc"
fi

echo ""
echo "=== sing-box Client Setup Complete ==="
echo ""
if [ "$INSTALL_SERVICE" -eq 1 ]; then
  echo "Mode: launchd service — auto-starts on login, auto-restarts on crash."
  START_NOTE="launchd background service"
else
  echo "Mode: manual — no auto-start. Runs in the background only while you keep it started."
  START_NOTE="background process (this login session)"
fi
echo ""
echo "Next steps:"
echo "  1. Edit config (fill SERVER_HOST / HY2_AUTH_TOKEN / SS_PASSWORD):"
echo "       sbedit         # opens \$EDITOR, runs 'sing-box check', auto-restarts on save"
echo ""
echo "  2. Reload shell + start:"
echo "       source ~/.zshrc"
echo "       sbstart        # $START_NOTE"
echo "       sbstatus       # verify (shows current outbound + port)"
echo "       sbon           # set http/https/all_proxy in this shell → 127.0.0.1:1082"
echo ""
echo "  Switch outbound: sbnode ss | hy2 | auto      Help: sbhelp"
