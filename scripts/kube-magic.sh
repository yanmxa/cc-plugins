#!/bin/bash
# ============================================================================
# Kube Magic - Interactive Kubernetes Commands with fzf
# https://github.com/junegunn/fzf
# ============================================================================
# Hotkey conventions:
#   Enter=primary  D=describe  Y=yaml  E=edit  A=watch
#   C=copy  W=delete  R=reload  /:toggle-preview
# ============================================================================

KUBE_MAGIC_VERSION="1.1.0"

# Common fzf styling for kubernetes commands
_kube_fzf_opts() {
  echo "--layout=reverse --border=rounded --border-label-pos=3"
}

# Preview window position: up (top-bottom layout)
_kube_preview_opts() {
  local size="${1:-65%}"
  echo "up:$size,border-bottom,wrap"
}

# Preview size toggle options for / keybinding
_kube_preview_toggle() {
  echo "75%|65%|50%|hidden"
}

# Clipboard command variable (set once, used in fzf binds)
if command -v pbcopy &>/dev/null; then
  KUBE_CLIP_CMD="pbcopy"
elif command -v xclip &>/dev/null; then
  KUBE_CLIP_CMD="xclip -selection clipboard"
elif command -v xsel &>/dev/null; then
  KUBE_CLIP_CMD="xsel --clipboard --input"
else
  KUBE_CLIP_CMD="cat >/dev/null"
fi

# k - Kube Magic: show help or browse CRDs
k() {
  if [ -z "$1" ]; then
    # Colors
    local D=$'\033[90m' C=$'\033[36m' G=$'\033[32m' Y=$'\033[33m' M=$'\033[35m' B=$'\033[34m' W=$'\033[97m' R=$'\033[0m'
    echo ""
    echo -e "    ${C}⎈${R}  ${W}Kube Magic${R} ${D}v${KUBE_MAGIC_VERSION}${R}"
    echo ""
    echo -e "  ${D}╭─────────────┬────────────────────────┬────────────────────────────────────────────╮${R}"
    echo -e "  ${D}│${R} ${C}COMMAND${R}     ${D}│${R} ${C}DESCRIPTION${R}            ${D}│${R} ${C}SPECIFIC OPERATIONS${R}                        ${D}│${R}"
    echo -e "  ${D}├─────────────┼────────────────────────┼────────────────────────────────────────────┤${R}"
    echo -e "  ${D}│${R} ${G}k${R} [type]    ${D}│${R} Help / browse CRDs     ${D}│${R} ${Y}Enter${R}:browse                               ${D}│${R}"
    echo -e "  ${D}│${R} ${G}ns${R}          ${D}│${R} Switch namespace       ${D}│${R} ${Y}Enter${R}:switch                               ${D}│${R}"
    echo -e "  ${D}│${R} ${G}ct${R}          ${D}│${R} Switch context         ${D}│${R} ${Y}Enter${R}:switch                               ${D}│${R}"
    echo -e "  ${D}│${R} ${G}exe${R}         ${D}│${R} Exec into pod          ${D}│${R} ${Y}Enter${R}:exec (bash→sh)                       ${D}│${R}"
    echo -e "  ${D}│${R} ${G}log${R} [-A]    ${D}│${R} Interactive logs       ${D}│${R} ${Y}Enter${R}:view ${M}F${R}:follow                        ${D}│${R}"
    echo -e "  ${D}├─────────────┼────────────────────────┼────────────────────────────────────────────┤${R}"
    echo -e "  ${D}│${R} ${G}pod${R} [-A]    ${D}│${R} Manage pods            ${D}│${R} ${Y}Enter${R}:exec ${M}L${R}:log ${M}T${R}:top ${M}P${R}:port-fwd ${M}V${R}:events ${D}│${R}"
    echo -e "  ${D}│${R} ${G}svc${R} [-A]    ${D}│${R} Manage services        ${D}│${R} ${M}P${R}:port-fwd ${M}N${R}:endpoints                     ${D}│${R}"
    echo -e "  ${D}│${R} ${G}deploy${R} [-A] ${D}│${R} Manage deployments     ${D}│${R} ${M}S${R}:scale ${M}X${R}:restart ${M}H${R}:history                ${D}│${R}"
    echo -e "  ${D}│${R} ${G}secret${R} [-A] ${D}│${R} View/decode secrets    ${D}│${R} ${Y}Enter${R}:decode                               ${D}│${R}"
    echo -e "  ${D}│${R} ${G}cm${R} [-A]     ${D}│${R} Manage configmaps      ${D}│${R} ${Y}Enter${R}:view                                 ${D}│${R}"
    echo -e "  ${D}│${R} ${G}ing${R} [-A]    ${D}│${R} Manage ingress         ${D}│${R} -                                          ${D}│${R}"
    echo -e "  ${D}│${R} ${G}pvc${R} [-A]    ${D}│${R} Manage PVCs            ${D}│${R} ${M}V${R}:show-PV ${M}P${R}:pods                           ${D}│${R}"
    echo -e "  ${D}│${R} ${G}job${R} [-A]    ${D}│${R} Manage jobs            ${D}│${R} ${M}L${R}:logs                                     ${D}│${R}"
    echo -e "  ${D}│${R} ${G}event${R} [-A]  ${D}│${R} View events            ${D}│${R} -                                          ${D}│${R}"
    echo -e "  ${D}├─────────────┼────────────────────────┼────────────────────────────────────────────┤${R}"
    echo -e "  ${D}│${R} ${G}nodes${R}       ${D}│${R} Manage nodes           ${D}│${R} ${M}T${R}:top ${M}P${R}:pods ${M}O${R}:cordon ${M}U${R}:uncordon           ${D}│${R}"
    echo -e "  ${D}│${R} ${G}crd${R} [type]  ${D}│${R} Browse CRDs            ${D}│${R} ${Y}Enter${R}:browse                               ${D}│${R}"
    echo -e "  ${D}╰─────────────┴────────────────────────┴────────────────────────────────────────────╯${R}"
    echo ""
    echo -e "    ${B}COMMON${R}  ${M}D${R}:describe ${M}Y${R}:yaml ${M}E${R}:edit ${M}A${R}:watch ${M}C${R}:copy ${M}W${R}:delete ${M}R${R}:reload ${M}/${R}:preview"
    echo -e "    ${B}FLAGS${R}   ${Y}-A${R} = all namespaces (default: current namespace)"
    echo ""
  else
    crd "$@"
  fi
}

