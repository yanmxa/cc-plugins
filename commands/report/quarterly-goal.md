---
argument-hint: [goal-topic] [--status] (e.g., "AI automation", "Migration Stability --status")
description: Create quarterly goal statements with optional progress tracking from Jira and GitHub
allowed-tools: [Bash, Write, AskUserQuestion]
---

Create concise quarterly goal statements following a proven template format. With `--status` flag, automatically retrieve and organize related work from Jira and GitHub into structured deliverables.

## Implementation Steps

1. **Parse Arguments**:
   - Extract goal topic/focus area from first argument
   - Check for `--status` flag to determine if progress tracking is needed
   - If no topic provided, ask user for goal topic

2. **Without --status (Simple Goal Creation)**:
   - Ask user for:
     - Target percentage or metric (default: 30%)
     - Specific tasks or focus areas (e.g., "PR submissions, Jira operations")
     - Team sharing component (yes/no)
   - Generate goal statement using template structure
   - Output formatted goal statement as copyable text

3. **With --status (Goal + Progress Tracking)**:
   - Ask user for:
     - Quarter and year (e.g., "Q4 2025")
     - Keywords for filtering Jira issues (e.g., "migration", "migrate")
     - Keywords for filtering GitHub PRs (e.g., "migration", "AI-assisted")
   - Query Jira issues using JQL with keywords and date range
   - Query GitHub PRs using search with keywords and date range
   - Categorize issues and PRs by themes (scalability, reliability, security, etc.)
   - Generate structured goal file with:
     - Goal Statement
     - Key Deliverables (categorized by theme)
     - Summary with metrics and links
   - Save as `Q{X}-{YEAR}-Goal-{N}-{Topic}.md`

4. **Generate Goal File Structure** (when --status is used):
   ```markdown
   # Goal {N}: {Topic}

   ## Goal Statement
   [Description of goal]

   ---

   ## Key Deliverables

   ### 1. {Category}: {Title}
   [Background problem description]
   [Solution description]

   **Core Delivery:**
   - [JIRA-XXXXX](link): Description
   - [PR #XXXX](link): Description

   **Customer Impact:**
   - Impact point 1
   - Impact point 2

   ---

   ## Summary
   **Goal Achieved:** [Achievement description]
   **Metrics:** [Key metrics with numbers]
   **Value:** [Customer/business value]
   **Links:** [Jira query] | [GitHub query]
   ```

5. **Categorization Logic**:
   - Group Jira issues and PRs by common themes in summaries/titles
   - Common categories:
     - Scalability Enhancement
     - Reliability Enhancement
     - Security (CVE fixes)
     - Code Quality (test fixes, documentation)
     - New Features
     - Customer Enhancements
   - For each category:
     - Describe the problem
     - Describe the solution
     - List Core Delivery (Jira + PRs with links)
     - Describe Customer Impact

## Usage Examples

- `/report:quarterly-goal "AI automation"` - Simple goal statement with 30% default target
- `/report:quarterly-goal "Migration Stability" --status` - Goal with progress from Jira/GitHub
- `/report:quarterly-goal "Platform Maintenance" --status` - Auto-categorize work by themes

## Template Structure (Simple Mode)

```
# [Goal Title]

My goal for this quarter is to use [method/approach] to [accomplish] more than [X%] of [target area], such as [task 1], [task 2], and [task 3]. I will track my time to confirm this method enhances my productivity by [specific benefit]. Additionally, I will share and promote [deliverable] with the team to improve overall team efficiency.
```

## Jira Query Examples

When using `--status`, construct JQL queries like:
```
assignee = currentUser()
AND ((created >= 2025-10-01 AND created <= 2025-12-31)
     OR (updated >= 2025-10-01 AND updated <= 2025-12-31))
AND (summary ~ "keyword1" OR summary ~ "keyword2")
```

## GitHub Query Examples

When using `--status`, construct GitHub searches like:
```
is:pr author:@me created:2025-10-01..2025-12-31 keyword in:title
is:pr author:@me created:2025-10-01..2025-12-31 "keyword" in:body
```

## Notes

- Without `--status`: Simple goal statement generation (original behavior)
- With `--status`: Full goal file with Jira/GitHub data and categorization
- Keep goal statements concise (3-5 sentences)
- Use narrative style for Key Deliverables (problem → solution → impact)
- Include all Jira and PR links in markdown format
- Auto-detect repository from git config when querying GitHub
- Categorize by technical themes, not by issue type
- File naming: `Q{quarter}-{year}-Goal-{number}-{topic-slug}.md`
