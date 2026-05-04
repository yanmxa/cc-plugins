#!/bin/bash
# Setup Neovim with kickstart.nvim (community-maintained starter config)
# or classic Vim with vim-plug as fallback.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-all}"  # all | --vim-only | --neovim-only

NVIM_CONFIG_DIR="$HOME/.config/nvim"
KICKSTART_REPO="https://github.com/nvim-lua/kickstart.nvim.git"

echo "=== Vim/Neovim Setup ==="

# --- Install Neovim ---
install_neovim() {
  if ! command -v nvim &>/dev/null; then
    if ! command -v brew &>/dev/null; then
      echo "ERROR: Homebrew is required. Install from https://brew.sh first."
      exit 1
    fi
    echo "Installing Neovim via Homebrew..."
    brew install neovim
  else
    echo "Neovim already installed: $(nvim --version | head -1)"
  fi

  # Build deps for treesitter parsers
  for dep in ripgrep fd; do
    if ! command -v "$dep" &>/dev/null; then
      echo "  Installing $dep (used by Telescope/treesitter)..."
      brew install "$dep"
    fi
  done
}

# --- Deploy kickstart.nvim as the default config ---
deploy_neovim_config() {
  if [ -d "$NVIM_CONFIG_DIR" ] || [ -L "$NVIM_CONFIG_DIR" ]; then
    BACKUP="$NVIM_CONFIG_DIR.backup.$(date +%Y%m%d_%H%M%S)"
    mv "$NVIM_CONFIG_DIR" "$BACKUP"
    echo "  Backed up existing config → $BACKUP"
  fi

  mkdir -p "$HOME/.config"
  echo "  Cloning kickstart.nvim..."
  git clone --depth 1 "$KICKSTART_REPO" "$NVIM_CONFIG_DIR"

  # Detach .git so user's customizations don't conflict with upstream
  rm -rf "$NVIM_CONFIG_DIR/.git"
  echo "  Deployed kickstart.nvim → $NVIM_CONFIG_DIR (detached from upstream — yours to edit)"
  echo ""
  echo "  Open nvim once to trigger lazy.nvim plugin install (auto-runs on first launch)."
  echo "  Customize: \$EDITOR $NVIM_CONFIG_DIR/init.lua"
}

# --- Setup classic Vim (fallback for systems without nvim) ---
setup_vim() {
  local VIMRC="$HOME/.vimrc"
  echo ""
  echo "Setting up classic Vim..."

  if [ -f "$VIMRC" ]; then
    BACKUP="$VIMRC.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$VIMRC" "$BACKUP"
    echo "  Backed up existing .vimrc → $BACKUP"
  fi

  # Install vim-plug (official install method per junegunn/vim-plug README)
  PLUG_VIM="$HOME/.vim/autoload/plug.vim"
  if [ ! -f "$PLUG_VIM" ]; then
    echo "  Installing vim-plug..."
    curl -fLo "$PLUG_VIM" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  else
    echo "  vim-plug already installed."
  fi

  cp "$SCRIPT_DIR/vimrc" "$VIMRC"
  echo "  Deployed vimrc."

  echo "  Installing Vim plugins (PlugInstall)..."
  vim +PlugInstall +qall 2>/dev/null || true
}

case "$MODE" in
  --vim-only)
    setup_vim
    ;;
  --neovim-only)
    install_neovim
    deploy_neovim_config
    ;;
  *)
    install_neovim
    deploy_neovim_config
    ;;
esac

echo ""
echo "=== Vim Setup Complete ==="
echo "  nvim  → kickstart.nvim (LSP, treesitter, telescope, completion)"
echo "          Edit: $NVIM_CONFIG_DIR/init.lua"
echo "          Docs: https://github.com/nvim-lua/kickstart.nvim"
