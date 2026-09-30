---
name: review
description: Run a full code review of a diff, branch or PR in four ordered passes — metrics, defects, excess, intent — and report them without merging. Use when asked to review a change, a PR, a branch, or work in progress, or for "full review" and "review since X". Runs measurement first so later passes never re-argue a number a tool already settled.
---

Four passes, in order. The order is the point: each one is told what the
previous settled and must not re-report it.

| # | pass | a finding is true because | action | metric |
|---|------|--------------------------|--------|--------|
| 1 | `metrics` | a tool computed it | add assertion, split function | readings vs ranges |
| 2 | `defects` | you can name inputs that break it | fix | failure scenario |
| 3 | `excess` | something already does this | delete | net lines |
| 4 | `intent` | the spec or a standard says otherwise | add, conform | the quoted line |

## Pin the target first

```bash
git rev-parse <base>          # must resolve
git diff <base>...HEAD --stat # must be non-empty
git log <base>..HEAD --oneline
```

Three-dot, so the comparison is against the merge-base. A bad ref or an empty
diff fails here, not inside four passes. No base given: ask, do not guess.

## Then run the passes

1. **`metrics`** — cheap and objective. Removes questions from every later pass.
2. **`defects`** — pass it the surviving mutants from step 1; they point at the
   boundaries.
3. **`excess`** — pass it the complexity and duplication readings.
4. **`intent`** — pass it what the graph axis already settled about conventions.

Independent passes may run as parallel sub-agents, but `metrics` must finish
first. Give each sub-agent the diff command, the commit list, and one line naming
what earlier passes settled.

**Go repository with the `go-dev` plugin installed**: delegate `defects` to
`go-bug-reviewer` and `go-security-reviewer`, and the architecture half of
`intent` to `go-structure-reviewer`. They go deeper on Go than a generic pass.
Want review *and* fixes applied? That is `go-optimize`, not this.

## Report

One heading per pass, in order, verbatim or lightly cleaned.

Do **not** merge or rerank across headings. A change can be measurably
well-tested, defect-free, lean — and still the wrong change. Separate headings
are what stop one pass masking another.

Close with one line per pass: findings count and the worst within that pass. No
single winner across passes.

Every pass clean: `Ship it.` and stop.

## Rules

- Never edit a threshold, delete a test, or add a suppression to make a reading
  pass. A gate only works if the thing being gated cannot move it.
- Skip anything tooling already enforces.
- Lists findings. Applying them is a separate request.
