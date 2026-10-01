---
name: defects
description: Hunt correctness bugs in a diff — wrong results, dropped errors, races, boundary and nil cases, security holes at trust boundaries, resource leaks, and behaviour the change removed. Every finding names concrete inputs that produce a wrong outcome, then gets adversarially verified. Use when asked whether a change is correct or safe, or for a bugs-only pass.
---

The bugs-only mode. A full `review` runs these angles alongside the others; use
this when correctness is the only question.

One rule decides whether a finding ships: **name inputs or state that produce a
wrong outcome.** No failure scenario, no finding. "This looks fragile" is not a
review comment.

## Per finding

```
<file>:<line>  <one-sentence defect>
  breaks when: <concrete inputs/state> → <wrong output, crash, or leak>
  verdict: CONFIRMED | PLAUSIBLE
```

Surface every candidate with a nameable scenario, then verify each one against
the diff and the surrounding files: `CONFIRMED` traced or reproduced,
`PLAUSIBLE` holds on reading, `REFUTED` shown false. **Keep the first two, drop
REFUTED**, and never silently upgrade a `PLAUSIBLE`.

Dropping half-believed candidates *before* verification is the dominant cause of
misses — that is what the verify step is for.

Rank most-severe first. Severity is **the consequence if you are right**, not how
sure you are; certainty is the verdict field. Grade by confidence and everything
collapses to `minor`.

A finding must anchor to a line the diff touched (±3). One that cannot be
anchored is dropped, not relocated.

## Where the bugs are

Read the diff, then read the callers. Most defects live in the seam.

- **Boundaries** — the `<` that should be `<=`, empty slice, zero, off-by-one,
  first and last iteration. If `metrics` ran, surviving `CONDITIONALS_BOUNDARY`
  mutants already point here: start there.
- **Error paths** — an error dropped, swallowed, or logged and continued. Ask
  what the caller does with it.
- **Nil and absent** — a pointer, a map miss, an interface holding a typed nil.
- **Concurrency** — shared state without a lock, a map written from two
  goroutines, a closure capturing a loop variable, a context never cancelled,
  a lock scope quietly shrunk.
- **Trust boundaries** — validated *at* the boundary, not deeper. Injection, path
  traversal, authz checked at the wrong layer, a secret logged.
- **Resources** — a `defer` that never runs, a body never closed, unbounded growth.
- **What the change removed** — a guard, a retry, a check that used to be there.
  Diffs hide deletions, and moved or extracted code is where guards get dropped.
- **Second-tier footguns** — a default evaluated once at definition, `hash()`
  non-determinism, predicate methods with side effects, setup/teardown asymmetry
  in tests, a config default flipped.

## Root cause, not symptom

Before proposing a fix, grep every caller. One guard in the shared function is a
smaller diff than a guard in each caller — and fixing only the path the diff
touches leaves the siblings broken. Whether the fix sits at the right depth at
all is `review`'s Altitude angle.

## Go repositories

With the `go-dev` plugin installed, delegate to `go-bug-reviewer` (correctness and
concurrency) and `go-security-reviewer` rather than repeating their work. They go
deeper on Go idiom. Keep the output format above.

## Boundaries

Out of scope: over-engineering (`excess`), missing requirements (`intent`),
wasted work and fix depth (`review`). Do not re-report a reading `metrics` produced.

Nothing found: `No defects found.` and stop.
