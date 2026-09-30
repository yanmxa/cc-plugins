---
name: review
description: Full code review of a diff, branch or PR — correctness, altitude, efficiency, reuse, cross-file consistency and conventions — as independent finder angles, then adversarial verification, then a sweep for what the first pass missed. Grades every finding by the evidence behind it, never by how sure the model says it is. Use when asked to review a change, a PR, a branch, or work in progress.
---

Findings are graded by **evidence**, never by conviction. Run `metrics` first:
what a tool settles must not be argued here.

## 0 — Pin the target

```bash
git rev-parse <base>                              # must resolve
git diff <base>...HEAD --stat                     # must be non-empty
git diff @{upstream}...HEAD; git diff HEAD        # committed + uncommitted
```

Three-dot, so the comparison is against the merge-base. A bad ref or empty diff
fails here, not inside a fan-out. No base given: ask.

## Effort sets the architecture, not just the count

| effort | shape | cap |
|---|---|---|
| `low` | one diff pass, hunk-only, no verify, no subagents | 8 |
| `high` | 8 angles × 6 candidates → verify | 10 |
| `max` | 10 angles × 8 candidates → verify → sweep | 15 |

At `low`, flag only what is visible in the hunk: inverted condition, off-by-one,
nil deref where adjacent lines show the value can be absent, removed guard,
falsy-zero check, missing `await`, wrong-variable copy-paste, error swallowed in
a catch that should propagate. **Not** style, naming, perf, or missing tests.

`high` and above are **recall-biased**: catching a real bug matters more than
avoiding a false positive, because verification comes later. Err on surfacing.

## 1 — Angles (independent, parallel)

Each angle returns up to N candidates with `file`, `line`, one-line `summary`,
and a concrete `failure_scenario`. For cleanup angles the scenario states the
**cost** — what is duplicated, wasted, or harder to maintain.

**Correctness** (3 angles at `high`, 5 at `max`) — boundaries and off-by-one,
error paths dropped or swallowed, nil and absent, concurrency (shared state,
loop-variable capture, context never cancelled), trust boundaries (injection,
path traversal, authz at the wrong layer, secret logged), resource leaks, and
behaviour the change **removed**.

**Altitude** — is each change fixing the root cause at the right depth, or
patching a symptom? Special cases layered onto shared infrastructure mean the
fix is not deep enough. Prefer the simpler, more general change to the
underlying mechanism, and **name that change**.

**Efficiency** — redundant computation or repeated I/O, independent operations
run sequentially, blocking work added to startup or a hot path. Also long-lived
objects built from closures: they keep the whole enclosing scope alive for the
object's lifetime, which leaks when that scope holds large values — prefer a
struct copying only the fields it needs. Name the cheaper alternative.

**Reuse** — new code re-implementing what the codebase already has. Grep the
shared and utility modules and the files adjacent to the change, and name the
existing helper to call instead.

**Cross-file** — the axis a per-file reviewer cannot see, because the file that
introduces something looks finished on its own:
- *Inconsistency* — a caller not updated with its callee; a contract altered on
  one side only (signature, return shape, error type, config key); a new path
  that bypasses something the codebase relies on.
- *Incompleteness* — something introduced that nothing uses; or a place that
  clearly should have adopted it and did not.

**Conventions** — the `CLAUDE.md` / `AGENTS.md` files governing the changed code:
user-level, repo root, and any in a directory that is an ancestor of a changed
file. Only flag a violation you can **quote the exact rule and the exact line**
for. Name the file. Nothing applies: return nothing.

Two rules bind this phase:

- **No angle suppresses another.** Two angles flagging one line for different
  reasons are two candidates.
- **Every candidate with a nameable failure scenario goes through.** A finder
  that quietly drops half-believed candidates bypasses verification, and that is
  the dominant cause of misses.

## 2 — Verify (one vote, three states)

Dedup candidates pointing at the same line and mechanism, keeping the one with
the most concrete failure scenario. Then one verifier per candidate, given the
diff, the relevant files, and the candidate, returning exactly one of:

`CONFIRMED` traced or reproduced · `PLAUSIBLE` holds on reading, unverified ·
`REFUTED` shown false.

**Keep CONFIRMED and PLAUSIBLE. Drop REFUTED.** Never silently upgrade a
`PLAUSIBLE`.

## 3 — Sweep (at `max`)

One fresh finder, holding the verified list, looking **only** for what is not on
it. Do not re-derive or re-confirm anything already there. Aim at what first
passes miss: moved or extracted code that dropped a guard; dataclass default
evaluated once; `hash()` non-determinism; a lock scope quietly shrunk; predicate
methods with side effects; setup/teardown asymmetry in tests; a config default
flipped. Nothing new: return empty. **Do not pad.**

## 4 — Grade, then report

Three things stay separate, and collapsing any two is how a review stops being
trusted:

| | what it is | who decides |
|---|---|---|
| **severity** `blocker\|major\|minor\|nit` | how bad the consequence is **if you are right** | the consequence |
| **tier** `adoptable\|reference` | what backs it: a deterministic rule or static-analysis output → `adoptable`; model reasoning alone → `reference` | the evidence |
| **certainty** `certain\|likely\|unsure` | the model grading its own homework | the model |

**Certainty never promotes a tier.** Severity is consequence, not confidence —
grade it by confidence and everything becomes `minor`.

Two gates before a finding ships:

- **Anchor** — it must land on a line the diff actually touched (±3). A finding
  that cannot be anchored is dropped, not relocated.
- **Citation** — cite only tool-call ids you actually received results from. An
  id that resolves to nothing, or to a tool whose output is not machine-checkable,
  contributes no evidence. It is dropped silently, not rewarded.

*Proximity is not corroboration.* A lint hit on the same line says nothing about
whether a separate claim about that line is true.

Report most-severe first, grouped by severity rather than by tier — the reader's
first question is whether this blocks a merge, not what backed the claim. Print
the tier beside each finding, and the certainty only on `reference` ones: beside a
compiler diagnostic it reads as doubt about a fact.

Angles are a way of finding things, not a way of organising the report. Do **not**
present one section per angle, and do not rerank a spec or convention finding
against a correctness one — severity ordering is within a kind, never across
kinds that mean different things.

Use `ReportFindings` where it exists, and then do not also print the list. Re-reviewing the same branch: dedup against what was already
reported so a second run does not restate the first.

Nothing survives: `No findings.` Padding a clean review is how reviews stop being
read.

## Boundaries

Lists findings. Applying them is a separate request. Skip what tooling enforces,
and skip what `metrics` measured.

Go repo with `go-dev` installed: delegate the correctness angles to
`go-bug-reviewer` and `go-security-reviewer`, and cross-file to
`go-structure-reviewer`. Review *and* fixes applied is `go-optimize`, not this.
