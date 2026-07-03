#!/bin/bash
# deploy-hysteria2-server.sh — SERVER mode. Runs on your Mac; SSH-deploys a
# Hysteria2 server to a Linux VPS and prints ready-to-paste client credentials.
# Invoked by `setup-hysteria2.sh --server ...`.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SERVER_PORT=443
SNI="bing.com"
export SSH_USER="root" SSH_PORT="22"

usage() {
  cat <<'USAGE'
Usage: setup-hysteria2.sh --server --host <ip> [options]

  --host <ip>          (required) VPS host / IP
  --ssh-user <u>       SSH user (default: root)
  --ssh-port <p>       SSH port (default: 22)
  --ssh-key <path>     private key for auth (default: ssh-agent / ~/.ssh keys)
  --server-port <n>    Hysteria2 listen port (default: 443, UDP)
  --sni <domain>       masquerade / SNI domain (default: bing.com)

Requires key-based SSH access to the VPS (run `ssh-copy-id <user>@<host>` once).
Deploys via the official hysteria installer + a self-signed cert + systemd.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)        export SSH_HOST="$2"; shift 2 ;;
    --ssh-user)    export SSH_USER="$2"; shift 2 ;;
    --ssh-port)    export SSH_PORT="$2"; shift 2 ;;
    --ssh-key)     export SSH_KEY="$2";  shift 2 ;;
    --server-port) SERVER_PORT="$2";     shift 2 ;;
    --sni)         SNI="$2";             shift 2 ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [ -z "${SSH_HOST:-}" ]; then
  echo "ERROR: --host is required" >&2; usage; exit 1
fi

# shellcheck source=ssh-deploy.sh
source "$SCRIPT_DIR/ssh-deploy.sh"

echo "=== Hysteria2 SERVER deploy → $SSH_USER@$SSH_HOST:$SSH_PORT ==="
echo "  listen :$SERVER_PORT (UDP)   masquerade/SNI: $SNI"
echo ""

ssh_precheck || exit 1

LOG="$(mktemp -t hy2deploy)"
trap 'rm -f "$LOG"' EXIT
ssh_run_remote_script "$SCRIPT_DIR/server-install-hysteria2.sh" \
  "HY2_PORT=$SERVER_PORT" "HY2_SNI=$SNI" | tee "$LOG"

get() { grep "^$1=" "$LOG" | tail -1 | cut -d= -f2-; }
SRV="$(get HY2_SERVER)"; PORT="$(get HY2_PORT)"; DSNI="$(get HY2_SNI)"
AUTH="$(get HY2_AUTH)"; PIN="$(get HY2_PINSHA256)"

if [ -z "$AUTH" ] || [ -z "$PIN" ]; then
  echo ""; echo "ERROR: deploy did not return credentials — check the output above." >&2
  exit 1
fi

cat <<EOF

╔══════════════════════════════════════════════════════════════╗
║              Hysteria2 server is up — client info            ║
╚══════════════════════════════════════════════════════════════╝

  server     ${SRV}:${PORT}
  auth       ${AUTH}
  sni        ${DSNI}
  pinSHA256  ${PIN}

── For the standalone hysteria2 client (~/.config/hysteria/config.yaml) ──
server: ${SRV}:${PORT}
auth: ${AUTH}
tls:
  sni: ${DSNI}
  insecure: true
  pinSHA256: ${PIN}

── For the sing-box client (the "hy2" outbound in ~/.config/sing-box/config.json) ──
  "server": "${SRV}",
  "server_port": ${PORT},
  "password": "${AUTH}",
  "tls": { "enabled": true, "server_name": "${DSNI}", "insecure": true }

Next: set up the client with  setup-hysteria2 (--client)  or  setup-sing-box,
then paste the fields above.  (sing-box has no SHA256 pin — insecure covers it.)
EOF
