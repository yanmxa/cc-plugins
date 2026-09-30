# review

Code review, language-agnostic and read-only. **Five skills: one prerequisite, one
pipeline, three focused modes.**

```
metrics   ← run first. Deterministic: a tool computed it.
  │
review    ← the pipeline. Angles → verify → sweep. Everything below, plus
  │         altitude, efficiency and cross-file, which have no standalone mode.
  ├── defects   bugs only
  ├── excess    deletions only
  └── intent    spec only
```

The three modes are **not extra passes**. Running `review` covers them. They exist
because "any bugs?", "what can we delete?" and "does this match the issue?" are
things people ask on their own.

## The one idea underneath

**A finding is worth as much as the evidence behind it, and never more.**

| tier | backed by | who can re-derive it |
| --- | --- | --- |
| `adoptable` | a deterministic rule, or static-analysis output | anyone |
| `reference` | model reasoning | nobody |

Three things stay separate, and collapsing any two is how a review stops being
trusted:

- **severity** — how bad the consequence is *if you are right*. Not confidence:
  grade by confidence and everything becomes `minor`.
- **tier** — what backs it. Decided by evidence.
- **certainty** — the model grading its own homework. Orders findings, **never
  promotes a tier**.

`metrics` runs first because it produces only the first kind. A number settled
there is not something a later pass re-argues.

## Two gates every judged finding passes

- **Anchor** — it lands on a line the diff touched (±3), or it is dropped, not
  relocated.
- **Citation** — cite only tool-call ids you actually got results from. One that
  resolves to nothing contributes no evidence, silently.

*Proximity is not corroboration.* A lint hit on the same line says nothing about a
separate claim about that line.

## The pipeline

`angles → verify → sweep`, and **effort changes the shape, not just the count**:

| effort | shape | cap |
| --- | --- | --- |
| `low` | one diff pass, hunk-only, no verify | 8 |
| `high` | 8 angles × 6 candidates → verify | 10 |
| `max` | 10 angles × 8 candidates → verify → sweep | 15 |

Angles: correctness (3–5), **altitude** (is the fix at the right depth, or a
special case layered on shared infrastructure), **efficiency** (wasted work, and
closures keeping a whole scope alive), **reuse** (name the helper that already
exists), **cross-file** (inconsistency and incompleteness — the axis a per-file
reviewer cannot see), **conventions** (quote the exact rule and the exact line).

No angle suppresses another: two angles flagging one line for different reasons
are two findings. Every candidate with a nameable failure scenario goes through to
verification — dropping half-believed candidates early is the dominant cause of
misses.

Verify is one vote, three states: `CONFIRMED` / `PLAUSIBLE` / `REFUTED`. Keep the
first two. The sweep looks only for what is not already on the list, and returns
empty rather than padding.

## Why the work is split this way

Skills are split by **what makes a finding true**, because that decides how it is
verified — and it is also what stops them repeating each other:

| | true because | action |
| --- | --- | --- |
| `metrics` | a tool computed it | add an assertion, split a function |
| `defects` | you can name inputs that break it | fix |
| `excess` | something already does this | delete |
| `intent` | the spec or a written rule says otherwise | add, conform |

Fowler's smells split by the same test, so nothing is counted twice. Whose fix
removes code — *Duplicated Code*, *Middle Man*, *Message Chains*, *Refused
Bequest*, *Speculative Generality* — belongs to `excess`. Whose fix is a rename or
a new type — *Mysterious Name*, *Primitive Obsession*, *Data Clumps*, *Feature
Envy* — belongs to `intent`. Scope creep is code to delete, so it is `excess`'s,
even though the spec is what reveals it.

## Relationship to `go-dev`

`go-dev` is Go-specific and applies fixes (`go-optimize`, built on six subagents).
This is language-agnostic and read-only. **Nothing was removed from it** —
`go-optimize` depends on all six.

Where the two meet, this one delegates: on a Go repo with `go-dev` installed, the
correctness angles hand off to `go-bug-reviewer` and `go-security-reviewer`, and
cross-file to `go-structure-reviewer`. Want fixes applied as well as found? That is
`go-optimize`.

## Scripts

Three, where hand-work would be unreliable rather than merely tedious. The
judgement passes have none, because wrapping a judgement in a script does not make
it deterministic.

| script | why it is not left to the model |
| --- | --- |
| `metrics/scripts/measure.sh` | dispatches to established tools per language and names which one produced each reading — a metric nobody can re-derive is not a measurement |
| `intent/scripts/refs.sh` | a `CLAUDE.md` governs only files at or below its directory, so "which rules apply" is an ancestor walk per changed file |
| `review/scripts/target.sh` | validates the base and prints the one diff command all angles share, before the fan-out rather than inside it |

## Where the deterministic numbers come from

Nothing in this plugin computes a metric itself. `measure.sh` runs established
tools and prints what produced each line, through `uvx`/`npx` where it can so most
need no installing:

| metric | tool | covers |
| --- | --- | --- |
| complexity, params, length, nesting | [`lizard`](https://github.com/terryyin/lizard) | 15+ languages, one pass |
| duplication | [`jscpd`](https://github.com/kucherenko/jscpd) (fallback `lizard -Eduplicate`) | 150+ languages |
| dead code | `staticcheck -checks=U1000` · [`vulture`](https://github.com/jendrikseipp/vulture) · [`knip`](https://github.com/webpro/knip) | Go · Python · JS/TS |
| maintainability index | [`radon mi`](https://github.com/rubik/radon) | Python |
| mutation score | [`metron`](https://github.com/yanmxa/metron) / [`gremlins`](https://github.com/go-gremlins/gremlins) · [`mutmut`](https://github.com/boxed/mutmut) · [`Stryker`](https://stryker-mutator.io) · [`PIT`](https://pitest.org) · [`cargo-mutants`](https://github.com/sourcefrog/cargo-mutants) | Go · Python · JS/TS · Java · Rust |

Mutation is reported as *available*, not run — it executes the test suite. It is
also the only one that answers whether the tests hold the code up; coverage
answers "did this line run", and a suite can execute every line while asserting
nothing.

A tool that is absent makes its axis **unmeasured**, printed with the line that
installs it. An absent reading is never a pass.
