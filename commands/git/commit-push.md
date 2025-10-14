---
argument-hint: "[--no-push] or leave empty to commit and push"
description: "Commit changes with sign-off and push to origin by default"
allowed-tools: [Bash]
---

Commit staged and unstaged changes with proper sign-off, and push to origin branch by default.

## Implementation Steps

1. **Check Repository Status**: Run `git status` and `git diff` to review changes that will be committed
2. **Stage and Commit Changes**: Add relevant files and create signed commit with concise descriptive message
3. **Push to Origin** (unless --no-push specified): Push committed changes to the current origin branch

## Usage Examples

- `/git:commit-push` - Commit with sign-off and push to origin (default)
- `/git:commit-push --no-push` - Commit with sign-off only, skip push

## Implementation Details

The command will:

- Analyze changes with `git status` and `git diff`
- Stage relevant modified and new files (avoiding unnecessary config files)
- Create commit using HEREDOC format with `-s` flag for sign-off
- Use conventional commit format (fix:, feat:, etc.) based on change content
- Push to origin by default unless `--no-push` parameter is provided

## Commit Message Format

Use this format with HEREDOC to ensure proper formatting:

```bash
git add <files> && git commit -s -m "$(cat <<'EOF'
<type>: <concise summary in imperative mood>

<optional detailed explanation of what changed and why>

Signed-off-by: <Your Name> <your.email@example.com>
EOF
)"
```

### Commit Types

- `fix:` - Bug fixes
- `feat:` - New features
- `refactor:` - Code refactoring
- `docs:` - Documentation changes
- `test:` - Test additions/modifications
- `chore:` - Maintenance tasks

## Notes

- Write concise commit messages based on actual changes, not repository style
- Always includes explicit `Signed-off-by:` line in commit message
- Avoids staging unnecessary files like configuration files
- Verifies commit success before push (unless disabled with --no-push)
- Respects current branch for push operations
- Uses HEREDOC format to ensure multi-line messages are properly formatted
