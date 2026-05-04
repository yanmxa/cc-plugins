#!/bin/bash
# macOS development environment bootstrap — orchestrates per-component skills
set -euo pipefail

SKILL_BASE="$HOME/.claude/plugins/setup/skills"

# ── Component registry: id|label|script ──────────────────────────────────────
# Edit this list to add/remove components
COMPONENTS=(
  "brew|Homebrew (package manager — required for everything else)|"
  "zsh|Zsh + Oh My Zsh + plugins + powerlevel10k + uv/fnm/Go|$SKILL_BASE/setup-zsh/scripts/setup-zsh.sh"
  "vim|Neovim with full Lua config|$SKILL_BASE/setup-vim/scripts/setup-vim.sh"
  "tmux|tmux + TPM + Dracula theme|$SKILL_BASE/setup-tmux/scripts/setup-tmux.sh"
  "git|Git global config + GitHub CLI (gh) + SSH key|$SKILL_BASE/setup-git/scripts/setup-git.sh"
  "ghostty|Ghostty terminal + Nerd Font|$SKILL_BASE/setup-ghostty/scripts/setup-ghostty.sh"
  "docker|Docker via OrbStack (fast, free for personal — replaces Docker Desktop)|$SKILL_BASE/setup-docker/scripts/setup-docker.sh"
  "hysteria2|Hysteria 2 proxy client (hy2start/hy2stop/hy2log)|$SKILL_BASE/setup-hysteria2/scripts/setup-hysteria2.sh"
  "prefs|macOS system preferences (4 dev-friendly defaults — extensions, screenshots, etc.)|"
)

# ── Argument parsing ─────────────────────────────────────────────────────────
SELECTED=""        # comma-separated component ids; empty = interactive

usage() {
  cat <<EOF
Usage: setup-macos.sh [--components <list>] [--all] [--interactive]

  --components <list>   Comma-separated component IDs to run, e.g. zsh,git,hysteria2
  --all                 Run every component
  --interactive         Interactive picker (default if no flags given)
  --list                Show available components

Components:
EOF
  for c in "${COMPONENTS[@]}"; do
    IFS='|' read -r id label _ <<< "$c"
    printf "  %-12s %s\n" "$id" "$label"
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --components)  SELECTED="$2"; shift 2 ;;
    --all)         SELECTED="$(printf '%s,' "${COMPONENTS[@]}" | sed 's/|[^,]*//g; s/,$//')"; shift ;;
    --interactive) SELECTED=""; shift ;;
    --list)        usage; exit 0 ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

# ── Interactive picker (only if no --components given) ───────────────────────
if [ -z "$SELECTED" ]; then
  echo "╔══════════════════════════════════════════╗"
  echo "║   macOS Dev Environment — Select Setup   ║"
  echo "╚══════════════════════════════════════════╝"
  echo ""
  echo "Pick components to install (one per line, Y=yes, n=skip):"
  echo ""

  PICKED=()
  for c in "${COMPONENTS[@]}"; do
    IFS='|' read -r id label _ <<< "$c"
    # Sensible defaults: Y for core, n for proxy / GUI tools
    case "$id" in
      brew|zsh|git)  default="Y" ;;
      *)             default="n" ;;
    esac
    prompt="  $id ($label) [${default}/$( [[ $default == Y ]] && echo n || echo y)] "
    read -r -p "$prompt" reply
    reply="${reply:-$default}"
    case "$reply" in
      y|Y) PICKED+=("$id") ;;
    esac
  done

  if [ ${#PICKED[@]} -eq 0 ]; then
    echo ""
    echo "Nothing selected. Exiting."
    exit 0
  fi

  SELECTED="$(IFS=,; echo "${PICKED[*]}")"
fi

echo ""
echo "Will run: $SELECTED"
echo ""

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

# ── Step: Homebrew ───────────────────────────────────────────────────────────
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

# ── Step: macOS system preferences (minimal — only universally useful) ──────
if should_run "prefs"; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  [prefs] macOS system preferences"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Finder: show all file extensions (avoid ambiguous filenames)
  defaults write com.apple.finder AppleShowAllExtensions -bool true

  # Dock: hide the "recent apps" section (rarely useful, just clutter)
  defaults write com.apple.dock show-recents -bool false

  # Screenshots: save to ~/Desktop/screenshots/ instead of cluttering Desktop
  mkdir -p "$HOME/Desktop/screenshots"
  defaults write com.apple.screencapture location "$HOME/Desktop/screenshots"

  # Don't write .DS_Store on network drives (avoid polluting shared SMB shares)
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

  killall Dock    2>/dev/null || true
  killall Finder  2>/dev/null || true

  echo "  macOS preferences applied (4 settings)."
fi

echo ""
echo "╔══════════════════════════════════════╗"
echo "║         Setup Complete!              ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or: source ~/.zshrc)"
echo "  2. Run 'p10k configure' to set up the prompt"
echo "  3. In tmux: prefix + I  to install plugins"
echo "  4. Add your SSH public key / gh authenticate"
should_run "hysteria2" && echo "  5. Edit ~/.config/hysteria/config.yaml + run 'hy2start'"
echo ""
echo "Re-run any single component:"
echo "  bash setup-macos.sh --components <id>"
