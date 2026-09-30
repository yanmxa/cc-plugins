---
name: defects
description: Hunt correctness bugs in a diff — wrong results, unhandled errors, races, boundary and nil cases, security holes at trust boundaries, resource leaks. Every finding must name concrete inputs that produce a wrong outcome, or it does not ship. Use when reviewing a diff, branch or PR for defects, or when asked whether a change is correct or safe. Does not hunt complexity or style; those are separate passes.
---

One rule decides whether a finding ships: **name inputs or state that produce a
wrong outcome.** No failure scenario, no finding. "This looks fragile" is not a
review comment.

## Per finding

```
<file>:<line>  <one-sentence defect>
  breaks when: <concrete inputs/state> → <wrong output, crash, or leak>
  verdict: CONFIRMED | PLAUSIBLE
```

`CONFIRMED` means you traced it or ran it. `PLAUSIBLE` means the scenario holds
on reading but you could not verify. Never silently upgrade. If a repo has
`ReportFindings`, use it and do not also print the list.

Rank most-severe first. Severity is **consequence if you are right**, not how
sure you are — certainty is the verdict field.

## Where the bugs actually are

Read the diff, then read the callers. Most defects are in the seam, not the hunk.

- **Boundaries** — the `<` that should be `<=`, empty slice, zero, off-by-one,
  first and last iteration. If metrics ran, surviving `CONDITIONALS_BOUNDARY`
  mutants already point at these: start there.
- **Error paths** — a returned error dropped, swallowed, or logged and continued.
  Ask what the caller does with it.
- **Nil and absent** — a pointer, a map miss, an interface holding a typed nil.
- **Concurrency** — shared state without a lock, a map written from two
  goroutines, a closure capturing a loop variable, a context never cancelled.
- **Trust boundaries** — anything crossing one gets validated there, not deeper.
  Injection, path traversal, authz checked at the wrong layer, a secret logged.
- **Resources** — a `defer` that never runs, a body never closed, unbounded
  growth.
- **The change removed behaviour** — a guard, a retry, a check that used to be
  there. Diffs hide deletions.

## Root cause, not symptom

Before proposing a fix, grep every caller of the function. One guard in the
shared function is a smaller diff than a guard in each caller — and fixing only
the path the diff touches leaves the siblings broken.

## Go repositories

If the `go-dev` plugin is installed, delegate to `go-bug-reviewer` (correctness
and concurrency) and `go-security-reviewer` rather than repeating their work
here. They go deeper on Go idiom than this pass. Keep the output format below.

## Boundaries

Out of scope: over-engineering, naming, style, missing requirements. Route those
to excess and intent. Do not flag a measured reading that
metrics already reported.

Nothing found: say `No defects found.` and stop. Padding a clean review with
speculation is how reviews stop being read.
