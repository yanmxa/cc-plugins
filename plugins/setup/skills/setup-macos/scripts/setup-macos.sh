#!/bin/bash
# macOS development environment bootstrap — orchestrates per-component skills
set -euo pipefail

SKILL_BASE="$HOME/.claude/plugins/setup/skills"
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

# ── Component registry: id|label|script ──────────────────────────────────────
COMPONENTS=(
  "brew|Homebrew (package manager — required for everything else)|"
  "zsh|Zsh + Oh My Zsh + plugins + powerlevel10k + uv/fnm/Go|$SKILL_BASE/setup-zsh/scripts/setup-zsh.sh"
  "vim|Neovim with kickstart.nvim|$SKILL_BASE/setup-vim/scripts/setup-vim.sh"
  "tmux|tmux + TPM + Dracula theme|$SKILL_BASE/setup-tmux/scripts/setup-tmux.sh"
  "git|Git global config + GitHub CLI (gh) + SSH key|$SKILL_BASE/setup-git/scripts/setup-git.sh"
  "ghostty|Ghostty terminal + Nerd Font|$SKILL_BASE/setup-ghostty/scripts/setup-ghostty.sh"
  "docker|Docker via OrbStack|$SKILL_BASE/setup-docker/scripts/setup-docker.sh"
  "hysteria2|Hysteria 2 proxy client (hy2start/hy2stop/hy2log)|$SKILL_BASE/setup-hysteria2/scripts/setup-hysteria2.sh"
  "prefs|macOS dev-friendly system preferences (4 settings)|"
)

# ── Component status detection (binary + config applied) ─────────────────────
# Returns 0 if installed AND configured. 1 otherwise.
check_installed() {
  local id="$1"
  case "$id" in
    brew)
      command -v brew &>/dev/null
      ;;
    zsh)
      [ -d "$HOME/.oh-my-zsh" ] \
        && [ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ] \
        && grep -q '^plugins=.*zsh-autosuggestions' "$HOME/.zshrc" 2>/dev/null \
        && command -v uv &>/dev/null \
        && command -v fnm &>/dev/null
      ;;
    vim)
      command -v nvim &>/dev/null \
        && [ -f "$HOME/.config/nvim/init.lua" ]
      ;;
    tmux)
      command -v tmux &>/dev/null \
        && [ -f "$HOME/.tmux.conf" ] \
        && [ -d "$HOME/.tmux/plugins/tpm" ]
      ;;
    git)
      command -v git &>/dev/null \
        && command -v gh &>/dev/null \
        && [ -n "$(git config --global user.email 2>/dev/null)" ] \
        && [ -n "$(git config --global user.name 2>/dev/null)" ] \
        && [ -f "$HOME/.ssh/id_ed25519" ] \
        && [ -f "$HOME/.gitignore_global" ]
      ;;
    ghostty)
      [ -d "/Applications/Ghostty.app" ] \
        && [ -f "$HOME/.config/ghostty/config" ]
      ;;
    docker)
      [ -d "/Applications/OrbStack.app" ] \
        && command -v docker &>/dev/null
      ;;
    hysteria2)
      command -v hysteria &>/dev/null \
        && [ -f "$HOME/.config/hysteria/config.yaml" ] \
        && [ -f "$HOME/.config/hysteria/aliases.sh" ] \
        && [ -f "$HOME/Library/LaunchAgents/com.hysteria.client.plist" ]
      ;;
    prefs)
      [ "$(defaults read com.apple.finder AppleShowAllExtensions 2>/dev/null)" = "1" ] \
        && [ "$(defaults read com.apple.dock show-recents 2>/dev/null)" = "0" ] \
        && [ "$(defaults read com.apple.desktopservices DSDontWriteNetworkStores 2>/dev/null)" = "1" ]
      ;;
    *) return 1 ;;
  esac
}

