#!/bin/zsh
# sing-box 客户端控制别名（Hysteria2 + Shadowsocks 二合一）
# 用法：在 ~/.zshrc.local 中 source 此文件

# ── 路径 ───────────────────────────────────────────────────────────
export SB_DIR="$HOME/.config/sing-box"
export SB_CONFIG="$SB_DIR/config.json"
export SB_PLIST="$HOME/Library/LaunchAgents/com.sing-box.client.plist"
export SB_LABEL="com.sing-box.client"
export SB_LOG="$SB_DIR/sing-box.log"
export SB_ERR_LOG="$SB_DIR/sing-box.err.log"
# 本地混合端口（SOCKS5 + HTTP 同口）。改这里要同步改 config.json 的 listen_port
export SB_MIXED_PORT="${SB_MIXED_PORT:-1082}"
# sing-box 可执行文件（手动模式后台直跑时用）
export SB_BIN="${SB_BIN:-$(command -v sing-box 2>/dev/null)}"

# 是否为 launchd 服务模式（存在 plist 即是；否则为手动模式）
sb_is_service() { [ -f "$SB_PLIST" ]; }

# ── 服务控制 ───────────────────────────────────────────────────────
sbstart() {
  if pgrep -f "sing-box run" > /dev/null; then
    echo "sing-box 已在运行"; sbstatus; return
  fi
  # 启动前先校验配置，避免带着坏配置起服务
  if [ -n "$SB_BIN" ] && ! "$SB_BIN" check -c "$SB_CONFIG" 2>/dev/null; then
    echo "配置校验失败，请先修复：sbedit"; "$SB_BIN" check -c "$SB_CONFIG"; return 1
  fi
  if sb_is_service; then
    launchctl load "$SB_PLIST" 2>/dev/null
    launchctl start "$SB_LABEL"
  else
    if [ -z "$SB_BIN" ]; then
      echo "找不到 sing-box 可执行文件（设置 SB_BIN 或用 brew 安装）"; return 1
    fi
    nohup "$SB_BIN" run -c "$SB_CONFIG" >>"$SB_LOG" 2>>"$SB_ERR_LOG" &
    disown 2>/dev/null
  fi
  sleep 1
  if pgrep -f "sing-box run" > /dev/null; then
    echo "sing-box 已启动 (PID: $(pgrep -f 'sing-box run'))"
  else
    echo "启动失败，查看日志：sblog"
  fi
}

sbstop() {
  if sb_is_service; then
    launchctl stop "$SB_LABEL" 2>/dev/null
    launchctl unload "$SB_PLIST" 2>/dev/null
  fi
  pkill -f "sing-box run" 2>/dev/null
  echo "sing-box 已停止"
}

sbrestart() {
  if sb_is_service; then
    launchctl kickstart -k "gui/$(id -u)/$SB_LABEL" 2>/dev/null
  else
    sbstop >/dev/null; sleep 1; sbstart; return
  fi
  sleep 1
  if pgrep -f "sing-box run" > /dev/null; then
    echo "sing-box 已重启 (PID: $(pgrep -f 'sing-box run'))"
  else
    echo "重启失败，查看日志：sblog"
  fi
}

sbstatus() {
  if pgrep -f "sing-box run" > /dev/null; then
    echo "sing-box 运行中 (PID: $(pgrep -f 'sing-box run'))"
    if sb_is_service; then
      echo "模式:   launchd 服务（开机自启 + 崩溃自动拉起）"
    else
      echo "模式:   手动（无开机自启）"
    fi
    echo "出站:   $(sbnode)"
    echo "混合口: 127.0.0.1:$SB_MIXED_PORT (SOCKS5 + HTTP)"
    lsof -i ":$SB_MIXED_PORT" 2>/dev/null | grep LISTEN
  else
    echo "sing-box 未运行"
  fi
}

sblog()  { tail -f "$SB_LOG" "$SB_ERR_LOG"; }
sblogs() {
  echo "=== stdout ==="; tail -n 50 "$SB_LOG" 2>/dev/null
  echo ""; echo "=== stderr ==="; tail -n 50 "$SB_ERR_LOG" 2>/dev/null
}

# 编辑配置 + 校验 + 自动重启（校验不过不重启，防止带坏配置）
sbedit() {
  ${EDITOR:-nano} "$SB_CONFIG"
  if [ -n "$SB_BIN" ] && ! "$SB_BIN" check -c "$SB_CONFIG"; then
    echo "配置校验未通过，未重启。修好再 sbrestart。"; return 1
  fi
  read -q "REPLY?重启 sing-box 应用新配置？(y/n) "; echo ""
  [[ $REPLY == "y" ]] && sbrestart
}