# ns - Switch namespace
ns() {
  local current_ns=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
  current_ns=${current_ns:-default}

  local selected=$(kubectl get namespaces --no-headers -o custom-columns=":metadata.name" | \
    fzf $(_kube_fzf_opts) --tmux 90%,80% \
      --border-label="╢ Namespace ╟" \
      --prompt "⎈ " \
      --header "Current: $current_ns │ Enter: switch │ /: toggle preview" \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 60%) \
      --preview 'echo "━━━ Pods ━━━" && kubectl get pods -n {1} 2>/dev/null || echo "(empty)";
                 echo "\n━━━ Services ━━━" && kubectl get svc -n {1} --no-headers 2>/dev/null | head -5 || echo "(none)"')

  [ -n "$selected" ] && kubectl config set-context --current --namespace="$selected"
}

# ct - Switch context
ct() {
  local current=$(kubectl config current-context 2>/dev/null)

  local selected=$(kubectl config get-contexts --no-headers | \
    awk '{if($1=="*") print "→ "$2; else print "  "$2}' | \
    fzf $(_kube_fzf_opts) --tmux 90%,75% \
      --border-label="╢ Context ╟" \
      --prompt "⎈ " \
      --header "Current: $current │ /: toggle preview" \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 55%) \
      --preview 'ctx=$(echo {1} | sed "s/→ //; s/  //");
                 echo "━━━ Context Details ━━━";
                 kubectl config get-contexts "$ctx" 2>/dev/null;
                 echo "\n━━━ Cluster Info ━━━";
                 kubectl cluster-info --context "$ctx" 2>/dev/null | head -5')

  if [ -n "$selected" ]; then
    selected=$(echo "$selected" | sed 's/→ //; s/  //')
    kubectl config use-context "$selected"
  fi
}

# exe - Exec into pod
exe() {
  local pod container containers

  pod=$(kubectl get po --no-headers -o custom-columns=":metadata.name" | \
    fzf $(_kube_fzf_opts) --tmux 90%,80% \
      --border-label="╢ Select Pod ╟" \
      --prompt "⎈ " \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 50%) \
      --preview 'kubectl get pod {1} -o wide 2>/dev/null')
  [ -z "$pod" ] && return

  containers=$(kubectl get pod "$pod" -o jsonpath='{range .spec.containers[*]}{.name}{"\n"}{end}')
  local container_count=$(echo "$containers" | wc -l | tr -d ' ')

  if [ "$container_count" -eq 1 ]; then
    container="$containers"
  else
    container=$(echo "$containers" | \
      fzf $(_kube_fzf_opts) --tmux 70%,50% \
        --border-label="╢ Select Container ╟" \
        --prompt "⎈ ")
    [ -z "$container" ] && return
  fi

  echo "→ Connecting to $pod/$container ..."
  kubectl exec -it "$pod" -c "$container" -- /bin/bash 2>/dev/null || \
  kubectl exec -it "$pod" -c "$container" -- /bin/sh
}

# log - Interactive log viewer
log() {
  local all_ns=false follow_mode=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -A) all_ns=true; shift ;;
      -f|--follow) follow_mode=true; shift ;;
      *) shift ;;
    esac
  done

  local current_ns=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
  current_ns=${current_ns:-default}
  local label="Logs: $current_ns"
  [ "$all_ns" = true ] && label="All Logs"

  if [ "$all_ns" = true ]; then
    FZF_DEFAULT_COMMAND="kubectl get pods --all-namespaces" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $label ╟" \
      --prompt "⎈ " \
      --header "Enter: view │ F: follow │ R: reload │ /: preview" \
      --bind 'enter:execute:kubectl logs --all-containers --tail=500 --namespace {1} {2} | less' \
      --bind 'F:execute:kubectl logs --follow --all-containers --tail=50 --namespace {1} {2} > /dev/tty' \
      --bind 'R:reload:kubectl get pods --all-namespaces' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window up:follow,65%,border-bottom,wrap \
      --preview 'kubectl logs --all-containers --tail=100 --namespace {1} {2} 2>/dev/null'
  else
    FZF_DEFAULT_COMMAND="kubectl get pods" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $label ╟" \
      --prompt "⎈ " \
      --header "Enter: view │ F: follow │ R: reload │ /: preview" \
      --bind 'enter:execute:kubectl logs --all-containers --tail=500 {1} | less' \
      --bind 'F:execute:kubectl logs --follow --all-containers --tail=50 {1} > /dev/tty' \
      --bind 'R:reload:kubectl get pods' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window up:follow,65%,border-bottom,wrap \
      --preview 'kubectl logs --all-containers --tail=100 {1} 2>/dev/null'
  fi
}

