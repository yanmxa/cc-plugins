#!/bin/zsh
# Shadowsocks 客户端(shadowsocks-rust / sslocal)控制别名
# 用法：在 ~/.zshrc.local 中 source 此文件

# ── 路径 ───────────────────────────────────────────────────────────
export SS_DIR="$HOME/.config/shadowsocks"
export SS_CONFIG="$SS_DIR/config.json"
export SS_PLIST="$HOME/Library/LaunchAgents/com.shadowsocks.client.plist"
export SS_LABEL="com.shadowsocks.client"
export SS_LOG="$SS_DIR/shadowsocks.log"
export SS_ERR_LOG="$SS_DIR/shadowsocks.err.log"
# 本地 SOCKS5 端口。改这里要同步改 config.json 的 local_port
export SS_SOCKS_PORT="${SS_SOCKS_PORT:-1084}"
# sslocal 可执行文件（手动模式后台直跑时用）
export SS_BIN="${SS_BIN:-$(command -v sslocal 2>/dev/null)}"

# 是否为 launchd 服务模式（存在 plist 即是；否则为手动模式）
ss_is_service() { [ -f "$SS_PLIST" ]; }

# ── 服务控制 ───────────────────────────────────────────────────────
# 启动 HTTP→SOCKS5 转换层(sing-box mixed 口 1082)
_ss_http_start() {
  if ! pgrep -f "sing-box.*ss-http" > /dev/null 2>&1; then
    nohup sing-box run -c "$SS_DIR/http-proxy.json" > /dev/null 2>&1 &
    sleep 1
  fi
}
_ss_http_stop() {
  pkill -f "sing-box.*ss-http" 2>/dev/null
}

ssstart() {
  if pgrep -f "sslocal -c" > /dev/null; then
    echo "Shadowsocks 已在运行"; _ss_http_start; ssstatus; return
  fi
  if ss_is_service; then
    launchctl load "$SS_PLIST" 2>/dev/null
    launchctl start "$SS_LABEL"
  else
    if [ -z "$SS_BIN" ]; then
      echo "找不到 sslocal 可执行文件（设置 SS_BIN 或 brew install shadowsocks-rust）"; return 1
    fi
    nohup "$SS_BIN" -c "$SS_CONFIG" >>"$SS_LOG" 2>>"$SS_ERR_LOG" &
    disown 2>/dev/null
  fi
  sleep 1
  if pgrep -f "sslocal -c" > /dev/null; then
    echo "Shadowsocks 已启动 (PID: $(pgrep -f 'sslocal -c'))"
    _ss_http_start
  else
    echo "启动失败，查看日志：sslog"
  fi
}

ssstop() {
  if ss_is_service; then
    launchctl stop "$SS_LABEL" 2>/dev/null
    launchctl unload "$SS_PLIST" 2>/dev/null
  fi
  pkill -f "sslocal -c" 2>/dev/null
  _ss_http_stop
  echo "Shadowsocks 已停止"
}

ssrestart() {
  if ss_is_service; then
    launchctl kickstart -k "gui/$(id -u)/$SS_LABEL" 2>/dev/null
  else
    ssstop >/dev/null; sleep 1; ssstart; return
  fi
  sleep 1
  if pgrep -f "sslocal -c" > /dev/null; then
    echo "Shadowsocks 已重启 (PID: $(pgrep -f 'sslocal -c'))"
  else
    echo "重启失败，查看日志：sslog"
  fi
}

ssstatus() {
  if pgrep -f "sslocal -c" > /dev/null; then
    echo "Shadowsocks 运行中 (PID: $(pgrep -f 'sslocal -c'))"
    if ss_is_service; then
      echo "模式:   launchd 服务（开机自启 + 崩溃自动拉起）"
    else
      echo "模式:   手动（无开机自启）"
    fi
    echo "SOCKS5: 127.0.0.1:$SS_SOCKS_PORT"
    echo "HTTP:   127.0.0.1:1082"
    lsof -i ":$SS_SOCKS_PORT" -i ":1082" 2>/dev/null | grep LISTEN
  else
    echo "Shadowsocks 未运行"
  fi
}

sslog()  { tail -f "$SS_LOG" "$SS_ERR_LOG"; }
sslogs() {
  echo "=== stdout ==="; tail -n 50 "$SS_LOG" 2>/dev/null
  echo ""; echo "=== stderr ==="; tail -n 50 "$SS_ERR_LOG" 2>/dev/null
}

