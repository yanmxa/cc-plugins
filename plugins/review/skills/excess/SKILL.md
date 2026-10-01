---
name: excess
description: Review a diff for code that should not exist — reinvented stdlib, a dependency for a few lines, an abstraction with one implementation, a helper the repo already has, scope nobody asked for, and the smells whose fix is deletion. One line per finding: location, what to cut, what replaces it. Ends with net lines removable. Use when asked what can be deleted, whether a change is over-engineered, or for a simplify-only pass.
---

The deletion-only mode. A full `review` already covers this among its angles;
use this when the only question is what to cut.

The diff's best outcome is getting shorter. One line per finding.

`<file>:L<line>: <tag> <what>. <replacement>.`

## Tags

- `delete:` dead code, unused flexibility, speculative feature. Replaces with nothing.
- `stdlib:` hand-rolled thing the standard library ships. Name the function.
- `native:` dependency or code doing what the platform already does. Name the feature.
- `repo:` this codebase already has it. Name the file and symbol.
- `yagni:` abstraction with one implementation, config nobody sets, layer with one
  caller, parameter always passed the same value. (Fowler's *Speculative Generality*.)
- `scope:` behaviour nobody asked for.
- `shrink:` same logic, fewer lines. Show the shorter form.
- `smell:<name>` a Fowler smell whose fix removes code: *Duplicated Code*,
  *Middle Man*, *Message Chains*, *Refused Bequest*.

Smells whose fix is a rename or a new type — *Mysterious Name*, *Primitive
Obsession*, *Data Clumps* — are `intent`'s, not this pass's. Nothing gets counted
twice.

## Examples

✅ `L12-38: stdlib: 27-line email validator. "@" in string, 1 line; real validation is the confirmation mail.`
✅ `L4: native: moment.js for one format call. Intl.DateTimeFormat, 0 deps.`
✅ `repo.py:L88: yagni: AbstractRepository, one implementation. Inline until a second exists.`
✅ `cart.go:L30: repo: re-implements money rounding. internal/money.Round.`
✅ `L52-71: delete: retry wrapper around an idempotent local call. Nothing.`
✅ `L30-44: shrink: manual loop builds dict. dict(zip(keys, values)), 1 line.`

❌ "Have you considered whether all these validation rules are needed?"

## Before writing a `repo:` finding

Grep for the thing and cite the symbol you found, or drop the finding. A helper a
few files over is the most common slop and the easiest finding to get wrong.

## Rules

- **A documented repo standard wins.** Where `CONTRIBUTING` or a standards doc
  endorses what a tag would flag, suppress it.
- **Skip what tooling enforces.**
- **Never flag the one smoke test or self-check.** That is the minimum, not bloat.
- A smell is a labelled heuristic, never a hard violation.

Out of scope: correctness, security, and performance. Wasted *work* is
`review`'s Efficiency angle; this pass counts lines, not cycles.

## Score

End with `net: -<N> lines possible.`

Nothing to cut: `Lean already. Ship.` and stop.

Lists findings; does not apply them.
