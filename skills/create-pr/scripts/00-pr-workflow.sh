#!/bin/bash
# 00-pr-workflow.sh - Complete PR workflow (fork → modify → PR)
# Usage: ./00-pr-workflow.sh <upstream_repo> <base_branch> <feature_branch> <pr_title> [work_dir] [depth]
# Example: ./00-pr-workflow.sh stolostron/multicluster-global-hub release-1.6 fix/bug-123 "Fix bug in handler" ~/tmp/contribute 1

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
step() { echo -e "${BLUE}[STEP]${NC} $*"; }

# Check arguments
if [ $# -lt 4 ]; then
    error "Usage: $0 <upstream_repo> <base_branch> <feature_branch> <pr_title> [work_dir] [depth]"
    error "Example: $0 stolostron/multicluster-global-hub release-1.6 fix/bug-123 \"Fix bug\" ~/tmp/contribute 1"
    error ""
    error "Parameters:"
    error "  upstream_repo   - Repository to fork (owner/repo)"
    error "  base_branch     - Base branch for PR (e.g., main, release-1.6)"
    error "  feature_branch  - Your feature branch name"
    error "  pr_title        - Pull request title"
    error "  work_dir        - Working directory (default: ~/tmp/contribute)"
    error "  depth           - Git clone depth (default: 1 for fast shallow clone)"
    error "                    Use 'full' for complete history if needed"
    exit 1
fi

UPSTREAM_REPO="$1"
BASE_BRANCH="$2"
FEATURE_BRANCH="$3"
PR_TITLE="$4"
WORK_DIR="${5:-$HOME/tmp/contribute}"
CLONE_DEPTH="${6:-1}"  # Default to shallow clone (depth=1) for speed
REPO_NAME=$(basename "$UPSTREAM_REPO")

info "========================================="
info "Contribution Workflow Started"
info "========================================="
info "Upstream repository: $UPSTREAM_REPO"
info "Base branch: $BASE_BRANCH"
info "Feature branch: $FEATURE_BRANCH"
info "PR title: $PR_TITLE"
info "Work directory: $WORK_DIR"
if [ "$CLONE_DEPTH" = "1" ]; then
    info "Clone depth: 1 (shallow clone - faster)"
elif [ -n "$CLONE_DEPTH" ]; then
    info "Clone depth: $CLONE_DEPTH"
else
    info "Clone depth: full history"
fi
info "========================================="

# Check prerequisites
step "1/7: Checking prerequisites..."
if ! command -v gh &> /dev/null; then
    error "GitHub CLI (gh) is not installed. Please install it first:"
    error "  brew install gh"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    error "Not authenticated with GitHub CLI. Please run:"
    error "  gh auth login"
    exit 1
fi

GH_USER=$(gh api user --jq '.login')
info "GitHub username: $GH_USER"

# Step 1: Fork and setup
step "2/7: Forking and setting up repository..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! bash "$SCRIPT_DIR/01-fork-and-setup.sh" "$UPSTREAM_REPO" "$WORK_DIR" "$CLONE_DEPTH"; then
    error "Failed to fork and setup repository"
    exit 1
fi

REPO_PATH="$WORK_DIR/$REPO_NAME"
cd "$REPO_PATH"

# Step 2: Check for contribution guidelines
step "3/7: Checking for contribution guidelines..."
if [ -f "CONTRIBUTING.md" ]; then
    info "Found CONTRIBUTING.md - Please review contribution guidelines:"
    head -20 CONTRIBUTING.md
    echo ""
    warn "Press Enter to continue after reviewing guidelines..."
    # For automation, we'll skip the wait
    # read -r
fi

# Step 3: Create feature branch
step "4/7: Creating feature branch from latest upstream..."
git fetch upstream
if git rev-parse --verify "$FEATURE_BRANCH" &> /dev/null; then
    warn "Branch '$FEATURE_BRANCH' already exists. Switching to it..."
    git checkout "$FEATURE_BRANCH"
    # Optionally rebase on latest upstream
    git rebase "upstream/$BASE_BRANCH" || {
        error "Failed to rebase. Please resolve conflicts manually."
        exit 1
    }
else
    git checkout -b "$FEATURE_BRANCH" "upstream/$BASE_BRANCH"
    info "Created branch '$FEATURE_BRANCH' from 'upstream/$BASE_BRANCH'"
fi

# Step 4: Pause for manual changes
step "5/7: Ready for code changes..."
info ""
info "Repository path: $REPO_PATH"
info "Current branch: $(git branch --show-current)"
info ""
info "Next steps:"
info "  1. Make your code changes"
info "  2. Commit your changes with: git commit -s -m \"message\""
info "  3. Return here and we'll create the PR"
info ""
warn "This script will now pause. Press Enter when you're ready to create the PR..."
# For automation in Claude, we'll skip this pause
# read -r

# Step 5: Verify changes are committed
step "6/7: Verifying changes are committed..."
if git diff-index --quiet HEAD --; then
    # Check if there are any commits on this branch
    COMMITS_AHEAD=$(git rev-list --count "upstream/$BASE_BRANCH..$FEATURE_BRANCH")
    if [ "$COMMITS_AHEAD" -eq 0 ]; then
        error "No changes committed. Please make changes and commit them first."
        exit 1
    fi
    info "Found $COMMITS_AHEAD commit(s) ready to push"
else
    error "You have uncommitted changes. Please commit or stash them first."
    info "Run: git status"
    exit 1
fi

# Step 6: Run checks (if applicable)
step "7/7: Running pre-PR checks..."
# Check for common files that indicate tests should be run
if [ -f "Makefile" ]; then
    if grep -q "^test:" Makefile; then
        info "Found 'test' target in Makefile. Consider running: make test"
    fi
    if grep -q "^lint:" Makefile; then
        info "Found 'lint' target in Makefile. Consider running: make lint"
    fi
fi

# Step 7: Create PR
info ""
info "========================================="
info "Creating Pull Request"
info "========================================="

# Get commit messages for PR body
COMMIT_MESSAGES=$(git log --pretty=format:"- %s" "upstream/$BASE_BRANCH..$FEATURE_BRANCH")
PR_BODY="## Changes

$COMMIT_MESSAGES

## Checklist
- [x] Code changes are committed with sign-off
- [ ] Tests pass locally (if applicable)
- [ ] Documentation updated (if needed)

---
*Generated via contribute script*"

# Use the fixed create-pr script
if bash "$SCRIPT_DIR/03-create-pr.sh" "$BASE_BRANCH" "$PR_TITLE" "$PR_BODY"; then
    info ""
    info "========================================="
    info "✅ Contribution workflow completed!"
    info "========================================="
else
    error "Failed to create PR. You can create it manually with:"
    error "  gh pr create --repo $UPSTREAM_REPO --base $BASE_BRANCH --head $GH_USER:$FEATURE_BRANCH"
    exit 1
fi