# pod - Manage pods
pod() {
  local all_ns=false
  [ "$1" = "-A" ] && { all_ns=true; shift; }

  local current_ns=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
  current_ns=${current_ns:-default}
  local label="Pods: $current_ns"
  [ "$all_ns" = true ] && label="All Pods"

  if [ "$all_ns" = true ]; then
    FZF_DEFAULT_COMMAND="kubectl get pods --all-namespaces" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $label ╟" \
      --prompt "⎈ " \
      --header "Enter: exec │ L: log │ D: describe │ Y: yaml │ E: edit │ T: top │ P: port-fwd │ V: events │ A: watch │ C: copy │ W: del │ R: reload" \
      --bind 'enter:execute:kubectl exec -it --namespace {1} {2} -- sh > /dev/tty' \
      --bind 'L:change-preview:kubectl logs --all-containers --tail=100 --namespace {1} {2} 2>/dev/null' \
      --bind 'D:change-preview:kubectl describe pod --namespace {1} {2} 2>/dev/null' \
      --bind 'Y:change-preview:kubectl get pod --namespace {1} {2} -oyaml 2>/dev/null' \
      --bind 'E:execute:kubectl edit pod --namespace {1} {2} > /dev/tty' \
      --bind 'T:execute:kubectl top pod --namespace {1} {2} --containers > /dev/tty; read -p "Press Enter..."' \
      --bind 'P:execute:
        ports=$(kubectl get pod --namespace {1} {2} -o jsonpath="{range .spec.containers[*]}{range .ports[*]}{.containerPort}{\" \"}{end}{end}");
        port=$(echo $ports | tr " " "\n" | grep -v "^$" | head -1);
        echo "→ Port-forwarding {2}:$port -> localhost:$port";
        kubectl port-forward --namespace {1} {2} $port:$port > /dev/tty' \
      --bind 'V:execute:kubectl get events --namespace {1} --field-selector involvedObject.name={2} | less' \
      --bind 'A:execute:kubectl get pod --namespace {1} {2} -w > /dev/tty' \
      --bind 'C:execute:echo -n "pod {2} -n {1}" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: pod {2} -n {1}" > /dev/tty' \
      --bind 'W:execute:kubectl delete pod --namespace {1} {2}' \
      --bind 'R:reload:kubectl get pods --all-namespaces' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 60%) \
      --preview 'kubectl get pod --namespace {1} {2} -oyaml 2>/dev/null' "$@"
  else
    FZF_DEFAULT_COMMAND="kubectl get pods" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $label ╟" \
      --prompt "⎈ " \
      --header "Enter: exec │ L: log │ D: describe │ Y: yaml │ E: edit │ T: top │ P: port-fwd │ V: events │ A: watch │ C: copy │ W: del │ R: reload" \
      --bind 'enter:execute:kubectl exec -it {1} -- sh > /dev/tty' \
      --bind 'L:change-preview:kubectl logs --all-containers --tail=100 {1} 2>/dev/null' \
      --bind 'D:change-preview:kubectl describe pod {1} 2>/dev/null' \
      --bind 'Y:change-preview:kubectl get pod {1} -oyaml 2>/dev/null' \
      --bind 'E:execute:kubectl edit pod {1} > /dev/tty' \
      --bind 'T:execute:kubectl top pod {1} --containers > /dev/tty; read -p "Press Enter..."' \
      --bind 'P:execute:
        ports=$(kubectl get pod {1} -o jsonpath="{range .spec.containers[*]}{range .ports[*]}{.containerPort}{\" \"}{end}{end}");
        port=$(echo $ports | tr " " "\n" | grep -v "^$" | head -1);
        echo "→ Port-forwarding {1}:$port -> localhost:$port";
        kubectl port-forward {1} $port:$port > /dev/tty' \
      --bind 'V:execute:kubectl get events --field-selector involvedObject.name={1} | less' \
      --bind 'A:execute:kubectl get pod {1} -w > /dev/tty' \
      --bind 'C:execute:ns=$(kubectl config view --minify -o jsonpath="{..namespace}"); ns=${ns:-default}; echo -n "pod {1} -n $ns" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: pod {1} -n $ns" > /dev/tty' \
      --bind 'W:execute:kubectl delete pod {1}' \
      --bind 'R:reload:kubectl get pods' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 60%) \
      --preview 'kubectl get pod {1} -oyaml 2>/dev/null' "$@"
  fi
}

