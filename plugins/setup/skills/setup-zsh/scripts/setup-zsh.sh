#!/bin/bash
# Setup Zsh with Oh My Zsh, plugins, powerlevel10k, and modern CLI tools
set -euo pipefail

MODE="${1:-all}"  # all, --plugins-only, --theme-only, --tools-only

ZSHRC="$HOME/.zshrc"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
ZSH_PLUGIN_DIR="$ZSH_CUSTOM_DIR/plugins"

echo "=== Zsh Setup ==="

# --- Helper: clone or update a git repo ---
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

# --- 1. Install Oh My Zsh ---
install_omz() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh already installed."
  else
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "Oh My Zsh installed."
  fi
}

# --- 2. Install plugins ---
install_plugins() {
  echo ""
  echo "Installing Zsh plugins..."

  clone_or_update "https://github.com/zsh-users/zsh-autosuggestions" "$ZSH_PLUGIN_DIR/zsh-autosuggestions"
  clone_or_update "https://github.com/zsh-users/zsh-completions" "$ZSH_PLUGIN_DIR/zsh-completions"
  clone_or_update "https://github.com/zsh-users/zsh-syntax-highlighting" "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"
  clone_or_update "https://github.com/Aloxaf/fzf-tab" "$ZSH_PLUGIN_DIR/fzf-tab"
  clone_or_update "https://github.com/rupa/z" "$ZSH_PLUGIN_DIR/z"

  # Install fzf if not present
  if ! command -v fzf &>/dev/null; then
    echo "  Installing fzf via Homebrew..."
    if command -v brew &>/dev/null; then
      brew install fzf
      "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
    else
      echo "  WARNING: Homebrew not found. Install fzf manually."
    fi
  else
    echo "  fzf already installed."
  fi

  # Update plugins list in .zshrc
  if [ -f "$ZSHRC" ]; then
    if grep -q '^plugins=' "$ZSHRC"; then
      sed -i '' '/^plugins=/c\
plugins=(git zsh-autosuggestions zsh-completions zsh-syntax-highlighting fzf-tab z)
' "$ZSHRC"
      echo "  Updated plugins list in .zshrc"
    else
      echo 'plugins=(git zsh-autosuggestions zsh-completions zsh-syntax-highlighting fzf-tab z)' >> "$ZSHRC"
      echo "  Added plugins list to .zshrc"
    fi

    # Ensure zsh-syntax-highlighting is sourced last
    SYNTAX_LINE='source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'
    grep -qF "$SYNTAX_LINE" "$ZSHRC" || echo "$SYNTAX_LINE" >> "$ZSHRC"
  fi

  echo "Plugins ready."
}

# --- 3. Install theme ---
install_theme() {
  echo ""
  echo "Installing powerlevel10k theme..."

  THEME_DIR="$ZSH_CUSTOM_DIR/themes/powerlevel10k"
  if [ -d "$THEME_DIR" ]; then
    echo "  powerlevel10k already installed, updating..."
    git -C "$THEME_DIR" pull --quiet 2>/dev/null || true
  else
    git clone --depth=1 --quiet https://github.com/romkatv/powerlevel10k.git "$THEME_DIR"
  fi

  # Set theme in .zshrc
  if [ -f "$ZSHRC" ] && grep -q '^ZSH_THEME=' "$ZSHRC"; then
    sed -i '' 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
    echo "  Updated ZSH_THEME in .zshrc"
  fi

  echo "powerlevel10k ready. Run 'p10k configure' to customize."
}

# --- 4. Install tools ---
install_tools() {
  echo ""
  echo "Installing CLI tools..."

  # zoxide
  if ! command -v zoxide &>/dev/null; then
    echo "  Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  else
    echo "  zoxide already installed."
  fi

  # Add zoxide init to .zshrc if not present
  if [ -f "$ZSHRC" ]; then
    ZOXIDE_LINE='eval "$(zoxide init zsh)"'
    grep -qF "$ZOXIDE_LINE" "$ZSHRC" || echo "$ZOXIDE_LINE" >> "$ZSHRC"
  fi

  echo "CLI tools ready."
}

# --- 5. Source custom env ---
setup_custom_env() {
  if [ -f "$HOME/myconfig/env/zsh.sh" ] && [ -f "$ZSHRC" ]; then
    ENV_LINE='source $HOME/myconfig/env/zsh.sh'
    if ! grep -qF "$ENV_LINE" "$ZSHRC"; then
      echo "$ENV_LINE" >> "$ZSHRC"
      echo "  Added myconfig env sourcing to .zshrc"
    fi
  fi
}

# --- Main ---
case "$MODE" in
  --plugins-only)
    install_plugins
    ;;
  --theme-only)
    install_theme
    ;;
  --tools-only)
    install_tools
    ;;
  *)
    install_omz
    install_plugins
    install_theme
    install_tools
    setup_custom_env
    ;;
esac

echo ""
echo "=== Setup Complete ==="
echo "Restart your terminal or run: source ~/.zshrc"
