---
argument-hint: "[quarter-year] [optional: guidance/focus]"
description: Generate a comprehensive quarterly work report with data-driven insights from Jira issues and GitHub PRs
allowed-tools: [Bash, TodoWrite, Read, Write]
---

Generate a comprehensive quarterly work report with clear structure, data-driven metrics, and easy-to-read format.

## Key Improvements

- **Include both created and updated dates**: Query Jira and GitHub using both creation and update timestamps to capture all relevant work
- **Pragmatic titles**: Use realistic, professional titles without superlatives (e.g., "Enhancement" vs "Transformation")
- **Concise HOW section**: 4-6 brief bullet points focusing on execution approach
- **Connected narratives**: One flowing paragraph per accomplishment (problem → solution → impact)
- **Impact & Data**: Clear separation of narrative and supporting metrics with links

## Arguments

- `$1`: Quarter and year (e.g., "Q3-2025", "2025-Q3", "Q3 2025") - automatically parsed
- `$2`: (Optional) Overall guidance or focus for the report (e.g., "emphasize migration stability and AI productivity gains", "focus on community contributions and innovation")

## Implementation Steps

1. **Parse Time Range**: Extract quarter and year from `$1` to determine date range (e.g., Q3 2025 → 2025-07-01 to 2025-09-30)

2. **Create Task Plan**: Use TodoWrite to track report generation steps (Jira query, PR analysis, metrics calculation, document drafting)

3. **Gather Jira Data**:
   - Query Jira issues for the quarter (include both created and updated): `jira issue list --jql "assignee = myan AND (created >= <start-date> OR updated >= <start-date>) AND (created <= <end-date> OR updated <= <end-date>)"`
   - Categorize issues by type based on summary keywords
   - Count total issues and issues by category

4. **Analyze GitHub Contributions**:
   - Query all PRs for specified repository (include both created and updated): `gh pr list --repo <repo> --search "author:yanmxa (created:<start-date>..<end-date> OR updated:<start-date>..<end-date>)"`
   - For simpler queries focusing on creation time: `gh pr list --repo <repo> --search "author:yanmxa created:<start-date>..<end-date>"`
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
   - **Apply Accomplishments Framework**: Separate WHAT (achievements) and HOW (execution approach)
   - **Narrative-First Approach**: Tell a story, don't list items
     - Focus on the problem, solution, and impact narrative
     - Use aggregated metrics to support the story (e.g., "15 PRs merged" not listing each PR)
     - Keep descriptions concise and connected (one paragraph per accomplishment)
     - Add links to filtered Jira/GitHub queries for readers to dive into details
     - **DO NOT** enumerate every Jira issue or PR in the report body
   - **Title Guidelines**: Keep titles realistic and pragmatic, avoid superlatives
     - ✅ Good: "Migration Reliability Enhancement", "AI-Assisted Development Integration", "Codebase Maintenance"
     - ❌ Avoid: "Migration Feature Transformation", "Pioneer", "Revolutionary", "Game-changing"
   - Create structured markdown with:
     - **Executive Summary**: Concise overview with key metrics (aligned with `$2`)
     - **Accomplishments (WHAT I did)**: 3-4 main achievements, each with:
       - One concise paragraph describing the accomplishment (problem → solution → impact)
       - **Impact & Data** section with aggregated metrics and links
     - **HOW I did it**: 4-6 concise bullet points (keep brief and specific):
       - Deep problem analysis (root cause thinking vs quick fixes)
       - Collaborative problem-solving (feedback loops, partnerships)
       - Coaching/mentorship (if applicable - guiding questions, building toolkit)
       - Experimentation & learning (controlled experiments, measured risks)
       - Transparent communication (design proposals, documentation, tracking)
       - Continuous adaptation (adapting based on results)
     - **Summary**: Key metrics and business impact
     - **Quick Links**: All relevant dashboard and resource links
   - Keep format concise and scannable

8. **Format and Save**:
   - Review for clarity and data accuracy
   - Save as `Q{quarter}-{year}-Quarterly-Connection.md` in current directory
   - Update TodoWrite to mark all tasks complete

## Accomplishments Framework

When describing accomplishments in the report, reflect on both **WHAT** you accomplished and **HOW** you accomplished it.

