#!/bin/bash

# Jira My Issues Script
# Fetches Jira issues data and outputs raw JSON for LLM processing
# Usage: jira-my-issues.sh [time-span]
# Example: jira-my-issues.sh 7d

set -euo pipefail

# Parse arguments
TIME_SPAN="${1:-7d}"

echo "Fetching issues (last $TIME_SPAN)..." >&2

# Output structured data for LLM to process
echo "===ASSIGNEE_ISSUES==="
jira issue list --assignee "$(jira me)" --updated "-$TIME_SPAN" --order-by updated --reverse --plain --columns key,type,status,priority,summary 2>/dev/null || echo "No assignee issues found"

echo "===REPORTER_ISSUES==="
jira issue list --reporter "$(jira me)" --updated "-$TIME_SPAN" --order-by updated --reverse --plain --columns key,type,status,priority,summary 2>/dev/null || echo "No reporter issues found"

echo "===CURRENT_SPRINT==="
jira sprint list --current --plain --columns type,key,summary,status 2>/dev/null || echo "No current sprint found"

echo "===TIME_SPAN==="
echo "$TIME_SPAN"
