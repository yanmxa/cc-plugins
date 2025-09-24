---
argument-hint: "[--no-push] or leave empty to commit and push"
description: "Commit changes with sign-off and push to origin by default"
allowed-tools: [Bash]
---

Commit staged and unstaged changes with proper sign-off, and push to origin branch by default.

## Implementation Steps

1. **Check Repository Status**: Run git status and git diff to review changes that will be committed
2. **Review Recent Commits**: Check git log to follow existing commit message style
3. **Stage and Commit Changes**: Add relevant files and create signed commit with descriptive message following conventional format
4. **Push to Origin** (unless --no-push specified): Push committed changes to the current origin branch

## Usage Examples

- `/git:commit-push` - Commit with sign-off and push to origin (default)
- `/git:commit-push --no-push` - Commit with sign-off only, skip push

## Implementation Details

The command will:
- Analyze changes with `git status` and `git diff`
- Check recent commits with `git log --oneline -5` for style consistency
- Stage relevant modified and new files (avoiding unnecessary config files)
- Create commit with `-s` flag for sign-off and conventional format
- Push to origin by default unless `--no-push` parameter is provided

## Notes
- Follows conventional commit format with descriptive messages
- Always includes sign-off as per user preferences
- Avoids staging unnecessary files like configuration files
- Verifies commit success before push (unless disabled with --no-push)
- Respects current branch for push operations