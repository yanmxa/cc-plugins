# Link Jira Issue and PR

Workflow to cross-link Jira issues with GitHub pull requests by adding the PR link to the Jira issue comment and the Jira link to the PR description.

## Context:
$ARGUMENTS should contain a Jira issue key and GitHub PR URL in flexible format (e.g., "ACM-23839 https://github.com/stolostron/rhacm-docs/pull/8218")

## Steps:

1. **Check for existing PR field in Jira**: Use the jira-administrator agent to check if the Jira issue has a dedicated pull request field/column
2. **Add PR link to Jira issue**: 
   - If PR field exists: Append the GitHub PR link to the existing pull request field/column
   - If PR field doesn't exist: Add a comment to the Jira issue containing the GitHub PR link
3. **Get current PR description**: Use `gh pr view` to fetch the current PR description and title from the GitHub PR
4. **Update PR description with Jira link**: Use `gh pr edit` to add a "Related Jira Issue" section to the PR description with the Jira issue link

## Target:
- Creates bidirectional linking between Jira issues and GitHub PRs for better traceability
- Takes Jira issue key and PR URL from $ARGUMENTS for flexible usage

## Notes:
- Requires GitHub CLI (`gh`) to be authenticated and configured
- Uses the jira-administrator agent which has access to Jira CLI tools
- Preserves existing PR description content while adding the Jira reference
- Extracts PR number from GitHub URL for gh CLI commands
- Intelligently handles PR linking based on Jira field availability (field update vs comment)