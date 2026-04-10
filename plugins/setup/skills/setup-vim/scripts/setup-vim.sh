#!/bin/bash
# Setup Neovim with full Lua config or classic Vim with vim-plug
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-all}"  # all, --vim-only, --neovim-only
MYCONFIG_DIR="$HOME/myconfig"

echo "=== Vim/Neovim Setup ==="

# --- 1. Install Neovim ---
install_neovim() {
  if ! command -v nvim &>/dev/null; then
    echo "Neovim not found. Installing via Homebrew..."
    if ! command -v brew &>/dev/null; then
      echo "ERROR: Homebrew is required but not installed."
      echo "Install it from https://brew.sh"
      exit 1
    fi
    brew install neovim
    echo "Neovim installed: $(nvim --version | head -1)"
  else
    echo "Neovim already installed: $(nvim --version | head -1)"
  fi
}

# --- 2. Deploy Neovim config ---
deploy_neovim_config() {
  local NVIM_CONFIG="$HOME/.config/nvim"
  local NVIM_SOURCE="$MYCONFIG_DIR/neovim/nvim"

  if [ ! -d "$NVIM_SOURCE" ]; then
    echo "WARNING: Neovim config source not found at $NVIM_SOURCE"
    echo "Make sure ~/myconfig repo is cloned with submodules:"
    echo "  git submodule update --init --recursive"
    return 1
  fi

  # Backup existing config
  if [ -d "$NVIM_CONFIG" ] || [ -L "$NVIM_CONFIG" ]; then
    BACKUP="$NVIM_CONFIG.backup.$(date +%Y%m%d%H%M%S)"
    mv "$NVIM_CONFIG" "$BACKUP"
    echo "Existing nvim config backed up to: $BACKUP"
  fi

  # Create symlink to myconfig neovim
  mkdir -p "$HOME/.config"
  ln -s "$NVIM_SOURCE" "$NVIM_CONFIG"
  echo "Neovim config deployed (symlinked to $NVIM_SOURCE)"

  echo ""
  echo "Open nvim to trigger lazy.nvim plugin installation."
}

# --- 3. Setup classic Vim ---
setup_vim() {
  local VIMRC="$HOME/.vimrc"

  echo ""
  echo "Setting up classic Vim..."

  # Backup existing vimrc
  if [ -f "$VIMRC" ]; then
    BACKUP="$VIMRC.backup.$(date +%Y%m%d%H%M%S)"
    cp "$VIMRC" "$BACKUP"
    echo "Existing .vimrc backed up to: $BACKUP"
  fi

  # Install vim-plug
  PLUG_VIM="$HOME/.vim/autoload/plug.vim"
  if [ ! -f "$PLUG_VIM" ]; then
    echo "Installing vim-plug..."
    curl -fLo "$PLUG_VIM" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    echo "vim-plug installed."
  else
    echo "vim-plug already installed."
  fi

  # Deploy vimrc (merge custom keybindings + plugins)
  cp "$SCRIPT_DIR/vimrc" "$VIMRC"
  echo "vimrc deployed."

  # Install plugins
  echo "Installing Vim plugins..."
  vim +PlugInstall +qall 2>/dev/null || true
  echo "Vim plugins installed."
}

# --- Main ---
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
    setup_vim
    ;;
esac

echo ""
echo "=== Setup Complete ==="
echo "  nvim  → full Lua IDE config"
echo "  vim   → classic config with molokai + airline"
