#!/bin/bash
# Kube Magic CLI - Install/Update/Uninstall management
# Usage: kube-magic-cli.sh [install|update|uninstall|status]

SCRIPT_PATH="$HOME/.claude/scripts/kube-magic.sh"
SHELL_CONFIG="$HOME/.zshrc"
SOURCE_LINE='[ -f "$HOME/.claude/scripts/kube-magic.sh" ] && source "$HOME/.claude/scripts/kube-magic.sh"'
COMMENT_LINE="# Kube Magic - Interactive Kubernetes commands with fzf"

get_version() {
  grep -m1 'KUBE_MAGIC_VERSION=' "$SCRIPT_PATH" 2>/dev/null | cut -d'"' -f2
}

check_deps() {
  local ok=true
  if ! command -v kubectl &>/dev/null; then
    echo "Error: kubectl is not installed"
    ok=false
  fi
  if ! command -v fzf &>/dev/null; then
    echo "Error: fzf is not installed"
    ok=false
  fi
  [ "$ok" = false ] && exit 1
}

do_install() {
  check_deps

  if grep -q "kube-magic.sh" "$SHELL_CONFIG" 2>/dev/null; then
    echo "✓ Kube Magic is already installed in $SHELL_CONFIG"
    return 0
  fi

  # Add source line (with one blank line before if file doesn't end with newline)
  if [ -s "$SHELL_CONFIG" ] && [ "$(tail -c1 "$SHELL_CONFIG" | wc -l)" -eq 0 ]; then
    echo "" >> "$SHELL_CONFIG"
  fi
  echo "$COMMENT_LINE" >> "$SHELL_CONFIG"
  echo "$SOURCE_LINE" >> "$SHELL_CONFIG"

  echo "✓ Installed Kube Magic in $SHELL_CONFIG"
  echo ""
  echo "Run 'source ~/.zshrc' or open a new terminal to activate."
  echo ""
  echo "Available commands: k, ns, ct, exe, log, pod, svc, deploy, secret, cm, event, node, crd, ing, pvc, job"
}

do_update() {
  if [ -f "$SCRIPT_PATH" ]; then
    echo "Current version: v$(get_version)"
    echo "Script location: $SCRIPT_PATH"
    echo ""
    echo "To update: Ask Claude to update the kube-magic.sh script"
  else
    echo "Kube Magic not found. Run '/kube:magic install' first."
  fi
}

do_uninstall() {
  if grep -q "kube-magic.sh" "$SHELL_CONFIG" 2>/dev/null; then
    cp "$SHELL_CONFIG" "${SHELL_CONFIG}.backup"

    # Remove lines and clean up extra blank lines
    grep -v "kube-magic.sh" "$SHELL_CONFIG" | grep -v "# Kube Magic - Interactive" | cat -s > "${SHELL_CONFIG}.tmp"
    mv "${SHELL_CONFIG}.tmp" "$SHELL_CONFIG"

    echo "✓ Removed Kube Magic from $SHELL_CONFIG"
    echo "  Backup saved to ${SHELL_CONFIG}.backup"
  else
    echo "Kube Magic not found in $SHELL_CONFIG"
  fi

  echo ""
  echo "Script file remains at: $SCRIPT_PATH"
  echo "To remove the script: rm $SCRIPT_PATH"
}

do_status() {
  echo "Kube Magic Status"
  echo "================="

  if [ -f "$SCRIPT_PATH" ]; then
    echo "Script: $SCRIPT_PATH (v$(get_version))"
  else
    echo "Script: Not found"
  fi

  if grep -q "kube-magic.sh" "$SHELL_CONFIG" 2>/dev/null; then
    echo "Shell config: Installed in $SHELL_CONFIG"
  else
    echo "Shell config: Not installed"
  fi

  echo ""
  echo "Dependencies:"
  command -v kubectl &>/dev/null && echo "  kubectl: OK" || echo "  kubectl: NOT FOUND"
  command -v fzf &>/dev/null && echo "  fzf: OK ($(fzf --version | head -1))" || echo "  fzf: NOT FOUND"
  command -v jq &>/dev/null && echo "  jq: OK" || echo "  jq: NOT FOUND (optional)"

  echo ""
  echo "Usage: /kube:magic [install|update|uninstall]"
}

