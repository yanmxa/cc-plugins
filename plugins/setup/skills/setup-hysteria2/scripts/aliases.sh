#!/bin/zsh
# Hysteria 2 客户端控制别名
# 用法：在 ~/.zshrc.local 中 source 此文件

# ── 路径 ───────────────────────────────────────────────────────────
export HY2_DIR="$HOME/.config/hysteria"
export HY2_CONFIG="$HY2_DIR/config.yaml"
export HY2_PLIST="$HOME/Library/LaunchAgents/com.hysteria.client.plist"
export HY2_LABEL="com.hysteria.client"
export HY2_LOG="$HY2_DIR/hysteria.log"
export HY2_ERR_LOG="$HY2_DIR/hysteria.err.log"
export HY2_SOCKS_PORT="${HY2_SOCKS_PORT:-1080}"
export HY2_HTTP_PORT="${HY2_HTTP_PORT:-1081}"

# ── 服务控制 ───────────────────────────────────────────────────────
hy2start() {
  if launchctl list | grep -q "$HY2_LABEL"; then
    echo "Hy2 已在运行"; hy2status; return
  fi
  launchctl load "$HY2_PLIST" 2>/dev/null
  launchctl start "$HY2_LABEL"
  sleep 1
  if pgrep -f "hysteria client" > /dev/null; then
    echo "Hy2 已启动 (PID: $(pgrep -f 'hysteria client'))"
  else
    echo "启动失败，查看日志：hy2log"
  fi
}

hy2stop() {
  launchctl stop "$HY2_LABEL" 2>/dev/null
  launchctl unload "$HY2_PLIST" 2>/dev/null
  pkill -f "hysteria client" 2>/dev/null
  echo "Hy2 已停止"
}

hy2restart() {
  launchctl kickstart -k "gui/$(id -u)/$HY2_LABEL" 2>/dev/null
  sleep 1
  if pgrep -f "hysteria client" > /dev/null; then
    echo "Hy2 已重启 (PID: $(pgrep -f 'hysteria client'))"
  else
    echo "重启失败，查看日志：hy2log"
  fi
}

hy2status() {
  if pgrep -f "hysteria client" > /dev/null; then
    echo "Hy2 运行中 (PID: $(pgrep -f 'hysteria client'))"
    echo "SOCKS5: 127.0.0.1:$HY2_SOCKS_PORT"
    echo "HTTP:   127.0.0.1:$HY2_HTTP_PORT"
    lsof -i ":$HY2_SOCKS_PORT" -i ":$HY2_HTTP_PORT" 2>/dev/null | grep LISTEN
  else
    echo "Hy2 未运行"
  fi
}

hy2log()  { tail -f "$HY2_LOG" "$HY2_ERR_LOG"; }
hy2logs() {
  echo "=== stdout ==="
  tail -n 50 "$HY2_LOG" 2>/dev/null
  echo ""
  echo "=== stderr ==="
  tail -n 50 "$HY2_ERR_LOG" 2>/dev/null
}

# 编辑配置 + 自动重启
hy2edit() {
  ${EDITOR:-nano} "$HY2_CONFIG"
  read -q "REPLY?重启 Hy2 应用新配置？(y/n) "
  echo ""
  [[ $REPLY == "y" ]] && hy2restart
}

# ── 终端代理开关（仅当前 shell） ──────────────────────────────────────
# 默认绕过的地址：本机 + .local + 常见内网段
# 可在 ~/.zshrc.local 里覆盖 HY2_NO_PROXY 来加自己的（如 *.company.com）
: "${HY2_NO_PROXY:=localhost,127.0.0.1,::1,*.local,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16}"

proxyon() {
  local http="http://127.0.0.1:$HY2_HTTP_PORT"
  local socks="socks5://127.0.0.1:$HY2_SOCKS_PORT"
  # 小写（curl/wget/git/python 等用）
  export http_proxy="$http" https_proxy="$http" all_proxy="$socks" no_proxy="$HY2_NO_PROXY"
  # 大写（Go/某些 RFC 兼容工具用）
  export HTTP_PROXY="$http" HTTPS_PROXY="$http" ALL_PROXY="$socks" NO_PROXY="$HY2_NO_PROXY"
  echo "代理已开启"
  echo "  http/https → $http"
  echo "  socks5     → $socks"
  echo "  bypass     → $HY2_NO_PROXY"
}

proxyoff() {
  unset http_proxy https_proxy all_proxy no_proxy
  unset HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY
  echo "代理已关闭"
}

# 安全自启动：只在 hysteria 真的在监听端口时才开代理（启动失败时不会污染 shell）
# 用法：在 ~/.zshrc.local 末尾加 `proxyon-auto`
proxyon-auto() {
  if lsof -i ":${HY2_HTTP_PORT:-1081}" -sTCP:LISTEN >/dev/null 2>&1; then
    proxyon >/dev/null
  fi
}

proxystatus() {
  if [[ -n "$http_proxy" || -n "$HTTP_PROXY" ]]; then
    echo "代理已开启:"
    echo "  http_proxy:  ${http_proxy:-<unset>}"
    echo "  HTTP_PROXY:  ${HTTP_PROXY:-<unset>}"
    echo "  all_proxy:   ${all_proxy:-<unset>}"
    echo "  no_proxy:    ${no_proxy:-<unset>}"
  else
    echo "代理未开启"
  fi
}

proxyip() {
  echo "=== 直连 IP ==="
  curl -s --max-time 5 https://api.ip.sb/geoip \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(f"  {d.get(\"ip\")} ({d.get(\"country\")} / {d.get(\"isp\")})")' 2>/dev/null \
    || echo "  连接失败"
  echo "=== Hy2 出口 IP ==="
  curl -s --max-time 5 -x "http://127.0.0.1:$HY2_HTTP_PORT" https://api.ip.sb/geoip \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(f"  {d.get(\"ip\")} ({d.get(\"country\")} / {d.get(\"isp\")})")' 2>/dev/null \
    || echo "  代理不通"
}

proxyspeed() {
  echo "测试 Hy2 下行速度（10MB 文件）..."
  curl -o /dev/null -x "http://127.0.0.1:$HY2_HTTP_PORT" \
    -w "下载速度: %{speed_download} B/s\n耗时: %{time_total}s\n" \
    https://speed.cloudflare.com/__down?bytes=10000000
}

# ── 一键命令 ───────────────────────────────────────────────────────
gohy2()   { hy2start; sleep 1; proxyon; proxyip; }
stophy2() { hy2stop; proxyoff; }

hy2help() {
  cat <<'EOF'
Hysteria 2 客户端命令：

服务管理：
  hy2start     启动 launchd 服务
  hy2stop      停止
  hy2restart   重启
  hy2status    查看 PID + 监听端口
  hy2log       实时日志（Ctrl+C 退出）
  hy2logs      最近 50 行日志
  hy2edit      编辑 ~/.config/hysteria/config.yaml + 自动重启

代理控制（仅当前 shell）：
  proxyon / proxyoff / proxystatus
  proxyip      对比直连 / 代理出口 IP
  proxyspeed   测试代理下行速度

一键命令：
  gohy2        启动 Hy2 + 开代理 + 测试 IP
  stophy2      停止 Hy2 + 关代理

文件位置：
  ~/.config/hysteria/config.yaml                       配置（chmod 600）
  ~/Library/LaunchAgents/com.hysteria.client.plist     launchd 服务
  ~/.config/hysteria/hysteria.log / hysteria.err.log   日志
EOF
}
