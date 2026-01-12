---
argument-hint: "[install|update|uninstall]"
description: Install, update, or uninstall Kube Magic - interactive Kubernetes commands with fzf
allowed-tools: [Bash]
---

Run the Kube Magic CLI script:

```bash
SCRIPT="$HOME/.claude/scripts/kube-magic-cli.sh"

# Normalize argument
arg="$ARGUMENTS"
case "$arg" in
  install|i)     arg="install" ;;
  update|u|up)   arg="update" ;;
  uninstall|rm|remove|delete) arg="uninstall" ;;
  status|s)      arg="status" ;;
  "")            arg="" ;;  # Interactive mode
  *)             echo "Unknown argument: $arg"; echo "Valid: install, update, uninstall, status"; exit 1 ;;
esac

"$SCRIPT" "$arg"
```
