#!/bin/bash
# issues.sh — Fetch all my assigned issues (excludes Closed and Backlog by default)
# Usage: issues.sh [extra_jql_filter]
# Examples:
#   issues.sh                          # all non-closed, non-backlog issues
#   issues.sh "project = ACM"         # add extra JQL filter
#   issues.sh "status = Closed"       # override: show closed issues
#
# Requires: jira-ops CLI, python3

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH="$SCRIPT_DIR:$PATH"

EXTRA_FILTER="${1:-}"

# Resolve custom field IDs dynamically (falls back to known defaults)
export SP_FIELD="${SP_FIELD:-$(jira-ops field get "Story Points" 2>/dev/null || echo "customfield_10028")}"
export AT_FIELD="${AT_FIELD:-$(jira-ops field get "Activity Type" 2>/dev/null || echo "customfield_10464")}"
export SPRINT_FIELD="${SPRINT_FIELD:-$(jira-ops field get "Sprint" 2>/dev/null || echo "customfield_10020")}"

# Build JQL
JQL='assignee = currentUser() AND status NOT IN (Closed, Backlog) ORDER BY status ASC, priority DESC'
if [ -n "$EXTRA_FILTER" ]; then
  JQL="assignee = currentUser() AND status NOT IN (Closed, Backlog) AND ${EXTRA_FILTER} ORDER BY status ASC, priority DESC"
fi

echo "JQL: $JQL"
echo "---"

# Search and format
jira-ops --json issue search \
  "$JQL" \
  "key,summary,issuetype,status,priority,components,parent,fixVersions,versions,$SPRINT_FIELD,$SP_FIELD,$AT_FIELD" \
  100 2>&1 | python3 "$SCRIPT_DIR/_format_issues.py" --sprint-mark
