#!/bin/sh
# Deterministic metrics from established tools. Every reading names what computed it.
#
# Nothing here computes a metric itself. A number is only re-derivable if you know
# which tool produced it, so provenance is printed, not implied — that is the whole
# difference between a measurement and an assertion.
#
# Tools are run with uvx/npx where possible, so none of them need installing first.
#
#   measure.sh [base-ref]     base-ref omitted → whole tree
#   CCN=20 measure.sh         raise the complexity warning threshold (default 15)
set -eu

BASE="${1:-}"; CCN="${CCN:-15}"; MISSING=""
have() { command -v "$1" >/dev/null 2>&1; }
gap()  { MISSING="$MISSING
  - $1"; }
hdr()  { printf '\n%s\n' "── $1 ──"; }

# Gaps are recorded with an `if`, never `have x && ... || gap`: that pattern also
# fires the gap when the tool exists and its pipeline merely exits non-zero — a
# `head` closing the pipe is enough — reporting an installed tool as unmeasured.

# Scope: changed files when given a base, else the tree.
if [ -n "$BASE" ]; then
	git rev-parse "$BASE" >/dev/null 2>&1 || { echo "bad ref: $BASE" >&2; exit 1; }
	FILES=$(git diff --name-only --diff-filter=ACMR "$BASE"...HEAD)
	[ -n "$FILES" ] || { echo "empty diff against $BASE" >&2; exit 1; }
	echo "scope: $(printf '%s\n' "$FILES" | wc -l | tr -d ' ') changed files since $BASE"
else
	FILES=$(git ls-files 2>/dev/null || true)
	echo "scope: whole tree"
fi
SRC=$(printf '%s\n' "$FILES" | grep -E '\.(go|py|js|jsx|ts|tsx|java|rb|rs|c|cc|cpp|h|hpp|cs|php|swift|kt|scala|m|mm|lua)$' || true)
[ -n "$SRC" ] || { echo "no source files in scope"; exit 0; }

# ── complexity ─────────────────────────────────────────────────────────────
# lizard covers 15+ languages in one pass and reports CCN, params, length and
# nesting depth per function. Preferred over per-language tools for exactly that.
hdr "complexity"
if have uvx || have lizard; then
	RUN="lizard"; have lizard || RUN="uvx lizard"
	echo "tool: lizard (CCN threshold $CCN)"
	# shellcheck disable=SC2086
	printf '%s\n' "$SRC" | xargs $RUN --csv 2>/dev/null | python3 -c '
import sys,csv,os
rows=[]
for r in csv.reader(sys.stdin):
    if len(r)<11: continue
    try: rows.append((int(r[1]),int(r[0]),int(r[3]),r[6],r[7],r[9]))
    except ValueError: pass
if not rows: print("  no functions parsed"); sys.exit()
t=int(os.environ.get("CCN","15"))
rows.sort(reverse=True)
over=[r for r in rows if r[0]>t]
print("  functions: %d   max CCN: %d   over %d: %d" % (len(rows),rows[0][0],t,len(over)))
for ccn,nloc,params,f,name,line in over[:12]:
    print("    CCN %-4d %-4s lines  %s:%s  %s" % (ccn,nloc,f,line,name))
' || gap "lizard failed to parse; check the file list"
else
	gap "complexity — needs lizard (pip install lizard, or uv so uvx can run it)"
fi

# ── duplication ────────────────────────────────────────────────────────────
hdr "duplication"
if have npx; then
	echo "tool: jscpd"
	printf '%s\n' "$SRC" | head -400 > /tmp/m.$$.lst
	# shellcheck disable=SC2046  # the file list must word-split into arguments
	npx --yes jscpd@latest --pattern "**/*" --min-tokens 60 --reporters json \
		--output /tmp/m.$$.d $(tr '\n' ' ' < /tmp/m.$$.lst) >/dev/null 2>&1 || true
	if [ -f /tmp/m.$$.d/jscpd-report.json ]; then
		python3 - /tmp/m.$$.d/jscpd-report.json <<'PY'
import json,sys
try: d=json.load(open(sys.argv[1]))
except Exception: print("  (no report)"); sys.exit()
s=d.get("statistics",{}).get("total",{})
print("  clones: %s   duplicated lines: %s (%.2f%%)" % (
    s.get("clones",0), s.get("duplicatedLines",0), s.get("percentage",0)))
for c in (d.get("duplicates") or [])[:8]:
    a,b=c["firstFile"],c["secondFile"]
    print("    %s:%s ~ %s:%s  (%s lines)" % (a["name"],a["start"],b["name"],b["start"],c.get("lines")))
PY
	else
		gap "duplication — jscpd produced no report"
	fi
	rm -rf /tmp/m.$$.lst /tmp/m.$$.d
elif have uvx || have lizard; then
	RUN="lizard"; have lizard || RUN="uvx lizard"
	echo "tool: lizard -Eduplicate (jscpd absent; jscpd is the more thorough option)"
	# shellcheck disable=SC2086
	printf '%s\n' "$SRC" | xargs $RUN -Eduplicate 2>/dev/null | grep -E "duplicate rate|~" | tail -10 | sed 's/^/  /'
else
	gap "duplication — needs jscpd (npx) or lizard"
fi

# ── per-language: dead code, coverage, mutation ─────────────────────────────
hdr "language-specific"
case "$SRC" in *.go*)
	echo "go:"
	if have staticcheck
	then staticcheck -checks=U1000 ./... 2>/dev/null | head -8 | sed 's/^/    unused: /'
	else gap "go dead code — go install honnef.co/go/tools/cmd/staticcheck@latest"; fi
	if have go; then go test -cover ./... 2>&1 | grep -E 'coverage:|FAIL' | sed 's/^/    /' || true; fi
	if have metron; then
		echo "    mutation: metron (run separately: metron --axes all)"
	elif have gremlins; then
		echo "    mutation: gremlins available (gremlins unleash)"
	else
		gap "go mutation — metron (github.com/yanmxa/metron) or gremlins"
	fi ;;