# 编辑配置 + 自动重启（sslocal 无 check 子命令；坏配置会在启动时报错，见 sslog）
ssedit() {
  ${EDITOR:-nano} "$SS_CONFIG"
  read -q "REPLY?重启 Shadowsocks 应用新配置？(y/n) "; echo ""
  [[ $REPLY == "y" ]] && ssrestart
}

# ── 终端代理开关（仅当前 shell，指向 SS SOCKS5 口） ────────────────────
# sslocal 只提供 SOCKS5；纯 HTTP-only 的程序请改用 sing-box(混合口)。curl/git/python 走 socks5h 即可。
: "${SS_NO_PROXY:=localhost,127.0.0.1,::1,*.local,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16}"

sson() {
  # sing-box 混合口(1082)：同时提供 HTTP 代理 + SOCKS5
  # 底层通过 SOCKS5 转发到 sslocal(1084)
  local http="http://127.0.0.1:1082"
  local socks="socks5://127.0.0.1:1082"
  export http_proxy="$http" https_proxy="$http" all_proxy="$socks" no_proxy="$SS_NO_PROXY"
  export HTTP_PROXY="$http" HTTPS_PROXY="$http" ALL_PROXY="$socks" NO_PROXY="$SS_NO_PROXY"
  echo "代理已开启"
  echo "  http/https → $http"
  echo "  socks5     → $socks"
  echo "  bypass     → $SS_NO_PROXY"
}

ssoff() {
  unset http_proxy https_proxy all_proxy no_proxy
  unset HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY
  echo "代理已关闭"
}

# 安全自启：仅当 sslocal 真在监听端口时才开代理
# 用法：在 ~/.zshrc.local 末尾加 `sson-auto`
sson-auto() {
  if lsof -i ":$SS_SOCKS_PORT" -sTCP:LISTEN >/dev/null 2>&1; then sson >/dev/null; fi
}

ssproxystatus() {
  if [[ -n "$all_proxy" || -n "$ALL_PROXY" ]]; then
    echo "代理已开启:"
    echo "  all_proxy: ${all_proxy:-<unset>}"
    echo "  no_proxy:  ${no_proxy:-<unset>}"
  else
    echo "代理未开启"
  fi
}

ssip() {
  echo "=== 直连 IP ==="
  curl -s --max-time 5 https://api.ip.sb/geoip \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(f"  {d.get(\"ip\")} ({d.get(\"country\")} / {d.get(\"isp\")})")' 2>/dev/null \
    || echo "  连接失败"
  echo "=== SS 出口 IP ==="
  curl -s --max-time 8 -x "socks5h://127.0.0.1:$SS_SOCKS_PORT" https://api.ip.sb/geoip \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(f"  {d.get(\"ip\")} ({d.get(\"country\")} / {d.get(\"isp\")})")' 2>/dev/null \
    || echo "  代理不通"
}

ssspeed() {
  echo "测试 SS 下行速度（10MB）..."
  curl -o /dev/null -x "socks5h://127.0.0.1:$SS_SOCKS_PORT" \
    -w "下载速度: %{speed_download} B/s\n耗时: %{time_total}s\n" \
    https://speed.cloudflare.com/__down?bytes=10000000
}

# ── 一键命令 ───────────────────────────────────────────────────────
goss()   { ssstart; sleep 1; sson; ssip; }
stopss() { ssstop; ssoff; }

sshelp() {
  cat <<'EOF'
Shadowsocks 客户端命令（shadowsocks-rust / sslocal）：

服务管理（自动适配 launchd 服务 / 手动模式）：
  ssstart      启动
  ssstop       停止
  ssrestart    重启
  ssstatus     PID + 模式 + 监听端口
  sslog        实时日志（Ctrl+C 退出）
  sslogs       最近 50 行日志
  ssedit       编辑 config.json + 自动重启

代理控制（仅当前 shell，SOCKS5）：
  sson / ssoff / ssproxystatus
  ssip         对比直连 / 代理出口 IP
  ssspeed      测试代理下行速度

一键命令：
  goss         启动 SS + 开代理 + 测 IP
  stopss       停止 SS + 关代理

文件位置：
  ~/.config/shadowsocks/config.json                    配置（chmod 600）
  ~/Library/LaunchAgents/com.shadowsocks.client.plist  launchd 服务（仅自启模式）
  ~/.config/shadowsocks/shadowsocks.log / .err.log     日志
EOF
}
