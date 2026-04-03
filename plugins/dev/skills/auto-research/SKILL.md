---
name: auto-research
disable-model-invocation: true
description: Generate a program.md for autonomous AI research experiments (Karpathy's autoresearch paradigm). Interviews user about codebase, metric, and constraints, then produces a tailored program for an AI agent to iterate autonomously.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
---

# AutoResearch: Generate Autonomous Research Programs

You are creating a `program.md` — a natural language program that instructs an AI agent to conduct
autonomous research experiments. The generated document is not documentation; it is executable
instructions that an AI agent will follow literally, running experiments in an infinite loop.

## The Core Idea

The human writes a research plan (program.md). The AI agent executes the experiment loop. Code is
the agent's operating target, not the human's. The human sleeps; the agent works.

## How This Skill Works

### Phase 1: Interview the User

Before generating anything, you need to understand the research context. Ask the user about these
areas (adapt based on what they've already told you — skip questions they've answered):

#### 1. Project Basics
- What is the project about? (e.g., "training a small LLM", "optimizing a recommender system")
- Where is the codebase? (directory path)
- What language/framework? (Python/PyTorch, etc.)

#### 2. File Scope
- Which file(s) should the agent modify? (the "experiment surface")
- Which files are read-only? (fixed infrastructure — evaluation, data loading, etc.)
- Are there any files the agent should read for context but not modify?

#### 3. Metric & Goal
- What is the primary metric? (e.g., val_bpb, accuracy, F1, loss, latency)
- Direction: lower is better, or higher is better?
- How is it measured? (which script/function, what command to run)
- How to extract the result from output? (grep pattern or similar)

#### 4. Experiment Execution
- What command runs a single experiment? (e.g., `uv run train.py`, `python train.py`)
- How long does one experiment take? (time budget)
- What hardware constraints exist? (GPU memory, CPU-only, MPS, etc.)

#### 5. Data & Environment
- What data does the project use? Where is it stored?
- Any one-time setup steps needed before experiments can run?
- Any dependencies or environment requirements?

#### 6. Constraints & Preferences
- Can the agent install new packages?
- Any specific areas the agent should focus on or avoid?
- Any simplicity preferences? (complexity budget for improvements)

### Phase 2: Explore the Codebase

After the interview, read the key files to understand:
- The project structure
- The current metric output format
- The evaluation mechanism
- What parameters/architecture choices are available to modify

### Phase 3: Generate program.md

Read the template at `references/program-template.md` and fill it in based on the interview
and codebase exploration. The template contains `{{PLACEHOLDER}}` markers — replace each one
with content tailored to the user's project.

#### Key Principles for Generation

1. **Preserve the original spirit**: The generated program.md must retain ALL sections from the
   template. Never remove sections — only customize their content. The structure (Setup,
   Experimentation rules, Output format, Logging, Experiment loop, Timeout, Crashes, NEVER STOP)
   is sacred.

2. **Be specific**: Replace generic placeholders with actual file names, actual commands, actual
   grep patterns. The agent following this document should not need to guess anything.

3. **Calibrate the noise threshold**: Based on the metric and experiment duration, set an
   appropriate threshold for distinguishing real improvement from noise. Short runs with high
   variance need larger thresholds.

4. **Right-size the experiment priority list**: Suggest experiment directions that make sense for
   the specific domain. An LLM training project has different levers than a reinforcement learning
   project or an image classifier.

5. **Adapt constraints to the environment**: A Mac with MPS has different constraints than an
   H100. Adjust VRAM warnings, batch size advice, and timeout values accordingly.

6. **Enforce non-interactive operations**: The generated program.md must emphasize that all
   commands run unattended. The template includes a "Non-interactive principle" section — ensure
   the run command, git operations, and any project-specific commands are configured with
   non-interactive flags. If the user's workflow involves commands that might prompt for input,
   identify and document the non-interactive alternatives during the interview phase.

### Phase 4: Review with User

Present the generated program.md to the user. Walk them through the key sections and confirm:
- Are the file scopes correct?
- Is the metric extraction right?
- Are the experiment priorities sensible?
- Is the time budget appropriate?

Make adjustments based on feedback.

### Phase 5: Save and Advise

Save the program.md to the project directory. Advise the user on how to start:

```
To start autonomous research:
1. Open a new Claude Code / AI agent session in the project directory
2. Prompt: "Read program.md and let's start. Do the setup first."
3. Confirm the setup, then let the agent run
4. Check results.tsv when you return
```
