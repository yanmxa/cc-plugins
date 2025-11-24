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

5. **Generate Short Summary**: Create a concise 2-3 sentence summary highlighting:
   - What was accomplished this week
   - Current ongoing focus areas (1-2 main themes)
   - **Emphasize AI-related work with bold formatting**
   - Format: "**Accomplished:** [brief accomplishments]. **Ongoing focus:** (1) **AI-powered [description]** - [details]; (2) [other focus]."

6. **Generate Simplified Summary Metrics**:
   - **Key Metrics** (single line): Total | Completion % | Distribution counts
   - **Focus Highlights** (3 core points maximum):
     - Main feature work with brief outcome
     - Security/Infrastructure work
     - **AI Integration work (use bold to emphasize)**
   - Avoid verbose detailed breakdowns, percentages, or lengthy descriptions

7. **Copy to Clipboard**: Use `pbcopy` to copy the formatted status report to clipboard for easy sharing

## Output Structure

The report includes three main sections:
1. **Accomplished** - Closed, Resolved, and Review status issues grouped by features
2. **Work On** - In Progress and New issues grouped by features
3. **Summary** - Simplified format with:
   - Short 2-3 sentence overview (emphasizing AI work in bold)
   - Key Metrics (single concise line)
   - Focus Highlights (3 core bullet points maximum)

## Notes
- Defaults to 7-day period if no argument provided
- Links use Red Hat Jira format: https://issues.redhat.com/browse/[KEY]
- Review status is considered "Accomplished" for completion rate calculation
- Automatically categorizes issues based on summary content and labels
- **AI-related work should be prominently highlighted with bold formatting**
- Summary section is simplified and concise - avoid verbose metrics and lengthy explanations
- Focus Highlights limited to 3 core points for clarity
- Perfect for weekly standup reports, sprint reviews, or manager updates