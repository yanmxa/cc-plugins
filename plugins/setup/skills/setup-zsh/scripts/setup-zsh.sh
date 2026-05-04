#!/bin/bash
# Setup Zsh with Oh My Zsh, plugins, powerlevel10k, and modern CLI tools
set -euo pipefail

MODE="${1:-all}"  # all, --plugins-only, --theme-only, --tools-only

ZSHRC="$HOME/.zshrc"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
ZSH_PLUGIN_DIR="$ZSH_CUSTOM_DIR/plugins"

echo "=== Zsh Setup ==="

clone_or_update() {
  local repo="$1" dest="$2"
  if [ -d "$dest" ]; then
    echo "  Updating $(basename "$dest")..."
    git -C "$dest" pull --quiet 2>/dev/null || true
  else
    echo "  Installing $(basename "$dest")..."
    git clone --quiet "$repo" "$dest"
  fi
}

install_omz() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh already installed."
  else
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "Oh My Zsh installed."
  fi
}

install_plugins() {
  echo ""
  echo "Installing Zsh plugins..."

  clone_or_update "https://github.com/zsh-users/zsh-autosuggestions"    "$ZSH_PLUGIN_DIR/zsh-autosuggestions"
  clone_or_update "https://github.com/zsh-users/zsh-completions"         "$ZSH_PLUGIN_DIR/zsh-completions"
  clone_or_update "https://github.com/zsh-users/zsh-syntax-highlighting" "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"
  clone_or_update "https://github.com/Aloxaf/fzf-tab"                    "$ZSH_PLUGIN_DIR/fzf-tab"
  clone_or_update "https://github.com/rupa/z"                            "$ZSH_PLUGIN_DIR/z"

  if ! command -v fzf &>/dev/null; then
    echo "  Installing fzf..."
    if command -v brew &>/dev/null; then
      brew install fzf
      "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
    else
      echo "  WARNING: Homebrew not found. Install fzf manually."
    fi
  else
    echo "  fzf already installed."
  fi

  echo "Plugins ready."
}

install_theme() {
  echo ""
  echo "Installing powerlevel10k theme..."
  clone_or_update "https://github.com/romkatv/powerlevel10k.git" "$ZSH_CUSTOM_DIR/themes/powerlevel10k"
  echo "powerlevel10k ready. Run 'p10k configure' to customize."
}

install_tools() {
  echo ""
  echo "Installing CLI tools..."

  # All tools: prefer Homebrew on macOS; require brew (no curl|sh fallback)
  if ! command -v brew &>/dev/null; then
    echo "ERROR: Homebrew is required for tool installs. Install from https://brew.sh first."
    return 1
  fi

  # zoxide — smart cd
  if ! command -v zoxide &>/dev/null; then
    echo "  Installing zoxide..."
    brew install zoxide
  else
    echo "  zoxide already installed."
  fi

  # uv — Python package manager (replaces pyenv + pip + virtualenv)
  if ! command -v uv &>/dev/null; then
    echo "  Installing uv..."
    brew install uv
  else
    echo "  uv already installed: $(uv --version)"
  fi

  # fnm — fast Node.js version manager (replaces nvm)
  if ! command -v fnm &>/dev/null; then
    echo "  Installing fnm..."
    brew install fnm
  else
    echo "  fnm already installed: $(fnm --version)"
  fi

  # Go
  if ! command -v go &>/dev/null; then
    echo "  Installing Go..."
    brew install go
  else
    echo "  Go already installed: $(go version)"
  fi

  echo "CLI tools ready."
}

write_zshrc() {
  echo ""
  echo "Writing self-contained ~/.zshrc..."

  if [ -f "$ZSHRC" ]; then
    BACKUP="$ZSHRC.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$ZSHRC" "$BACKUP"
    echo "  Backed up existing .zshrc → $BACKUP"
  fi

  cat > "$ZSHRC" << 'ZSHRC_EOF'
# ~/.zshrc — generic shell config. Secrets → ~/.env. Machine extras → ~/.zshrc.local.

# ── Oh My Zsh ──
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-completions zsh-syntax-highlighting fzf-tab z)
source "$ZSH/oh-my-zsh.sh"

# ── Locale & editor ──
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
export EDITOR=nvim VISUAL=nvim PAGER=less

# ── History (50k, dedupe, shared) ──
HISTFILE="$HOME/.zsh_history"; HISTSIZE=50000; SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS \
       SHARE_HISTORY HIST_VERIFY EXTENDED_HISTORY

# ── PATH ──
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# ── Python (uv) ── force venv use; bare `pip install` is blocked
export UV_PYTHON_PREFERENCE=only-managed
command -v uv &>/dev/null && eval "$(uv generate-shell-completion zsh)"
pip() {
  [[ "${1:-}" == install ]] && { echo "Use: uv venv && uv pip install ...   |   uv tool install <pkg>"; return 1; }
  command pip "$@"
}

