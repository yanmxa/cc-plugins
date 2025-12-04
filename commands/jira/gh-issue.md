---
argument-hint: [operation] [description] - operation: create|update|link|query; description: context and details
description: Manage Global Hub Jira issues using jira-administrator agent with predefined defaults
allowed-tools: Task, Bash, Skill
---

Unified command for all Global Hub Jira operations with intelligent intent detection.

## Operations

### CREATE
**Patterns**:
- PR URL → Create from PR + auto-link
- Type + details → Create typed issue
- Natural text → Auto-detect type/points/priority

**Examples**:
- `create https://github.com/stolostron/multicluster-global-hub/pull/2133`
- `create bug "Memory leak" "Crashes after 24h"`
- `create "Add retry mechanism, story with 3 points"`

### UPDATE
**Patterns**:
- Issue + fields → Update fields
- Issue + PR → Update + link PR
- Issue + description → Update following template

**Examples**:
- `update ACM-27143 --priority Critical`
- `update ACM-27143 https://github.com/.../pull/123`
- `update ACM-27143 "Reformat using Story template"`

### LINK
**Auto-detect link type by checking both issue types**:

| First Issue | Second Issue | Action |
|-------------|--------------|--------|
| Story/Task/Bug | Epic | Set Epic Link (jira epic add) |
| Any | PR URL | Use link-jira-pr skill |
| Any | Any | Create issue link (Related/Blocks/etc) |

**Examples**:
- `link ACM-27143 ACM-22567` → Auto-detect: Story to Epic = `jira epic add ACM-22567 ACM-27143`
- `link ACM-27143 https://github.com/.../pull/123` → `~/.claude/skills/link-jira-pr/scripts/link-jira-pr.sh`
- `link ACM-27143 blocks ACM-27002` → `jira issue link ACM-27143 ACM-27002 Blocks`

### QUERY
**Examples**:
- `query "status=Open AND assignee=currentUser()"`
- `query "open bugs assigned to me"`

## Implementation

**Parse**: Extract operation, PR URLs, issue keys, type, points, priority

**For LINK operation**:
1. Check if description contains PR URL → Use link-jira-pr skill
2. Extract two issue keys → Check both types:
   - If one is Epic, other is Story/Task/Bug → `jira epic add <EPIC> <ISSUE>`
   - Otherwise → `jira issue link <ISSUE1> <ISSUE2> <type>`
3. Done

**For CREATE/UPDATE**: Use jira-tools:jira-administrator agent

## Global Hub Defaults
Component: `Global Hub` | Label: `GlobalHub` | Fix Version: `Global Hub 1.7.0` | Assignee: Current user | Activity Type: Auto-set

## Templates
**Story**: Value Statement, DoD, Dev Complete, Tests, Security, Docs, Support
**Bug**: Problem, Version, Reproducible, Steps, Actual/Expected, Additional
**Epic**: Goal, Importance, Scenarios, Acceptance, Dependencies, Questions, Checklist
**Feature**: Overview, Goals, Requirements, Use Cases, Scope, Background, Docs

## Notes
- Check for duplicates before creating
- PR linking uses link-jira-pr skill (auto: sprint, status, points)
- All text marked "Generated with Claude Code"
