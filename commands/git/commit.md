# Git Commit Guide

## Basic Workflow

```bash
# 1. Check status
git status

# 2. Add files selectively (recommended)
git add src/main.go pkg/migration/ README.md
# Or add all: git add .

# 3. Commit with sign-off
git commit -m "fix: improve migration rollback messages

Standardize timeout message formats and fix LastTransitionTime updates." -s

# 4. Push (handle rebase if needed)
git push origin
# If push is rejected due to remote changes:
git pull --rebase && git push
```

## Commit All Modified (alternative)
```bash
git commit -am "fix: improve rollback messages" -s
```

## .gitignore Essentials

```gitignore
# IDE & System
.vscode/ .idea/ .DS_Store *.swp *~

# Go
*.exe *.test *.out /vendor/ /bin/

# Build & Logs  
dist/ build/ *.log .cache/
```

## Commit Message Format

```
<type>: <short description>

<optional details>
```

**Types:** `fix`, `feat`, `refactor`, `test`, `docs`

## Quick Commands

```bash
git status              # Check what changed
git diff --staged       # Review staged changes
git add -i             # Interactive add
git commit --amend -s  # Modify last commit
git commit --amend --signoff # Add sign-off to last commit
git reset HEAD~1       # Undo last commit
git log --oneline      # View history
```

## Push Troubleshooting

```bash
# If push is rejected (non-fast-forward):
git pull --rebase    # Rebase local changes on top of remote
git push            # Push after successful rebase

# Alternative: merge instead of rebase
git pull            # Merge remote changes
git push           # Push merged changes
```

## Best Practices

- Use `.gitignore` to exclude IDE/system files
- Review with `git status` and `git diff` before committing  
- Always sign-off with `-s` or `--signoff`
- Test before committing
- Keep messages concise but clear
- Use `git pull --rebase` to maintain linear history