esac
case "$SRC" in *.py*)
	echo "python:"
	if   have vulture; then vulture . 2>/dev/null | head -8 | sed 's/^/    dead: /'
	elif have uvx;     then uvx vulture . 2>/dev/null | head -8 | sed 's/^/    dead: /'
	else gap "python dead code — pip install vulture"; fi
	if   have radon; then radon mi -s . 2>/dev/null | head -6 | sed 's/^/    maintainability: /'
	elif have uvx;   then uvx radon mi -s . 2>/dev/null | head -6 | sed 's/^/    maintainability: /'
	else gap "python maintainability — pip install radon"; fi
	have mutmut || gap "python mutation — pip install mutmut (mutmut run)" ;;
esac
case "$SRC" in *.ts*|*.js*)
	echo "js/ts:"
	if have npx
	then npx --yes knip@latest --no-progress 2>/dev/null | head -8 | sed 's/^/    unused: /' || true
	else gap "js dead code — knip (needs npx)"; fi
	gap "js mutation — npx stryker run (@stryker-mutator/core)" ;;
esac
case "$SRC" in *.rs*)
	echo "rust:"
	if have cargo && cargo mutants --version >/dev/null 2>&1
	then echo "    mutation: cargo-mutants available (cargo mutants)"
	else gap "rust mutation — cargo install cargo-mutants"; fi ;;
esac

[ -n "$MISSING" ] && printf '\n── unmeasured ──%s\n' "$MISSING"
cat <<'EOF'

Every line above names the tool that produced it; a reading whose tool is absent
is listed as unmeasured, never as a pass. Mutation testing runs the test suite,
so it is reported as available rather than run here — start it deliberately.
EOF
