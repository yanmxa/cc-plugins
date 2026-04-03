# {{PROJECT_NAME}} — Autonomous Research Program

This is an autonomous research program. An AI agent follows these instructions to conduct
experiments, iterating on code to optimize a target metric — without human intervention.

## Setup

To set up a new experiment run, work with the user to:

1. **Agree on a run tag**: propose a tag based on today's date (e.g. `mar22`). The branch `autoresearch/<tag>` must not already exist — this is a fresh run.
2. **Create the branch**: `git checkout -b autoresearch/<tag>` from current main branch.
3. **Read the in-scope files**: Read these files for full context:
{{IN_SCOPE_FILES}}
4. **Verify prerequisites**: {{VERIFY_PREREQUISITES}}
5. **Initialize results.tsv**: Create `results.tsv` with just the header row. The baseline will be recorded after the first run.
6. **Confirm and go**: Confirm setup looks good.

Once you get confirmation, kick off the experimentation.

## Experimentation

{{EXPERIMENT_CONTEXT}}

**What you CAN do:**
{{CAN_DO_LIST}}

**What you CANNOT do:**
{{CANNOT_DO_LIST}}

**Non-interactive principle**: You are running unattended — the human may be asleep or away. Every command you run must complete without human input. Specifically:
- Do NOT use interactive commands (`git add -i`, `git rebase -i`, `python -i`, `less`, `vim`, etc.)
- Do NOT run commands that prompt for confirmation (`y/n`). Use non-interactive flags (e.g. `yes |`, `-y`, `--yes`, `--no-input`, `--force`) where needed.
- Do NOT use `tee` or let output stream into your context — always redirect to a log file.
- Do NOT start background services that require manual setup or teardown.
- If a command might hang waiting for input (e.g. a download prompt, a license agreement), find the non-interactive alternative or skip it.
- All git operations must be non-interactive: use `git commit -m "..."` (never `git commit` alone which opens an editor), use `git merge --no-edit`, etc.

If you discover during the loop that a command requires interaction, treat it as a crash — log it, revert, and find an alternative approach.

**The goal is simple: get the {{METRIC_DIRECTION}} {{METRIC_NAME}}.** {{GOAL_CONTEXT}}

**{{RESOURCE_CONSTRAINT_NAME}}** is a soft constraint. Some increase is acceptable for meaningful {{METRIC_NAME}} gains, but it should not blow up dramatically.

**Simplicity criterion**: All else being equal, simpler is better. A small improvement that adds ugly complexity is not worth it. Conversely, removing something and getting equal or better results is a great outcome — that's a simplification win. When evaluating whether to keep a change, weigh the complexity cost against the improvement magnitude. A {{NOISE_THRESHOLD}} {{METRIC_NAME}} improvement that adds 20 lines of hacky code? Probably not worth it. A {{NOISE_THRESHOLD}} {{METRIC_NAME}} improvement from deleting code? Definitely keep. An improvement of ~0 but much simpler code? Keep.

**Controlled variable principle**: Each experiment should change **one variable at a time** whenever possible. This way, when the result improves or worsens, you can accurately attribute the cause. Exception: when two variables are logically coupled (e.g., changing model depth requires adjusting learning rate), they may be changed together — but note this explicitly in the experiment description. If a multi-variable experiment succeeds, consider running ablation experiments next to verify each change's independent contribution.

**The first run**: Your very first run should always be to establish the baseline, so you will run the experiment script as is.

## Output format

Once the experiment finishes it prints a summary. You can extract the key metrics from the log file:

```
{{GREP_PATTERN}}
```

{{OUTPUT_FORMAT_NOTES}}

## Logging results

When an experiment is done, log it to `results.tsv` (tab-separated, NOT comma-separated — commas break in descriptions).

The TSV has a header row and these columns:

```
{{TSV_HEADER}}
```

{{TSV_COLUMN_DESCRIPTIONS}}

Example:

```
{{TSV_EXAMPLE}}
```

## The experiment loop

The experiment runs on a dedicated branch (e.g. `autoresearch/<tag>`).

LOOP FOREVER:

1. Look at the git state: the current branch/commit we're on
2. Tune {{MODIFIABLE_FILES}} with an experimental idea by directly hacking the code.
3. git commit
4. Run the experiment: `{{RUN_COMMAND}} > run.log 2>&1` (redirect everything — do NOT use tee or let output flood your context)
5. Read out the results: `{{RESULT_GREP_COMMAND}}`
6. If the grep output is empty, the run crashed. Run `tail -n 50 run.log` to read the stack trace and attempt a fix. If you can't get things to work after more than a few attempts, give up.
7. Record the results in the tsv (NOTE: do not commit the results.tsv file, leave it untracked by git)
8. If {{METRIC_NAME}} improved ({{METRIC_IMPROVED_CONDITION}}), you "advance" the branch, keeping the git commit
9. If {{METRIC_NAME}} is equal or worse, you git reset back to where you started

