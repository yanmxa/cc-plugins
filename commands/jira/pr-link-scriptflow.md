---
argument-hint: <issue-key> <pr-url> [story-points]
description: Link Jira issue and GitHub PR using ScriptFlow automation
allowed-tools: [mcp__scriptflow__script_run]
---

# Link Jira Issue and PR (ScriptFlow Version)

Simplified workflow that uses the ScriptFlow `jira-pr-link` script to cross-link Jira issues with GitHub pull requests, automatically managing issue status, sprint assignment, and story points.

## Context:
$ARGUMENTS should contain:
- `$1`: Jira issue key (e.g., "ACM-25088")
- `$2`: GitHub PR URL (e.g., "https://github.com/stolostron/multicluster-global-hub/pull/2032")
- `$3`: Story points value (optional, e.g., "1", "3", "5")

## Steps:

1. **Execute ScriptFlow Script**: Run the `jira-pr-link` script with the provided arguments using `mcp__scriptflow__script_run` tool:
   - Pass `$1` (issue key) as first argument
   - Pass `$2` (PR URL) as second argument
   - Pass `$3` (story points) as third argument if provided
   - Script will automatically handle all operations: PR linking, Jira commenting, status transitions, sprint assignment, and story points

2. **Report Results**: Display the script output showing what was accomplished

## What the Script Does:
- ✅ Adds Jira issue link to PR description (if not exists)
- ✅ Adds PR link as Jira comment (if not exists)
- ✅ Transitions issue from "New" to "In Progress" (if applicable)
- ✅ Assigns issue to current active sprint (if not assigned)
- ✅ Sets story points (if provided and not already set)
- ✅ Prevents duplicate operations with intelligent checks

## Target:
- Single-command execution for complete Jira-PR linking workflow
- Leverages automated ScriptFlow script for consistency and reliability
- All operations handled by the script with graceful error handling
- Clean, concise output showing what was accomplished

## Notes:
- Requires ScriptFlow script `jira-pr-link` to be installed
- Script location: `~/.claude/configs/scriptflow/jira-pr-link.sh`
- Requires GitHub CLI (`gh`) to be authenticated and configured
- Requires Jira CLI to be authenticated and configured
- If story points not provided as argument, script will warn but continue
- Script validates PR URL format and extracts owner/repo/number automatically
