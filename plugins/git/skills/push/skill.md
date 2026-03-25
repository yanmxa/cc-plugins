---
name: push
description: Commit changes with DCO sign-off and push to origin. Use this skill when the user says "commit and push", "push updates", "push changes", "save my work", "upload changes", or wants to commit with sign-off and push to the remote branch.
argument-hint: "[--no-push] or leave empty to commit and push"
allowed-tools: [Bash]
---

# Push

Commit staged and unstaged changes with proper sign-off, and push to origin branch by default.

## Steps

1. **Review changes** to understand what will be committed:
   ```bash
   git status
   git diff --stat
   git log --oneline -5
   ```

2. **Stage changes** — add specific modified files (prefer targeted adds over `git add -A`):
   ```bash
   git add path/to/modified/files
   ```

3. **Commit with sign-off** using conventional commit format:
   ```bash
   git commit -s -m "$(cat <<'EOF'
   type: descriptive title

   Detailed description of changes.

   Co-Authored-By: Claude <noreply@anthropic.com>
   EOF
   )"
   ```

4. **Push to origin** (skip if `--no-push` is in `$ARGUMENTS`):
   ```bash
   git push origin $(git branch --show-current)
   ```

5. **Verify** with `git status`.

## Conventional Commit Types

- **feat**: New features
- **fix**: Bug fixes
- **docs**: Documentation changes
- **refactor**: Code refactoring
- **test**: Adding/updating tests
- **chore**: Maintenance tasks
