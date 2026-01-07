---
argument-hint: "[time-span] (default: 7d) - Time span for issue filtering (e.g., 7d, 14d, 30d). If no time span specified, shows last 7 days"
description: List and categorize your assigned Jira issues from a specified time period with beautiful formatting
allowed-tools: [Bash]
---

Execute the jira-my-issues.sh script to list and categorize your assigned Jira issues with beautiful formatting.

## Implementation

Run the script with optional time span parameter (defaults to current user via `jira me`):

```bash
~/.claude/scripts/jira-my-issues.sh "${1:-7d}"
```

The script will:
1. Fetch issues where you (current user) are assignee and reporter
2. Merge and deduplicate results
3. Cross-reference with current sprint issues
4. Output structured data for LLM to format and analyze
5. Display categorized output with status, type, and priority indicators

## Output Format

```text
# 📋 Your Jira Issues - Last X Days

## 🆕 New `N issues`
   📖 ACM-XXXX - Story summary `🔴 Critical` 📌
   📖 ACM-XXXX - Story summary `🟠 Major` 📝
   🐛 ACM-XXXX - Bug summary `🔵 Normal` 📌 👤

## 🔄 In Progress `N issues`
   📖 ACM-XXXX - Story summary `🔴 Critical` 📌
   🐛 ACM-XXXX - Bug summary `🟠 Major` 👤

## 👀 Review `N issues`
   📖 ACM-XXXX - Story summary `🔴 Critical` 📌 📝
   🐛 ACM-XXXX - Bug summary `🟠 Major`

## 🧪 Testing `N issues`
   📖 ACM-XXXX - Story summary `🔴 Critical`
   🐛 ACM-XXXX - Bug summary `🟠 Major` 📌

## ✅ Resolved `N issues`
   📖 ACM-XXXX - Story summary `🔴 Critical` 👤
   🐛 ACM-XXXX - Bug summary `🟠 Major`

## 🔒 Closed `N issues`
   📖 ACM-XXXX - Story summary `🔴 Critical` 📌
   🐛 ACM-XXXX - Bug summary `🟠 Major` 📝

## 📊 Summary
   • Total Issues: N (📌 M in current sprint)
   • By Status: 🆕 New X% • 🔄 In Progress Y% • 👀 Review Z% • 🧪 Testing A% • ✅ Resolved B% • 🔒 Closed C%
   • By Type: 📖 Stories X% • 🐛 Bugs Y% • 📋 Tasks Z%
   • By Priority: 🔴 Critical X% • 🟠 Major Y% • 🔵 Normal Z% • 🟢 Minor A% • ⚪ Undefined B%
```

## Indicators

### Status Indicators
- 🆕 `New` - Newly created issues
- 🔄 `In Progress` - Active work
- 👀 `Review` - Under review
- 🧪 `Testing` - Being tested
- ✅ `Resolved` - Resolved issues
- 🔒 `Closed` - Completed issues
- ⏸️ `Other` - Any other status

### Priority Indicators
- 🔴 `Critical` - Highest priority issues
- 🟠 `Major` - High priority issues
- 🔵 `Normal` - Standard priority issues
- 🟢 `Minor` - Low priority issues
- ⚪ `Undefined` - No priority set

### Sprint Indicator
- 📌 - Issue is in the current active sprint (shown after priority)

### Role Indicators
- 📝 - Reporter only (you created this issue but it's assigned to someone else)
- 👤 - Assignee only (assigned to you but created by someone else)
- (no indicator) - Both reporter and assignee (you created and own this issue)

## Notes

- Default time span is 7 days if not specified
- When time span is provided (e.g., 7d, 14d, 30d), shows issues updated within that period
- Includes both issues assigned to you AND issues created/reported by you
- User is automatically determined via `jira me` (no need to specify assignee)
- Duplicates are automatically removed if an issue appears in both assignee and reporter lists
- Only shows issue types that have assigned issues
- Percentages are rounded to nearest whole number
- Issues in the current active sprint are marked with 📌 indicator
- All your issues are shown regardless of sprint assignment
- Script outputs structured data, formatting is handled by LLM