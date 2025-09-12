# Create PR to $ARGUMENTS

Create a pull request following Git best practices:

## Steps:

1. **Sync & Branch**: Update main + create feature branch with appropriate prefix
2. **Commit**: Stage relevant files + commit with conventional message and sign-off
3. **Push & PR**: Push branch + create ready PR with detailed description

## Target:
- If $ARGUMENTS provided: use as target repo/branch
- If empty: default to upstream/main

## Commands to execute:

```bash
# Set target
TARGET=${ARGUMENTS:-upstream/main}

# 1. Sync & Branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
    # Sync with upstream first
    git fetch origin
    git pull origin main
    
    # Create feature branch with prefix
    # Choose: feature/, fix/, docs/, chore/, refactor/, test/
    git checkout -b feature/descriptive-name
fi

# 2. Stage & Commit with conventional format
git add path/to/relevant/files
git commit -m "feat: descriptive title

Detailed description of what and why this change is made.

- List specific changes
- Reference issue numbers if applicable

Signed-off-by: Meng Yan <myan@redhat.com>"

# 3. Push & Create PR
git push -u origin $(git branch --show-current)
gh pr create --base ${TARGET#*/} --title "Title" --body "$(cat <<'EOF'
## Summary
Brief description of the change and its purpose

## Changes
- Specific change 1
- Specific change 2  
- Reference any related issues

## Test plan
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Documentation updated if needed

## Checklist
- [ ] Code follows project conventions
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Breaking changes documented

🤖 Generated with [Claude Code](https://claude.ai/code)
EOF
)"
```

## Conventional Commit Types:
- **feat**: New features
- **fix**: Bug fixes
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **test**: Adding/updating tests
- **chore**: Maintenance tasks