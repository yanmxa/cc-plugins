#!/bin/sh
# Locate every reference a diff can be judged against: the spec it came from and
# the written rules that govern the files it touched.
#
# Worth a script for one reason: a CLAUDE.md only applies to files at or below its
# directory, so "which rules govern this change" is an ancestor walk per changed
# file. Done by hand that is either wrong or tedious.
#
#   refs.sh [base-ref]     default: main
set -eu
BASE="${1:-main}"
git rev-parse "$BASE" >/dev/null 2>&1 || { echo "bad ref: $BASE" >&2; exit 1; }
FILES=$(git diff --name-only --diff-filter=ACMR "$BASE"...HEAD)
[ -n "$FILES" ] || { echo "empty diff against $BASE" >&2; exit 1; }

echo "── issue references in the commits ──"
# Capture first: a pipeline's status comes from its last command, so `| sed ... ||`
# never fires when grep finds nothing.
REFS=$(git log "$BASE"..HEAD --pretty=%B \
	| grep -oE '(#|![0-9])[0-9]+|[A-Z][A-Z0-9]+-[0-9]+|(Closes|Fixes|Resolves|Refs)[: ]+[^ ]+' \
	| sort -u || true)
if [ -n "$REFS" ]; then printf '%s\n' "$REFS" | sed 's/^/  /'
else echo "  none — ask where the spec is; never invent one"; fi

echo
echo "── candidate spec files ──"
BR=$(git rev-parse --abbrev-ref HEAD | tr '/_' '--')
SPECS=$(find docs specs .scratch doc -maxdepth 3 -type f \( -name '*.md' -o -name '*.txt' \) 2>/dev/null \
	| grep -iE "$(echo "$BR" | cut -d- -f2-)|spec|rfc|design|proposal" | head -10 || true)
if [ -n "$SPECS" ]; then printf '%s\n' "$SPECS" | sed 's/^/  /'
else echo "  none matched the branch name"; fi

echo
echo "── written rules governing the changed files ──"
# A directory's CLAUDE.md applies only to files at or below it, so walk up from
# each changed file and collect what it is actually subject to.
{
	for f in $FILES; do
		d=$(dirname "$f")
		while :; do
			for n in CLAUDE.md CLAUDE.local.md AGENTS.md; do
				[ -f "$d/$n" ] && echo "$d/$n"
			done
			[ "$d" = "." ] && break
			d=$(dirname "$d")
		done
	done
	[ -f "$HOME/.claude/CLAUDE.md" ] && echo "$HOME/.claude/CLAUDE.md"
	for n in CONTRIBUTING.md CODING_STANDARDS.md STYLE.md CONVENTIONS.md; do
		[ -f "$n" ] && echo "$n"
	done
} | sort -u | sed 's/^/  /'

echo
cat <<'EOF'
Read each rule file before judging. Only flag a violation you can quote the exact
rule and the exact line for — a documented rule always overrides an inferred
convention, and where nothing is written down the neighbouring code is the
standard, which makes it a judgement call.
EOF
