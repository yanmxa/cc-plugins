#!/bin/bash
# create.sh — Create a Jira issue with Global Hub defaults
# Usage: create.sh <summary> [options...]
#
# Options (key=value):
#   type=Task|Story|Bug|Spike|Epic  (default: Task)
#   priority=Major|Minor|...        (default: omitted)
#   sp=<number>                     (story points)
#   parent=<KEY>                    (parent issue)
#   component=<name>               (default: Global Hub)
#   sprint=current|<id>            (move to sprint after creation)
#
# Defaults: project=ACM, component=Global Hub, assignee=current user
#
# Requires: jira-ops CLI, jq

set -euo pipefail

export PATH="$(cd "$(dirname "$0")" && pwd):$PATH"

if [ $# -lt 1 ]; then
  echo "Usage: create.sh <summary> [type=Task] [priority=Major] [sp=3] [parent=ACM-xxx] [sprint=current]" >&2
  exit 1
fi

SUMMARY="$1"
shift

# Defaults
TYPE="Task"
COMPONENT="Global Hub"
PRIORITY=""
SP=""
PARENT=""
SPRINT=""

# Parse options
for pair in "$@"; do
  field="${pair%%=*}"
  value="${pair#*=}"
  case "$field" in
    type) TYPE="$value" ;;
    priority) PRIORITY="$value" ;;
    sp|storypoints) SP="$value" ;;
    parent) PARENT=$(echo "$value" | tr '[:lower:]' '[:upper:]') ;;
    component) COMPONENT="$value" ;;
    sprint) SPRINT="$value" ;;
  esac
done

# Build JSON payload
PAYLOAD="{\"fields\":{\"project\":{\"key\":\"ACM\"},\"issuetype\":{\"name\":\"$TYPE\"},\"summary\":\"$SUMMARY\",\"components\":[{\"name\":\"$COMPONENT\"}],\"assignee\":{\"id\":\"-1\"}"

if [ -n "$PRIORITY" ]; then
  PAYLOAD="$PAYLOAD,\"priority\":{\"name\":\"$PRIORITY\"}"
fi
if [ -n "$PARENT" ]; then
  PAYLOAD="$PAYLOAD,\"parent\":{\"key\":\"$PARENT\"}"
fi

PAYLOAD="$PAYLOAD}}"

# Create issue
ISSUE_KEY=$(jira-ops issue create "$PAYLOAD" 2>/dev/null)
echo "CREATED: $ISSUE_KEY"
echo "URL: https://redhat.atlassian.net/browse/$ISSUE_KEY"

# Post-creation updates (parallel)
PIDS=()
if [ -n "$SP" ]; then
  jira-ops issue set-field "$ISSUE_KEY" "Story Points" "$SP" 2>/dev/null &
  PIDS+=($!)
fi
if [ -n "$SPRINT" ]; then
  SPRINT_ID="$SPRINT"
  if [ "$SPRINT_ID" = "current" ]; then
    SPRINT_ID=$(jira-ops sprint list 2697 2>/dev/null | grep -i "GH Sprint" | awk '{print $1}')
  fi
  jira-ops sprint move "$SPRINT_ID" "$ISSUE_KEY" 2>/dev/null &
  PIDS+=($!)
fi

for pid in "${PIDS[@]}"; do
  wait "$pid"
done

[ -n "$SP" ] && echo "SP: $SP"
[ -n "$SPRINT" ] && echo "SPRINT: moved"
