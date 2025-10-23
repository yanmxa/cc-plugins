---
argument-hint: [time-period] (e.g., 7d, 14d, 30d - defaults to 7d)
description: Generate a categorized weekly/periodic status report from Jira issues grouped by features
allowed-tools: [Bash, Write]
---

Generate a comprehensive status report from Jira issues, categorizing them by features and grouping into "Accomplished" and "Work On" sections.

## Implementation Steps

1. **Fetch Jira Issues**: Get issues updated within the specified time period using `jira issue list --assignee $(jira me) --updated "-${1:-7d}"`

2. **Categorize by Status**: Group issues into "Accomplished" (Closed, Resolved, Review status) and "Work On" (In Progress, New, other active statuses)

3. **Group by Features**: Organize issues under feature categories such as:
   - Customer Requirement - Feature: [Feature Name]
   - Global Hub Feature - [Feature Area]
   - Global Hub Maintenance
   - AI/ML Features
   - Long-term Projects

4. **Format Items**: Structure each item as: [Type] Title/Summary `Status` - **[Issue Key with Link]**

5. **Generate Summary**: Calculate completion rates, total issues handled, focus areas, and key achievements

6. **Copy to Clipboard**: Use `pbcopy` to copy the formatted status report to clipboard for easy sharing

## Notes
- Defaults to 7-day period if no argument provided
- Links use Red Hat Jira format: https://issues.redhat.com/browse/[KEY]
- Review status is considered "Accomplished" for completion rate calculation
- Automatically categorizes issues based on summary content and labels
- Perfect for weekly standup reports, sprint reviews, or manager updates