### WHAT (Accomplishments):
- Technical deliverables (features, bug fixes, PRs, Jira issues)
- Metrics and quantifiable outcomes
- Business impact and customer value
- Project completions and milestones

### HOW (Execution Approach):
- **Strategic thinking and influence skills**: How did you approach complex problems? What strategies did you employ?
- **Relationship building**: How did you collaborate within and outside your team?
- **Mentorship and support**: How did you help teammates through consulting, coaching, or being a sounding board?
- **Innovation and learning**: What new approaches or tools did you introduce?
- **Communication and leadership**: How did you facilitate discussions, align stakeholders, or drive decisions?

### Accomplishment Presentation Styles:

**Option 1: Separate WHAT and HOW**
```
Accomplishments (WHAT):
- Implemented Delta Bundle Sync reducing bandwidth by 70%
- Delivered 53 PRs with 52.8% AI-assisted
- Mentored GSoC student successfully

HOW I did it:
- Strategic thinking: Architected delta sync to solve scalability bottleneck
- Built relationships: Collaborated with OCM community for FL integration
- Provided mentorship: Guided student through framework extensions
```

**Option 2: Combined WHAT and HOW (Recommended for concise reports)**
```
- Implemented Delta Bundle Sync by architecting an incremental update system, reducing bandwidth by 70% and enabling 300-cluster scale
- Delivered 53 PRs with 52.8% AI-assistance by strategically integrating Claude Code into workflow and building automation tooling
- Mentored GSoC student to successfully extend FL framework support by providing consistent coaching and being a technical sounding board
```

### Integration into Report:
Each major section should naturally combine WHAT (technical achievement) with HOW (execution approach) to tell a complete story of impact and methodology.

---

## Narrative Writing Guidelines

**Key Principle: Story First, Data Second, Links for Deep Dive**

- **Tell the Story**: Focus on problem → solution → impact narrative
- **Aggregate Data**: Use summary metrics (e.g., "15 PRs merged, 70% improvement") instead of listing each item
- **Selective Examples**: Include 1-2 representative examples with direct links for concrete context
- **Enable Deep Dive**: Provide filtered Jira JQL or GitHub search links for readers who want full details
- **Avoid Enumeration**: Never list all Jira issues or PRs in the report body

**Example of Good vs. Bad Approach:**

❌ **Bad (Listing Everything):**
```
Implemented Delta Bundle Sync:
- ACM-19871: Delta Bundle Sync story
- PR #1793: Efficient bundle sync
- PR #1810: Delta sync mode
- PR #1799: Resync queue
- PR #1800: Lightweight emitters
- ACM-23340: Consumer group customization
- PR #1895: Add consumer group API
- PR #1910: Transport config
...
```

✅ **Good (Narrative + Aggregated Data + Links):**
```
Implemented Delta Bundle Sync by architecting an incremental update system that transmits only changed fields instead of full snapshots, reducing bandwidth by 70% and enabling 300-cluster scale.

Metrics:
- 15 PRs merged, 8 stories completed
- 70% data transfer reduction
- 40% performance improvement

Example: [PR #1793](link) established the foundation for efficient bundle sync across clusters.

[View all related work](jira-jql-link) | [PRs](github-search-link)
```

---

## Report Structure Template

