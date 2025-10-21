---
argument-hint: [quarter-year] [optional: guidance/focus]
description: Generate a comprehensive quarterly work report with data-driven insights from Jira issues and GitHub PRs
allowed-tools: [Bash, TodoWrite, Read, Write]
---

Generate a comprehensive quarterly work report with clear structure, data-driven metrics, and easy-to-read format.

## Arguments

- `$1`: Quarter and year (e.g., "Q3-2025", "2025-Q3", "Q3 2025") - automatically parsed
- `$2`: (Optional) Overall guidance or focus for the report (e.g., "emphasize migration stability and AI productivity gains", "focus on community contributions and innovation")

## Implementation Steps

1. **Parse Time Range**: Extract quarter and year from `$1` to determine date range (e.g., Q3 2025 → 2025-07-01 to 2025-09-30)

2. **Create Task Plan**: Use TodoWrite to track report generation steps (Jira query, PR analysis, metrics calculation, document drafting)

3. **Gather Jira Data**:
   - Query Jira issues for the quarter: `jira issue list --jql "assignee = currentUser() AND created >= <start-date> AND created <= <end-date>"`
   - Categorize issues by type based on summary keywords
   - Count total issues and issues by category

4. **Analyze GitHub Contributions**:
   - Query all PRs for specified repository: `gh pr list --repo <repo> --search "author:@me created:<start-date>..<end-date>"`
   - Count total PRs merged
   - If `$2` mentions AI/productivity/automation: Search PRs containing specific marker phrase in body (e.g., "Claude Code")
   - Identify representative PRs for each major category

5. **Collect Additional Contributions** (Optional - only if `$2` mentions community/open-source/GSoC/MCP):
   - Search for related GitHub issues or PRs in other repositories
   - Query community contributions
   - Gather open-source project evidence

6. **Calculate Metrics** (Based on `$2` guidance):
   - Total PRs and Jira issues
   - If AI mentioned in `$2`: Calculate AI-assisted development rate and time savings estimates
   - Issue resolution counts by priority/type
   - Other relevant metrics based on guidance focus

7. **Generate Report Document**:
   - Apply guidance from `$2` to shape narrative, emphasis, and structure
   - Create structured markdown with:
     - **Executive Summary**: One-sentence overview with key metrics (aligned with `$2`)
     - **2-3 Main Sections**: Each with Key Achievement, Metrics, Representative Issues/PRs
     - **Summary**: Key metrics and business impact aligned with `$2`
     - **Quick Links**: All relevant dashboard and resource links
   - Keep format concise and scannable

8. **Format and Save**:
   - Review for clarity and data accuracy
   - Save as `Q{quarter}-{year}-Quarterly-Connection.md` in current directory
   - Update TodoWrite to mark all tasks complete

## Report Structure Template

```markdown
# Q{X} {YEAR} Quarterly Connection Report

## Executive Summary
[One-sentence overview shaped by guidance, with key metrics]

## 1. [Primary Work Area - determined by guidance]
### Key Achievement
### Metrics
### Representative Issues & PRs
### Technical Highlights (optional)

## 2. [Secondary Work Area]
### Key Achievement
### Metrics
### Notable Contributions

## 3. [Tertiary Work Area - if applicable based on guidance]
### Key sections based on guidance focus

## Summary
### Key Metrics
### Business Impact

## Quick Links
```

## Conditional Content Based on Guidance

**If `$2` contains "AI" / "productivity" / "automation":**
- Include AI-assisted development metrics
- Search PRs for marker phrase in body (default: "Claude Code", or extract custom marker from guidance)
- Calculate AI-assisted rate: `(PRs with marker / Total PRs) × 100%`
- Add workflow automation time savings breakdown
- Include AI productivity impact section

**If `$2` contains "community" / "open-source" / "GSoC" / "MCP":**
- Add community contributions section
- Search for related issues/PRs in external repositories
- Include mentorship and open-source impact metrics

**If `$2` contains specific feature names (e.g., "migration", "testing"):**
- Emphasize that feature area in primary section
- Filter Jira issues by feature keywords
- Highlight related PRs and technical achievements

**Default (no `$2`):**
- Balanced report across all work areas
- Focus on PRs and Jira issues without AI metrics
- General structure with 2-3 main work categories

## Example Usage

```bash
# Q3 2025 report with AI productivity focus
/dev:quarterly-report "Q3 2025" "emphasize migration feature stabilization and AI-driven productivity transformation"

# Q2 2025 report focusing on community impact (no AI metrics)
/dev:quarterly-report "2025-Q2" "highlight open-source community contributions and CNCF ecosystem expansion"

# Q4 2024 general report (no AI metrics)
/dev:quarterly-report "Q4-2024" "focus on code quality and bug fixes"

# Q1 2025 simple report without guidance
/dev:quarterly-report "Q1-2025"
```

## Guidance Examples

- `"emphasize production-grade reliability and enterprise customer value"`
- `"focus on innovation leadership and AI integration"`
- `"highlight code quality, test coverage, and technical debt reduction"`
- `"showcase community contributions and open-source impact"`
- `"demonstrate productivity transformation through AI tools (marker: Generated with Claude)"` (custom marker)

## Notes

- **Auto-parsing**: Supports multiple quarter formats (Q3-2025, 2025-Q3, Q3 2025)
- **Conditional Metrics**: AI metrics only included if mentioned in `$2`
- **Custom Markers**: Can specify custom search phrase in `$2` (e.g., "marker: Generated with AI")
- **Repository Detection**: Auto-detects main repository from git config or prompts user
- **Data Sources**: Requires `jira` CLI and `gh` CLI configured
- **Output**: Saves to current directory as `Q{quarter}-{year}-Quarterly-Connection.md`
- **Format**: Concise, scannable, data-driven with clickable links
