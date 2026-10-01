#!/bin/sh
# Pin and validate the review target, once, before any fan-out.
#
# The failure it prevents: a bad ref or an empty diff discovered inside eight
# parallel finder subagents, after paying for all of them.
#
#   target.sh [base-ref]     default: @{upstream}, else main
set -eu
BASE="${1:-}"
if [ -z "$BASE" ]; then
	BASE=$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || echo main)
fi
git rev-parse "$BASE" >/dev/null 2>&1 || { echo "bad ref: $BASE" >&2; exit 1; }

MERGE=$(git merge-base "$BASE" HEAD)
STAT=$(git diff --shortstat "$MERGE"...HEAD)
DIRTY=$(git status --porcelain | wc -l | tr -d ' ')
[ -n "$STAT" ] || [ "$DIRTY" != 0 ] || { echo "empty diff against $BASE" >&2; exit 1; }

cat <<EOF
base:        $BASE
merge-base:  $(echo "$MERGE" | cut -c1-12)
committed:   ${STAT:-none}
uncommitted: $DIRTY file(s)

Use this diff command in every angle, so they all review the same thing:
  git diff $MERGE...HEAD $([ "$DIRTY" != 0 ] && echo '; git diff HEAD')

commits:
EOF
git log "$MERGE"..HEAD --oneline | sed 's/^/  /'
printf '\nfiles:\n'
git diff --name-status "$MERGE"...HEAD | sed 's/^/  /'