```markdown
# Q{X} {YEAR} Quarterly Connection Report

## Executive Summary

[Concise overview: During Q{X} {YEAR}, I focused on {2-3 areas} ({metrics}). My approach emphasized {methods}.]

---

## Accomplishments (WHAT I did)

### 1. [Primary Achievement - Pragmatic Title]

[One concise paragraph: Problem → Solution → Impact. Keep it connected and flowing, not fragmented.]

**Impact & Data:**
- [X Jira issues](jql-link) resolved | [Y PRs merged](github-link)
- Key metric 1
- Key metric 2 | Key metric 3

---

### 2. [Secondary Achievement - Pragmatic Title]

[One concise paragraph describing the accomplishment and its value.]

**Impact & Data:**
- [X PRs (Y%) AI-assisted](github-link) with Claude Code
- Time savings: workflow1 (Xh), workflow2 (Yh), workflow3 (Zh)
- Zero quality degradation

---

### 3. [Third Achievement - Pragmatic Title]

[One concise paragraph about contribution/mentorship/community work.]

**Impact & Data:**
- [X Jira issues](jql-link) progressed (breakdown)
- [Y items contributed](link): specific items
- [Project link](url) with details

---

### 4. [Fourth Achievement - Pragmatic Title]

[One concise paragraph about maintenance/quality work.]

**Impact & Data:**
- [X PRs merged](link) | [Y Jira issues](link) resolved
- Zero critical bugs | Z+ improvements delivered
- Major work streams: Area1 (X PRs), Area2 (Y PRs), Area3 (Z PRs)

---

## HOW I did it:

- **Deep problem analysis**: [Brief example of root cause thinking vs quick fixes; strategic prioritization]

- **Collaborative problem-solving**: [Brief examples of feedback loops, cross-team partnerships, knowledge sharing]

- **Coaching/mentorship**: [If applicable - guiding questions, connecting people, building toolkit]

- **Experimentation & learning**: [Brief example of controlled experiments, build-learn-share]

- **Transparent communication**: [Brief examples: design proposals, documentation as thinking, systematic tracking]

- **Continuous adaptation**: [Brief example of adapting based on results, developing judgment]

---

## Summary

### Key Metrics

- **X PRs merged** | **Y+ Jira issues** resolved
- **Z% AI-assisted development** (if applicable) | **A-B% productivity gain**
- **C issues** in area1 | **D items** contributed in area2
- **Zero critical regressions** while maintaining velocity

### Business Impact

**Area1:** [Impact description]

**Area2:** [Impact description]

**Area3:** [Impact description]

**Area4:** [Impact description]

---

## Quick Links

**GitHub:** [All Q{X} PRs](link) | [AI-Assisted PRs](link) (if applicable)

**Jira:** [All Q{X} Issues](link) | [Area1 Issues](link) | [Area2 Issues](link)

**Community:** [Project1](link) | [Project2](link) | [Prototype](link)
```

### Link Generation Guidelines

When creating filtered links for Jira and GitHub:

**Jira JQL Examples (include both created and updated):**
- All issues for quarter: `assignee = myan AND (created >= YYYY-MM-DD OR updated >= YYYY-MM-DD) AND (created <= YYYY-MM-DD OR updated <= YYYY-MM-DD)`
- Issues for feature: `assignee = myan AND (created >= YYYY-MM-DD OR updated >= YYYY-MM-DD) AND (created <= YYYY-MM-DD OR updated <= YYYY-MM-DD) AND (summary ~ "keyword" OR summary ~ "keyword2")`
- By type: `assignee = myan AND type = Bug AND (created >= YYYY-MM-DD OR updated >= YYYY-MM-DD) AND (created <= YYYY-MM-DD OR updated <= YYYY-MM-DD)`

**GitHub Search Examples:**
- All PRs in quarter (include both created and updated): `is:pr author:yanmxa (created:YYYY-MM-DD..YYYY-MM-DD OR updated:YYYY-MM-DD..YYYY-MM-DD)`
- All PRs created in quarter (simpler): `is:pr author:yanmxa created:YYYY-MM-DD..YYYY-MM-DD`
- PRs for feature: `is:pr author:yanmxa created:YYYY-MM-DD..YYYY-MM-DD keyword in:title`
- AI-assisted: `is:pr author:yanmxa created:YYYY-MM-DD..YYYY-MM-DD "Claude Code" in:body`

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
- **Data Query Approach**:
  - **Jira**: Use `(created >= date OR updated >= date) AND (created <= date OR updated <= date)` to capture issues created OR updated in the quarter
  - **GitHub**: Consider using `(created:date..date OR updated:date..date)` to capture PRs created OR updated in the quarter
  - This ensures comprehensive coverage of all work done during the period
- **Conditional Metrics**: AI metrics only included if mentioned in `$2`
- **Custom Markers**: Can specify custom search phrase in `$2` (e.g., "marker: Generated with AI")
- **Repository Detection**: Auto-detects main repository from git config or prompts user
- **Data Sources**: Requires `jira` CLI and `gh` CLI configured
- **Output**: Saves to current directory as `Q{quarter}-{year}-Quarterly-Connection.md`
- **Format**: Concise, scannable, data-driven with clickable links
