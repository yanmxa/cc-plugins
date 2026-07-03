#!/usr/bin/env bash
# Runs ON the Linux VPS (pushed there by ssh-deploy.sh). Installs a shadowsocks-rust
# server (ssserver) with a systemd service + firewall rule, then prints the client
# credentials + ss:// URI in a RESULT block. Debian/Ubuntu (apt).
#
# Params via env (non-secret):  SS_PORT (8388)   SS_METHOD (aes-256-gcm)
# The password is generated here and returned — never passed in.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

PORT="${SS_PORT:-8388}"
METHOD="${SS_METHOD:-aes-256-gcm}"

echo "=== [1/6] deps ==="
need=""
command -v curl    >/dev/null 2>&1 || need="$need curl"
command -v xz      >/dev/null 2>&1 || need="$need xz-utils"
command -v ss      >/dev/null 2>&1 || need="$need iproute2"
command -v openssl >/dev/null 2>&1 || need="$need openssl"
if [ -n "$need" ]; then
  apt-get -o DPkg::Lock::Timeout=120 update -y
  apt-get -o DPkg::Lock::Timeout=120 install -y $need
fi

echo "=== [2/6] download shadowsocks-rust ==="
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  A="x86_64-unknown-linux-gnu" ;;
  aarch64) A="aarch64-unknown-linux-gnu" ;;
  *) echo "UNSUPPORTED_ARCH=$ARCH"; exit 1 ;;
esac
VER="$(curl -fsSL --max-time 20 https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest \
       | grep -oP '"tag_name":\s*"\K[^"]+' || true)"
[ -z "$VER" ] && VER="v1.23.5"
echo "VER=$VER ASSET=$A"
cd /tmp
URL="https://github.com/shadowsocks/shadowsocks-rust/releases/download/${VER}/shadowsocks-${VER}.${A}.tar.xz"
curl -fSL --retry 3 --max-time 120 -o ssrust.tar.xz "$URL"
tar -xJf ssrust.tar.xz ssserver
install -m 0755 ssserver /usr/local/bin/ssserver
rm -f ssrust.tar.xz ssserver
/usr/local/bin/ssserver --version

echo "=== [3/6] config ==="
PW="$(openssl rand -base64 16 | tr -d '\n')"
mkdir -p /etc/shadowsocks-rust
cat > /etc/shadowsocks-rust/config.json <<EOF
{
    "server": "0.0.0.0",
    "server_port": ${PORT},
    "password": "${PW}",
    "method": "${METHOD}",
    "mode": "tcp_and_udp",
    "timeout": 300
}
EOF
chmod 600 /etc/shadowsocks-rust/config.json

echo "=== [4/6] service ==="
cat > /etc/systemd/system/shadowsocks-rust.service <<'EOF'
[Unit]
Description=Shadowsocks-rust Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ssserver -c /etc/shadowsocks-rust/config.json
Restart=on-failure
RestartSec=3
LimitNOFILE=51200

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable shadowsocks-rust >/dev/null 2>&1 || true
systemctl restart shadowsocks-rust
sleep 1
systemctl is-active shadowsocks-rust || {
  echo "!! service not active — recent logs:"; journalctl -u shadowsocks-rust -n 20 --no-pager 2>/dev/null || true; }

echo "=== [5/6] firewall ==="
if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -qi "Status: active"; then
  ufw allow ${PORT}/tcp >/dev/null 2>&1 || true
  ufw allow ${PORT}/udp >/dev/null 2>&1 || true
  echo "ufw: opened ${PORT} tcp+udp"
else
  echo "ufw: inactive/absent (host firewall not blocking)"
fi

echo "=== [6/6] verify ==="
ss -tlnp 2>/dev/null | grep ":${PORT} " || echo "WARN: not listening (tcp) on ${PORT}"

IP="$(curl -fsSL --max-time 8 https://api.ipify.org 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')"
USERINFO="$(printf '%s:%s' "$METHOD" "$PW" | base64 | tr -d '\n')"
echo "==== RESULT ===="
echo "SS_SERVER=$IP"
echo "SS_PORT=$PORT"
echo "SS_METHOD=$METHOD"
echo "SS_PASSWORD=$PW"
echo "SS_URI=ss://${USERINFO}@${IP}:${PORT}#SS-${IP}"
echo "==== DONE ===="
