#!/bin/bash
# Setup Shadowsocks on macOS (client) or a Linux VPS (server, over SSH).
#   --client (default) install shadowsocks-rust sslocal client + config + aliases
#                      + optional launchd service.
#   --server           SSH-deploy a shadowsocks-rust server to a Linux VPS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SS_DIR="$HOME/.config/shadowsocks"
SS_CONFIG="$SS_DIR/config.json"
SS_ALIASES="$SS_DIR/aliases.sh"
SS_PLIST="$HOME/Library/LaunchAgents/com.shadowsocks.client.plist"

# --- Mode: server vs client (default: client) ---
for arg in "$@"; do
  if [ "$arg" = "--server" ]; then
    filtered=()
    for a in "$@"; do
      case "$a" in --server|--client) ;; *) filtered+=("$a") ;; esac
    done
    exec bash "$SCRIPT_DIR/deploy-shadowsocks-server.sh" ${filtered[@]+"${filtered[@]}"}
  fi
done
# strip a lone --client so the client arg loop below doesn't reject it
filtered=()
for a in "$@"; do case "$a" in --client) ;; *) filtered+=("$a") ;; esac; done
set -- ${filtered[@]+"${filtered[@]}"}

# --- Parse args: choose whether to install the launchd auto-start service ---
INSTALL_SERVICE=1
for arg in "$@"; do
  case "$arg" in
    --service)             INSTALL_SERVICE=1 ;;
    --no-service|--manual) INSTALL_SERVICE=0 ;;
    -h|--help)
      cat <<'USAGE'
Usage: setup-shadowsocks.sh [--client] [--service | --no-service]
       setup-shadowsocks.sh --server --host <ip> [server options]

  --client               (default) set up a Shadowsocks client on this Mac.
    --service            (default) install a launchd service (auto-start on login).
    --no-service         manual — start/stop yourself with ssstart / ssstop.
  --server               SSH-deploy a Shadowsocks server to a Linux VPS.
                         Run with --help after --server for server options.
USAGE
      exit 0 ;;
    *) echo "Unknown option: $arg (use --service or --no-service)" >&2; exit 1 ;;
  esac
done

echo "=== Shadowsocks Client Setup ==="
if [ "$INSTALL_SERVICE" -eq 1 ]; then
  echo "  Mode: launchd service (auto-start on login)"
else
  echo "  Mode: manual (no launchd auto-start)"
fi

# --- 1. Install shadowsocks-rust (provides sslocal) ---
if ! command -v sslocal &>/dev/null; then
  if command -v brew &>/dev/null; then
    echo "  Installing shadowsocks-rust via Homebrew..."
    brew install shadowsocks-rust
  else
    echo "ERROR: Homebrew not found. Install from https://brew.sh first."
    exit 1
  fi
else
  echo "  sslocal already installed: $(sslocal --version 2>/dev/null | head -1 || echo 'present')"
fi
SSLOCAL_BIN="$(command -v sslocal)"

# --- 2. Create config dir ---
mkdir -p "$SS_DIR"

# --- 3. Deploy config (preserve existing — never overwrite real secrets) ---
if [ -f "$SS_CONFIG" ]; then
  echo "  $SS_CONFIG already exists, leaving alone."
else
  cp "$SCRIPT_DIR/config.json.template" "$SS_CONFIG"
  chmod 600 "$SS_CONFIG"
  echo "  Deployed config → $SS_CONFIG (chmod 600)"
  echo "  ⚠️  Edit it: ssedit  (fill SERVER_HOST / SS_PASSWORD)"
fi

# --- 4. Deploy aliases (always overwrite — this is managed code) ---
cp "$SCRIPT_DIR/aliases.sh" "$SS_ALIASES"
chmod 755 "$SS_ALIASES"
echo "  Deployed aliases → $SS_ALIASES"

# --- 5. Deploy HTTP proxy config (sing-box mixed port, always overwrite) ---
cp "$SCRIPT_DIR/http-proxy.json.template" "$SS_DIR/http-proxy.json"
chmod 644 "$SS_DIR/http-proxy.json"
echo "  Deployed HTTP proxy config → $SS_DIR/http-proxy.json"

# --- 6. Generate launchd plist (service mode only) ---
if [ "$INSTALL_SERVICE" -eq 1 ]; then
  mkdir -p "$HOME/Library/LaunchAgents"
  sed -e "s|__HOME__|$HOME|g" \
      -e "s|__SSLOCAL_BIN__|$SSLOCAL_BIN|g" \
      "$SCRIPT_DIR/com.shadowsocks.client.plist.template" > "$SS_PLIST"
  echo "  Generated launchd plist → $SS_PLIST (auto-start on login)"
else
  if [ -f "$SS_PLIST" ]; then
    launchctl unload "$SS_PLIST" 2>/dev/null || true
    rm -f "$SS_PLIST"
    echo "  Removed existing launchd plist (manual mode) → $SS_PLIST"
  else
    echo "  Skipped launchd plist (manual mode)"
  fi
fi

# --- 6. Wire aliases into shell (self-sufficient: works without setup-zsh) ---
ZSHRC="$HOME/.zshrc"
ZSHRC_LOCAL="$HOME/.zshrc.local"
[ ! -f "$ZSHRC_LOCAL" ] && touch "$ZSHRC_LOCAL"
[ ! -f "$ZSHRC" ]       && touch "$ZSHRC"

if grep -qF "$SS_ALIASES" "$ZSHRC_LOCAL" 2>/dev/null; then
  echo "  Aliases already sourced in ~/.zshrc.local"
else
  {
    echo ""
    echo "# Shadowsocks client shortcuts"
    echo "[ -f $SS_ALIASES ] && source $SS_ALIASES"
  } >> "$ZSHRC_LOCAL"
  echo "  Added source line to ~/.zshrc.local"
fi

if grep -qF '.zshrc.local' "$ZSHRC" 2>/dev/null; then
  echo "  ~/.zshrc already sources ~/.zshrc.local"
else
  {
    echo ""
    echo "# Source machine-local config (added by setup-shadowsocks)"
    echo '[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"'
  } >> "$ZSHRC"
  echo "  Wired ~/.zshrc.local into ~/.zshrc"
fi

echo ""
echo "=== Shadowsocks Client Setup Complete ==="
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
echo "  1. Edit config (fill SERVER_HOST / SS_PASSWORD):"
echo "       ssedit         # opens \$EDITOR + auto-restarts on save"
echo ""
echo "  2. Reload shell + start:"
echo "       source ~/.zshrc"
echo "       ssstart        # $START_NOTE"
echo "       ssstatus       # verify"
echo "       sson           # set HTTP+SOCKS5 proxy → 127.0.0.1:1082 in this shell"
echo ""
echo "  Help: sshelp"
echo ""
echo "  Ports: SOCKS5 → 127.0.0.1:1084 (sslocal)"
echo "         HTTP+SOCKS5 → 127.0.0.1:1082 (sing-box)"
