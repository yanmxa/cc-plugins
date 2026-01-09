---
name: create-pr
description: Automate creating pull requests - fork repos, create branches, commit changes, and submit PRs. Works in current directory or creates new clone. Idempotent and safe to re-run. Keywords - create PR, pull request, fork, contribute, upstream.
allowed-tools: [Bash, Read, Write, Edit, Glob, Grep]
---

# Create PR - Pull Request Automation

Automate creating pull requests from start to finish.

## What This Does

1. Fork the repository (if needed)
2. Clone or use existing local repo
3. Create feature branch from upstream
4. Auto-commit your changes
5. Push and create PR

## Quick Start

**Basic workflow:**
```bash
# 1. Fork, clone, and create branch
bash $CLAUDE_PLUGIN_ROOT/skills/create-pr/scripts/01-fork-and-setup.sh \
  owner/repo \
  ~/code \
  1 \
  main \
  my-feature

# 2. Make your changes (use Edit tool)...

# 3. Auto-commit and create PR
bash $CLAUDE_PLUGIN_ROOT/skills/create-pr/scripts/03-create-pr.sh \
  main \
  "PR title" \
  "PR description"
```

**Current directory mode:**
```bash
cd /path/to/your/repo
bash $CLAUDE_PLUGIN_ROOT/skills/create-pr/scripts/01-fork-and-setup.sh owner/repo . "" main my-feature
# Make changes...
bash $CLAUDE_PLUGIN_ROOT/skills/create-pr/scripts/03-create-pr.sh main "Fix bug"
```

## Scripts

### `01-fork-and-setup.sh` - Setup repo and branch

```bash
01-fork-and-setup.sh <repo> [work_dir] [depth] [base_branch] [feature_branch]
```

**Parameters:**
- `repo` - Repository to fork (e.g., `owner/repo`)
- `work_dir` - Where to clone (default: `~/tmp/contribute`, use `.` for current dir)
- `depth` - Clone depth (default: full, use `1` for 10x faster shallow clone)
- `base_branch` - Branch to base work on (e.g., `main`)
- `feature_branch` - Your new branch name (e.g., `fix/bug-123`)

**What it does:**
- Creates fork if needed (detects existing forks, even with different names)
- Clones repo or uses existing local copy
- Sets up `upstream` (original) and `origin` (fork) remotes
- Creates feature branch from latest upstream
- **Idempotent** - Safe to re-run multiple times

### `03-create-pr.sh` - Commit and create PR

```bash
03-create-pr.sh <base_branch> <pr_title> [pr_body] [commit_message]
```

**Parameters:**
- `base_branch` - Target branch for PR (e.g., `main`)
- `pr_title` - PR title
- `pr_body` - PR description (optional)
- `commit_message` - Commit message (optional, defaults to PR title)

**What it does:**
- Auto-commits any uncommitted changes with DCO sign-off
- Pushes branch to your fork
- Checks for existing PRs (avoids duplicates)
- Creates PR to upstream
- Returns PR URL
- **Idempotent** - Won't create duplicate PRs

## Examples

### Example 1: Fix bug in upstream repo

```bash
# User request: "Fix version 2.9 to 2.15 in stolostron/multicluster-global-hub"

# Step 1: Setup
bash $CLAUDE_PLUGIN_ROOT/skills/create-pr/scripts/01-fork-and-setup.sh \
  stolostron/multicluster-global-hub \
  ~/tmp/contribute \
  1 \
  main \
  docs/fix-version

# Step 2: Make changes (using Edit tool to modify files)
# ... Edit files to change 2.9 to 2.15 ...

# Step 3: Create PR
bash $CLAUDE_PLUGIN_ROOT/skills/create-pr/scripts/03-create-pr.sh \
  main \
  "docs: update version from 2.9 to 2.15" \
  "Update documentation links to point to 2.15 instead of 2.9"
```

### Example 2: Work in current directory

```bash
# User is already in a git repo and wants to work there

cd /path/to/existing/repo

bash $CLAUDE_PLUGIN_ROOT/skills/create-pr/scripts/01-fork-and-setup.sh \
  owner/repo \
  . \
  "" \
  main \
  fix/issue-123

# Make changes...

bash $CLAUDE_PLUGIN_ROOT/skills/create-pr/scripts/03-create-pr.sh \
  main \
  "Fix issue #123"
```

### Example 3: Handles fork name mismatches

```bash
# Scenario: Your fork is named "hub-of-hubs" but upstream is "multicluster-global-hub"
# The script automatically detects this and handles it

bash $CLAUDE_PLUGIN_ROOT/skills/create-pr/scripts/01-fork-and-setup.sh \
  stolostron/multicluster-global-hub \
  ~/code \
  1 \
  main \
  fix/bug

# Output: "Found existing fork with different name: yanmxa/hub-of-hubs"
# Script uses the correct fork name automatically
```

## Key Features

✅ **Idempotent** - Safe to re-run, won't duplicate work
✅ **Smart fork detection** - Finds forks even with different names
✅ **Auto-fork** - Creates fork if it doesn't exist
✅ **Auto-commit** - Commits changes with DCO sign-off
✅ **No duplicates** - Checks for existing PRs before creating
✅ **Current dir mode** - Can work in existing repos (use `.` as work_dir)
✅ **Fast clone** - Shallow clone by default (10x faster)
✅ **Proper remotes** - Sets up upstream (HTTPS) and origin (SSH)

## Performance

**Clone speed with depth=1:**
| Repository | Full Clone | Shallow (depth=1) | Speedup |
|------------|------------|-------------------|---------|
| kubernetes | ~3GB | ~300MB | 10x |
| Linux kernel | ~4GB | ~400MB | 10x |
| Typical repo | ~500MB | ~50MB | 10x |

## Prerequisites

- **GitHub CLI (`gh`)** - Must be installed and authenticated
  ```bash
  brew install gh
  gh auth login
  ```

- **Git** - Configured with name and email
  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "your.email@example.com"
  ```

- **SSH Keys** - Setup for GitHub (for cloning via SSH)

## Troubleshooting

**Fork already exists**
→ Script handles automatically, uses existing fork

**Repository already cloned**
→ Script verifies and updates remotes

**PR already exists**
→ Script shows existing PR URL instead of creating duplicate

**Fork has different name**
→ Script detects via GitHub API and uses correct name

**Current directory not a git repo**
→ Don't use `.` as work_dir, or cd to a git repo first

## Notes

- All commits are signed with DCO (`-s` flag)
- Uses `git add -u` (only modified/deleted files, not new untracked files)
- Creates PRs with proper `username:branch` format
- Handles both HTTPS (upstream) and SSH (origin) remotes
- Color-coded output for easy reading