# svc - Manage services
svc() {
  local all_ns=false ns_flag=""
  [ "$1" = "-A" ] && { all_ns=true; ns_flag="--all-namespaces"; shift; }

  local current_ns=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
  current_ns=${current_ns:-default}
  local label="Services: $current_ns"
  [ "$all_ns" = true ] && label="All Services"

  if [ "$all_ns" = true ]; then
    FZF_DEFAULT_COMMAND="kubectl get svc --all-namespaces" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $label ╟" \
      --prompt "⎈ " \
      --header "P: port-fwd │ D: describe │ Y: yaml │ E: edit │ N: endpoints │ A: watch │ C: copy │ W: del │ R: reload" \
      --bind 'P:execute:
        port=$(kubectl get svc --namespace {1} {2} -o jsonpath="{.spec.ports[0].port}");
        echo "→ Port-forwarding {2}:$port -> localhost:$port";
        kubectl port-forward --namespace {1} svc/{2} $port:$port > /dev/tty' \
      --bind 'D:change-preview:kubectl describe svc --namespace {1} {2} 2>/dev/null' \
      --bind 'Y:change-preview:kubectl get svc --namespace {1} {2} -oyaml 2>/dev/null' \
      --bind 'E:execute:kubectl edit svc --namespace {1} {2} > /dev/tty' \
      --bind 'N:change-preview:kubectl get endpoints --namespace {1} {2} -oyaml 2>/dev/null' \
      --bind 'A:execute:kubectl get svc --namespace {1} {2} -w > /dev/tty' \
      --bind 'C:execute:echo -n "svc {2} -n {1}" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: svc {2} -n {1}" > /dev/tty' \
      --bind 'W:execute:kubectl delete svc --namespace {1} {2}' \
      --bind 'R:reload:kubectl get svc --all-namespaces' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 55%) \
      --preview 'kubectl get svc --namespace {1} {2} -oyaml 2>/dev/null' "$@"
  else
    FZF_DEFAULT_COMMAND="kubectl get svc" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $label ╟" \
      --prompt "⎈ " \
      --header "P: port-fwd │ D: describe │ Y: yaml │ E: edit │ N: endpoints │ A: watch │ C: copy │ W: del │ R: reload" \
      --bind 'P:execute:
        port=$(kubectl get svc {1} -o jsonpath="{.spec.ports[0].port}");
        echo "→ Port-forwarding {1}:$port -> localhost:$port";
        kubectl port-forward svc/{1} $port:$port > /dev/tty' \
      --bind 'D:change-preview:kubectl describe svc {1} 2>/dev/null' \
      --bind 'Y:change-preview:kubectl get svc {1} -oyaml 2>/dev/null' \
      --bind 'E:execute:kubectl edit svc {1} > /dev/tty' \
      --bind 'N:change-preview:kubectl get endpoints {1} -oyaml 2>/dev/null' \
      --bind 'A:execute:kubectl get svc {1} -w > /dev/tty' \
      --bind 'C:execute:ns=$(kubectl config view --minify -o jsonpath="{..namespace}"); ns=${ns:-default}; echo -n "svc {1} -n $ns" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: svc {1} -n $ns" > /dev/tty' \
      --bind 'W:execute:kubectl delete svc {1}' \
      --bind 'R:reload:kubectl get svc' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 55%) \
      --preview 'kubectl get svc {1} -oyaml 2>/dev/null' "$@"
  fi
}

# deploy - Manage deployments
deploy() {
  local all_ns=false ns_flag=""
  [ "$1" = "-A" ] && { all_ns=true; ns_flag="--all-namespaces"; shift; }

  local current_ns=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
  current_ns=${current_ns:-default}
  local label="Deployments: $current_ns"
  [ "$all_ns" = true ] && label="All Deployments"

  if [ "$all_ns" = true ]; then
    FZF_DEFAULT_COMMAND="kubectl get deploy --all-namespaces" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $label ╟" \
      --prompt "⎈ " \
      --header "D: describe │ Y: yaml │ E: edit │ S: scale │ X: restart │ H: history │ A: watch │ C: copy │ W: del │ R: reload" \
      --bind 'D:change-preview:kubectl describe deploy --namespace {1} {2} 2>/dev/null' \
      --bind 'Y:change-preview:kubectl get deploy --namespace {1} {2} -oyaml 2>/dev/null' \
      --bind 'E:execute:kubectl edit deploy --namespace {1} {2} > /dev/tty' \
      --bind 'S:execute:
        current=$(kubectl get deploy --namespace {1} {2} -o jsonpath="{.spec.replicas}");
        replicas=$(echo -e "0\n1\n2\n3\n5\n10" | fzf --tmux 40%,30% --border=rounded --prompt="Scale {2} ($current→): ");
        [ -n "$replicas" ] && kubectl scale deploy --namespace {1} {2} --replicas=$replicas && echo "→ Scaled {2}: $current → $replicas" > /dev/tty' \
      --bind 'X:execute:kubectl rollout restart deploy --namespace {1} {2} && echo "→ Restarted {2}" > /dev/tty' \
      --bind 'H:change-preview:kubectl rollout history deploy --namespace {1} {2} 2>/dev/null' \
      --bind 'A:execute:kubectl get deploy --namespace {1} {2} -w > /dev/tty' \
      --bind 'C:execute:echo -n "deploy {2} -n {1}" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: deploy {2} -n {1}" > /dev/tty' \
      --bind 'W:execute:kubectl delete deploy --namespace {1} {2}' \
      --bind 'R:reload:kubectl get deploy --all-namespaces' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 55%) \
      --preview 'kubectl get deploy --namespace {1} {2} -oyaml 2>/dev/null' "$@"
  else
    FZF_DEFAULT_COMMAND="kubectl get deploy" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $label ╟" \
      --prompt "⎈ " \
      --header "D: describe │ Y: yaml │ E: edit │ S: scale │ X: restart │ H: history │ A: watch │ C: copy │ W: del │ R: reload" \
      --bind 'D:change-preview:kubectl describe deploy {1} 2>/dev/null' \
      --bind 'Y:change-preview:kubectl get deploy {1} -oyaml 2>/dev/null' \
      --bind 'E:execute:kubectl edit deploy {1} > /dev/tty' \
      --bind 'S:execute:
        current=$(kubectl get deploy {1} -o jsonpath="{.spec.replicas}");
        replicas=$(echo -e "0\n1\n2\n3\n5\n10" | fzf --tmux 40%,30% --border=rounded --prompt="Scale {1} ($current→): ");
        [ -n "$replicas" ] && kubectl scale deploy {1} --replicas=$replicas && echo "→ Scaled {1}: $current → $replicas" > /dev/tty' \
      --bind 'X:execute:kubectl rollout restart deploy {1} && echo "→ Restarted {1}" > /dev/tty' \
      --bind 'H:change-preview:kubectl rollout history deploy {1} 2>/dev/null' \
      --bind 'A:execute:kubectl get deploy {1} -w > /dev/tty' \
      --bind 'C:execute:ns=$(kubectl config view --minify -o jsonpath="{..namespace}"); ns=${ns:-default}; echo -n "deploy {1} -n $ns" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: deploy {1} -n $ns" > /dev/tty' \
      --bind 'W:execute:kubectl delete deploy {1}' \
      --bind 'R:reload:kubectl get deploy' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 55%) \
      --preview 'kubectl get deploy {1} -oyaml 2>/dev/null' "$@"
  fi
}

