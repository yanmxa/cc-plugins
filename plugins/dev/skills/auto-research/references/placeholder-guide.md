# Placeholder Guide

This document explains how to fill each `{{PLACEHOLDER}}` in `program-template.md`
based on the user's research context.

## Basic Placeholders

| Placeholder | Description | Example |
|---|---|---|
| `{{PROJECT_NAME}}` | Project name | "autoresearch", "nano-rl", "image-classifier" |
| `{{MODIFIABLE_FILES}}` | File(s) the agent edits | "`train.py`", "`model.py` and `config.py`" |
| `{{METRIC_NAME}}` | Primary evaluation metric | "val_bpb", "test_accuracy", "eval_loss", "latency_ms" |
| `{{METRIC_DIRECTION}}` | "lowest" or "highest" | "lowest" for loss, "highest" for accuracy |
| `{{METRIC_IMPROVED_CONDITION}}` | How to compare | "lower", "higher" |
| `{{RUN_COMMAND}}` | Command to run experiment | "uv run train.py", "python train.py --epochs 10" |
| `{{TIME_BUDGET}}` | Expected experiment duration | "~5 minutes", "~15 minutes", "~2 minutes" |
| `{{TIMEOUT_LIMIT}}` | Maximum allowed duration | "10 minutes", "30 minutes" |
| `{{TIMEOUT_SECONDS}}` | Timeout in seconds | "600", "1800" |
| `{{EXPERIMENT_DURATION}}` | Per-experiment time | "5 minutes", "15 minutes" |
| `{{EXPERIMENTS_PER_HOUR}}` | Calculate from duration | "12", "4" |
| `{{EXPERIMENTS_OVERNIGHT}}` | ~8 hours worth | "100", "32" |

## Threshold Placeholders

These depend on the metric's scale and the experiment's variance.

| Placeholder | How to determine | Example (BPB ~1.0) | Example (accuracy ~85%) |
|---|---|---|---|
| `{{SIGNIFICANT_THRESHOLD}}` | ~0.5% of metric value | "0.005" | "0.5%" |
| `{{MARGINAL_RANGE}}` | 0.1%-0.5% of metric value | "0.001~0.005" | "0.1%~0.5%" |
| `{{NOISE_THRESHOLD}}` | <0.1% of metric value | "0.001" | "0.1%" |

For very short experiments (<2 min), increase these by 2x. For long experiments (>30 min), decrease by 0.5x.

## Content Block Placeholders

### {{IN_SCOPE_FILES}}

List all files the agent should read, with descriptions. Format:

```markdown
   - `README.md` — repository context
   - `prepare.py` — fixed constants, data prep, evaluation. Do not modify.
   - `train.py` — the file you modify. Model, optimizer, training loop.
```

### {{VERIFY_PREREQUISITES}}

Specific checks for the project's data/environment. Examples:

- LLM training: "Check that `~/.cache/autoresearch/` contains data shards and a tokenizer. If not, tell the human to run `uv run prepare.py`."
- Image classification: "Check that `data/train/` and `data/val/` directories exist with images. If not, tell the human to run `python download_data.py`."
- RL: "Check that the gym environment is installed: `python -c 'import gymnasium'`. If not, tell the human to run `pip install gymnasium[mujoco]`."

### {{EXPERIMENT_CONTEXT}}

Brief description of how experiments work. Example:

"Each experiment runs on a single GPU. The training script runs for a fixed time budget of 5 minutes (wall clock training time, excluding startup/compilation). You launch it simply as: `uv run train.py`."

### {{CAN_DO_LIST}}

What the agent is allowed to modify. Example:

```markdown
- Modify `train.py` — this is the only file you edit. Everything is fair game: model architecture,
  optimizer, hyperparameters, training loop, batch size, model size, etc.
```

### {{CANNOT_DO_LIST}}

Hard constraints. Example:

```markdown
- Modify `prepare.py`. It is read-only. It contains the fixed evaluation, data loading, tokenizer.
- Install new packages or add dependencies. You can only use what's in `pyproject.toml`.
- Modify the evaluation harness. The `evaluate_bpb` function is the ground truth metric.
```

### {{GOAL_CONTEXT}}

Additional context about the goal. Example:

"Since the time budget is fixed, you don't need to worry about training time — it's always 5 minutes. Everything is fair game: change the architecture, the optimizer, the hyperparameters. The only constraint is that the code runs without crashing and finishes within the time budget."

### {{RESOURCE_CONSTRAINT_NAME}}

Primary resource constraint. Examples: "VRAM", "Memory", "CPU time", "Disk space"

### {{GREP_PATTERN}}

How to extract metrics from logs. Example:

```bash
grep "^val_bpb:\|^peak_vram_mb:" run.log
```

### {{OUTPUT_FORMAT_NOTES}}

Any notes about interpreting output. Example:

"Note that the script is configured to always stop after 5 minutes, so depending on the computing platform the numbers might look different."

### {{TSV_HEADER}}

Tab-separated header. Standard:

```
commit	val_bpb	memory_gb	status	description
```

Adapt metric column name and add domain-specific columns as needed.

### {{TSV_COLUMN_DESCRIPTIONS}}

Numbered list explaining each column.

### {{TSV_EXAMPLE}}

A realistic example with 4 rows: baseline, keep, discard, crash.

### {{RESULT_GREP_COMMAND}}

The exact grep command. Example:

```bash
grep "^val_bpb:\|^peak_vram_mb:" run.log
```

### {{EXPERIMENT_PRIORITIES}}

Domain-specific experiment directions. Organized by phase:

#### For LLM pretraining:
```markdown
1. **Low-hanging fruit** (experiments 1-10): hyperparameter tuning
   - Learning rate +/- 50%
   - Batch size 2x or 0.5x
   - Warmdown ratio adjustments
   - Weight decay adjustments

2. **Architecture search** (experiments 10-40): structural changes
   - Depth vs width trade-off
   - Attention head count/dimension
   - MLP expansion ratio
   - Window patterns

3. **Algorithmic innovation** (experiments 40+): novel techniques
   - Different activation functions
   - New regularization methods
   - Optimizer parameter groups
   - Training tricks

4. **Simplification audit** (every 20 experiments):
   - Remove one feature at a time
   - If metric holds or improves, keep the simplification
```

#### For image classification:
```markdown
1. **Baseline tuning** (experiments 1-10):
   - Learning rate schedule
   - Data augmentation parameters
   - Batch size

2. **Architecture** (experiments 10-30):
   - Model depth/width
   - Skip connections
   - Attention mechanisms

3. **Regularization** (experiments 30+):
   - Dropout rates
   - Weight decay
   - Label smoothing
   - Mixup/CutMix
```

### {{REVIEW_INTERVAL}}

How often to do periodic review. Based on experiment duration:
- 5 min experiments → every 15-20 experiments
- 15 min experiments → every 8-10 experiments
- 30+ min experiments → every 5 experiments

### {{STUCK_THRESHOLD}}

Number of consecutive failures before triggering "when stuck" protocol.
Typically 5-8 for fast experiments, 3-5 for slow ones.
