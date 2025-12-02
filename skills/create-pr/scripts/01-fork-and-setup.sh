#!/bin/bash
# 01-fork-and-setup.sh - Fork repository and setup local environment
# Usage: ./01-fork-and-setup.sh <upstream_repo> [work_dir] [depth] [base_branch] [feature_branch]
# Example: ./01-fork-and-setup.sh stolostron/multicluster-global-hub ~/tmp/contribute 1 main fix/version

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Check arguments
if [ $# -lt 1 ]; then
    error "Usage: $0 <upstream_repo> [work_dir] [depth] [base_branch] [feature_branch]"
    error "Example: $0 stolostron/multicluster-global-hub ~/tmp/contribute 1 main fix/version"
    error "Example (current dir): cd /path/to/repo && $0 stolostron/multicluster-global-hub . 1 main fix/version"
    error ""
    error "Parameters:"
    error "  upstream_repo   - Repository to fork (owner/repo)"
    error "  work_dir        - Working directory (default: ~/tmp/contribute)"
    error "                    Use '.' to work in current directory (must be a git repo)"
    error "  depth           - Git clone depth (default: full history)"
    error "                    Use 1 for shallow clone (faster, less history)"
    error "  base_branch     - Base branch to branch from (optional)"
    error "  feature_branch  - Feature branch to create (optional, requires base_branch)"
    exit 1
fi

UPSTREAM_REPO="$1"
WORK_DIR="${2:-$HOME/tmp/contribute}"
CLONE_DEPTH="${3:-}"
BASE_BRANCH="${4:-}"
FEATURE_BRANCH="${5:-}"
REPO_NAME=$(basename "$UPSTREAM_REPO")

# Support current directory mode
USE_CURRENT_DIR=false
if [ "$WORK_DIR" = "." ]; then
    USE_CURRENT_DIR=true
    WORK_DIR="$(pwd)"
    info "Using current directory mode"
fi

info "Upstream repository: $UPSTREAM_REPO"
info "Work directory: $WORK_DIR"
info "Repository name: $REPO_NAME"
if [ -n "$CLONE_DEPTH" ]; then
    info "Clone depth: $CLONE_DEPTH (shallow clone for faster download)"
else
    info "Clone depth: full history"
fi
if [ -n "$BASE_BRANCH" ] && [ -n "$FEATURE_BRANCH" ]; then
    info "Will create feature branch: $FEATURE_BRANCH from $BASE_BRANCH"
fi

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    error "GitHub CLI (gh) is not installed. Please install it first:"
    error "  brew install gh"
    exit 1
fi

# Check if user is authenticated with gh
if ! gh auth status &> /dev/null; then
    error "Not authenticated with GitHub CLI. Please run:"
    error "  gh auth login"
    exit 1
fi

# Get current GitHub username
GH_USER=$(gh api user --jq '.login')
info "GitHub username: $GH_USER"

# Check if fork already exists (with possible different name)
info "Checking if fork already exists..."
FORK_EXISTS=false
FORK_REPO_NAME=""

# First, try the expected name
if gh repo view "$GH_USER/$REPO_NAME" &> /dev/null; then
    warn "Fork already exists: $GH_USER/$REPO_NAME"
    FORK_EXISTS=true
    FORK_REPO_NAME="$REPO_NAME"
else
    # Check if there's a fork with a different name by querying the upstream repo
    info "Checking for fork with different name..."
    POTENTIAL_FORK=$(gh api "repos/$UPSTREAM_REPO/forks" --jq ".[] | select(.owner.login == \"$GH_USER\") | .name" 2>/dev/null | head -1)

    if [ -n "$POTENTIAL_FORK" ]; then
        warn "Found existing fork with different name: $GH_USER/$POTENTIAL_FORK"
        warn "Original repo: $REPO_NAME, Fork name: $POTENTIAL_FORK"
        FORK_EXISTS=true
        FORK_REPO_NAME="$POTENTIAL_FORK"
    else
        info "Fork does not exist. Creating fork..."
        FORK_OUTPUT=$(gh repo fork "$UPSTREAM_REPO" --clone=false 2>&1)
        if [ $? -eq 0 ]; then
            # Extract the actual fork name from output or check again
            FORK_REPO_NAME=$(gh api "repos/$UPSTREAM_REPO/forks" --jq ".[] | select(.owner.login == \"$GH_USER\") | .name" 2>/dev/null | head -1)
            if [ -z "$FORK_REPO_NAME" ]; then
                FORK_REPO_NAME="$REPO_NAME"  # Fallback to expected name
            fi
            info "Fork created successfully: $GH_USER/$FORK_REPO_NAME"
            FORK_EXISTS=true
        else
            error "Failed to create fork"
            error "$FORK_OUTPUT"
            exit 1
        fi
    fi
fi

# Use the actual fork name for subsequent operations
if [ -n "$FORK_REPO_NAME" ]; then
    info "Using fork: $GH_USER/$FORK_REPO_NAME"
else
    error "Could not determine fork repository name"
    exit 1
fi

# Determine repository path
if [ "$USE_CURRENT_DIR" = true ]; then
    # In current directory mode, check if we're already in a git repo
    if git rev-parse --git-dir &> /dev/null; then
        REPO_PATH="$WORK_DIR"
        info "Using current directory as repository: $REPO_PATH"
    else
        error "Current directory mode requires you to be in a git repository"
        error "Either cd to the repository or specify a different work_dir"
        exit 1
    fi
else
    # Create work directory if it doesn't exist
    mkdir -p "$WORK_DIR"
    REPO_PATH="$WORK_DIR/$REPO_NAME"
fi

# Check if repository already cloned (using the original repo name for local directory)
if [ -d "$REPO_PATH/.git" ]; then
    warn "Repository already exists at: $REPO_PATH"
    info "Checking remotes..."

    cd "$REPO_PATH"

    # Check current remotes
    if git remote get-url upstream &> /dev/null; then
        CURRENT_UPSTREAM=$(git remote get-url upstream)
        info "Current upstream: $CURRENT_UPSTREAM"
    else
        warn "No upstream remote found. Adding it..."
        git remote add upstream "https://github.com/$UPSTREAM_REPO.git"
        info "Added upstream: https://github.com/$UPSTREAM_REPO.git"
    fi

    if git remote get-url origin &> /dev/null; then
        CURRENT_ORIGIN=$(git remote get-url origin)
        info "Current origin: $CURRENT_ORIGIN"
    else
        warn "No origin remote found. Adding it..."
        git remote add origin "git@github.com:$GH_USER/$FORK_REPO_NAME.git"
        info "Added origin: git@github.com:$GH_USER/$FORK_REPO_NAME.git"
    fi
else
    if [ "$USE_CURRENT_DIR" = true ]; then
        error "Current directory is not a git repository and current directory mode is enabled"
        error "Either cd to the repository or use a different work_dir"
        exit 1
    fi

    info "Cloning fork to: $REPO_PATH"
    cd "$WORK_DIR"

    # Clone the fork with optional depth
    CLONE_CMD="git clone"
    if [ -n "$CLONE_DEPTH" ]; then
        CLONE_CMD="$CLONE_CMD --depth $CLONE_DEPTH"
        info "Using shallow clone (depth=$CLONE_DEPTH) for faster download..."
    fi

    # Clone using the actual fork name, but rename directory to original repo name
    if [ "$FORK_REPO_NAME" = "$REPO_NAME" ]; then
        # Fork name matches, no need to rename
        if $CLONE_CMD "git@github.com:$GH_USER/$FORK_REPO_NAME.git"; then
            info "Fork cloned successfully"
            cd "$REPO_NAME"

            # Add upstream remote
            info "Adding upstream remote..."
            git remote add upstream "https://github.com/$UPSTREAM_REPO.git"
            info "Added upstream: https://github.com/$UPSTREAM_REPO.git"
        else
            error "Failed to clone fork"
            exit 1
        fi
    else
        # Fork name differs, clone and rename
        if $CLONE_CMD "git@github.com:$GH_USER/$FORK_REPO_NAME.git" "$REPO_NAME"; then
            info "Fork cloned successfully (renamed from $FORK_REPO_NAME to $REPO_NAME)"
            cd "$REPO_NAME"

            # Add upstream remote
            info "Adding upstream remote..."
            git remote add upstream "https://github.com/$UPSTREAM_REPO.git"
            info "Added upstream: https://github.com/$UPSTREAM_REPO.git"
        else
            error "Failed to clone fork"
            exit 1
        fi
    fi
fi

# Fetch latest from upstream
info "Fetching latest from upstream..."
if [ -n "$CLONE_DEPTH" ]; then
    # For shallow clones, also use depth when fetching
    git fetch --depth "$CLONE_DEPTH" upstream
else
    git fetch upstream
fi

# Create feature branch if specified
if [ -n "$BASE_BRANCH" ] && [ -n "$FEATURE_BRANCH" ]; then
    info "Creating feature branch..."

    # Check if feature branch already exists
    if git rev-parse --verify "$FEATURE_BRANCH" &> /dev/null; then
        warn "Branch '$FEATURE_BRANCH' already exists. Switching to it..."
        git checkout "$FEATURE_BRANCH"
    else
        info "Creating branch '$FEATURE_BRANCH' from 'upstream/$BASE_BRANCH'..."
        git checkout -b "$FEATURE_BRANCH" "upstream/$BASE_BRANCH"
        info "Created and switched to branch '$FEATURE_BRANCH'"
    fi
fi

info "✅ Setup complete!"
info ""
info "Repository path: $REPO_PATH"
info "Remotes configured:"
git remote -v
if [ -n "$FEATURE_BRANCH" ]; then
    info "Current branch: $(git branch --show-current)"
fi
info ""
info "Next steps:"
info "  1. cd $REPO_PATH"
info "  2. Make your changes"
info "  3. Run create-pr script to submit PR"
