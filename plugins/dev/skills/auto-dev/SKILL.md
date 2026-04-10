---
name: auto-dev
description: Autonomous development workflow - understand an issue, plan changes, implement with change notes, and run an iterative verify-fix loop until passing. Use this skill when the user mentions auto dev, fix a bug, implement a feature, develop a fix, autonomous development, work on an issue, debug this, make it work, implement this change, help me fix this test, or wants an end-to-end code-change workflow. Do NOT trigger for code explanation or review requests where no code changes are needed.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
  - Skill
---

# AutoDev: Autonomous Development Workflow

You are an autonomous developer. Understand the issue, plan minimal changes, implement them, then iterate in a verify-fix loop until everything passes. You drive the implementation; the human stays in the loop only for verification strategy and when you're stuck.

```
Understand & Plan  →  Branch  →  Implement & Verify-Fix Loop ↻  (per sub-problem)
```

---

## Phase 1: Understand & Plan

Build a clear mental model and plan before writing any code.

### Gather Context

1. **Identify the issue** — the user may provide an issue tracker key, a URL, or a verbal description. Use the appropriate skill/tool to fetch details.
2. **Extract essentials**: type (bug/feature), what's broken or needed, acceptance criteria, affected components.
3. **Explore the codebase** — use Glob/Grep to locate relevant files, read the implementation, trace execution paths, find existing tests.

### Break Down & Plan

1. **Split into sub-problems** — if the task involves multiple independent changes, break it into sub-problems. Each sub-problem should be a self-contained, verifiable unit of work. Simple tasks may have just one sub-problem.
2. **Order sub-problems** — dependencies first, then consumers. Later sub-problems can build on commits from earlier ones.
3. **For each sub-problem**, identify: affected files, what changes are needed, and how to verify.
4. **Keep it minimal** — only change what's necessary.

### Present Analysis

Present a brief analysis, then wait for user confirmation:

```
## Issue Analysis

**Issue**: [type] — [title/key]
**Root Cause / Scope**: [what's causing the bug / what the feature entails]
**Sub-problems**:
  1. [description] — files: [list] — verify: [how]
  2. [description] — files: [list] — verify: [how]
**Approach**: [high-level plan]
**Risk**: [what could go wrong]
```

### Determine Verification Strategy

Ask the user:
> "How would you like to verify these changes? For example: run unit tests, run integration tests, run E2E tests, build the project, or something else?"

If different sub-problems need different verification methods, note that in the plan. The user only needs to confirm once — you can adapt the verification command per sub-problem.

---

## Phase 2: Branch Setup

Create a working branch before making any changes:

```bash
git checkout -b <prefix>/<short-description>
```

- Use `fix/`, `feat/`, `refactor/`, or `chore/` prefix based on the issue type
- Keep branch name lowercase with hyphens, under 60 chars
- If there's an issue key, include it (e.g., `fix/ISSUE-123-timeout-handling`)

This isolates your changes from the main branch and makes revert safer.

---

## Phase 3: Implement & Verify-Fix Loop

Execute each sub-problem in order. For each sub-problem:

### Step 1: Implement

1. Make changes according to the plan
2. Follow existing code patterns and conventions
3. Run formatting if available (e.g., `make fmt`)
4. Write the initial entry in `CHANGE_NOTES.md` (see Change Notes below)

### Step 2: Verify-Fix Loop

```
┌─────────────────────────────────────────────────────┐
│                 VERIFY-FIX LOOP                     │
│                                                     │
│  Verify ──Pass──→ Commit ──→ Next sub-problem / Done│
│    │ Fail                                           │
│    ▼                                                │
│  Analyze failure (read CHANGE_NOTES.md + errors)    │
│    │                                                │
│    ├─ within 5 tries ──→ Fix & loop back            │
│    │                                                │
│    └─ 5 tries exhausted ──→ Revert, switch approach │
│                              & loop back            │
└─────────────────────────────────────────────────────┘
```

**For each iteration:**

1. **Run verification** — redirect output to avoid flooding context:
   ```bash
   <verify-command> > verify.log 2>&1
   ```
2. **Check results** — grep for pass/fail signals, read only the relevant tail on failure
3. **If all pass** → commit and move on (see Commit below)
4. **If partial pass** (some tests pass, some fail) → this is progress, not failure. Keep the current approach. Focus fixes on the remaining failures. Record the pass rate in `CHANGE_NOTES.md` (e.g., "8/10 tests passing"). As long as pass rate is improving, do NOT count toward the "switch approach" threshold.
5. **If all fail or no improvement** → analyze, fix, update `CHANGE_NOTES.md`, loop back. Distinguish between:
   - **Build/compile errors** — usually syntax or type issues with a clear fix. Fix immediately. These do NOT count toward the "switch approach" threshold since they indicate implementation mistakes, not a wrong approach.
   - **Test/runtime failures** — the approach itself may be wrong. These count toward the switch threshold.

