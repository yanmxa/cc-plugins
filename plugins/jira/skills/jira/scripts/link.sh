#!/bin/bash
# link.sh — Link a Jira issue to a URL or set parent issue
# Usage: link.sh <ISSUE_KEY> <URL_OR_ISSUE_KEY> [custom_title]
#
# Auto-detects URL type and generates appropriate title:
#   github.com/.../pull/N     -> "PR #N - <repo>"
#   gitlab/.../merge_requests -> "MR !N - <repo>"
#   drive.google.com          -> "Google Drive"
#   redhat.com/en/blog/...    -> "Blog: <slug>"
#   ACM-XXXXX (issue key)     -> sets as parent instead of remote link
#   Other URL                 -> uses domain as title
#
# Requires: jira-ops CLI

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH="$SCRIPT_DIR:$PATH"
source "$SCRIPT_DIR/jira-ops.sh"

if [ $# -lt 2 ]; then
  echo "Usage: link.sh <ISSUE_KEY> <URL_OR_KEY> [custom_title]" >&2
  exit 1
fi

KEY=$(echo "$1" | tr '[:lower:]' '[:upper:]')
TARGET="$2"
CUSTOM_TITLE="${3:-}"

# Check if target is an issue key (e.g., ACM-12345)
if echo "$TARGET" | grep -qiE '^[A-Z]+-[0-9]+$'; then
  PARENT=$(echo "$TARGET" | tr '[:lower:]' '[:upper:]')
  jira-ops issue update "$KEY" "{\"fields\":{\"parent\":{\"key\":\"$PARENT\"}}}" 2>/dev/null
  echo "OK: $KEY parent -> $PARENT"
  exit 0
fi

# It's a URL — generate title
URL="$TARGET"
TITLE="${CUSTOM_TITLE:-$(jira_url_title "$URL")}"

jira-ops issue remote-link "$KEY" "$URL" "$TITLE" 2>/dev/null
echo "OK: $KEY linked -> $TITLE ($URL)"
