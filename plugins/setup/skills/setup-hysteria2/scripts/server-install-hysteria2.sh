#!/usr/bin/env bash
# Runs ON the Linux VPS (pushed there by ssh-deploy.sh). Installs a Hysteria2
# server with a self-signed cert, systemd service, and firewall rule, then prints
# the client credentials in a RESULT block. Debian/Ubuntu (apt). Idempotent-ish.
#
# Params via env (non-secret):  HY2_PORT (443)   HY2_SNI (bing.com)
# The auth password is generated here and returned — never passed in.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

PORT="${HY2_PORT:-443}"
SNI="${HY2_SNI:-bing.com}"

echo "=== [1/6] deps ==="
need=""
command -v curl    >/dev/null 2>&1 || need="$need curl"
command -v openssl >/dev/null 2>&1 || need="$need openssl"
if [ -n "$need" ]; then
  apt-get -o DPkg::Lock::Timeout=120 update -y
  apt-get -o DPkg::Lock::Timeout=120 install -y $need
fi

echo "=== [2/6] install hysteria (official installer) ==="
if ! command -v hysteria >/dev/null 2>&1; then
  curl -fsSL https://get.hy2.sh/ | bash
fi
hysteria version 2>/dev/null | head -1 || true

echo "=== [3/6] self-signed cert (CN=$SNI) ==="
mkdir -p /etc/hysteria
if [ ! -f /etc/hysteria/server.crt ]; then
  openssl ecparam -genkey -name prime256v1 -out /etc/hysteria/server.key
  openssl req -new -x509 -days 3650 -key /etc/hysteria/server.key \
    -out /etc/hysteria/server.crt -subj "/CN=$SNI" \
    -addext "subjectAltName=DNS:$SNI" 2>/dev/null
fi
# hysteria-server.service runs as the 'hysteria' user — let it read the key
chown hysteria:hysteria /etc/hysteria/server.crt /etc/hysteria/server.key 2>/dev/null || true
chmod 644 /etc/hysteria/server.crt; chmod 600 /etc/hysteria/server.key

echo "=== [4/6] config ==="
PW="$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | cut -c1-32)"
cat > /etc/hysteria/config.yaml <<EOF
listen: :$PORT

tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: $PW

# 未认证流量伪装成 $SNI 的反代，抗探测
masquerade:
  type: proxy
  proxy:
    url: https://$SNI
    rewriteHost: true
EOF
chown hysteria:hysteria /etc/hysteria/config.yaml 2>/dev/null || true
chmod 600 /etc/hysteria/config.yaml

echo "=== [5/6] service ==="
systemctl enable hysteria-server.service >/dev/null 2>&1 || true
systemctl restart hysteria-server.service
sleep 1
systemctl is-active hysteria-server.service || {
  echo "!! service not active — recent logs:"; journalctl -u hysteria-server.service -n 20 --no-pager 2>/dev/null || true; }

echo "=== [6/6] firewall ==="
if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -qi "Status: active"; then
  ufw allow ${PORT}/udp >/dev/null 2>&1 || true
  ufw allow ${PORT}/tcp >/dev/null 2>&1 || true
  echo "ufw: opened ${PORT} udp+tcp"
else
  echo "ufw: inactive/absent (host firewall not blocking)"
fi

PIN="$(openssl x509 -in /etc/hysteria/server.crt -noout -fingerprint -sha256 | sed 's/.*=//; s/://g')"
IP="$(curl -fsSL --max-time 8 https://api.ipify.org 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')"

echo "==== RESULT ===="
echo "HY2_SERVER=$IP"
echo "HY2_PORT=$PORT"
echo "HY2_SNI=$SNI"
echo "HY2_AUTH=$PW"
echo "HY2_PINSHA256=$PIN"
echo "==== DONE ===="
