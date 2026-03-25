#!/bin/bash
# sprint.sh — Fetch all my current GH Sprint issues
# Usage: sprint.sh [board_id]
#
# Requires: jira-ops CLI, python3

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH="$SCRIPT_DIR:$PATH"

BOARD_ID="${1:-2697}"

# Resolve custom field IDs dynamically (falls back to known defaults)
export SP_FIELD="${SP_FIELD:-$(jira-ops field get "Story Points" 2>/dev/null || echo "customfield_10028")}"
export AT_FIELD="${AT_FIELD:-$(jira-ops field get "Activity Type" 2>/dev/null || echo "customfield_10464")}"

# Get active GH Sprint ID
SPRINT_LINE=$(jira-ops sprint list "$BOARD_ID" 2>/dev/null | grep -i "GH Sprint" | head -1)
if [ -z "$SPRINT_LINE" ]; then
  echo "ERROR: No active GH Sprint found on board $BOARD_ID" >&2
  exit 1
fi
SPRINT_ID=$(echo "$SPRINT_LINE" | awk '{print $1}')
SPRINT_NAME=$(echo "$SPRINT_LINE" | sed 's/^[0-9]*[[:space:]]*[a-z]*[[:space:]]*//')
echo "SPRINT: $SPRINT_NAME (ID: $SPRINT_ID)"
echo "---"

# Search and format (--labels to include Labels column)
jira-ops --json issue search \
  "sprint = $SPRINT_ID AND assignee = currentUser() AND status != Closed" \
  "key,summary,issuetype,status,priority,components,parent,fixVersions,versions,labels,$SP_FIELD,$AT_FIELD" \
  100 2>&1 | python3 "$SCRIPT_DIR/_format_issues.py" --labels
