# Link Jira Issue and PR

Workflow to cross-link Jira issues with GitHub pull requests by adding the PR link to the Jira issue comment and the Jira link to the PR description.

## Context:
$ARGUMENTS should contain a Jira issue key and GitHub PR URL in flexible format (e.g., "ACM-23839 https://github.com/stolostron/rhacm-docs/pull/8218")

## Steps:

1. **Batch Information Gathering**: Run in parallel using single message with multiple tool calls:
   - `jira issue view <issue-key>` to get current issue status, sprint assignment, and story points
   - `gh pr view <pr-number> --repo <repo>` to get current PR description and details

2. **GitHub PR Operations**:
   - Update PR description with "Related Jira Issue" section using `gh pr edit`
   - Preserve existing PR description content

3. **Jira Issue Operations** (batch these together to minimize interactions):
   - Check if PR link already exists in issue comments; if found, skip adding PR link comment
   - If PR link not found, add PR link comment using `jira issue comment add <issue-key> "Related GitHub PR: <pr-url>" with optional concise PR description
   - If issue status is "New", transition to "In Progress" using `jira issue move`
   - If no sprint assigned, add to current active sprint using `jira sprint add <sprint-id> <issue-key>`
   - If no story points and user provided value in arguments, set using `jira issue edit <issue-key> --no-input --custom story-points=<value>`
   - If no story points and not specified in arguments, ask user once for story points value

## Target:
- Creates bidirectional linking between Jira issues and GitHub PRs for better traceability
- Takes Jira issue key and PR URL from $ARGUMENTS for flexible usage
- Automatically transitions new issues to "In Progress" when PR is linked
- Ensures issues are assigned to the current active sprint for proper project tracking
- Prompts for and sets story points if not already assigned

## Notes:
- Requires GitHub CLI (`gh`) to be authenticated and configured
- Uses the jira-administrator agent which has access to Jira CLI tools
- Preserves existing PR description content while adding the Jira reference
- Extracts PR number from GitHub URL for gh CLI commands
- Intelligently handles PR linking based on Jira field availability (field update vs comment)
- Automatically manages issue lifecycle: status transitions, sprint assignments, and story points
- Uses `jira sprint list --table` to identify the current active sprint by "active" state
- Only updates status from "New" to "In Progress" - preserves other statuses
- Interactive story point assignment when not already set - ensures proper estimation tracking
- Uses `jira issue edit --no-input --custom story-points=<value>` for story point updates