# secret - View secrets
secret() {
  local all_ns=false
  [ "$1" = "-A" ] && { all_ns=true; shift; }

  local current_ns=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
  current_ns=${current_ns:-default}
  local label="Secrets: $current_ns"
  [ "$all_ns" = true ] && label="All Secrets"

  if [ "$all_ns" = true ]; then
    FZF_DEFAULT_COMMAND="kubectl get secrets --all-namespaces" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $label ╟" \
      --prompt "⎈ " \
      --header "Enter: decode │ D: describe │ Y: yaml │ E: edit │ A: watch │ C: copy │ W: del │ R: reload" \
      --bind 'enter:change-preview:kubectl get secret --namespace {1} {2} -o json 2>/dev/null | jq -r ".data | to_entries[] | \"━━━ \(.key) ━━━\n\(.value | @base64d)\n\""' \
      --bind 'D:change-preview:kubectl describe secret --namespace {1} {2} 2>/dev/null' \
      --bind 'Y:change-preview:kubectl get secret --namespace {1} {2} -oyaml 2>/dev/null' \
      --bind 'E:execute:kubectl edit secret --namespace {1} {2} > /dev/tty' \
      --bind 'A:execute:kubectl get secret --namespace {1} {2} -w > /dev/tty' \
      --bind 'C:execute:echo -n "secret {2} -n {1}" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: secret {2} -n {1}" > /dev/tty' \
      --bind 'W:execute:kubectl delete secret --namespace {1} {2}' \
      --bind 'R:reload:kubectl get secrets --all-namespaces' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 50%) \
      --preview 'kubectl get secret --namespace {1} {2} -oyaml 2>/dev/null' "$@"
  else
    FZF_DEFAULT_COMMAND="kubectl get secrets" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $label ╟" \
      --prompt "⎈ " \
      --header "Enter: decode │ D: describe │ Y: yaml │ E: edit │ A: watch │ C: copy │ W: del │ R: reload" \
      --bind 'enter:change-preview:kubectl get secret {1} -o json 2>/dev/null | jq -r ".data | to_entries[] | \"━━━ \(.key) ━━━\n\(.value | @base64d)\n\""' \
      --bind 'D:change-preview:kubectl describe secret {1} 2>/dev/null' \
      --bind 'Y:change-preview:kubectl get secret {1} -oyaml 2>/dev/null' \
      --bind 'E:execute:kubectl edit secret {1} > /dev/tty' \
      --bind 'A:execute:kubectl get secret {1} -w > /dev/tty' \
      --bind 'C:execute:ns=$(kubectl config view --minify -o jsonpath="{..namespace}"); ns=${ns:-default}; echo -n "secret {1} -n $ns" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: secret {1} -n $ns" > /dev/tty' \
      --bind 'W:execute:kubectl delete secret {1}' \
      --bind 'R:reload:kubectl get secrets' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 50%) \
      --preview 'kubectl get secret {1} -oyaml 2>/dev/null' "$@"
  fi
}

# cm - Manage configmaps
cm() {
  local all_ns=false
  [ "$1" = "-A" ] && { all_ns=true; shift; }

  local current_ns=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
  current_ns=${current_ns:-default}
  local label="ConfigMaps: $current_ns"
  [ "$all_ns" = true ] && label="All ConfigMaps"

  if [ "$all_ns" = true ]; then
    FZF_DEFAULT_COMMAND="kubectl get cm --all-namespaces" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $label ╟" \
      --prompt "⎈ " \
      --header "Enter: view │ D: describe │ Y: yaml │ E: edit │ A: watch │ C: copy │ W: del │ R: reload" \
      --bind 'enter:change-preview:kubectl get cm --namespace {1} {2} -o json 2>/dev/null | jq -r ".data"' \
      --bind 'D:change-preview:kubectl describe cm --namespace {1} {2} 2>/dev/null' \
      --bind 'Y:change-preview:kubectl get cm --namespace {1} {2} -oyaml 2>/dev/null' \
      --bind 'E:execute:kubectl edit cm --namespace {1} {2} > /dev/tty' \
      --bind 'A:execute:kubectl get cm --namespace {1} {2} -w > /dev/tty' \
      --bind 'C:execute:echo -n "cm {2} -n {1}" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: cm {2} -n {1}" > /dev/tty' \
      --bind 'W:execute:kubectl delete cm --namespace {1} {2}' \
      --bind 'R:reload:kubectl get cm --all-namespaces' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 55%) \
      --preview 'kubectl get cm --namespace {1} {2} -oyaml 2>/dev/null' "$@"
  else
    FZF_DEFAULT_COMMAND="kubectl get cm" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $label ╟" \
      --prompt "⎈ " \
      --header "Enter: view │ D: describe │ Y: yaml │ E: edit │ A: watch │ C: copy │ W: del │ R: reload" \
      --bind 'enter:change-preview:kubectl get cm {1} -o json 2>/dev/null | jq -r ".data"' \
      --bind 'D:change-preview:kubectl describe cm {1} 2>/dev/null' \
      --bind 'Y:change-preview:kubectl get cm {1} -oyaml 2>/dev/null' \
      --bind 'E:execute:kubectl edit cm {1} > /dev/tty' \
      --bind 'A:execute:kubectl get cm {1} -w > /dev/tty' \
      --bind 'C:execute:ns=$(kubectl config view --minify -o jsonpath="{..namespace}"); ns=${ns:-default}; echo -n "cm {1} -n $ns" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: cm {1} -n $ns" > /dev/tty' \
      --bind 'W:execute:kubectl delete cm {1}' \
      --bind 'R:reload:kubectl get cm' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 55%) \
      --preview 'kubectl get cm {1} -oyaml 2>/dev/null' "$@"
  fi
}

