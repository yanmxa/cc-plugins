---
name: git
description: Git workflow automation - commit/push with sign-off, create/list/compact/rebase PRs, and contribute to upstream repos. Use this skill whenever the user mentions PR, pull request, create PR, show my PRs, list PRs, squash commits, compact commits, rebase PR, commit and push, push updates, push changes, contribute to a repo, fork and submit, or wants to manage any aspect of Git operations.
allowed-tools: [Bash, Read, Write, Edit, Glob, Grep]
---

# Git

Git workflow automation: commit/push and full PR lifecycle. Scripts are at `${CLAUDE_SKILL_DIR}/scripts/`.

## Push

Commit changes with DCO sign-off and push to origin.

1. **Review** changes: `git status`, `git diff --stat`, `git log --oneline -5`
2. **Stage** specific modified files (prefer targeted adds over `git add -A`)
3. **Commit with sign-off** using conventional commit format:
   ```bash
   git commit -s -m "$(cat <<'EOF'
   type: descriptive title

   Detailed description of changes.

   Co-Authored-By: Claude <noreply@anthropic.com>
   EOF
   )"
   ```
4. **Push to origin**: `git push origin $(git branch --show-current)`
5. **Verify**: `git status`

Conventional types: **feat**, **fix**, **docs**, **refactor**, **test**, **chore**

---

## Create PR

Fork repos, create branches, commit changes, and submit PRs. Idempotent and safe to re-run.

```bash
# 1. Fork, clone, and create branch
bash ${CLAUDE_SKILL_DIR}/scripts/01-fork-and-setup.sh \
  owner/repo ~/code 1 main my-feature

# 2. Make your changes (use Edit tool)...

# 3. Auto-commit and create PR
bash ${CLAUDE_SKILL_DIR}/scripts/03-create-pr.sh \
  main "PR title" "PR description"
```

**`01-fork-and-setup.sh <repo> [work_dir] [depth] [base_branch] [feature_branch]`**
- Creates fork if needed (detects existing forks, even with different names)
- Clones repo or uses existing local copy
- Sets up `upstream` and `origin` remotes, creates feature branch

**`03-create-pr.sh <base_branch> <pr_title> [pr_body] [commit_message]`**
- Auto-commits with DCO sign-off, pushes to fork
- Checks for existing PRs (avoids duplicates), returns PR URL

**Current directory mode** — use `.` as work_dir:
```bash
bash ${CLAUDE_SKILL_DIR}/scripts/01-fork-and-setup.sh owner/repo . "" main fix/issue-123
bash ${CLAUDE_SKILL_DIR}/scripts/03-create-pr.sh main "Fix issue #123"
```

---

## List PRs

```bash
# Your open PRs
bash ${CLAUDE_SKILL_DIR}/scripts/show-prs.sh

# PRs requiring your review
bash ${CLAUDE_SKILL_DIR}/scripts/show-prs.sh --require-review
```

Status: **🚧 Draft** | **✅ Approved** | **⚠️ Changes Requested** | **👀 Needs Review**

---

## Compact Commits

Squash all commits in a PR into a single commit with DCO sign-off.

```bash
gh pr view $PR_NUMBER --json commits,title,body
gh pr checkout $PR_NUMBER
N=$(gh pr view $PR_NUMBER --json commits --jq '.commits | length')
git reset --soft HEAD~$N
git commit --signoff -m "Comprehensive commit message"
git push --force-with-lease
```

---

## Rebase PR

Rebase a PR (or all open PRs) against target base branch and force push.

**Single PR:**
```bash
gh pr view $PR_NUMBER --json baseRefName,isCrossRepository
gh pr checkout $PR_NUMBER
git fetch $REMOTE
git rebase $REMOTE/$BASE_BRANCH
git push --force-with-lease
```

**Batch mode** — rebase all open PRs:
```bash
gh pr list --author "@me" --state open \
  --json number,headRefName,baseRefName,isCrossRepository
```
For each PR: determine remote (upstream for forks, origin for same-repo), rebase, resolve conflicts, force push.

| Condition | Default Remote |
|-----------|---------------|
| Fork PR (`isCrossRepository: true`) | `upstream` |
| Same-repo PR | `origin` |

---

## Notes

- Requires `gh` CLI installed and authenticated, Git configured with name/email, SSH keys for GitHub
- All commits include DCO sign-off (`-s` flag)
- Uses `--force-with-lease` for safe force pushing
- Idempotent — safe to re-run without duplicating work
- Smart fork detection handles renamed forks
