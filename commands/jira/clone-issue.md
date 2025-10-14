---
argument-hint: <source-issue-key> <new-summary> [description] [--active] [--story-points N]
description: Clone a Jira issue with new summary and description, optionally assign to active sprint
allowed-tools: [Bash]
---

Clone a Jira issue and update its title and description. Optionally use `--active` flag to assign the cloned issue to the current active sprint and move it to "In Progress" status. Use `--story-points N` to set story points.

## Implementation Steps

1. **Clone Issue**: Clone the source issue with the new summary using `jira issue clone $1 -s "$2"`

2. **Update Description**: If description is provided (arguments between summary and flags), pipe it to update the cloned issue using `echo "$description" | jira issue edit <NEW-KEY> --no-input`

3. **Assign to Current User**: Set the assignee to the default user (current user) using `jira issue assign <NEW-KEY> default`

4. **Set Story Points** (if `--story-points N` provided):
   - Attempt to set story points using `jira issue edit <NEW-KEY> --custom "customfield_12310243=N" --no-input`
   - If this fails (field not configured), remind user to set manually

5. **Optional Active Sprint Assignment** (if `--active` flag present):
   - Get current active sprint ID: `jira sprint list --state active --plain --columns "ID,NAME,STATE"`
   - Add issue to sprint: `jira sprint add <SPRINT-ID> <NEW-KEY>`
   - Move to In Progress: `jira issue move <NEW-KEY> "In Progress"`

6. **Reminder**: Only display story points reminder if `--story-points` was NOT provided in the arguments

## Output Format

```
✅ Issue cloned successfully: ACM-XXXXX
   Summary: <new-summary>
   Status: <New|In Progress>
   Assignee: <your-name>
   Sprint: <sprint-name if --active>
   Story Points: <N if set>

⚠️  Remember to set story points in Jira web interface (only shown if not provided)
   https://issues.redhat.com/browse/ACM-XXXXX
```

## Notes

- The `--active` flag can be placed anywhere after the summary
- The `--story-points N` flag can be placed anywhere in the arguments
- Description is optional and should be placed after summary but before flags
- Story points reminder only appears when `--story-points` is not specified
- The cloned issue will always be assigned to the current user by default
- Use this command when you need to create a similar issue with different details

## Examples

```bash
# Basic clone with new summary (will remind about story points)
/jira:clone-issue ACM-25088 "Fix database constraint error"

# Clone with story points (no reminder)
/jira:clone-issue ACM-25088 "Fix ON CONFLICT error" --story-points 3

# Clone with description and story points, assign to active sprint
/jira:clone-issue ACM-25088 "Fix duplicate key error" "The error occurs when inserting duplicate policy events..." --story-points 3 --active

# Clone and assign to active sprint without story points (will remind)
/jira:clone-issue ACM-25088 "Fix policy handler error" --active
```
