---
name: excess
description: Review a diff for code that should not exist — reinvented stdlib, a new dependency for a few lines, an abstraction with one implementation, a helper the repo already has, scope the spec never asked for, and the Fowler smells whose fix is deletion or merging. One line per finding: location, what to cut, what replaces it. Ends with net lines removable. Use when asked what can be deleted, whether a change is over-engineered, or for a simplify pass.
---

The diff's best outcome is getting shorter. One line per finding.

`<file>:L<line>: <tag> <what>. <replacement>.`

## Tags

- `delete:` dead code, unused flexibility, speculative feature. Replaces with nothing.
- `stdlib:` hand-rolled thing the standard library ships. Name the function.
- `native:` dependency or code doing what the platform already does. Name the feature.
- `repo:` this codebase already has it. Name the file and symbol — this is the
  most common kind and the easiest to miss.
- `yagni:` abstraction with one implementation, config nobody sets, layer with
  one caller, parameter always passed the same value.
- `scope:` behaviour the spec did not ask for.
- `shrink:` same logic, fewer lines. Show the shorter form.
- `smell:<name>` a Fowler smell whose fix is removal or merging: Duplicated Code,
  Middle Man, Message Chains, Repeated Switches, Refused Bequest, Data Clumps,
  Primitive Obsession, Feature Envy, Divergent Change, Shotgun Surgery.

Speculative Generality is `yagni`, not a smell — same finding, one tag.

## Examples

✅ `L12-38: stdlib: 27-line email validator. "@" in string, 1 line; real validation is the confirmation mail.`
✅ `L4: native: moment.js for one format call. Intl.DateTimeFormat, 0 deps.`
✅ `repo.py:L88: yagni: AbstractRepository, one implementation. Inline until a second exists.`
✅ `cart.go:L30: repo: re-implements money rounding. internal/money.Round.`
✅ `L52-71: delete: retry wrapper around an idempotent local call. Nothing.`
✅ `L30-44: shrink: manual loop builds dict. dict(zip(keys, values)), 1 line.`

❌ "Have you considered whether all these validation rules are needed?"

## Before writing a `repo:` finding

Grep for the thing. A helper a few files over is the most common slop and the
easiest finding to get wrong — cite the symbol you found, or drop the finding.

## Rules that bind this pass

- **A documented repo standard wins.** Where CONTRIBUTING or a standards doc
  endorses what a tag would flag, suppress it.
- **Skip what tooling enforces.** The linter's job is not yours.
- **Never flag the one smoke test or self-check.** That is the minimum, not bloat.
- Judgement calls are labelled as such. A smell is a heuristic, never a violation.

## Score

End with `net: -<N> lines possible.`

Nothing to cut: `Lean already. Ship.` and stop.

Lists findings; does not apply them.
