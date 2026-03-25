---
name: pr
description: Full PR lifecycle - create, list, compact commits, and rebase pull requests. Use this skill whenever the user mentions PR, pull request, create PR, show my PRs, list PRs, squash commits, compact commits, rebase PR, contribute to a repo, fork and submit, or wants to manage any aspect of GitHub pull requests.
allowed-tools: [Bash, Read, Write, Edit, Glob, Grep]
---

# PR - Pull Request Lifecycle

Manage the full lifecycle of GitHub pull requests: create, list, compact, and rebase.

Scripts are at `${CLAUDE_SKILL_DIR}/scripts/`.

## Create PR

Fork repos, create branches, commit changes, and submit PRs. Idempotent and safe to re-run.

### Quick Start

```bash
# 1. Fork, clone, and create branch
bash ${CLAUDE_SKILL_DIR}/scripts/01-fork-and-setup.sh \
  owner/repo \
  ~/code \
  1 \
  main \
  my-feature

# 2. Make your changes (use Edit tool)...

# 3. Auto-commit and create PR
bash ${CLAUDE_SKILL_DIR}/scripts/03-create-pr.sh \
  main \
  "PR title" \
  "PR description"
```

### Scripts

**`01-fork-and-setup.sh <repo> [work_dir] [depth] [base_branch] [feature_branch]`**
- Creates fork if needed (detects existing forks, even with different names)
- Clones repo or uses existing local copy
- Sets up `upstream` and `origin` remotes
- Creates feature branch from latest upstream

**`03-create-pr.sh <base_branch> <pr_title> [pr_body] [commit_message]`**
- Auto-commits changes with DCO sign-off
- Pushes branch to fork
- Checks for existing PRs (avoids duplicates)
- Creates PR to upstream, returns PR URL

### Current Directory Mode

```bash
cd /path/to/your/repo
bash ${CLAUDE_SKILL_DIR}/scripts/01-fork-and-setup.sh owner/repo . "" main fix/issue-123
# Make changes...
bash ${CLAUDE_SKILL_DIR}/scripts/03-create-pr.sh main "Fix issue #123"
```

---

## List PRs

Display open pull requests across all repositories with status indicators.

```bash
# Your open PRs
bash ${CLAUDE_SKILL_DIR}/scripts/show-prs.sh

# PRs requiring your review
bash ${CLAUDE_SKILL_DIR}/scripts/show-prs.sh --require-review
```

### Status Indicators

- **🚧 Draft** | **✅ Approved** | **⚠️ Changes Requested** | **👀 Needs Review**

---

## Compact Commits

Squash all commits in a PR into a single commit with comprehensive message and DCO sign-off.

### Steps

1. Get PR details and checkout branch:
   ```bash
   gh pr view $PR_NUMBER --json commits,title,body
   gh pr checkout $PR_NUMBER
   ```

2. Count and compact commits:
   ```bash
   N=$(gh pr view $PR_NUMBER --json commits --jq '.commits | length')
   git reset --soft HEAD~$N
   git commit --signoff -m "Comprehensive commit message"
   ```

3. Force push:
   ```bash
   git push --force-with-lease
   ```

---

## Rebase PR

Rebase a PR (or all open PRs) against their target base branch and force push.

### Single PR

```bash
gh pr view $PR_NUMBER --json baseRefName,isCrossRepository
gh pr checkout $PR_NUMBER
git fetch $REMOTE
git rebase $REMOTE/$BASE_BRANCH
git push --force-with-lease
```

### Batch Mode (all open PRs)

```bash
gh pr list --author "@me" --state open \
  --json number,headRefName,baseRefName,isCrossRepository
```

Process each PR: determine remote (upstream for forks, origin for same-repo), rebase, resolve conflicts if needed, force push.

### Remote Selection

| Condition | Default Remote |
|-----------|---------------|
| Fork PR (`isCrossRepository: true`) | `upstream` |
| Same-repo PR | `origin` |

---

## Notes

- Requires `gh` CLI installed and authenticated, Git configured with name/email, SSH keys for GitHub
- All commits include DCO sign-off (`-s` flag)
- Uses `--force-with-lease` for safe force pushing
- Idempotent - safe to re-run without duplicating work
- Smart fork detection handles renamed forks
