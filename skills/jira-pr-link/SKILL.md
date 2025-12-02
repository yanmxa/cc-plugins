---
name: jira-pr-link
description: Cross-link Jira issues with GitHub pull requests by adding PR links to Jira comments and Jira links to PR descriptions. Automatically manages issue status transitions (New→In Progress), sprint assignment, and story points. Use when linking PRs to Jira issues, connecting GitHub work to Jira tracking, or automating Jira-GitHub workflow integration.
allowed-tools: [Bash]
---

# Jira-PR Link Skill

Automate the complete workflow of linking Jira issues with GitHub pull requests, including bidirectional linking, status management, sprint assignment, and story points configuration.

## When to Use This Skill

- User asks to "link PR to Jira issue" or "link Jira issue to PR"
- User mentions "connect Jira and GitHub PR"
- User wants to "update Jira with PR link"
- User requests "add PR to Jira" or "add Jira to PR"
- Automating Jira-GitHub integration workflows
- After creating a PR that fixes a Jira issue

## Core Functionality

This skill provides automated cross-linking between Jira and GitHub:

1. **Bidirectional Linking**:
   - Adds Jira issue link to GitHub PR description
   - Adds PR link to Jira issue comments

2. **Status Management**:
   - Transitions issues from "New" to "In Progress" when PR is linked

3. **Sprint Assignment**:
   - Automatically adds issue to current active sprint if not assigned

4. **Story Points**:
   - Sets story points if provided

## Instructions

### Step 1: Validate Inputs

Ensure you have:
- **Jira Issue Key** (e.g., ACM-27001)
- **GitHub PR URL** (e.g., https://github.com/stolostron/multicluster-global-hub/pull/2133)
- **Story Points** (optional, e.g., 3)

### Step 2: Execute the Script

Run the jira-pr-link script from the skill's scripts directory:

```bash
~/.claude/skills/jira-pr-link/scripts/jira-pr-link.sh <ISSUE_KEY> <PR_URL> [STORY_POINTS]
```

**Examples**:
```bash
# Link without story points
~/.claude/skills/jira-pr-link/scripts/jira-pr-link.sh ACM-27001 https://github.com/stolostron/multicluster-global-hub/pull/2133

# Link with story points
~/.claude/skills/jira-pr-link/scripts/jira-pr-link.sh ACM-27001 https://github.com/stolostron/multicluster-global-hub/pull/2133 3
```

### Step 3: Parse and Report Results

The script performs the following operations automatically:

1. ✅ **Gathers Information**:
   - Fetches Jira issue details (status, story points)
   - Fetches GitHub PR details (title, body)

2. ✅ **Updates GitHub PR**:
   - Checks if Jira link already exists in PR description
   - Prepends Jira issue link to PR body if not present

3. ✅ **Updates Jira Issue**:
   - Checks if PR link already exists in Jira comments
   - Adds PR link as comment if not present

4. ✅ **Manages Status**:
   - Transitions issue from "New" to "In Progress" if needed
   - Skips if issue is already in progress or later state

5. ✅ **Assigns to Sprint**:
   - Finds current active sprint
   - Adds issue to sprint if not already assigned

6. ✅ **Sets Story Points**:
   - Sets story points if provided as third argument
   - Skips if story points already set

### Step 4: Provide User Feedback

Report the results to the user with:
- ✅ Success message with issue key and PR number
- 🔗 Links to both Jira issue and GitHub PR
- Summary of actions taken (what was updated, skipped, or failed)

## Output Format

The script provides emoji-annotated output:
- 🔗 Linking operation started
- 📥 Gathering information
- ✓ Successful operations
- ℹ️ Informational messages (already exists, skipped)
- ⚠️ Warnings (failures that don't stop execution)
- ❌ Errors (fatal failures)

## Error Handling

The script includes built-in error handling:
- Validates PR URL format
- Checks if Jira issue exists
- Checks if GitHub PR exists
- Gracefully handles failures (warns but continues)
- Prevents duplicate operations (checks before adding)

## Examples

### Example 1: Basic PR-Jira Linking
```bash
~/.claude/skills/jira-pr-link/scripts/jira-pr-link.sh ACM-27001 https://github.com/stolostron/multicluster-global-hub/pull/2133
```

**What happens**:
- Links created between ACM-27001 and PR #2133
- Issue transitioned to "In Progress" if it was "New"
- Issue added to active sprint if not assigned
- Warning shown that story points are not set

### Example 2: PR-Jira Linking with Story Points
```bash
~/.claude/skills/jira-pr-link/scripts/jira-pr-link.sh ACM-26966 https://github.com/stolostron/multicluster-global-hub/pull/2133 3
```

**What happens**:
- Same as Example 1, plus:
- Story points set to 3

### Example 3: Re-running (Idempotent)
```bash
~/.claude/skills/jira-pr-link/scripts/jira-pr-link.sh ACM-27001 https://github.com/stolostron/multicluster-global-hub/pull/2133 3
```

**What happens** (if already linked):
- ℹ️ Skips PR description update (already exists)
- ℹ️ Skips Jira comment (already exists)
- ℹ️ Skips status transition (already in progress)
- ℹ️ Skips sprint assignment (already assigned)
- ℹ️ Skips story points (already set)

## Best Practices

1. **Always Provide Story Points**: Include story points when linking to avoid manual updates later
2. **Run Early**: Link PRs as soon as they're created for better tracking
3. **Idempotent**: Safe to re-run; script checks before making changes
4. **Verify Links**: Check both Jira and GitHub to confirm linking succeeded

## Requirements

- **GitHub CLI (`gh`)**: Must be authenticated and configured
- **Jira CLI (`jira`)**: Must be authenticated and configured
- **Permissions**: Write access to GitHub repository and Jira project

## Common Issues

### Issue: "Failed to fetch Jira issue"
**Solution**: Verify issue key exists and you have access

### Issue: "Failed to fetch PR"
**Solution**: Verify PR number and repository are correct

### Issue: "Failed to transition issue status"
**Solution**: Check Jira workflow allows New→In Progress transition

### Issue: "Failed to add issue to sprint"
**Solution**: Verify active sprint exists and you have permission

## Integration with Other Workflows

This skill integrates well with:
- Git workflow automation (create PR → link Jira)
- Release management (track PR completion in Jira)
- Sprint planning (auto-assign linked issues to sprint)
- Story point estimation (set points during PR creation)

## Notes

- Script validates PR URL format before proceeding
- All operations are logged with clear status messages
- Warnings don't stop execution; script continues with remaining steps
- Links are added only if they don't already exist (prevents duplicates)
- Self-contained: Script is bundled within skill directory
