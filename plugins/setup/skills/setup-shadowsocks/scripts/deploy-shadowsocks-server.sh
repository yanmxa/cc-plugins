#!/bin/bash
# deploy-shadowsocks-server.sh — SERVER mode. Runs on your Mac; SSH-deploys a
# shadowsocks-rust server to a Linux VPS and prints ready-to-paste client info.
# Invoked by `setup-shadowsocks.sh --server ...`.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SERVER_PORT=8388
METHOD="aes-256-gcm"
export SSH_USER="root" SSH_PORT="22"

usage() {
  cat <<'USAGE'
Usage: setup-shadowsocks.sh --server --host <ip> [options]

  --host <ip>          (required) VPS host / IP
  --ssh-user <u>       SSH user (default: root)
  --ssh-port <p>       SSH port (default: 22)
  --ssh-key <path>     private key for auth (default: ssh-agent / ~/.ssh keys)
  --server-port <n>    Shadowsocks listen port (default: 8388)
  --method <cipher>    AEAD cipher (default: aes-256-gcm; or chacha20-ietf-poly1305)

Requires key-based SSH access to the VPS (run `ssh-copy-id <user>@<host>` once).
Deploys shadowsocks-rust (ssserver) + systemd + firewall.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)        export SSH_HOST="$2"; shift 2 ;;
    --ssh-user)    export SSH_USER="$2"; shift 2 ;;
    --ssh-port)    export SSH_PORT="$2"; shift 2 ;;
    --ssh-key)     export SSH_KEY="$2";  shift 2 ;;
    --server-port) SERVER_PORT="$2";     shift 2 ;;
    --method)      METHOD="$2";          shift 2 ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [ -z "${SSH_HOST:-}" ]; then
  echo "ERROR: --host is required" >&2; usage; exit 1
fi

# shellcheck source=ssh-deploy.sh
source "$SCRIPT_DIR/ssh-deploy.sh"

echo "=== Shadowsocks SERVER deploy → $SSH_USER@$SSH_HOST:$SSH_PORT ==="
echo "  listen :$SERVER_PORT   method: $METHOD"
echo ""

ssh_precheck || exit 1

LOG="$(mktemp -t ssdeploy)"
trap 'rm -f "$LOG"' EXIT
ssh_run_remote_script "$SCRIPT_DIR/server-install-shadowsocks.sh" \
  "SS_PORT=$SERVER_PORT" "SS_METHOD=$METHOD" | tee "$LOG"

get() { grep "^$1=" "$LOG" | tail -1 | cut -d= -f2-; }
SRV="$(get SS_SERVER)"; PORT="$(get SS_PORT)"; DMETHOD="$(get SS_METHOD)"
PW="$(get SS_PASSWORD)"; URI="$(get SS_URI)"

if [ -z "$PW" ]; then
  echo ""; echo "ERROR: deploy did not return credentials — check the output above." >&2
  exit 1
fi

cat <<EOF

╔══════════════════════════════════════════════════════════════╗
║             Shadowsocks server is up — client info           ║
╚══════════════════════════════════════════════════════════════╝

  server     ${SRV}:${PORT}
  method     ${DMETHOD}
  password   ${PW}

  ss:// link (import into most clients / scan as QR):
  ${URI}

── For the sing-box client (the "ss" outbound in ~/.config/sing-box/config.json) ──
  "server": "${SRV}",
  "server_port": ${PORT},
  "method": "${DMETHOD}",
  "password": "${PW}"

Next: set up a client with  setup-shadowsocks (--client)  or  setup-sing-box,
then paste the fields above.
EOF
