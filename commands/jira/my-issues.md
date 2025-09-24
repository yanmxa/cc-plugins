---
argument-hint: "[time-span] [assignee] (default: active sprint, $(jira me)) - Time span for issue filtering (e.g., 7d, 14d, 30d) and assignee. If no time span specified, shows current active sprint issues"
description: List and categorize your assigned Jira issues from a specified time period with beautiful formatting
allowed-tools: [Bash]
---

List and categorize your assigned Jira issues from a specified time period with beautiful formatting organized by type and status using the Jira CLI directly.

## Implementation Steps

1. **Execute Command**:
   - If no time span provided: Run `jira sprint list --current --assignee ${2:-$(jira me)} --order-by rank --reverse`
   - If time span provided: Run `jira issue list --assignee ${2:-$(jira me)} --updated "-$1" --plain --columns "TYPE,KEY,SUMMARY,STATUS,PRIORITY"`
2. **Check for Sprint Info**:
   - If sprint information is available in the output (shows sprint name/dates), include it in the header
   - If no sprint info is available, use generic header "Your Current Sprint Issues"
3. **Categorize and Format**:
   - For current sprint: Organize by status first, then categorize by type within each status
   - For time-based queries: Categorize by issue type and status, then format with the output format shown below

## Output Format

### For Current Sprint (no time span specified)
```text
# 📋 Your Current Sprint Issues [- Sprint #{number} {name} ({dates}) if available]

## 🆕 New `N issues`
   📖 ACM-XXXX - Story summary `🔴 Critical`
   🐛 ACM-XXXX - Bug summary `🟠 Major`

## 🔄 In Progress `N issues`
   📖 ACM-XXXX - Story summary `🔴 Critical`
   🐛 ACM-XXXX - Bug summary `🟠 Major`

## 👀 Review `N issues`
   📖 ACM-XXXX - Story summary `🔴 Critical`
   🐛 ACM-XXXX - Bug summary `🟠 Major`

## 🧪 Testing `N issues`
   📖 ACM-XXXX - Story summary `🔴 Critical`
   🐛 ACM-XXXX - Bug summary `🟠 Major`

## ✅ Resolved `N issues`
   📖 ACM-XXXX - Story summary `🔴 Critical`
   🐛 ACM-XXXX - Bug summary `🟠 Major`

## 🔒 Closed `N issues`
   📖 ACM-XXXX - Story summary `🔴 Critical`
   🐛 ACM-XXXX - Bug summary `🟠 Major`

## 📊 Summary
   • Total Issues: N
   • By Status: 🆕 New X% • 🔄 In Progress Y% • 👀 Review Z% • 🧪 Testing A% • ✅ Resolved B% • 🔒 Closed C%
   • By Type: 📖 Stories X% • 🐛 Bugs Y%
   • By Priority: 🔴 Critical X% • 🟠 Major Y% • 🔵 Normal Z% • ⚪ Undefined A%
```

### For Time-Based Queries (when time span specified)
```text
# 📋 Your Jira Issues - Last X Days

## 📖 Stories `N issues`
   🔒 ACM-XXXX - Issue summary `Closed` `🔴 Critical`
   ✅ ACM-XXXX - Issue summary `Resolved` `🟠 Major`
   🧪 ACM-XXXX - Issue summary `Testing` `🔵 Normal`
   👀 ACM-XXXX - Issue summary `Review` `🔴 Critical`
   🔄 ACM-XXXX - Issue summary `In Progress` `🟠 Major`
   🆕 ACM-XXXX - Issue summary `New` `🔵 Normal`

## 🐛 Bugs `N issues`
   🔒 ACM-XXXX - Bug summary `Closed` `🔴 Critical`
   ✅ ACM-XXXX - Bug summary `Resolved` `🟠 Major`
   🧪 ACM-XXXX - Bug summary `Testing` `🔵 Normal`
   👀 ACM-XXXX - Bug summary `Review` `🔴 Critical`
   🔄 ACM-XXXX - Bug summary `In Progress` `🟠 Major`
   🆕 ACM-XXXX - Bug summary `New` `🔵 Normal`

## 📊 Summary
   • Total Issues: N
   • By Type: 📖 Stories X% • 🐛 Bugs Y%
   • By State: 🆕 New X% • 🔄 In Progress Y% • 👀 Review Z% • 🧪 Testing A% • ✅ Resolved B% • 🔒 Closed C%
   • By Priority: 🔴 Critical X% • 🟠 Major Y% • 🔵 Normal Z% • ⚪ Undefined A%
```

## Status Indicators

- 🆕 `New` - Newly created issues
- 🔄 `In Progress` - Active work
- 👀 `Review` - Under review
- 🧪 `Testing` - Being tested
- ✅ `Resolved` - Resolved issues
- 🔒 `Closed` - Completed issues
- ⏸️ `Other` - Any other status

## Priority Indicators

- 🔴 `Critical` - Highest priority issues
- 🟠 `Major` - High priority issues
- 🔵 `Normal` - Standard priority issues
- 🟢 `Minor` - Low priority issues
- ⚪ `Undefined` - No priority set

## Notes

- If no time span is specified, shows current active sprint issues by default
- When time span is provided (e.g., 7d, 14d, 30d), shows issues updated within that period
- Assignee defaults to $(jira me) but can be specified as second parameter
- Only shows issue types that have assigned issues
- Percentages are rounded to nearest whole number
- Sprint information (name, number, dates) is included in header if available from the Jira command output
- If sprint info is not available in the output, uses generic "Your Current Sprint Issues" header