# 查看/切换默认出站：sbnode            → 打印当前默认
#                    sbnode ss|hy2|auto → 切换并重启
sbnode() {
  if [ -z "$1" ]; then
    grep -o '"default": *"[^"]*"' "$SB_CONFIG" | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
    return
  fi
  case "$1" in
    ss|hy2|auto) ;;
    *) echo "用法: sbnode [ss|hy2|auto]"; return 1 ;;
  esac
  sed -i '' 's/"default": *"[^"]*"/"default": "'"$1"'"/' "$SB_CONFIG"
  echo "默认出站 → $1"
  if pgrep -f "sing-box run" > /dev/null; then sbrestart; fi
}

# ── 终端代理开关（仅当前 shell，指向 sing-box 混合口） ─────────────────
# 默认绕过：本机 + .local + 常见内网段。可在 ~/.zshrc.local 覆盖 SB_NO_PROXY
: "${SB_NO_PROXY:=localhost,127.0.0.1,::1,*.local,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16}"

sbon() {
  local url="http://127.0.0.1:$SB_MIXED_PORT"
  local socks="socks5://127.0.0.1:$SB_MIXED_PORT"
  export http_proxy="$url" https_proxy="$url" all_proxy="$socks" no_proxy="$SB_NO_PROXY"
  export HTTP_PROXY="$url" HTTPS_PROXY="$url" ALL_PROXY="$socks" NO_PROXY="$SB_NO_PROXY"
  echo "代理已开启 → $url (SOCKS5/HTTP 同口)"
  echo "  bypass → $SB_NO_PROXY"
}

sboff() {
  unset http_proxy https_proxy all_proxy no_proxy
  unset HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY
  echo "代理已关闭"
}

# 安全自启：仅当 sing-box 真在监听端口时才开代理（启动失败不会污染 shell）
# 用法：在 ~/.zshrc.local 末尾加 `sbon-auto`
sbon-auto() {
  if lsof -i ":$SB_MIXED_PORT" -sTCP:LISTEN >/dev/null 2>&1; then sbon >/dev/null; fi
}

sbproxystatus() {
  if [[ -n "$http_proxy" || -n "$HTTP_PROXY" ]]; then
    echo "代理已开启:"
    echo "  http_proxy: ${http_proxy:-<unset>}"
    echo "  all_proxy:  ${all_proxy:-<unset>}"
    echo "  no_proxy:   ${no_proxy:-<unset>}"
  else
    echo "代理未开启"
  fi
}

sbip() {
  echo "=== 直连 IP ==="
  curl -s --max-time 5 https://api.ip.sb/geoip \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(f"  {d.get(\"ip\")} ({d.get(\"country\")} / {d.get(\"isp\")})")' 2>/dev/null \
    || echo "  连接失败"
  echo "=== sing-box 出口 IP（当前出站: $(sbnode)）==="
  curl -s --max-time 8 -x "http://127.0.0.1:$SB_MIXED_PORT" https://api.ip.sb/geoip \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(f"  {d.get(\"ip\")} ({d.get(\"country\")} / {d.get(\"isp\")})")' 2>/dev/null \
    || echo "  代理不通"
}

sbspeed() {
  echo "测试 sing-box 下行速度（10MB，当前出站: $(sbnode)）..."
  curl -o /dev/null -x "http://127.0.0.1:$SB_MIXED_PORT" \
    -w "下载速度: %{speed_download} B/s\n耗时: %{time_total}s\n" \
    https://speed.cloudflare.com/__down?bytes=10000000
}

# ── 一键命令 ───────────────────────────────────────────────────────
gosb()   { sbstart; sleep 1; sbon; sbip; }
stopsb() { sbstop; sboff; }

sbhelp() {
  cat <<'EOF'
sing-box 客户端命令（Hysteria2 + Shadowsocks 二合一）：

服务管理（自动适配 launchd 服务 / 手动模式）：
  sbstart      启动（启动前自动 sing-box check）
  sbstop       停止
  sbrestart    重启
  sbstatus     PID + 模式 + 当前出站 + 监听端口
  sblog        实时日志（Ctrl+C 退出）
  sblogs       最近 50 行日志
  sbedit       编辑 config.json + 校验 + 自动重启

出站切换：
  sbnode              打印当前默认出站
  sbnode ss|hy2|auto  切换默认出站并重启（auto = 自动测速选最快）

代理控制（仅当前 shell）：
  sbon / sboff / sbproxystatus
  sbip         对比直连 / 代理出口 IP
  sbspeed      测试代理下行速度

一键命令：
  gosb         启动 sing-box + 开代理 + 测 IP
  stopsb       停止 sing-box + 关代理

文件位置：
  ~/.config/sing-box/config.json                       配置（chmod 600）
  ~/Library/LaunchAgents/com.sing-box.client.plist     launchd 服务（仅自启模式）
  ~/.config/sing-box/sing-box.log / .err.log           日志
EOF
}
