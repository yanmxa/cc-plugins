---
argument-hint: "[sprint-id] (optional, defaults to current active sprint)"
description: List sprint issues grouped by assignee with visual formatting and status categorization
allowed-tools: [Bash]
---

Display all issues in a Jira sprint organized by assignee, with clear status grouping and visual formatting. Closed issues are dimmed for focus on active work.

## Implementation Steps

1. **Get Sprint ID**: If no sprint-id provided, fetch current active sprint ID using `jira sprint list --state active --plain --columns ID,NAME`
2. **Fetch Sprint Issues**: Run `jira sprint list <SPRINT_ID> --plain --columns TYPE,KEY,SUMMARY,STATUS,ASSIGNEE,PRIORITY --no-truncate`
3. **Parse and Group**: Parse the output and group issues by ASSIGNEE
4. **Format Output**: For each assignee, display:
   - Assignee name as section header with issue count
   - Group by status: New, In Progress, Review, Closed
   - Use emojis for issue types: 📋 Task, 🐛 Bug, 📖 Story, 🔬 Spike
   - Use priority indicators: 🔴 Critical, 🟠 Major, 🔵 Normal, ⚪ Minor/Undefined
   - Dim closed issues using `<dim>` tags
   - Add separator `---` between assignees
5. **Display Summary**: Show team statistics:
   - Total issues and team members
   - Distribution by status and priority

## Output Format

```
# 📋 Sprint Name - Grouped by Assignee

## 👤 Assignee Name - N issues
### 🔄 In Progress (N)
   📋 KEY - Summary `🟠 Priority`

### 👀 Review (N)
   🐛 KEY - Summary `🔴 Priority`

### 🔒 Closed (N)
   <dim>📋 KEY - Summary `🔵 Priority`</dim>

---

## 📊 Team Summary
   • Total Issues: N
   • By Status: percentages
   • By Priority: percentages
```

## Usage Examples

- `/jira:sprint-issues` - Show current active sprint issues by assignee
- `/jira:sprint-issues 78998` - Show specific sprint issues by assignee

## Notes

- Closed issues are dimmed to focus on active work
- Status order: New → In Progress → Review → Testing → Resolved → Closed
- Works with any Jira sprint ID
- Requires jira CLI configured and authenticated
