---
argument-hint: <task-description> - describe what code to write, modify, or refactor
description: Delegate code writing to OpenAI Codex CLI (GPT-5.1-Codex-Max), let Codex implement freely while Claude Code handles planning and validation
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - AskUserQuestion
---

Delegate code writing task to OpenAI Codex CLI. Claude Code provides context and goals, Codex decides the best implementation approach.

## Task

$ARGUMENTS

## Workflow

```
Claude Code                               Codex (Code Writing ONLY)
+----------------------------------+     +-------------------------+
| 1. Understand requirements       |     |                         |
| 2. Break into small subtasks     |     |                         |
|                                  |     |                         |
| +--------- Loop per subtask --------+  |                         |
| | 3. Provide context & goal    |----->| 4. Write/modify code    |
| | 5. Run & validate            |<-----|    (NO running/testing) |
| |    ↓ if issues found         |      |                         |
| | 6. Resume with error context |----->| 7. Fix code             |
| +-------------------------------+      |                         |
|                                  |     |                         |
| 8. Report final results          |     |                         |
+----------------------------------+     +-------------------------+
```

## Important Rules

**Codex responsibilities (code only):**
- Write new code
- Modify existing code
- Refactor code
- DO NOT run scripts, tests, or commands

**Claude Code responsibilities:**
- Plan and break down tasks into small subtasks
- Provide context to Codex (one subtask at a time)
- Run and validate code after Codex finishes
- Resume Codex session with error context if fixes needed
- Iterate until subtask is complete, then move to next

**Task sizing:**
- Break large tasks into smaller, focused subtasks
- One Codex call = one focused coding task
- Easier to validate and iterate

## Step 1: Decide Execution Strategy

Evaluate based on conversation history, task complexity, and session state:

**Resume previous session when:**
- This is a follow-up to a recent Codex task in the same conversation
- User wants to iterate, fix, or extend previous Codex work
- Task continues work on the same files/feature

**Start new session when:**
- Completely new task or different feature
- No relevant previous session exists
- User explicitly wants fresh start

**Skip context gathering when:**
- Simple, self-contained task
- All necessary context already in conversation history
- User provides complete specifications

**Gather context when:**
- Complex multi-file changes
- Task requires understanding existing codebase
- First time working in this directory/project

If context needed:
```bash
# Project instructions
cat CLAUDE.md 2>/dev/null | head -100 || cat README.md 2>/dev/null | head -50 || true

# Git status
git status --short 2>/dev/null || true
```

## Step 2: Build Task Prompt for Codex

**Key Principle: Describe WHAT, not HOW. Let Codex decide the best implementation.**

**Always include in prompt:**
- **Goal**: What needs to be accomplished (one focused subtask)
- **Context**: Relevant existing code (if modifying)
- **Constraints**: Only hard requirements (e.g., must use specific API, compatibility needs)
- **Scope**: "Only write/modify code. Do not run or test."

Optionally:
- **Examples**: Reference code for style/patterns (not prescriptive)

**DO NOT:**
- Dictate implementation details
- Provide step-by-step instructions for how to code it
- Restrict Codex to a specific approach
- Over-specify the solution structure

**Good prompt example:**
```
Goal: Add caching to database query functions to reduce redundant calls.

Context: The query functions are in src/db/queries.py. Here's the current pattern:
[paste relevant code snippet]

Constraints:
- Must be compatible with async functions
- Cache should be invalidatable

Scope: Only write the code. Do not run or test it.
```

**Bad prompt example (too prescriptive):**
```
Create a decorator called @cache that:
1. Uses functools.lru_cache
2. Has a TTL parameter
3. Stores results in a dict...
```

## Step 3: Execute Codex

**Default model: `gpt-5.1-codex-max`**

**New session:**
```bash
codex exec --full-auto --sandbox workspace-write --skip-git-repo-check -C "$(pwd)" "{task_prompt}"
```

**Resume previous session:**
```bash
echo "{follow_up_instructions}" | codex exec --skip-git-repo-check resume --last
```

**With additional directory access (when needed):**
```bash
codex exec --full-auto --sandbox workspace-write --skip-git-repo-check -C "$(pwd)" --add-dir "{additional_directory}" "{task_prompt}"
```

**Available models (`-m` flag):**
- `gpt-5.1-codex-max` (default, highest capability)
- `gpt-5-codex` (standard coding model)
- `gpt-5` (general purpose)
- `o3` (reasoning focused)

## Step 4: Review & Validate

After Codex completes:

**Review changes:**
```bash
git diff --stat
git diff
```

**Validate based on task type:**
- Scripts: Run directly to check functionality
- Functions/modules: Quick import or usage test
- Existing tests: Run relevant test suite if available
- Syntax: Lint or compile to catch errors

## Step 5: Handle Issues

**If validation fails or code has problems, always try to resume first to preserve session context:**

**Primary approach - Resume Codex with error context:**
```bash
echo "The code has this issue:

{error_output}

Please fix. Only modify code, do not run or test." | codex exec --skip-git-repo-check resume --last
```

Then validate again. Repeat resume cycle if needed.

**Fallback options (if resume not suitable):**
- Claude Code fixes trivial issues directly (typos, imports)
- Ask user how to proceed for complex problems

## Step 6: Report Results

Summarize to user:
- What Codex generated/modified
- Files changed
- Validation results
- Any remaining issues
- Note: Session can be continued with another `/codex/code` call

## Command Reference

| Scenario | Command |
|----------|---------|
| Standard code writing | `codex exec --full-auto --sandbox workspace-write --skip-git-repo-check -C "$(pwd)" "{prompt}"` |
| With extra directory | Add `--add-dir "{dir}"` |
| Resume last session | `echo "{prompt}" \| codex exec --skip-git-repo-check resume --last` |
| Use specific model | Add `-m gpt-5-codex` or `-m o3` |
| Read-only analysis | Replace `--sandbox workspace-write` with `--sandbox read-only` |

## Error Handling

**Codex command fails:**
```bash
codex --version  # Verify Codex is available
```
If fails, inform user to check Codex installation/authentication.

**Session resume fails:**
- Start fresh session with full context