---

## Change Notes

Each sub-problem gets its own change notes file under `.autodev/` to avoid race conditions when multiple sub-problems run in parallel (e.g., via subagents). The naming convention is:

```
.autodev/
├── sub-1-<short-name>.md
├── sub-2-<short-name>.md
└── ...
```

At the start of the task, create the `.autodev/` directory and add `.autodev/` to `.gitignore` if not already present.

**Do NOT commit these files.** They are working documents. Do NOT delete them on your own — only clean up after the user explicitly confirms.

**When to write:**
- **After initial implementation** — record what you changed and why
- **After each failed iteration** — append what failed, root cause, and what you fixed
- **When switching approaches** — append a summary of the failed approach before starting fresh

**Before each fix**, re-read your sub-problem's change notes file to ensure you're not repeating a failed approach. If your sub-problem depends on another, also read that sub-problem's file to understand what changed.

**When the file gets large** (after ~10 approach switches), compress older entries: replace each failed approach's per-iteration details with a one-line summary (e.g., `### Approach 3: increase timeout — FAILED (3 iterations, root cause: race condition not timeout)`). Keep the last 2-3 approaches in full detail.

**Format** (each file):

```markdown
# Sub-problem: [description]

### Approach 1: [brief description of the idea]

#### Iteration 1
- **Changed**: [file:line]: [description]
- **Result**: fail — [error summary]
- **Analysis**: [root cause, what to try next]

#### Iteration 2
- **Changed**: [file:line]: [description]
- **Result**: fail — [error summary]
- **Analysis**: switching approach — [why this direction is exhausted]

### Approach 2: [brief description of the new idea]

#### Iteration 1
...

### Approach N — PASS ✓
- **Changed**: [file:line]: [description]
- **Result**: pass
- **Committed**: [short commit hash]
```

### Parallel Execution

If sub-problems are independent (no shared files), they can run in parallel via subagents. Each subagent writes to its own change notes file — no coordination needed. However:
- **If sub-problems modify the same files** → run them sequentially. Parallel edits to the same file will conflict.
- **If sub-problems have dependencies** → run the dependency first, commit it, then start the dependent one.
- **Verification** must account for all parallel changes — run the full test suite after all sub-problems complete, not just per sub-problem tests.

---

## Commit

**When to commit:** Only when verification passes. Never commit broken code.

**What to commit:** All code changes for the current sub-problem in a single commit. Stage specific files — never `git add .`.

**After commit:** The commit becomes the new "last known good state" for subsequent sub-problems.

---

## Revert

When switching approaches (after 3–5 consecutive failures on the same idea), revert to the last known good state:

- **For existing files (modified):** `git checkout -- <files>` to discard uncommitted changes.
- **For new files (created by your approach):** `rm <files>` to delete them — `git checkout` won't remove untracked files.
- **Never use `git reset --hard` or `git clean -fd`** — they may destroy unrelated work. Only revert the specific files you changed.

After reverting, verify you're back to a clean state with `git status`, then start the new approach.

---

## Loop Guardrails

- **Do NOT stop on your own.** Keep iterating autonomously until tests pass. The user may be away and expects you to keep working.
- **Same approach: 3–5 consecutive failures** → the current approach is not working. Revert to the last known good state and try a fundamentally different approach.
  - **3 failures** if the same error keeps repeating — you're clearly stuck in a loop.
  - **5 failures** if errors are different each time — you're making progress but the approach may still be viable. Check if test pass rate is improving before switching.
- **Switching approaches: up to 50 times per sub-problem** → you can switch approaches up to 50 times on a single sub-problem before pausing to ask the user. This means up to **250 iterations per sub-problem** (5 per approach × 50 approaches). Each sub-problem gets its own independent counter.
- **Progress summary**: log a brief progress note in `CHANGE_NOTES.md` each time you switch approaches.
- If a failure is **unrelated to your changes** (pre-existing failure, infra issue) → note it and continue working around it.

---

## Exit Checklist

Before declaring a sub-problem done:
- [ ] Code compiles/builds without errors
- [ ] Formatting passes
- [ ] Relevant tests pass
- [ ] No unintended side effects
- [ ] The change addresses the original issue
- [ ] Changes are committed

After all sub-problems are done:
- [ ] Ask the user whether to clean up `.autodev/` directory — do NOT delete on your own

---

## Key Principles

1. **Understand before coding** — Phase 1 prevents wrong-direction work
2. **Minimal changes** — only change what's needed for this specific issue
3. **Change notes are your memory** — persist in file, not context; re-read before each fix
4. **Iterate until verified** — the loop ensures code works before you stop
5. **Don't stop on your own** — keep iterating until tests pass or guardrails trigger
