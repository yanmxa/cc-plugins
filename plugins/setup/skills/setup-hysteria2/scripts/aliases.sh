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
export HY2_MIXED_PORT="${HY2_MIXED_PORT:-1083}"     # sing-box 混合口（对外统一端口）
# hysteria 可执行文件（手动模式后台直跑时用）
# 优先用 ~/.local/bin/hysteria（可手动 pin 版本），其次 Homebrew，最后 PATH
if [ -x "$HOME/.local/bin/hysteria" ]; then
  export HY2_BIN="$HOME/.local/bin/hysteria"
elif [ -x "/opt/homebrew/bin/hysteria" ]; then
  export HY2_BIN="/opt/homebrew/bin/hysteria"
else
  export HY2_BIN="${HY2_BIN:-$(command -v hysteria 2>/dev/null)}"
fi

# 是否为 launchd 服务模式（存在 plist 即是；否则为手动模式）
hy2_is_service() { [ -f "$HY2_PLIST" ]; }

# ── sing-box HTTP+SOCKS5 混合口（:1083 → hysteria SOCKS5 :1080） ────
_hy2_http_start() {
  if ! lsof -i ":$HY2_MIXED_PORT" -sTCP:LISTEN > /dev/null 2>&1; then
    nohup sing-box run -c "$HY2_DIR/http-proxy.json" > /dev/null 2>&1 &
    sleep 2
  fi
}
_hy2_http_stop() {
  pkill -f "sing-box.*hy2-http" 2>/dev/null
  # fallback: kill by listening port
  local pid; pid="$(lsof -ti ":$HY2_MIXED_PORT" -sTCP:LISTEN 2>/dev/null)"
  [ -n "$pid" ] && kill "$pid" 2>/dev/null
}

# ── 服务控制 ───────────────────────────────────────────────────────
hy2start() {
  if pgrep -f "hysteria client" > /dev/null; then
    echo "Hy2 已在运行"; hy2status; return
  fi
  if hy2_is_service; then
    # launchd 服务模式
    launchctl load "$HY2_PLIST" 2>/dev/null
    launchctl start "$HY2_LABEL"
  else
    # 手动模式（无 launchd）：后台直跑，日志写入同一位置
    if [ -z "$HY2_BIN" ]; then
      echo "找不到 hysteria 可执行文件（设置 HY2_BIN 或用 brew 安装）"; return 1
    fi
    nohup "$HY2_BIN" client -c "$HY2_CONFIG" >>"$HY2_LOG" 2>>"$HY2_ERR_LOG" &
    disown 2>/dev/null
  fi
  sleep 1
  if pgrep -f "hysteria client" > /dev/null; then
    echo "Hy2 已启动 (PID: $(pgrep -f 'hysteria client'))"
    _hy2_http_start
  else
    echo "启动失败，查看日志：hy2log"
  fi
}

hy2stop() {
  if hy2_is_service; then
    launchctl stop "$HY2_LABEL" 2>/dev/null
    launchctl unload "$HY2_PLIST" 2>/dev/null
  fi
  pkill -f "hysteria client" 2>/dev/null
  _hy2_http_stop
  echo "Hy2 已停止"
}

