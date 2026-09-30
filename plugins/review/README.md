# review

Code review in four passes, language-agnostic, read-only.

The boundary between passes is **what makes a finding true**, because that
decides how it gets verified — and it is also what keeps the passes from
repeating each other.

| pass | true because | action | metric |
| --- | --- | --- | --- |
| `metrics` | a tool computed it | add assertion, split function | readings vs ranges |
| `defects` | you can name inputs that break it | fix | failure scenario per finding |
| `excess` | something already does this | delete | net lines removable |
| `intent` | the spec or a standard says otherwise | add, conform | the quoted line |

`review` runs all four in that order and reports them under separate headings.
Each pass is told what the previous settled and must not re-report it. That
ordering is the whole anti-redundancy mechanism: **measure what can be measured,
then judge only what is left.**

## Use

```
/review:review main      # all four passes against the merge-base
/review:metrics          # just the measured pass
/review:excess           # just "what can we delete"
```

Each pass is independently useful. `metrics` before a refactor, `excess` on a PR
that grew, `intent` when a change drifted from its issue.

## Why four

- Fowler's *Speculative Generality*, *Middle Man* and *Duplicated Code* all end
  in deletion, so they are tags inside `excess`, not a pass of their own.
- "Does it fit the repo" splits. The part a tool settles — dead code, duplication,
  bypassed wrappers, dependency direction — belongs to `metrics`. Only the
  unwritten remainder reaches `intent`.
- Scope creep is code to delete, so it lives in `excess` even though the spec is
  what reveals it. Missing requirements live in `intent`. Split by action, not by
  evidence.

## Why not fewer

Each pass needs a mindset that suppresses the others. Hunting bugs finds no
excess; hunting deletions finds no missing requirement; both ignore a number a
tool already produced. Merge any two and the quieter one is reliably lost.

## Relationship to `go-dev`

`go-dev` is a Go-specific review-and-fix pipeline (`go-optimize`) built on six
subagents. This plugin is language-agnostic and read-only.

Where they meet, this one delegates: on a Go repository with `go-dev` installed,
`defects` hands off to `go-bug-reviewer` and `go-security-reviewer`, and the
architecture half of `intent` to `go-structure-reviewer`. Want fixes applied as
well as found? Use `go-optimize`.

## `metrics` needs a measuring tool

It prefers [metron](https://github.com/yanmxa/metron) — mutation score,
cognitive complexity and its delta, dead and duplicated code, CRAP ranking.
Without it the pass falls back to whatever the repo has (coverage, linters, CI)
and reports the axes it could not measure as unmeasured. An absent reading is
never a pass.