# ── Node (fnm) ── auto-switches on .nvmrc / .node-version
command -v fnm &>/dev/null && eval "$(fnm env --use-on-cd --shell zsh)"

# ── Go ──
command -v go &>/dev/null && { export GOPATH="$HOME/go"; export PATH="$PATH:$GOPATH/bin"; }

# ── Smart cd (zoxide) ──
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# ── Optional toolchains (loaded only if installed) ──
[ -f "$HOME/.cargo/env" ]                          && source "$HOME/.cargo/env"
[ -d "$HOME/.bun" ]                                && { export BUN_INSTALL="$HOME/.bun"; export PATH="$BUN_INSTALL/bin:$PATH"; [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"; }
[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]       && source "$HOME/google-cloud-sdk/path.zsh.inc"
[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ] && source "$HOME/google-cloud-sdk/completion.zsh.inc"
for _c in "$HOME/miniforge3" "$HOME/miniconda3"; do
  [ -f "$_c/etc/profile.d/conda.sh" ] && { source "$_c/etc/profile.d/conda.sh"; break; }
done; unset _c

# ── zsh-syntax-highlighting (MUST be last among plugins) ──
_h="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[ -f "$_h" ] && source "$_h"; unset _h

# ── Aliases ──
alias vim=nvim vi=vi
alias ll='ls -lAh' la='ls -la' l='ls -CF'
alias ..='cd ..' ...='cd ../..' ....='cd ../../..'
alias grep='grep --color=auto' mkdir='mkdir -p'
alias g=git k=kubectl d=docker dc='docker compose'

# ── Functions ──
mkcd() { mkdir -p "$1" && cd "$1"; }
extract() {
  [ -f "$1" ] || { echo "extract: '$1' is not a file"; return 1; }
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz)         tar xJf "$1" ;;
    *.tar)            tar xf  "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.gz)             gunzip  "$1" ;;
    *.zip)            unzip   "$1" ;;
    *.rar)            unrar x "$1" ;;
    *.7z)             7z x    "$1" ;;
    *) echo "extract: unsupported format: $1"; return 1 ;;
  esac
}

# ── Local overrides (last — wins over everything above) ──
[ -f "$HOME/.env" ]         && { set -a; source "$HOME/.env"; set +a; }
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
ZSHRC_EOF

  echo "  ~/.zshrc written."
}

setup_env_files() {
  echo ""
  echo "Creating starter env files (won't overwrite existing)..."

  # ~/.env — environment variables / secrets
  if [ ! -f "$HOME/.env" ]; then
    cat > "$HOME/.env" << 'ENV_EOF'
# ~/.env — User environment variables (secrets, API tokens, paths)
# Sourced by ~/.zshrc with auto-export. NEVER commit this file to git.
# Edit then reload with: source ~/.zshrc
#
# Lines below are bare assignments (no `export` needed — auto-exported).

# ── AI / LLM ──────────────────────────────────────────────────────────
# OPENAI_API_KEY=sk-...
# ANTHROPIC_API_KEY=sk-ant-...

# ── GitHub / Git ──────────────────────────────────────────────────────
# GITHUB_TOKEN=ghp_...

# ── Cloud ─────────────────────────────────────────────────────────────
# AWS_PROFILE=default
# AWS_REGION=us-west-2
# GCP_PROJECT=my-project

# ── Tool config ───────────────────────────────────────────────────────
# HOMEBREW_GITHUB_API_TOKEN=ghp_...
ENV_EOF
    chmod 600 "$HOME/.env"
    echo "  Created ~/.env (chmod 600)"
  else
    echo "  ~/.env already exists, leaving alone."
  fi

  # ~/.zshrc.local — machine-specific shell config (only create stub if missing)
  if [ ! -f "$HOME/.zshrc.local" ]; then
    cat > "$HOME/.zshrc.local" << 'LOCAL_EOF'
# ~/.zshrc.local — machine-specific shell config (gitignored)
# Put aliases, functions, work-only config here. Sourced AFTER ~/.zshrc.
# For environment variables / secrets use ~/.env instead.

# Example:
# alias work-vpn='sudo openconnect vpn.company.com'
# alias prod-db='psql -h prod.example.com -U admin'
LOCAL_EOF
    echo "  Created ~/.zshrc.local stub"
  else
    echo "  ~/.zshrc.local already exists, leaving alone."
  fi
}

case "$MODE" in
  --plugins-only) install_plugins ;;
  --theme-only)   install_theme ;;
  --tools-only)   install_tools ;;
  --env-only)     setup_env_files ;;
  *)
    install_omz
    install_plugins
    install_theme
    install_tools
    write_zshrc
    setup_env_files
    ;;
esac

echo ""
echo "=== Zsh Setup Complete ==="
echo ""
echo "Config files:"
echo "  ~/.zshrc        — main shell config (tracked)"
echo "  ~/.env          — secrets / API keys     (gitignored, chmod 600)"
echo "  ~/.zshrc.local  — machine-local shell    (gitignored)"
echo ""
echo "Reload: source ~/.zshrc"