# event - View events
event() {
  local ns_flag="" label="Events"
  if [ "$1" = "-A" ]; then
    ns_flag="--all-namespaces"
    label="All Events"
    shift
  fi

  FZF_DEFAULT_COMMAND="kubectl get events $ns_flag --sort-by='.lastTimestamp'" \
    fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
    --border-label="╢ $label ╟" \
    --prompt "⎈ " \
    --header "D: describe object │ W: watch mode │ R: reload │ /: preview" \
    --bind 'D:execute:kubectl describe {4} --namespace {1} {5} 2>/dev/null | less' \
    --bind 'R:reload:kubectl get events '"$ns_flag"' --sort-by=".lastTimestamp"' \
    --bind 'W:execute:kubectl get events '"$ns_flag"' -w > /dev/tty' \
    --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
    --preview-window $(_kube_preview_opts 45%) \
    --preview 'echo "Type: {3}\nReason: {4}\nObject: {5}"' "$@"
}

# nodes - Manage nodes
nodes() {
  FZF_DEFAULT_COMMAND="kubectl get nodes -o wide" \
    fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
    --border-label="╢ Nodes ╟" \
    --prompt "⎈ " \
    --header "D: describe │ Y: yaml │ E: edit │ T: top │ P: pods │ O: cordon │ U: uncordon │ A: watch │ C: copy │ R: reload" \
    --bind 'D:change-preview:kubectl describe node {1} 2>/dev/null' \
    --bind 'Y:change-preview:kubectl get node {1} -oyaml 2>/dev/null' \
    --bind 'E:execute:kubectl edit node {1} > /dev/tty' \
    --bind 'T:execute:kubectl top node {1} > /dev/tty; read -p "Press Enter..."' \
    --bind 'P:change-preview:kubectl get pods --all-namespaces --field-selector spec.nodeName={1} 2>/dev/null' \
    --bind 'O:execute:kubectl cordon {1} && echo "→ Node {1} cordoned" > /dev/tty' \
    --bind 'U:execute:kubectl uncordon {1} && echo "→ Node {1} uncordoned" > /dev/tty' \
    --bind 'A:execute:kubectl get node {1} -w > /dev/tty' \
    --bind 'C:execute:echo -n "node {1}" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: node {1}" > /dev/tty' \
    --bind 'R:reload:kubectl get nodes -o wide' \
    --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
    --preview-window $(_kube_preview_opts 55%) \
    --preview 'kubectl get node {1} -oyaml 2>/dev/null' "$@"
}

