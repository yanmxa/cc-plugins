#!/bin/bash
# ssh-deploy.sh — sourced helper for "server mode": push a Linux install script to
# a remote VPS over SSH and run it. Key-based auth only (no passwords in the plugin);
# secrets are generated ON the server and printed back, never sent over the wire.
#
# Required env before calling:
#   SSH_HOST                 target VPS host / IP
# Optional:
#   SSH_USER (default root)  SSH login user
#   SSH_PORT (default 22)    SSH port
#   SSH_KEY                  path to a private key (else the agent / default keys)
#
# Provides:
#   ssh_precheck                       → 0 if key auth works, else 1 (+ fix-it hint)
#   ssh_run_remote_script <file> [V=x] → base64-push <file>, run it with env V=x, stream output

SSH_USER="${SSH_USER:-root}"
SSH_PORT="${SSH_PORT:-22}"
_SSH_OPTS=()

ssh_init() {
  _SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o ConnectTimeout=15 -p "$SSH_PORT")
  [ -n "${SSH_KEY:-}" ] && _SSH_OPTS+=(-i "$SSH_KEY")
}

# Verify key-based auth works. Returns non-zero (with a fix-it hint) if not.
ssh_precheck() {
  ssh_init
  if ssh -o BatchMode=yes "${_SSH_OPTS[@]}" "$SSH_USER@$SSH_HOST" true 2>/dev/null; then
    return 0
  fi
  echo "ERROR: cannot SSH to $SSH_USER@$SSH_HOST:$SSH_PORT with key auth." >&2
  echo "       Set up key access once, then re-run:" >&2
  echo "         ssh-copy-id -p $SSH_PORT $SSH_USER@$SSH_HOST" >&2
  echo "       (or pass --ssh-key <path> to an authorized private key)" >&2
  return 1
}

# Push a local install script to the VPS and execute it with the given env assignments.
# Streams remote stdout/stderr live. Pass NON-secret params only (host/port/sni) — the
# remote script generates its own passwords and prints them in its RESULT block.
# base64 is single-quote-safe (alphabet has no quotes); env assignments must be shell-word safe.
ssh_run_remote_script() {
  local script="$1"; shift
  local envassign="$*"
  local b64; b64="$(base64 < "$script" | tr -d '\n')"
  ssh_init
  ssh "${_SSH_OPTS[@]}" "$SSH_USER@$SSH_HOST" \
    "echo '$b64' | base64 -d > /tmp/_prox_run.sh && env $envassign bash /tmp/_prox_run.sh; rc=\$?; rm -f /tmp/_prox_run.sh; exit \$rc"
}
