---
name: intent
description: Check a diff against what it was supposed to do — the issue or spec it came from, and this repo's documented standards. Finds requirements missing or half-done, requirements implemented wrongly, and conventions broken. Every finding quotes the spec line or standard it violates. Use when reviewing a PR or branch against its issue, or when asked whether a change actually does what was asked. Correctness and complexity are separate passes.
---

A change can be correct, lean, and still the wrong change. This pass asks only:
does it do what it was supposed to, the way this repo does things.

Every finding **quotes the line it violates** — a spec sentence or a standard.
No quotable reference, no finding.

## 1. Find the reference

**Spec**, in order: issue refs in the commit messages (`#123`, `Closes #45`) →
a path the user passed → a spec under `docs/`, `specs/` or `.scratch/` matching
the branch → ask. None exists: report `no spec available` and do the standards
half only. Never invent the requirement you wish had been written.

**Standards**: `CONTRIBUTING.md`, `CODING_STANDARDS.md`, `AGENTS.md`,
`CLAUDE.md`, a style doc. Plus the conventions the code itself shows —
neighbouring functions in the same package are the standard when nothing is
written down.

## 2. Report

```
## Spec
missing   <spec line quoted> — not implemented / only <what exists>
wrong     <spec line quoted> — implemented as <X>, spec says <Y>

## Standards
<file>:<line>  <rule quoted, with its source file> — <how the diff breaks it>
```

Keep the two headings separate and do **not** rerank across them. A change that
follows every convention while implementing the wrong thing passes one and fails
the other; merging them lets either mask the other.

## 3. Rules

- **Hard violation vs judgement call** — label each. A documented rule breached
  is hard. An unwritten convention inferred from neighbours is a judgement call.
- **Scope creep goes to excess**, not here. Behaviour nobody asked for is
  code to delete; this pass reports what is *missing or wrong*.
- **Skip what tooling enforces**, and skip anything metrics already
  measured — the graph axis settles bypassed wrappers, unprecedented
  dependencies and convention drift deterministically. Do not re-argue those.
- A requirement that looks done: check it, do not assume. "Looks implemented but
  is wrong" is the most valuable finding this pass produces and the easiest to
  skip past.

## Close

One line per heading: findings count, and the worst within that heading. No
single winner across headings.

Nothing found, spec present: `Implements the spec; follows the standards.`
