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
5. **Verify and update Jira issue status**:
   - Check if the issue status is "New"
   - If status is "New", transition it to "In Progress" using `jira issue move`
6. **Check and assign sprint**:
   - Check if the issue is assigned to any sprint
   - If no sprint is assigned, get the current active sprint using `jira sprint list --table` and find the sprint with "active" state
   - Assign the issue to the active sprint using `jira sprint add <sprint-id> <issue-key>`
7. **Verify and set story points**:
   - Check if the issue has story points assigned
   - If story points are not set and user hasn't specified them in the arguments, ask the user for story points
   - Update the issue with story points using `jira issue edit <issue-key> --no-input --custom story-points=<value>`

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