preview_content() {
  case "$1" in
    install)
      echo "━━━ INSTALL ━━━"
      echo ""
      echo "Add Kube Magic to your shell configuration."
      echo ""
      echo "What it does:"
      echo "  • Adds source line to ~/.zshrc"
      echo "  • Enables all kube commands on new terminals"
      echo ""
      echo "After install, available commands:"
      echo "  k        - Show help / browse CRDs"
      echo "  ns       - Switch namespace"
      echo "  ct       - Switch context"
      echo "  exe      - Exec into pod"
      echo "  log      - Interactive logs"
      echo "  pod      - Manage pods"
      echo "  svc      - Manage services"
      echo "  deploy   - Manage deployments"
      echo "  secret   - View/decode secrets"
      echo "  cm       - Manage configmaps"
      echo "  event    - View events"
      echo "  node     - Manage nodes"
      echo "  crd      - Browse CRDs"
      echo "  ing      - Manage ingress"
      echo "  pvc      - Manage PVCs"
      echo "  job      - Manage jobs"
      ;;
    update)
      echo "━━━ UPDATE ━━━"
      echo ""
      echo "Check current version and update instructions."
      echo ""
      if [ -f "$SCRIPT_PATH" ]; then
        echo "Current version: v$(get_version)"
        echo "Script location: $SCRIPT_PATH"
      else
        echo "Script: Not found"
      fi
      echo ""
      echo "To update the script, ask Claude to modify"
      echo "~/.claude/scripts/kube-magic.sh"
      ;;
    uninstall)
      echo "━━━ UNINSTALL ━━━"
      echo ""
      echo "Remove Kube Magic from your shell configuration."
      echo ""
      echo "What it does:"
      echo "  • Removes source line from ~/.zshrc"
      echo "  • Creates backup at ~/.zshrc.backup"
      echo "  • Script file remains (can reinstall later)"
      echo ""
      if grep -q "kube-magic.sh" "$SHELL_CONFIG" 2>/dev/null; then
        echo "Status: Currently installed"
      else
        echo "Status: Not installed"
      fi
      ;;
    status)
      echo "━━━ STATUS ━━━"
      echo ""
      if [ -f "$SCRIPT_PATH" ]; then
        echo "Script: $SCRIPT_PATH"
        echo "Version: v$(get_version)"
      else
        echo "Script: Not found"
      fi
      echo ""
      if grep -q "kube-magic.sh" "$SHELL_CONFIG" 2>/dev/null; then
        echo "Shell config: Installed in $SHELL_CONFIG"
      else
        echo "Shell config: Not installed"
      fi
      echo ""
      echo "Dependencies:"
      command -v kubectl &>/dev/null && echo "  kubectl: OK" || echo "  kubectl: NOT FOUND"
      command -v fzf &>/dev/null && echo "  fzf: OK" || echo "  fzf: NOT FOUND"
      command -v jq &>/dev/null && echo "  jq: OK" || echo "  jq: NOT FOUND (optional)"
      ;;
  esac
}

do_interactive() {
  local selected
  selected=$(echo -e "install\nupdate\nuninstall\nstatus" | \
    fzf --layout=reverse --border=rounded --tmux 80%,70% \
      --border-label="╢ Kube Magic ╟" \
      --prompt "⎈ " \
      --header "Select operation │ Enter: execute │ /: toggle preview" \
      --bind '/:change-preview-window(70%|50%|hidden)' \
      --preview-window 'right:60%,border-left,wrap' \
      --preview "SCRIPT_PATH='$SCRIPT_PATH'; SHELL_CONFIG='$SHELL_CONFIG'; $0 --preview {}")

  [ -n "$selected" ] && "$0" "$selected"
}

case "$1" in
  install)   do_install ;;
  update)    do_update ;;
  uninstall) do_uninstall ;;
  status)    do_status ;;
  --preview) preview_content "$2" ;;
  "")        do_interactive ;;
  *)         echo "Usage: $0 [install|update|uninstall|status]" ;;
esac