The idea is that you are a completely autonomous researcher trying things out. If they work, keep. If they don't, discard. And you're advancing the branch so that you can iterate. If you feel like you're getting stuck in some way, you can rewind but you should probably do this very very sparingly (if ever).

### Noise awareness

Not every numerical improvement is a real improvement — short experiments have inherent randomness. Use these thresholds:

- {{METRIC_NAME}} improvement > {{SIGNIFICANT_THRESHOLD}}: **significant improvement**, definitely keep
- {{METRIC_NAME}} improvement {{MARGINAL_RANGE}}: **marginal improvement**, keep but mark as "marginal" in the description
- {{METRIC_NAME}} improvement < {{NOISE_THRESHOLD}}: **likely noise**, discard unless the code is simpler

If you accumulate 3+ marginal improvements in a row without a significant one, consider re-running the baseline to recalibrate — the baseline measurement itself may have been noisy.

### Git safety

When discarding an experiment, use:
```bash
git reset --hard HEAD~1
```

Before discarding, verify that `results.tsv` is untracked:
```bash
git status --porcelain results.tsv  # should show ?? results.tsv
```

Never use `git clean` — it would delete results.tsv, run.log, and notes.md.

### Timeout

Each experiment should take approximately {{TIME_BUDGET}} (+ startup/eval overhead). If a run exceeds {{TIMEOUT_LIMIT}}, kill it and treat it as a failure (discard and revert).

Use timeout to enforce this:
```bash
timeout {{TIMEOUT_SECONDS}} {{RUN_COMMAND}} > run.log 2>&1
```

If the exit code is 124 (killed by timeout), log as crash with description "timeout after {{TIMEOUT_LIMIT}}".

### Crashes

If a run crashes (OOM, a bug, etc.), use your judgment: If it's something dumb and easy to fix (e.g. a typo, a missing import), fix it and re-run. If the idea itself is fundamentally broken, just skip it, log "crash" as the status in the tsv, and move on.

### NEVER STOP

Once the experiment loop has begun (after the initial setup), do NOT pause to ask the human if you should continue. Do NOT ask "should I keep going?" or "is this a good stopping point?". The human might be asleep, or gone from a computer and expects you to continue working *indefinitely* until you are manually stopped. You are autonomous. If you run out of ideas, think harder — read papers referenced in the code, re-read the in-scope files for new angles, try combining previous near-misses, try more radical changes. The loop runs until the human interrupts you, period.

As an example use case, a user might leave you running while they sleep. If each experiment takes you ~{{EXPERIMENT_DURATION}} then you can run approx {{EXPERIMENTS_PER_HOUR}}/hour, for a total of about {{EXPERIMENTS_OVERNIGHT}} over the duration of the average human sleep. The user then wakes up to experimental results, all completed by you while they slept!

## Experiment strategy

### Priority order

Follow this general progression, adapting to what works:

{{EXPERIMENT_PRIORITIES}}

### Periodic review

Every {{REVIEW_INTERVAL}} experiments, pause the loop briefly to:

1. Re-read `results.tsv` to review all experiments so far
2. Identify **patterns**: which directions consistently help? which consistently fail?
3. Identify **unexplored territory**: are there obvious levers you haven't tried?
4. Write a brief summary to `notes.md` (untracked by git) with:
   - Current best {{METRIC_NAME}} and how far from baseline
   - Top 3 most effective changes
   - Top 3 failed directions (to avoid repeating)
   - Next 5 experiments planned
5. Resume the loop with updated strategy

This review prevents repeating failed experiments and helps you think more systematically
about the search space. Even if context window is compressed, `notes.md` preserves your
accumulated knowledge.

### When stuck

If you've had {{STUCK_THRESHOLD}} consecutive discards/crashes:

1. Re-read the modifiable source file(s) carefully — you may have missed something
2. Re-read `notes.md` to recall what has and hasn't worked
3. Try the **opposite** of your recent direction (if you've been making things bigger, try smaller)
4. Try a **simplification experiment**: remove a feature and see if the metric holds
5. Try **combining** two previously marginal improvements
6. Look for ideas in code comments, referenced papers, or related projects

## Recovery

If you find yourself in a non-normal state (possibly from a previous interrupted session):

1. Check `git status` — if there are uncommitted changes, `git stash` them
2. Compare `git log --oneline -1` with the last entry in `results.tsv`
   — if the latest commit has no TSV entry, it may be an incomplete experiment
3. Re-run the latest commit's experiment to confirm its result
4. Read `notes.md` if it exists, to restore context about what was tried
5. Resume the normal loop
