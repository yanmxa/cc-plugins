---
name: metrics
description: Settle by measurement what a review would otherwise argue about — cyclomatic complexity per function, duplication, dead code, coverage, and mutation score — by running established tools rather than estimating. Every reading names the tool that produced it. Use FIRST in any code review, and whenever asked how complex, duplicated or actually-tested a codebase is.
---

Run first. Anything a tool can settle must not reach a judgement pass.

**Nothing here is computed by hand or by eye.** A number is only re-derivable if
you know which tool produced it, so every reading names its tool. That provenance
is the difference between a measurement and an assertion — and it is why these
findings can be trusted without argument while a reasoned one cannot.

```bash
${CLAUDE_SKILL_DIR}/scripts/measure.sh              # whole tree
${CLAUDE_SKILL_DIR}/scripts/measure.sh main         # changed files only
CCN=20 ${CLAUDE_SKILL_DIR}/scripts/measure.sh main  # raise the threshold
```

It dispatches to whatever is available and lists the rest as **unmeasured**, with
the install line. It runs tools through `uvx`/`npx` where it can, so most of them
need no installing.

## What computes what

| metric | tool | covers |
| --- | --- | --- |
| cyclomatic complexity, params, length, nesting | [`lizard`](https://github.com/terryyin/lizard) | 15+ languages, one pass |
| duplication | [`jscpd`](https://github.com/kucherenko/jscpd) | 150+ languages |
| — fallback | `lizard -Eduplicate` | same 15+ |
| dead code | `staticcheck -checks=U1000` · [`vulture`](https://github.com/jendrikseipp/vulture) · [`knip`](https://github.com/webpro/knip) | Go · Python · JS/TS |
| maintainability index | [`radon mi`](https://github.com/rubik/radon) | Python |
| coverage | the language's own runner | all |
| mutation score | [`metron`](https://github.com/yanmxa/metron) or [`gremlins`](https://github.com/go-gremlins/gremlins) · [`mutmut`](https://github.com/boxed/mutmut) · [`Stryker`](https://stryker-mutator.io) · [`PIT`](https://pitest.org) · [`cargo-mutants`](https://github.com/sourcefrog/cargo-mutants) | Go · Python · JS/TS · Java · Rust |

Mutation is **reported as available, not run** — it executes the test suite and
costs minutes. Start it deliberately:

```bash
metron --since main --axes all --budget 10m --format json   # Go
npx stryker run                                             # JS/TS
mutmut run                                                  # Python
```

Mutation score is the only one of these that answers *whether the tests hold the
code up*. Coverage answers "did this line run", which is a different question —
a suite can execute every line and assert nothing.

## Read it

Highest complexity first, then the duplication pairs, then dead code. Where a
mutation score exists, rank by **complexity weighted by how poorly tested the
function is** — a middling function nothing pins is more dangerous than a gnarly
one with a suite around it. That is
[CRAP](https://www.artima.com/weblogs/viewpost.jsp?thread=210575); `metron`
computes it directly.

## Hand off

Name what you settled so later passes skip it: "complexity and duplication
measured with lizard and jscpd; mutation unmeasured (no runner installed)."

A judgement pass re-arguing a measured number is the redundancy this pass exists
to remove. Equally: **an unmeasured axis is never a pass.** Say which tool is
missing and what installs it.

Never raise a threshold, delete a test, or add a suppression to move a reading.
If a threshold is wrong for the repo, say so and leave it.