hy2restart() {
  if hy2_is_service; then
    launchctl kickstart -k "gui/$(id -u)/$HY2_LABEL" 2>/dev/null
  else
    # 手动模式：停后再起
    hy2stop >/dev/null; sleep 1; hy2start; return
  fi
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
    if hy2_is_service; then
      echo "模式:   launchd 服务（开机自启 + 崩溃自动拉起）"
    else
      echo "模式:   手动（无开机自启）"
    fi
    echo "SOCKS5: 127.0.0.1:$HY2_SOCKS_PORT"
    echo "HTTP:   127.0.0.1:$HY2_HTTP_PORT"
    echo "统一口: 127.0.0.1:$HY2_MIXED_PORT  (HTTP+SOCKS5)"
    lsof -i ":$HY2_SOCKS_PORT" -i ":$HY2_MIXED_PORT" 2>/dev/null | grep LISTEN
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

hy2on() {
  local http="http://127.0.0.1:$HY2_MIXED_PORT"
  local socks="socks5://127.0.0.1:$HY2_MIXED_PORT"
  export http_proxy="$http" https_proxy="$http" all_proxy="$socks" no_proxy="$HY2_NO_PROXY"
  export HTTP_PROXY="$http" HTTPS_PROXY="$http" ALL_PROXY="$socks" NO_PROXY="$HY2_NO_PROXY"
  echo "代理已开启"
  echo "  http/https → $http"
  echo "  socks5     → $socks"
  echo "  bypass     → $HY2_NO_PROXY"
}

hy2off() {
  unset http_proxy https_proxy all_proxy no_proxy
  unset HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY
  echo "代理已关闭"
}

# 安全自启动：只在 hysteria 真的在监听端口时才开代理（启动失败时不会污染 shell）
# 用法：在 ~/.zshrc.local 末尾加 `proxyon-auto`
hy2on-auto() {
  if lsof -i ":${HY2_HTTP_PORT:-1081}" -sTCP:LISTEN >/dev/null 2>&1; then
    hy2on >/dev/null
  fi
}

hy2proxystatus() {
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

hy2ip() {
  echo "=== 直连 IP ==="
  curl -s --max-time 5 https://api.ip.sb/geoip \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(f"  {d.get(\"ip\")} ({d.get(\"country\")} / {d.get(\"isp\")})")' 2>/dev/null \
    || echo "  连接失败"
  echo "=== Hy2 出口 IP ==="
  curl -s --max-time 5 -x "http://127.0.0.1:$HY2_HTTP_PORT" https://api.ip.sb/geoip \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(f"  {d.get(\"ip\")} ({d.get(\"country\")} / {d.get(\"isp\")})")' 2>/dev/null \
    || echo "  代理不通"
}

hy2speed() {
  echo "测试 Hy2 下行速度（10MB 文件）..."
  curl -o /dev/null -x "http://127.0.0.1:$HY2_HTTP_PORT" \
    -w "下载速度: %{speed_download} B/s\n耗时: %{time_total}s\n" \
    https://speed.cloudflare.com/__down?bytes=10000000
}

# ── SSH 辅助（读取 config.yaml 自动获取服务器地址） ─────────────────
# 可通过环境变量覆盖 SSH 连接参数：
#   HY2_SSH_HOST   （默认：从 config.yaml 解析）
#   HY2_SSH_USER   （默认：root）
#   HY2_SSH_PORT   （默认：22）
#   HY2_SSH_KEY    （私钥路径，有则优先尝试）
#   HY2_SSH_PASS   （密码 auth，用于 sshpass / expect）
: "${HY2_SSH_USER:=root}"
: "${HY2_SSH_PORT:=22}"

# 从 config.yaml 提取 server 地址（格式 host:port → 只取 host）
_hy2_server_host() {
  if [ -n "${HY2_SSH_HOST:-}" ]; then echo "$HY2_SSH_HOST"; return; fi
  awk '/^[[:space:]]*server:/{gsub(/:.*/,"",$2); print $2; exit}' "$HY2_CONFIG" 2>/dev/null
}

# 尝试多种 SSH auth 方式执行远程命令（stdout 传给调用方，stderr → /dev/null）
# 优先级：key (BatchMode) → sshpass → expect → 失败
_hy2_ssh() {
  local host user port key pass
  host="$(_hy2_server_host)"
  user="${HY2_SSH_USER}" port="${HY2_SSH_PORT}"
  key="${HY2_SSH_KEY:-}"
  pass="${HY2_SSH_PASS:-}"

  if [ -z "$host" ]; then
    echo "ERROR: 无法确定服务器地址。设置 HY2_SSH_HOST 或在 config.yaml 里填 server。" >&2
    return 1
  fi

  # 1) 优先 key auth
  local key_flag=""
  [ -n "$key" ] && key_flag="-i $key"
  if ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8 \
         -p "$port" $key_flag "$user@$host" 'true' 2>/dev/null; then
    # key auth works — 直接跑用户命令
    ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
        -p "$port" $key_flag "$user@$host" "$@"
    return $?
  fi

  # 2) sshpass (需安装: brew install sshpass)
  if [ -n "$pass" ] && command -v sshpass &>/dev/null; then
    sshpass -p "$pass" ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
           -p "$port" $key_flag "$user@$host" "$@"
    return $?
  fi

  # 3) expect (macOS 自带) — 密码和连接参数全走环境变量，避免 Tcl 转义
  if [ -n "$pass" ] && command -v expect &>/dev/null; then
    export HY2_EXPECT_PASS="$pass" HY2_EXPECT_HOST="$host" HY2_EXPECT_PORT="$port"
    export HY2_EXPECT_USER="$user" HY2_EXPECT_CMD="$*"
    expect -c '
      log_user 0
      set timeout 20
      spawn ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -p $env(HY2_EXPECT_PORT) $env(HY2_EXPECT_USER)@$env(HY2_EXPECT_HOST) $env(HY2_EXPECT_CMD)
      expect {
        "password:" { send "$env(HY2_EXPECT_PASS)\r" }
        timeout { exit 1 }
        eof { exit 0 }
      }
      log_user 1
      expect eof
    ' 2>/dev/null
    local rc=$?
    unset HY2_EXPECT_PASS HY2_EXPECT_HOST HY2_EXPECT_PORT HY2_EXPECT_USER HY2_EXPECT_CMD
    return $rc
  fi

  echo "ERROR: 无法 SSH 到 $user@$host:$port。" >&2
  echo "       设置 HY2_SSH_KEY 指向私钥路径，或 HY2_SSH_PASS + sshpass/expect。" >&2
  echo "       建议：ssh-copy-id -p $port $user@$host 一次性配置免密登录。" >&2
  return 1
}

# ── 诊断：本地 + 远程全面检查 ──────────────────────────────────────
hy2diag() {
  local host server_port err_count
  host="$(_hy2_server_host)"
  server_port="$(awk '/^[[:space:]]*server:/{gsub(/.*:/,"",$2); if($2)print $2; else print "443"; exit}' "$HY2_CONFIG" 2>/dev/null)"
  : "${server_port:=443}"

  echo "══════════════ Hy2 诊断 $(date '+%Y-%m-%d %H:%M:%S') ══════════════"
  echo ""

  # ── 本地检查 ──
  echo "── [1/4] 本地客户端 ──"
  if pgrep -f "hysteria client" > /dev/null; then
    local pid; pid="$(pgrep -f 'hysteria client')"
    echo "  状态:   ✅ 运行中 (PID: $pid)"
    hy2_is_service && echo "  模式:   launchd 服务" || echo "  模式:   手动"
    if lsof -i ":${HY2_SOCKS_PORT}" -sTCP:LISTEN >/dev/null 2>&1; then
      echo "  SOCKS5: ✅ 127.0.0.1:$HY2_SOCKS_PORT"
    else
      echo "  SOCKS5: ❌ 未监听"
    fi
    if lsof -i ":${HY2_HTTP_PORT}" -sTCP:LISTEN >/dev/null 2>&1; then
      echo "  HTTP:   ✅ 127.0.0.1:$HY2_HTTP_PORT"
    else
      echo "  HTTP:   ❌ 未监听"
    fi
  else
    echo "  状态:   ❌ 未运行"
  fi

  # 本地版本
  local cli_ver; cli_ver="$(hysteria version 2>/dev/null | grep '^Version:' | awk '{print $2}')"
  echo "  版本:   ${cli_ver:-未知}"

  # 最近 30 分钟的错误统计（避免统计历史旧错误）
  local since; since="$(date -v-30M '+%Y-%m-%dT%H:%M' 2>/dev/null || date -d '30 minutes ago' '+%Y-%m-%dT%H:%M' 2>/dev/null)"
  if [ -n "$since" ]; then
    err_count="$(grep "$since" "$HY2_ERR_LOG" 2>/dev/null | grep -c 'WARN.*error\|ERROR.*error' || true)"
  else
    err_count="$(grep -c 'WARN.*error' "$HY2_ERR_LOG" 2>/dev/null || true)"
  fi
  echo "  近期错误(30min): ${err_count} 条（最近 5 条见下）"
  if [ -n "$since" ]; then
    grep "$since" "$HY2_ERR_LOG" 2>/dev/null | grep 'WARN.*error\|ERROR.*error' | tail -5 | while IFS= read -r line; do
      echo "    $(echo "$line" | sed 's/[[:cntrl:]]\[[0-9;]*m//g')"
    done
  else
    grep 'WARN.*error\|ERROR.*error' "$HY2_ERR_LOG" 2>/dev/null | tail -5 | while IFS= read -r line; do
      echo "    $(echo "$line" | sed 's/[[:cntrl:]]\[[0-9;]*m//g')"
    done
  fi

  echo ""

  # ── 网络连通性 ──
  echo "── [2/4] 网络连通性 ──"
  if [ -n "$host" ]; then
    # UDP 连通性（Hysteria 走 QUIC/UDP）
    if nc -zvu -w 3 "$host" "$server_port" 2>&1 | grep -q "succeeded"; then
      echo "  UDP $host:$server_port: ✅ 可达"
    else
      echo "  UDP $host:$server_port: ⚠️  nc 测试不通（可能被墙/防火墙拦截，但 hysteria 有 obfuscation 也许能通）"
    fi
  else
    echo "  ⚠️  未配置服务器地址"
  fi
  echo ""

  # ── 远程服务器检查 ──
  echo "── [3/4] 远程服务器 ──"
  if [ -z "$host" ]; then
    echo "  ⏭️  跳过（无服务器地址）"
  else
    local remote_out
    remote_out="$(_hy2_ssh "
echo '  === 系统 ==='
uname -a 2>/dev/null | head -1
echo '  === 运行状态 ==='
systemctl is-active hysteria-server 2>/dev/null || echo '未知'
echo '  === 版本 ==='
hysteria version 2>/dev/null | grep '^Version:' || echo '未知'
echo '  === 运行时长 ==='
ps -o etime= -p \$(systemctl show hysteria-server -p MainPID --value 2>/dev/null) 2>/dev/null || echo '未知'
echo '  === 内存 ==='
ps -o rss= -p \$(systemctl show hysteria-server -p MainPID --value 2>/dev/null) 2>/dev/null | awk '{printf \"%.1f MB\", \$1/1024}' || echo '未知'
echo '  === 监听 ==='
ss -ulnp 2>/dev/null | grep hysteria || echo '未检测到 UDP 监听'
echo '  === UFW ==='
ufw status 2>/dev/null | grep -E \"$server_port|Status\" || echo '未检测到'
echo '  === 近期日志（最近 8 条） ==='
journalctl -u hysteria-server --no-pager -n 8 2>/dev/null || echo '无 journalctl'
echo '  === 出网测试 ==='
curl -sI --max-time 8 https://google.com 2>&1 | head -1 || echo '出网失败'
" 2>&1)"
    echo "$remote_out"
  fi
  echo ""

  # ── 代理功能测试 ──
  echo "── [4/4] 代理功能测试 ──"
  local test_result
  test_result="$(curl -sI --max-time 8 -x "http://127.0.0.1:$HY2_HTTP_PORT" https://www.google.com 2>&1 | head -1)"
  if echo "$test_result" | grep -qE "HTTP/[12](\.[0-9])? [23][0-9][0-9]"; then
    echo "  HTTP CONNECT → google.com: ✅ $test_result"
  else
    echo "  HTTP CONNECT → google.com: ❌ ${test_result:-无响应}"
  fi

  echo ""
  echo "════════════════ 诊断完成 ════════════════"
}

# ── 同时重启服务端 + 客户端 ─────────────────────────────────────────
hy2restart-all() {
  local host
  host="$(_hy2_server_host)"

  echo "══ 重启 Hy2 服务端 + 客户端 ══"
  echo ""

  # 1) 远程重启
  if [ -n "$host" ]; then
    echo "→ 重启服务端 ($host)..."
    _hy2_ssh "systemctl restart hysteria-server && echo '  服务端重启成功' || echo '  服务端重启失败'" 2>&1
    sleep 2
    # 验证
    local srv_status
    srv_status="$(_hy2_ssh "systemctl is-active hysteria-server" 2>/dev/null)"
    echo "  服务端状态: ${srv_status:-未知}"
  else
    echo "⚠️  未配置服务器地址，跳过服务端重启"
  fi

  echo ""

  # 2) 本地重启
  echo "→ 重启本地客户端..."
  hy2restart
  sleep 1

  # 3) 最终验证
  echo ""
  echo "── 重启后验证 ──"
  if pgrep -f "hysteria client" > /dev/null; then
    echo "  本地: ✅ 运行中 (PID: $(pgrep -f 'hysteria client'))"
  else
    echo "  本地: ❌ 未运行"
  fi

  # 代理连通性
  local test_result
  test_result="$(curl -sI --max-time 8 -x "http://127.0.0.1:$HY2_HTTP_PORT" https://www.google.com 2>&1 | head -1)"
  if echo "$test_result" | grep -qE "HTTP/[12](\.[0-9])? [23][0-9][0-9]"; then
    echo "  代理: ✅ Google 可达"
  else
    echo "  代理: ❌ ${test_result:-不通}"
  fi
  echo ""
  echo "══ 完成 ══"
}

# ── 一键命令 ───────────────────────────────────────────────────────
gohy2()   { hy2start; sleep 1; hy2on; hy2ip; }
stophy2() { hy2stop; hy2off; }

hy2help() {
  cat <<'EOF'
Hysteria 2 客户端命令：

服务管理（自动适配 launchd 服务 / 手动模式）：
  hy2start     启动（有 plist 走 launchd 服务，否则后台直跑）
  hy2stop      停止
  hy2restart   重启
  hy2status    查看 PID + 模式 + 监听端口
  hy2log       实时日志（Ctrl+C 退出）
  hy2logs      最近 50 行日志
  hy2edit      编辑 ~/.config/hysteria/config.yaml + 自动重启

诊断 & 运维：
  hy2diag         全面诊断（本地 + 远程服务器 + 网络 + 代理测试）
  hy2restart-all  同时重启服务端（SSH）和本地客户端

代理控制（仅当前 shell）：
  hy2on    / hy2off / hy2proxystatus
  hy2ip      对比直连 / 代理出口 IP
  hy2speed   测试代理下行速度

统一端口：HTTP+SOCKS5 → 127.0.0.1:1083 (sing-box → hysteria :1080)

一键命令：
  gohy2        启动 Hy2 + 开代理 + 测试 IP
  stophy2      停止 Hy2 + 关代理

SSH 配置（用于 hy2diag / hy2restart-all 远程操作）：
  服务器地址自动从 config.yaml 的 server 字段提取。
  覆盖：export HY2_SSH_HOST=1.2.3.4 HY2_SSH_USER=root HY2_SSH_PORT=22
  认证：export HY2_SSH_KEY=/path/to/key  (推荐)
        export HY2_SSH_PASS='your-password' (需要 sshpass 或 expect)

文件位置：
  ~/.config/hysteria/config.yaml                       配置（chmod 600）
  ~/Library/LaunchAgents/com.hysteria.client.plist     launchd 服务（仅自启模式）
  ~/.config/hysteria/hysteria.log / hysteria.err.log   日志
EOF
}
