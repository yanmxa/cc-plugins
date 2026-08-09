#!/bin/bash
# Setup Hysteria2 client on macOS — install binary, deploy config + aliases,
# and (optionally) a launchd auto-start service.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HY2_DIR="$HOME/.config/hysteria"
HY2_CONFIG="$HY2_DIR/config.yaml"
HY2_ALIASES="$HY2_DIR/aliases.sh"
HY2_PLIST="$HOME/Library/LaunchAgents/com.hysteria.client.plist"

# --- Mode: server vs client (default: client) ---
# --server  → SSH-deploy a Hysteria2 SERVER to a Linux VPS, then exit
#             (delegates to deploy-hysteria2-server.sh; takes --host/--ssh-user/...).
# --client  → (default) configure THIS Mac as a Hysteria2 client (rest of this file).
for arg in "$@"; do
  if [ "$arg" = "--server" ]; then
    filtered=()
    for a in "$@"; do
      case "$a" in --server|--client) ;; *) filtered+=("$a") ;; esac
    done
    exec bash "$SCRIPT_DIR/deploy-hysteria2-server.sh" ${filtered[@]+"${filtered[@]}"}
  fi
done
# strip a lone --client so the client arg loop below doesn't reject it
filtered=()
for a in "$@"; do case "$a" in --client) ;; *) filtered+=("$a") ;; esac; done
set -- ${filtered[@]+"${filtered[@]}"}

# --- Parse args: choose whether to install the launchd auto-start service ---
# --service     (default) install launchd plist → auto-start on login + KeepAlive
# --no-service  skip launchd → start/stop manually via hy2start / hy2stop
INSTALL_SERVICE=1
for arg in "$@"; do
  case "$arg" in
    --service)             INSTALL_SERVICE=1 ;;
    --no-service|--manual) INSTALL_SERVICE=0 ;;
    -h|--help)
      cat <<'USAGE'
Usage: setup-hysteria2.sh [--service | --no-service]

  --service     (default) install a launchd service so hysteria auto-starts on
                login and is kept alive if it crashes.
  --no-service  do NOT install launchd. You start/stop it yourself with
                hy2start / hy2stop (runs in the background for the login session).
USAGE
      exit 0 ;;
    *) echo "Unknown option: $arg (use --service or --no-service)" >&2; exit 1 ;;
  esac
done

echo "=== Hysteria2 Setup ==="
if [ "$INSTALL_SERVICE" -eq 1 ]; then
  echo "  Mode: launchd service (auto-start on login)"
else
  echo "  Mode: manual (no launchd auto-start)"
fi

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

# --- 5. Deploy HTTP proxy config (sing-box mixed port, always overwrite) ---
cp "$SCRIPT_DIR/http-proxy.json.template" "$HY2_DIR/http-proxy.json"
chmod 644 "$HY2_DIR/http-proxy.json"
echo "  Deployed HTTP proxy config → $HY2_DIR/http-proxy.json"

# --- 6. Generate launchd plist (service mode only) ---
if [ "$INSTALL_SERVICE" -eq 1 ]; then
  mkdir -p "$HOME/Library/LaunchAgents"
  sed -e "s|__HOME__|$HOME|g" \
      -e "s|__HYSTERIA_BIN__|$HYSTERIA_BIN|g" \
      "$SCRIPT_DIR/com.hysteria.client.plist.template" > "$HY2_PLIST"
  echo "  Generated launchd plist → $HY2_PLIST (auto-start on login)"
else
  # Manual mode: remove any pre-existing plist so the old service stops auto-starting.
  if [ -f "$HY2_PLIST" ]; then
    launchctl unload "$HY2_PLIST" 2>/dev/null || true
    rm -f "$HY2_PLIST"
    echo "  Removed existing launchd plist (manual mode) → $HY2_PLIST"
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
if [ "$INSTALL_SERVICE" -eq 1 ]; then
  echo "Mode: launchd service — auto-starts on login, auto-restarts on crash."
  START_NOTE="launchd background service"
else
  echo "Mode: manual — no auto-start. Runs in the background only while you keep it started."
  START_NOTE="background process (this login session)"
fi
echo ""
echo "Next steps:"
echo "  1. Edit config (set server / auth / pinSHA256):"
echo "       hy2edit         # opens \$EDITOR + auto-restarts on save"
echo ""
echo "  2. Reload shell + start:"
echo "       source ~/.zshrc"
echo "       hy2start        # $START_NOTE"
echo "       hy2status       # verify"
echo "       proxyon         # set http/https/all_proxy in this shell"
echo ""
echo "  Help: hy2help"
echo ""
echo "  统一端口: HTTP+SOCKS5 → 127.0.0.1:1083 (sing-box → hysteria :1080)"
