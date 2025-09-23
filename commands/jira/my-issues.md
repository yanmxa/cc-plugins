---
argument-hint: "[time-span] (default: 7d) - Time span for issue filtering (e.g., 7d, 14d, 30d)"
description: List and categorize your assigned Jira issues from a specified time period with beautiful formatting
allowed-tools: [Bash]
---

List and categorize your assigned Jira issues from a specified time period with beautiful formatting organized by type and status using the Jira CLI directly.

## Implementation Steps

1. **Execute Single Command**: Run `jira issue list --assignee $(jira me) --updated "-${1:-7d}" --plain`
2. **Categorize and Format**: Based on the result, categorize by issue type and status, then format with the specific output format shown below

## Output Format

```text
# 📋 Your Jira Issues - Last X Days

## 📖 Stories `N issues`
✅ ACM-XXXX - Issue summary `Closed`
🔄 ACM-XXXX - Issue summary `In Progress`
👀 ACM-XXXX - Issue summary `Review`
🆕 ACM-XXXX - Issue summary `New`

## 🐛 Bugs `N issues`
[Similar format]

## 📊 Summary
- Total Issues: N
- By Type: Stories X% • Bugs Y%
- By State: ✅ Closed X% • 🔄 In Progress Y% • 👀 Review Z% • 🆕 New W%
```

## Status Indicators

- ✅ `Closed` - Completed issues
- 🔄 `In Progress` - Active work
- 👀 `Review` - Under review
- 🆕 `New` - Newly created
- ⏸️ `Other` - Any other status

## Notes

- Default time span is 7 days if not specified
- Only shows issue types that have assigned issues
- Percentages are rounded to nearest whole number