# Reason if not installed (best-effort hint for the picker)
status_hint() {
  local id="$1"
  case "$id" in
    brew)      command -v brew &>/dev/null || echo "not installed" ;;
    zsh)
      [ ! -d "$HOME/.oh-my-zsh" ] && { echo "no Oh My Zsh"; return; }
      [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ] && { echo "no powerlevel10k"; return; }
      grep -q '^plugins=.*zsh-autosuggestions' "$HOME/.zshrc" 2>/dev/null || { echo "plugins not in .zshrc"; return; }
      command -v uv  &>/dev/null || { echo "uv missing"; return; }
      command -v fnm &>/dev/null || { echo "fnm missing"; return; }
      ;;
    vim)
      command -v nvim &>/dev/null || { echo "no nvim binary"; return; }
      [ -f "$HOME/.config/nvim/init.lua" ] || echo "no init.lua"
      ;;
    tmux)
      command -v tmux &>/dev/null || { echo "no tmux binary"; return; }
      [ -f "$HOME/.tmux.conf" ] || { echo "no .tmux.conf"; return; }
      [ -d "$HOME/.tmux/plugins/tpm" ] || echo "no TPM"
      ;;
    git)
      command -v git &>/dev/null || { echo "no git binary"; return; }
      command -v gh  &>/dev/null || { echo "no gh CLI"; return; }
      [ -z "$(git config --global user.email 2>/dev/null)" ] && { echo "no git user.email"; return; }
      [ -f "$HOME/.ssh/id_ed25519" ] || { echo "no SSH key"; return; }
      [ -f "$HOME/.gitignore_global" ] || echo "no global gitignore"
      ;;
    ghostty)
      [ -d "/Applications/Ghostty.app" ] || { echo "Ghostty.app not installed"; return; }
      [ -f "$HOME/.config/ghostty/config" ] || echo "no config"
      ;;
    docker)
      [ -d "/Applications/OrbStack.app" ] || { echo "OrbStack not installed"; return; }
      command -v docker &>/dev/null || echo "no docker CLI"
      ;;
    hysteria2)
      command -v hysteria &>/dev/null || { echo "no hysteria binary"; return; }
      [ -f "$HOME/.config/hysteria/config.yaml" ] || { echo "no config.yaml"; return; }
      [ -f "$HOME/Library/LaunchAgents/com.hysteria.client.plist" ] || echo "no launchd plist"
      ;;
    prefs)
      [ "$(defaults read com.apple.finder AppleShowAllExtensions 2>/dev/null)" = "1" ] || { echo "extensions hidden"; return; }
      [ "$(defaults read com.apple.dock show-recents 2>/dev/null)" = "0" ] || echo "dock recents enabled"
      ;;
  esac
}

# ── Argument parsing ─────────────────────────────────────────────────────────
SELECTED=""

usage() {
  cat <<EOF
Usage: setup-macos.sh [--components <list>] [--all] [--list]

  --components <list>   Comma-separated component IDs (e.g. zsh,git,hysteria2)
  --all                 Run every component
  --list                Show all components with current install status
  -h, --help            Show this help

Components:
EOF
  for c in "${COMPONENTS[@]}"; do
    IFS='|' read -r id label _ <<< "$c"
    printf "  %-12s %s\n" "$id" "$label"
  done
}

# Comma-list of all component ids
all_ids() {
  local ids=()
  for c in "${COMPONENTS[@]}"; do
    IFS='|' read -r id _ _ <<< "$c"
    ids+=("$id")
  done
  (IFS=,; echo "${ids[*]}")
}

show_list() {
  echo "Components (status checked against current system):"
  echo ""
  printf "  %-12s %-10s %s\n" "ID" "STATUS" "DESCRIPTION"
  printf "  %-12s %-10s %s\n" "----" "------" "-----------"
  for c in "${COMPONENTS[@]}"; do
    IFS='|' read -r id label _ <<< "$c"
    if check_installed "$id"; then
      printf "  %-12s %-10s %s\n" "$id" "[ OK ]" "$label"
    else
      hint="$(status_hint "$id")"
      printf "  %-12s %-10s %s%s\n" "$id" "[MISS]" "$label" "${hint:+  ($hint)}"
    fi
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --components)  SELECTED="$2"; shift 2 ;;
    --all)         SELECTED="$(all_ids)"; shift ;;
    --list)        show_list; exit 0 ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

