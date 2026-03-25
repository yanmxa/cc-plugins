#!/bin/bash
# update.sh — Update Jira issue fields in one shot
# Usage: update.sh <ISSUE_KEY> <field=value> [field=value ...]
#
# Supported fields:
#   status=<status>          — transition issue
#   sp=<number>              — set story points
#   priority=<name>          — set priority (Major, Minor, etc.)
#   activity=<value>         — set activity type
#   component=<name>         — set component
#   parent=<KEY>             — set parent issue
#   sprint=<id|current>      — move to sprint ("current" = active GH Sprint)
#   assignee=<id|-1>         — assign (-1 = current user)
#   link=<URL>               — add remote link (auto-detect title)
#
# Requires: jira-ops CLI

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH="$SCRIPT_DIR:$PATH"
source "$SCRIPT_DIR/jira-ops.sh"

if [ $# -lt 2 ]; then
  echo "Usage: update.sh <ISSUE_KEY> <field=value> [field=value ...]" >&2
  exit 1
fi

KEY=$(echo "$1" | tr '[:lower:]' '[:upper:]')
shift

PIDS=()
CMDS=()

for pair in "$@"; do
  field="${pair%%=*}"
  value="${pair#*=}"

  case "$field" in
    status|state)
      jira-ops issue transition "$KEY" "$value" 2>/dev/null &
      PIDS+=($!); CMDS+=("status -> $value")
      ;;
    sp|storypoints|story_points)
      jira-ops issue set-field "$KEY" "Story Points" "$value" 2>/dev/null &
      PIDS+=($!); CMDS+=("SP -> $value")
      ;;
    priority)
      jira-ops issue update "$KEY" "{\"fields\":{\"priority\":{\"name\":\"$value\"}}}" 2>/dev/null &
      PIDS+=($!); CMDS+=("priority -> $value")
      ;;
    activity|activity_type)
      AT_FIELD=$(jira-ops field get "Activity Type" 2>/dev/null || echo "customfield_10464")
      jira-ops issue update "$KEY" "{\"fields\":{\"$AT_FIELD\":{\"value\":\"$value\"}}}" 2>/dev/null &
      PIDS+=($!); CMDS+=("activity -> $value")
      ;;
    component)
      jira-ops issue update "$KEY" "{\"fields\":{\"components\":[{\"name\":\"$value\"}]}}" 2>/dev/null &
      PIDS+=($!); CMDS+=("component -> $value")
      ;;
    parent)
      PARENT_KEY=$(echo "$value" | tr '[:lower:]' '[:upper:]')
      jira-ops issue update "$KEY" "{\"fields\":{\"parent\":{\"key\":\"$PARENT_KEY\"}}}" 2>/dev/null &
      PIDS+=($!); CMDS+=("parent -> $PARENT_KEY")
      ;;
    sprint)
      SPRINT_ID="$value"
      if [ "$SPRINT_ID" = "current" ]; then
        SPRINT_ID=$(jira-ops sprint list 2697 2>/dev/null | grep -i "GH Sprint" | awk '{print $1}')
      fi
      jira-ops sprint move "$SPRINT_ID" "$KEY" 2>/dev/null &
      PIDS+=($!); CMDS+=("sprint -> $SPRINT_ID")
      ;;
    assignee)
      jira-ops issue update "$KEY" "{\"fields\":{\"assignee\":{\"id\":\"$value\"}}}" 2>/dev/null &
      PIDS+=($!); CMDS+=("assignee -> $value")
      ;;
    link)
      URL="$value"
      TITLE=$(jira_url_title "$URL")
      jira-ops issue remote-link "$KEY" "$URL" "$TITLE" 2>/dev/null &
      PIDS+=($!); CMDS+=("link -> $TITLE")
      ;;
    *)
      echo "Unknown field: $field" >&2
      ;;
  esac
done

# Wait for all parallel operations
FAILED=0
for i in "${!PIDS[@]}"; do
  if wait "${PIDS[$i]}"; then
    echo "OK: $KEY ${CMDS[$i]}"
  else
    echo "FAIL: $KEY ${CMDS[$i]}" >&2
    FAILED=1
  fi
done

exit $FAILED
