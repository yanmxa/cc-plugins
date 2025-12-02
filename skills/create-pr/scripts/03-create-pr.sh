#!/bin/bash
# 03-create-pr.sh - Add, commit, push changes and create PR to upstream
# Usage: ./03-create-pr.sh <base_branch> <pr_title> [pr_body] [commit_message]
# Example: ./03-create-pr.sh main "Fix bug in sync handler" "This PR fixes..." "fix: resolve bug"

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
if [ $# -lt 2 ]; then
    error "Usage: $0 <base_branch> <pr_title> [pr_body] [commit_message]"
    error "Example: $0 main \"Fix bug in sync handler\" \"This PR fixes...\" \"fix: resolve bug\""
    exit 1
fi

BASE_BRANCH="$1"
PR_TITLE="$2"
PR_BODY="${3:-}"
COMMIT_MESSAGE="${4:-$PR_TITLE}"

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    error "GitHub CLI (gh) is not installed. Please install it first:"
    error "  brew install gh"
    exit 1
fi

# Check if in a git repository
if ! git rev-parse --git-dir &> /dev/null; then
    error "Not in a git repository"
    exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
info "Current branch: $CURRENT_BRANCH"

# Check if current branch is the base branch
if [ "$CURRENT_BRANCH" = "$BASE_BRANCH" ]; then
    error "You are on the base branch ($BASE_BRANCH). Please create a feature branch first."
    exit 1
fi

# Check for uncommitted changes and auto-commit if any
if ! git diff-index --quiet HEAD --; then
    info "Found uncommitted changes. Auto-committing..."

    # Add all modified/deleted files (not new untracked files)
    git add -u

    # Commit with sign-off
    git commit -s -m "$COMMIT_MESSAGE"

    info "Changes committed: $COMMIT_MESSAGE"
fi

# Get upstream repo info
if ! UPSTREAM_URL=$(git remote get-url upstream 2>/dev/null); then
    error "No upstream remote found. Please run 01-fork-and-setup.sh first."
    exit 1
fi

# Extract owner/repo from upstream URL
UPSTREAM_REPO=$(echo "$UPSTREAM_URL" | sed -E 's|.*github\.com[:/](.*)\.git|\1|' | sed 's|\.git$||')
info "Upstream repository: $UPSTREAM_REPO"

# Get origin repo info and extract username
ORIGIN_URL=$(git remote get-url origin)
ORIGIN_REPO=$(echo "$ORIGIN_URL" | sed -E 's|.*github\.com[:/](.*)\.git|\1|' | sed 's|\.git$||')
ORIGIN_USER=$(echo "$ORIGIN_REPO" | cut -d'/' -f1)
info "Origin repository: $ORIGIN_REPO"
info "Origin user: $ORIGIN_USER"

# Push current branch to origin
info "Pushing current branch to origin..."
if git push -u origin "$CURRENT_BRANCH" 2>&1 | grep -q "Everything up-to-date"; then
    info "Branch already up-to-date on origin"
else
    info "Branch pushed to origin"
fi

# Check if PR already exists
info "Checking if PR already exists..."
EXISTING_PR=$(gh pr list --repo "$UPSTREAM_REPO" --head "$ORIGIN_USER:$CURRENT_BRANCH" --json number,title,url --jq '.[0]')

if [ -n "$EXISTING_PR" ] && [ "$EXISTING_PR" != "null" ]; then
    PR_NUMBER=$(echo "$EXISTING_PR" | jq -r '.number')
    PR_URL=$(echo "$EXISTING_PR" | jq -r '.url')
    EXISTING_TITLE=$(echo "$EXISTING_PR" | jq -r '.title')

    warn "PR already exists!"
    info "  PR #$PR_NUMBER: $EXISTING_TITLE"
    info "  URL: $PR_URL"
    info ""
    info "Would you like to update the existing PR or create a new one?"
    exit 0
fi

# Create PR
info "Creating PR to upstream..."
if [ -n "$PR_BODY" ]; then
    PR_URL=$(gh pr create --repo "$UPSTREAM_REPO" --base "$BASE_BRANCH" --head "$ORIGIN_USER:$CURRENT_BRANCH" --title "$PR_TITLE" --body "$PR_BODY")
else
    # Use interactive editor if no body provided
    PR_URL=$(gh pr create --repo "$UPSTREAM_REPO" --base "$BASE_BRANCH" --head "$ORIGIN_USER:$CURRENT_BRANCH" --title "$PR_TITLE")
fi

if [ $? -eq 0 ]; then
    info "✅ PR created successfully!"
    info "  URL: $PR_URL"
else
    error "Failed to create PR"
    exit 1
fi