# crd - Browse CRDs
crd() {
  local resource="${1:-}"

  if [ -z "$resource" ]; then
    resource=$(FZF_DEFAULT_COMMAND="kubectl get crd" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
        --border-label="╢ CRD ╟" \
        --prompt "⎈ " \
        --header "Enter: browse │ D: describe │ Y: yaml │ E: edit │ A: watch │ C: copy │ W: del │ R: reload │ /: preview" \
        --bind 'enter:accept' \
        --bind 'D:change-preview:kubectl describe crd {1} 2>/dev/null' \
        --bind 'Y:change-preview:kubectl get crd {1} -oyaml 2>/dev/null' \
        --bind 'E:execute:kubectl edit crd {1} > /dev/tty' \
        --bind 'A:execute:kubectl get crd {1} -w > /dev/tty' \
        --bind 'C:execute:echo -n "crd {1}" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: crd {1}" > /dev/tty' \
        --bind 'W:execute:kubectl delete crd {1}' \
        --bind 'R:reload:kubectl get crd' \
        --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
        --preview-window $(_kube_preview_opts 55%) \
        --preview 'kubectl get crd {1} -oyaml 2>/dev/null' | awk '{print $1}')
    [ -z "$resource" ] && return
  fi

  local header=$(kubectl get "$resource" --all-namespaces 2>/dev/null | head -1)
  local first_col=$(echo "$header" | awk '{print $1}')

  if [ "$first_col" = "NAMESPACE" ]; then
    FZF_DEFAULT_COMMAND="kubectl get $resource --all-namespaces" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $resource ╟" \
      --prompt "⎈ " \
      --header "D: describe │ Y: yaml │ E: edit │ A: watch │ C: copy │ W: del │ R: reload │ /: preview" \
      --bind 'D:change-preview:kubectl describe '"$resource"' --namespace {1} {2} 2>/dev/null' \
      --bind 'Y:change-preview:kubectl get '"$resource"' --namespace {1} {2} -oyaml 2>/dev/null' \
      --bind 'E:execute:kubectl edit '"$resource"' --namespace {1} {2} > /dev/tty' \
      --bind 'A:execute:kubectl get '"$resource"' --namespace {1} {2} -w > /dev/tty' \
      --bind 'C:execute:echo -n "'"$resource"' {2} -n {1}" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: '"$resource"' {2} -n {1}" > /dev/tty' \
      --bind 'W:execute:kubectl delete '"$resource"' --namespace {1} {2}' \
      --bind 'R:reload:kubectl get '"$resource"' --all-namespaces' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 55%) \
      --preview 'kubectl get '"$resource"' --namespace {1} {2} -oyaml 2>/dev/null'
  else
    FZF_DEFAULT_COMMAND="kubectl get $resource" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $resource ╟" \
      --prompt "⎈ " \
      --header "D: describe │ Y: yaml │ E: edit │ A: watch │ C: copy │ W: del │ R: reload │ /: preview" \
      --bind 'D:change-preview:kubectl describe '"$resource"' {1} 2>/dev/null' \
      --bind 'Y:change-preview:kubectl get '"$resource"' {1} -oyaml 2>/dev/null' \
      --bind 'E:execute:kubectl edit '"$resource"' {1} > /dev/tty' \
      --bind 'A:execute:kubectl get '"$resource"' {1} -w > /dev/tty' \
      --bind 'C:execute:echo -n "'"$resource"' {1}" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: '"$resource"' {1}" > /dev/tty' \
      --bind 'W:execute:kubectl delete '"$resource"' {1}' \
      --bind 'R:reload:kubectl get '"$resource"'' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 55%) \
      --preview 'kubectl get '"$resource"' {1} -oyaml 2>/dev/null'
  fi
}

# ing - Manage ingress
ing() {
  local all_ns=false
  [ "$1" = "-A" ] && { all_ns=true; shift; }

  local current_ns=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
  current_ns=${current_ns:-default}
  local label="Ingress: $current_ns"
  [ "$all_ns" = true ] && label="All Ingress"

  if [ "$all_ns" = true ]; then
    FZF_DEFAULT_COMMAND="kubectl get ingress --all-namespaces" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $label ╟" \
      --prompt "⎈ " \
      --header "D: describe │ Y: yaml │ E: edit │ A: watch │ C: copy │ W: del │ R: reload │ /: preview" \
      --bind 'D:change-preview:kubectl describe ingress --namespace {1} {2} 2>/dev/null' \
      --bind 'Y:change-preview:kubectl get ingress --namespace {1} {2} -oyaml 2>/dev/null' \
      --bind 'E:execute:kubectl edit ingress --namespace {1} {2} > /dev/tty' \
      --bind 'A:execute:kubectl get ingress --namespace {1} {2} -w > /dev/tty' \
      --bind 'C:execute:echo -n "ingress {2} -n {1}" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: ingress {2} -n {1}" > /dev/tty' \
      --bind 'W:execute:kubectl delete ingress --namespace {1} {2}' \
      --bind 'R:reload:kubectl get ingress --all-namespaces' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 55%) \
      --preview 'kubectl get ingress --namespace {1} {2} -oyaml 2>/dev/null' "$@"
  else
    FZF_DEFAULT_COMMAND="kubectl get ingress" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $label ╟" \
      --prompt "⎈ " \
      --header "D: describe │ Y: yaml │ E: edit │ A: watch │ C: copy │ W: del │ R: reload │ /: preview" \
      --bind 'D:change-preview:kubectl describe ingress {1} 2>/dev/null' \
      --bind 'Y:change-preview:kubectl get ingress {1} -oyaml 2>/dev/null' \
      --bind 'E:execute:kubectl edit ingress {1} > /dev/tty' \
      --bind 'A:execute:kubectl get ingress {1} -w > /dev/tty' \
      --bind 'C:execute:ns=$(kubectl config view --minify -o jsonpath="{..namespace}"); ns=${ns:-default}; echo -n "ingress {1} -n $ns" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: ingress {1} -n $ns" > /dev/tty' \
      --bind 'W:execute:kubectl delete ingress {1}' \
      --bind 'R:reload:kubectl get ingress' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 55%) \
      --preview 'kubectl get ingress {1} -oyaml 2>/dev/null' "$@"
  fi
}

