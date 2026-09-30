---
name: metrics
description: Settle by measurement what a review would otherwise argue about — mutation score, cognitive complexity and delta, dead and duplicated code, CRAP ranking — by running metron, the test suite and the linter. Use FIRST in any code review, and whenever asked whether tests actually hold the code up, how risky a function is, or which part of a change to look at first. Produces readings against reference ranges, never opinions.
---

Run first. Every question a tool can settle must not reach a judgement pass.

Never estimate a metric. Never describe one you did not run. A reading you could
not take reports as unmeasured, with the reason — an absent number is not a pass.

## Run

```bash
metron --since <base> --axes complexity,graph --format json   # ~1s
metron --since <base> --axes all --budget 10m --format json   # adds mutation: runs the suite
```

No metron, or not Go: fall back to what the repo has — `go test -cover`,
`golangci-lint run`, whatever CI runs — and say which axes went unmeasured.

`--all` instead of `--since` reviews existing code. It answers strictly less: no
`cognitive Δ`, and the bypassed-wrapper and unprecedented-dependency checks do
not run.

## Read

`measures` carry `status` (`ok`/`warn`/`fail`/`unmeasured`) and the range.
`observations` carry the finding; **`detail` on a mutation finding is the
assertion to add**. `diagnostics` holds cyclomatic, fan-out, nesting, CRAP and
the raw mutant tally.

## Report

```
mutation score 36% (≥70) · strength 36% · reach 100%   → tests run it, assert nothing
cognitive Δ    +9  (=0)  RangeArgs                     → got worse, not extracted
redundant      1   (=0)  1 unreachable
CRAP 54  cart.go:15 Total   ← highest; complexity alone passed it
```

Then, in CRAP order, the findings with their `detail` verbatim. CRAP first is the
point: a function complexity cleared but tests do not pin is the most likely
place a change breaks something silently.

## Hand off

Name what you settled, so later passes skip it: "mutation and complexity
measured; graph unmeasured (no index)". A judgement pass re-arguing a measured
number is the redundancy this pass exists to remove.

Never edit thresholds, delete tests, or add suppressions to move a reading. If a
range is wrong for the repo, say so and leave it.
