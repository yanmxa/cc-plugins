---
name: my-prs
description: Display GitHub pull requests across all repositories with status indicators and clickable links. Use when user asks to "show my PRs", "list my pull requests", "open my PRs", or wants to see their GitHub contributions.
allowed-tools: [Bash]
---

# My Pull Requests Viewer

Display all open pull requests authored by the current user across all repositories, grouped by repository with status indicators and clickable links.

## When to Use This Skill

- User asks to see their pull requests
- User wants to check PR status across repositories
- User needs clickable links to PRs
- User mentions "my PRs", "pull requests", "open PRs"
- User asks for PRs requiring their review ("show PRs to review", "PRs requiring review", "what needs my review")

## Instructions

1. **Execute the PR Display Script**: Run the `show-prs.sh` script located in the skill's scripts directory:

   **For your own PRs:**
   ```bash
   bash $CLAUDE_CURRENT_PLUGIN_DIR/skills/my-prs/scripts/show-prs.sh
   ```

   **For PRs requiring your review:**
   ```bash
   bash $CLAUDE_CURRENT_PLUGIN_DIR/skills/my-prs/scripts/show-prs.sh --require-review
   ```

   The script automatically:
   - Fetches open PRs (either authored by you or requiring your review based on the flag)
   - Groups them by repository
   - Formats each PR with appropriate status indicators
   - Displays clickable URLs for each PR with author info (for review requests)
   - Shows a legend explaining the status indicators

## Output Format

```
**Your Open PRs:**

**repo-owner/repo-name:**
 👀 #123 - PR title (→ target-branch)
  https://github.com/repo-owner/repo-name/pull/123

 ✅ #456 - Another PR title (→ main)
  https://github.com/repo-owner/repo-name/pull/456

**another-org/another-repo:**
 ⚠️ #789 - PR with changes requested (→ main)
  https://github.com/another-org/another-repo/pull/789

**Legend:**
- 👀 Needs review
- ✅ Approved
- ⚠️ Changes requested
- 🚧 Draft
```

## Example Commands

### Get all PRs across repositories
```bash
gh search prs --author "@me" --state=open --limit 100
```

### Get detailed PR info for a specific repo
```bash
gh pr list --repo stolostron/multicluster-global-hub \
  --author "@me" --state open \
  --json number,title,url,baseRefName,reviewDecision,isDraft | \
  jq -r '.[] | (if .isDraft then " 🚧" elif .reviewDecision == "APPROVED" then " ✅" elif .reviewDecision == "CHANGES_REQUESTED" then " ⚠️" else " 👀" end) + " #\(.number) - \(.title) (→ \(.baseRefName))\n  \(.url)"'
```

## Status Indicators

- **🚧 Draft**: PR is still in draft mode
- **✅ Approved**: PR has been approved and ready to merge
- **⚠️ Changes Requested**: Reviewers requested changes
- **👀 Needs Review**: PR is waiting for review

## Best Practices

- Always show repository name as a grouping header
- Include target branch (→ branch-name) for context
- Provide clickable URLs for easy navigation
- Keep output concise but informative
- Handle cases where user has no open PRs gracefully

## Tool Usage

This skill uses `gh` (GitHub CLI) with:
- `gh search prs` - Find PRs across all repositories
- `gh pr list` - Get detailed PR information per repository
- `jq` - Format JSON output into readable text

## Notes

- Requires GitHub CLI (`gh`) to be installed and authenticated
- Limit set to 100 PRs to avoid overwhelming output
- Only shows open PRs (not closed or merged)
- Groups by repository for better organization