# pvc - Manage PVCs
pvc() {
  local all_ns=false
  [ "$1" = "-A" ] && { all_ns=true; shift; }

  local current_ns=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
  current_ns=${current_ns:-default}
  local label="PVC: $current_ns"
  [ "$all_ns" = true ] && label="All PVC"

  if [ "$all_ns" = true ]; then
    FZF_DEFAULT_COMMAND="kubectl get pvc --all-namespaces" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $label ╟" \
      --prompt "⎈ " \
      --header "D: describe │ Y: yaml │ E: edit │ V: show PV │ P: pods │ A: watch │ C: copy │ W: del │ R: reload" \
      --bind 'D:change-preview:kubectl describe pvc --namespace {1} {2} 2>/dev/null' \
      --bind 'Y:change-preview:kubectl get pvc --namespace {1} {2} -oyaml 2>/dev/null' \
      --bind 'E:execute:kubectl edit pvc --namespace {1} {2} > /dev/tty' \
      --bind 'V:change-preview:pv=$(kubectl get pvc --namespace {1} {2} -o jsonpath="{.spec.volumeName}"); kubectl describe pv $pv 2>/dev/null' \
      --bind 'P:change-preview:kubectl get pods --namespace {1} -o json 2>/dev/null | jq -r ".items[] | select(.spec.volumes[]?.persistentVolumeClaim.claimName == \"{2}\") | .metadata.name"' \
      --bind 'A:execute:kubectl get pvc --namespace {1} {2} -w > /dev/tty' \
      --bind 'C:execute:echo -n "pvc {2} -n {1}" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: pvc {2} -n {1}" > /dev/tty' \
      --bind 'W:execute:kubectl delete pvc --namespace {1} {2}' \
      --bind 'R:reload:kubectl get pvc --all-namespaces' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 55%) \
      --preview 'kubectl get pvc --namespace {1} {2} -oyaml 2>/dev/null' "$@"
  else
    FZF_DEFAULT_COMMAND="kubectl get pvc" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $label ╟" \
      --prompt "⎈ " \
      --header "D: describe │ Y: yaml │ E: edit │ V: show PV │ P: pods │ A: watch │ C: copy │ W: del │ R: reload" \
      --bind 'D:change-preview:kubectl describe pvc {1} 2>/dev/null' \
      --bind 'Y:change-preview:kubectl get pvc {1} -oyaml 2>/dev/null' \
      --bind 'E:execute:kubectl edit pvc {1} > /dev/tty' \
      --bind 'V:change-preview:pv=$(kubectl get pvc {1} -o jsonpath="{.spec.volumeName}"); kubectl describe pv $pv 2>/dev/null' \
      --bind 'P:change-preview:kubectl get pods -o json 2>/dev/null | jq -r ".items[] | select(.spec.volumes[]?.persistentVolumeClaim.claimName == \"{1}\") | .metadata.name"' \
      --bind 'A:execute:kubectl get pvc {1} -w > /dev/tty' \
      --bind 'C:execute:ns=$(kubectl config view --minify -o jsonpath="{..namespace}"); ns=${ns:-default}; echo -n "pvc {1} -n $ns" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: pvc {1} -n $ns" > /dev/tty' \
      --bind 'W:execute:kubectl delete pvc {1}' \
      --bind 'R:reload:kubectl get pvc' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 55%) \
      --preview 'kubectl get pvc {1} -oyaml 2>/dev/null' "$@"
  fi
}

# job - Manage jobs
job() {
  local all_ns=false
  [ "$1" = "-A" ] && { all_ns=true; shift; }

  local current_ns=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
  current_ns=${current_ns:-default}
  local label="Jobs: $current_ns"
  [ "$all_ns" = true ] && label="All Jobs"

  if [ "$all_ns" = true ]; then
    FZF_DEFAULT_COMMAND="kubectl get jobs --all-namespaces" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $label ╟" \
      --prompt "⎈ " \
      --header "L: logs │ D: describe │ Y: yaml │ A: watch │ C: copy │ W: del │ R: reload │ /: preview" \
      --bind 'L:change-preview:pod=$(kubectl get pods --namespace {1} -l job-name={2} -o jsonpath="{.items[0].metadata.name}"); kubectl logs --namespace {1} $pod 2>/dev/null' \
      --bind 'D:change-preview:kubectl describe job --namespace {1} {2} 2>/dev/null' \
      --bind 'Y:change-preview:kubectl get job --namespace {1} {2} -oyaml 2>/dev/null' \
      --bind 'A:execute:kubectl get job --namespace {1} {2} -w > /dev/tty' \
      --bind 'C:execute:echo -n "job {2} -n {1}" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: job {2} -n {1}" > /dev/tty' \
      --bind 'W:execute:kubectl delete job --namespace {1} {2}' \
      --bind 'R:reload:kubectl get jobs --all-namespaces' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 55%) \
      --preview 'kubectl get job --namespace {1} {2} -oyaml 2>/dev/null' "$@"
  else
    FZF_DEFAULT_COMMAND="kubectl get jobs" \
      fzf $(_kube_fzf_opts) --tmux 100%,90% --header-lines=1 \
      --border-label="╢ $label ╟" \
      --prompt "⎈ " \
      --header "L: logs │ D: describe │ Y: yaml │ A: watch │ C: copy │ W: del │ R: reload │ /: preview" \
      --bind 'L:change-preview:pod=$(kubectl get pods -l job-name={1} -o jsonpath="{.items[0].metadata.name}"); kubectl logs $pod 2>/dev/null' \
      --bind 'D:change-preview:kubectl describe job {1} 2>/dev/null' \
      --bind 'Y:change-preview:kubectl get job {1} -oyaml 2>/dev/null' \
      --bind 'A:execute:kubectl get job {1} -w > /dev/tty' \
      --bind 'C:execute:ns=$(kubectl config view --minify -o jsonpath="{..namespace}"); ns=${ns:-default}; echo -n "job {1} -n $ns" | '"$KUBE_CLIP_CMD"' && echo "→ Copied: job {1} -n $ns" > /dev/tty' \
      --bind 'W:execute:kubectl delete job {1}' \
      --bind 'R:reload:kubectl get jobs' \
      --bind '/:change-preview-window('"$(_kube_preview_toggle)"')' \
      --preview-window $(_kube_preview_opts 55%) \
      --preview 'kubectl get job {1} -oyaml 2>/dev/null' "$@"
  fi
}

# Print version
kube_magic_version() {
  echo "Kube Magic v$KUBE_MAGIC_VERSION"
}
