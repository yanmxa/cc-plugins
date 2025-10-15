# Review PR $ARGUMENTS

```bash
# Show open PRs if no argument
[[ -z "$ARGUMENTS" ]] && gh pr list --state open && exit 0

PR_NUMBER="$ARGUMENTS"
REPO_INFO=$(gh repo view --json owner,name --jq '.owner.login + "/" + .name')
COMMIT_SHA=$(gh api repos/$REPO_INFO/pulls/$PR_NUMBER --jq '.head.sha')

# Quick overview
gh pr view $PR_NUMBER
gh pr checks $PR_NUMBER
gh pr diff $PR_NUMBER
```

## What to Look For

🔒 **Security first**: Auth, input validation, secrets, injection attacks  
🐛 **Logic bugs**: Edge cases, race conditions, error handling  
🏗️ **Code quality**: Patterns, duplication, naming, complexity  
~~ 🧪 **Tests**:  Coverage, meaningful scenarios, integration tests ~~ 
📝 **Docs**: Clear code, comments where needed, breaking changes

## Leave Comments

**For issues (blocking):**
```bash
gh api repos/$REPO_INFO/pulls/$PR_NUMBER/comments --method POST \
    --field body="🔒 Security risk: [issue]. Fix: [solution]" \
    --field commit_id="$COMMIT_SHA" --field path="file.js" --field line=42 --field side="RIGHT"
```

**For suggestions:**
```bash
gh api repos/$REPO_INFO/pulls/$PR_NUMBER/comments --method POST \
    --field body="💡 Consider [improvement] for [benefit]" \
    --field commit_id="$COMMIT_SHA" --field path="file.js" --field line=42 --field side="RIGHT"
```

## Final Decision

```bash
# Block it
gh pr review $PR_NUMBER --request-changes --body "Security/bug issues found"

# Ship it
gh pr review $PR_NUMBER --approve --body "LGTM"
```