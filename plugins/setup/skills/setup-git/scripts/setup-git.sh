#!/bin/bash
# Install git + GitHub CLI, then configure git global settings for a new machine
set -euo pipefail

echo "=== Git + GitHub Setup ==="

# --- Install git (brew version is fresher than system CLT version) ---
if ! command -v git &>/dev/null; then
  if command -v brew &>/dev/null; then
    echo "  Installing git via Homebrew..."
    brew install git
  else
    echo "ERROR: git not found and Homebrew not available. Install Xcode Command Line Tools or Homebrew first."
    exit 1
  fi
else
  GIT_PATH="$(command -v git)"
  if [[ "$GIT_PATH" != /opt/homebrew/* && "$GIT_PATH" != /usr/local/* ]] && command -v brew &>/dev/null; then
    echo "  Upgrading to Homebrew git (current: system git at $GIT_PATH)..."
    brew install git
  else
    echo "  git already installed: $(git --version)"
  fi
fi

# --- Identity ---
GIT_NAME="${1:-}"
GIT_EMAIL="${2:-}"

if [ -z "$GIT_NAME" ]; then
  CURRENT_NAME="$(git config --global user.name 2>/dev/null || true)"
  if [ -n "$CURRENT_NAME" ]; then
    echo "Current git user.name: $CURRENT_NAME"
    read -r -p "  Name [keep current]: " INPUT_NAME
    GIT_NAME="${INPUT_NAME:-$CURRENT_NAME}"
  else
    read -r -p "  Git user name: " GIT_NAME
  fi
fi

if [ -z "$GIT_EMAIL" ]; then
  CURRENT_EMAIL="$(git config --global user.email 2>/dev/null || true)"
  if [ -n "$CURRENT_EMAIL" ]; then
    echo "Current git user.email: $CURRENT_EMAIL"
    read -r -p "  Email [keep current]: " INPUT_EMAIL
    GIT_EMAIL="${INPUT_EMAIL:-$CURRENT_EMAIL}"
  else
    read -r -p "  Git user email: " GIT_EMAIL
  fi
fi

git config --global user.name  "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
echo "  Identity: $GIT_NAME <$GIT_EMAIL>"

# --- Editor ---
if command -v nvim &>/dev/null; then
  git config --global core.editor "nvim"
  echo "  Editor: nvim"
elif command -v vim &>/dev/null; then
  git config --global core.editor "vim"
  echo "  Editor: vim"
fi

# --- Pull / push / branch defaults ---
git config --global pull.rebase           true
git config --global push.autoSetupRemote  true
git config --global init.defaultBranch    main
git config --global core.autocrlf         input
echo "  Pull/push defaults set."

# --- Credential helper (macOS) ---
if [[ "$(uname)" == "Darwin" ]]; then
  git config --global credential.helper osxkeychain
  echo "  Credential helper: osxkeychain"
fi

# --- Useful aliases ---
git config --global alias.lg      "log --oneline --graph --decorate --all"
git config --global alias.st      "status -sb"
git config --global alias.co      "checkout"
git config --global alias.br      "branch"
git config --global alias.unstage "reset HEAD --"
git config --global alias.last    "log -1 HEAD"
git config --global alias.aliases "config --get-regexp alias"
echo "  Aliases: lg, st, co, br, unstage, last, aliases"

# --- Global gitignore ---
GLOBAL_IGNORE="$HOME/.gitignore_global"
if [ ! -f "$GLOBAL_IGNORE" ]; then
  cat > "$GLOBAL_IGNORE" << 'GITIGNORE_EOF'
# macOS
.DS_Store
.AppleDouble
.LSOverride
Icon
._*
.Spotlight-V100
.Trashes

# Editor
*.swp
*.swo
*~
.idea/
.vscode/
*.sublime-*

# Secrets / env (defense in depth — never commit)
.env
.env.local
.env.*.local
*.pem
*.key
*_rsa
*_ed25519

# Build / cache
.cache/
__pycache__/
*.pyc
node_modules/
.venv/
venv/
.pytest_cache/
.mypy_cache/
.ruff_cache/

# Logs
*.log
GITIGNORE_EOF
  echo "  Created ~/.gitignore_global"
else
  echo "  ~/.gitignore_global already exists, leaving alone."
fi
git config --global core.excludesfile "$GLOBAL_IGNORE"
echo "  Configured core.excludesfile → $GLOBAL_IGNORE"

# --- SSH key ---
echo ""
echo "--- SSH Key ---"
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
  echo "No SSH key found at $SSH_KEY. Generating..."
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY" -N ""
  echo "  SSH key generated."
else
  echo "  SSH key already exists at $SSH_KEY."
fi

if [ -z "${SSH_AUTH_SOCK:-}" ]; then
  eval "$(ssh-agent -s)" >/dev/null
fi
ssh-add "$SSH_KEY" 2>/dev/null || true

# --- GitHub CLI (gh) ---
echo ""
echo "--- GitHub CLI (gh) ---"
if ! command -v gh &>/dev/null; then
  if command -v brew &>/dev/null; then
    echo "  Installing gh via Homebrew..."
    brew install gh
  else
    echo "  WARNING: Homebrew not found. Install gh manually: https://cli.github.com"
  fi
else
  echo "  gh already installed: $(gh --version | head -1)"
fi

# gh auth: check if already authenticated
if command -v gh &>/dev/null; then
  if gh auth status &>/dev/null 2>&1; then
    echo "  Already authenticated with GitHub:"
    gh auth status 2>&1 | grep -E 'Logged in|account' | sed 's/^/    /'
  else
    cat <<'AUTH_GUIDE'

  ─────────────────────────────────────────────────────────────────
  Running 'gh auth login' — make these choices:

    Account?           → GitHub.com
    Protocol?          → SSH
    Generate new key?  → No, use existing key (~/.ssh/id_ed25519.pub)
    Title for SSH key  → <your machine name>
    Authenticate?      → Login with a web browser

  This uploads your SSH key to GitHub AND stores an OAuth token.
  Both 'git push' and 'gh pr create' will work after this.
  ─────────────────────────────────────────────────────────────────

AUTH_GUIDE
    gh auth login
  fi
fi

# --- Summary ---
echo ""
echo "=== Git + GitHub Setup Complete ==="
echo ""
echo "Your SSH public key (add to GitHub / GitLab if not using gh auth):"
echo "----------------------------------------------"
cat "${SSH_KEY}.pub"
echo "----------------------------------------------"
echo ""
echo "Verify with:"
echo "  git config --list --global"
echo "  gh auth status"
