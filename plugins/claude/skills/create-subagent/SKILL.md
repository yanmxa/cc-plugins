---
name: create-subagent
description: Create a specialized AI subagent with isolated context and custom configuration. Use when user says "create subagent", "create agent", "make an agent", or needs task-specific delegation.
argument-hint: "[subagent-name] or leave empty for interactive mode"
allowed-tools: [Write, Read, Glob, Bash, AskUserQuestion, Grep]
disable-model-invocation: true
---

# Create Subagent

Create a specialized AI subagent that runs in its own context window with custom system prompt, tool access, and permissions. Subagents preserve main conversation context by handling complex tasks independently.

## Quick Start

```bash
# Interactive mode - guided creation
/create-subagent

# Auto mode - create from name
/create-subagent code-reviewer
```

## Subagent Locations

| Location | Path | Scope | Priority |
|----------|------|-------|----------|
| Project | `.claude/agents/<name>.md` | This project | Higher |
| User | `~/.claude/agents/<name>.md` | All projects | Lower |

Project-level subagents override user-level when names conflict.

## Creation Process

### 1. Determine Mode

- **With argument** (`$ARGUMENTS`): Auto mode - generate from name and recent workflow
- **Without argument**: Interactive mode - ask guided questions

### 2. Interactive Mode Questions

Use AskUserQuestion with these prompts:

**Question 1 - Role**:
- Header: "Role"
- Question: "What specialized role should this subagent fulfill?"
- Options:
  - "Code quality expert" - Review, refactor, improve code
  - "Testing specialist" - Write and run tests
  - "Architecture advisor" - Design systems, plan structure
  - "Domain expert" - Specialized domain knowledge

**Question 2 - Activation**:
- Header: "Activation"
- Question: "When should Claude delegate to this subagent?"
- Options:
  - "After code changes" - Proactively review new code
  - "Specific keywords" - Trigger on certain terms
  - "Explicit request only" - Only when user asks
  - "High-volume operations" - Isolate verbose output

**Question 3 - Tools** (multiSelect: true):
- Header: "Tools"
- Question: "Which tools should this subagent access?"
- Options:
  - "Read-only" - Read, Grep, Glob (safe exploration)
  - "File operations" - Read, Write, Edit, Glob
  - "Shell commands" - Bash execution
  - "All tools" - Inherit everything

**Question 4 - Model**:
- Header: "Model"
- Question: "Which model should power this subagent?"
- Options:
  - "Sonnet (Recommended)" - Balanced performance
  - "Haiku (Fast)" - Quick, cost-effective
  - "Opus (Advanced)" - Most capable
  - "Inherit" - Same as main conversation

**Question 5 - Scope**:
- Header: "Scope"
- Question: "Where should this subagent be available?"
- Options:
  - "User-level" - Save to ~/.claude/agents/
  - "Project-level" - Save to .claude/agents/

### 3. Extract Workflow Patterns

When analyzing recent conversation:

1. Identify domain from file types and commands
2. Track tool usage patterns
3. Detect repeated action sequences
4. Extract trigger keywords from user messages

### 4. Generate Subagent File

```bash
# User-level
~/.claude/agents/$SUBAGENT_NAME.md

# Project-level
.claude/agents/$SUBAGENT_NAME.md
```

### 5. Write Subagent Content

Use this template:

```markdown
---
name: subagent-name
description: Role + when to invoke. Include trigger keywords for auto-delegation.
tools: Read, Write, Bash  # Optional, inherits all if omitted
model: sonnet             # Optional: sonnet, opus, haiku, inherit
---

You are a [specific role] specializing in [domain].

## Responsibilities

1. **Primary Task**: What you do first
2. **Secondary Task**: What you do next
3. **Quality Assurance**: How you verify work

## Workflow

When invoked:

1. **Analyze**: Understand the current state
2. **Execute**: Perform the main task
3. **Verify**: Check results meet standards
4. **Report**: Summarize findings

## Best Practices

- Guideline 1
- Guideline 2
- Common pitfall to avoid

## Output Format

[Template for deliverables]
```

## Frontmatter Reference

See [reference.md](reference.md) for complete frontmatter field documentation.

Key fields:

| Field | Description |
|-------|-------------|
| `name` | Unique identifier (lowercase, hyphens) |
| `description` | Role + activation triggers (critical for auto-delegation) |
| `tools` | Comma-separated list; inherits all if omitted |
| `disallowedTools` | Tools to explicitly deny |
| `model` | `sonnet`, `opus`, `haiku`, or `inherit` |
| `permissionMode` | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `skills` | Skills to preload into subagent context |
| `hooks` | Lifecycle hooks for this subagent |

## Description Best Practices

**Poor descriptions**:
- "Helps review code" (vague, no triggers)
- "API testing tool" (no context)

**Good descriptions**:
- "Expert code reviewer. Reviews for quality, security, maintainability. Use immediately after writing code, before commits, or when refactoring."
- "API testing specialist. Validates REST endpoints, schemas, error handling. Use when testing APIs or debugging HTTP requests."

## Built-in Subagents

Claude Code includes these built-in subagents:

| Agent | Model | Tools | Purpose |
|-------|-------|-------|---------|
| Explore | Haiku | Read-only | Fast codebase exploration |
| Plan | Inherit | Read-only | Research during plan mode |
| general-purpose | Inherit | All | Complex multi-step tasks |

## When to Use Subagents

Use subagents when:
- Task produces verbose output (tests, logs)
- Need to enforce tool restrictions
- Work is self-contained and returns summary
- Different model needed for sub-task

Use main conversation when:
- Frequent back-and-forth needed
- Multiple phases share context
- Quick, targeted changes
- Latency matters

## Validation Checklist

Before finalizing:

1. **YAML syntax**: Valid frontmatter with proper delimiters
2. **Description**: Includes role + activation triggers + keywords
3. **System prompt**: Clear role, structured workflow, quality criteria
4. **Tool access**: Appropriate for task, not too permissive

## Output Format

After creation:

```
Subagent created: subagent-name
Location: ~/.claude/agents/subagent-name.md
Role: [description]
Model: sonnet
Tools: Read, Write, Bash

To use:
- Automatic: Claude delegates when context matches
- Explicit: "Use the subagent-name subagent to [task]"
```

## Examples

See [examples.md](examples.md) for complete subagent examples.

## Debugging

If subagent doesn't activate:

1. Check file: `ls ~/.claude/agents/subagent-name.md`
2. Verify YAML: `head -10 ~/.claude/agents/subagent-name.md`
3. Make description more specific with trigger keywords
4. Test explicit: "Use the subagent-name subagent to [task]"
5. Run `/agents` to verify it's loaded