# ── Interactive multi-select picker ──────────────────────────────────────────
if [ -z "$SELECTED" ]; then
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║          macOS Dev Environment — Component Picker            ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo ""
  echo "Current status:"
  echo ""
  printf "  %-3s  %-10s %-12s %s\n" "#" "STATUS" "ID" "DESCRIPTION"
  printf "  %-3s  %-10s %-12s %s\n" "-" "------" "----" "-----------"

  IDS=()
  i=1
  for c in "${COMPONENTS[@]}"; do
    IFS='|' read -r id label _ <<< "$c"
    IDS+=("$id")
    if check_installed "$id"; then
      printf "  %-3s  %-10s %-12s %s\n" "$i" "[ OK ]" "$id" "$label"
    else
      hint="$(status_hint "$id")"
      printf "  %-3s  %-10s %-12s %s%s\n" "$i" "[MISS]" "$id" "$label" "${hint:+  ($hint)}"
    fi
    i=$((i+1))
  done

  echo ""
  echo "Pick components to install (space-separated numbers):"
  echo "  e.g.  '2 5 7'    install zsh, git, hysteria2"
  echo "        'all'      install everything"
  echo "        'missing'  install everything not currently ready"
  echo "        Enter      cancel"
  echo ""
  read -r -p "> " input

  PICKED=()
  case "$input" in
    "")
      echo "Cancelled."
      exit 0
      ;;
    all)
      PICKED=("${IDS[@]}")
      ;;
    missing)
      for id in "${IDS[@]}"; do
        check_installed "$id" || PICKED+=("$id")
      done
      ;;
    *)
      for n in $input; do
        if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "${#IDS[@]}" ]; then
          PICKED+=("${IDS[$((n-1))]}")
        else
          echo "Invalid number: '$n' — skipping"
        fi
      done
      ;;
  esac

  if [ ${#PICKED[@]} -eq 0 ]; then
    echo "Nothing selected. Exiting."
    exit 0
  fi

  SELECTED="$(IFS=,; echo "${PICKED[*]}")"

  # Show the equivalent CLI command
  echo ""
  echo "─────────────────────────────────────────────────────────"
  echo "Selected: $SELECTED"
  echo ""
  echo "Equivalent command (copy to re-run later):"
  echo "  bash $SELF --components $SELECTED"
  echo "─────────────────────────────────────────────────────────"
  echo ""
  read -r -p "Proceed? [Y/n] " confirm
  case "${confirm:-Y}" in
    n|N) echo "Cancelled."; exit 0 ;;
  esac
fi

# ── Helper: run a single component ───────────────────────────────────────────
should_run() {
  local id="$1"
  [[ ",$SELECTED," == *",$id,"* ]]
}

run_step() {
  local id="$1" label="$2" script="$3"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  [$id] $label"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if [ -n "$script" ] && [ -f "$script" ]; then
    bash "$script"
  fi
}

# ── Step: Homebrew (no script — inline) ──────────────────────────────────────
if should_run "brew"; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  [brew] Homebrew"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if ! command -v brew &>/dev/null; then
    echo "  Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo "  Homebrew already installed. Updating..."
    brew update --quiet
  fi
fi

# ── Step: components with their own scripts ──────────────────────────────────
for c in "${COMPONENTS[@]}"; do
  IFS='|' read -r id label script <<< "$c"
  [ "$id" = "brew" ] && continue
  [ "$id" = "prefs" ] && continue
  [ -z "$script" ] && continue
  if should_run "$id"; then
    run_step "$id" "$label" "$script"
  fi
done

# ── Step: macOS system preferences (no script — inline) ─────────────────────
if should_run "prefs"; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  [prefs] macOS system preferences"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  defaults write com.apple.finder AppleShowAllExtensions -bool true
  defaults write com.apple.dock show-recents -bool false
  mkdir -p "$HOME/Desktop/screenshots"
  defaults write com.apple.screencapture location "$HOME/Desktop/screenshots"
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

  killall Dock    2>/dev/null || true
  killall Finder  2>/dev/null || true

  echo "  macOS preferences applied (4 settings)."
fi

# ── Final summary with status verification ──────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                       Setup Complete                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Verification (each component checked for binary AND applied config):"
echo ""
IFS=',' read -r -a RAN_IDS <<< "$SELECTED"
for id in "${RAN_IDS[@]}"; do
  if check_installed "$id"; then
    printf "  %-12s [ OK ]\n" "$id"
  else
    hint="$(status_hint "$id")"
    printf "  %-12s [MISS] %s\n" "$id" "${hint:-incomplete}"
  fi
done

echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or: source ~/.zshrc)"
echo "  2. Run 'p10k configure' to set up the prompt"
echo "  3. In tmux: prefix + I  to install plugins"
should_run "git"       && echo "  4. Verify GitHub auth: gh auth status"
should_run "hysteria2" && echo "  5. Edit ~/.config/hysteria/config.yaml + run 'hy2start'"
should_run "docker"    && echo "  6. Verify Docker: docker run hello-world"
echo ""
echo "Re-check status anytime:  bash $SELF --list"
