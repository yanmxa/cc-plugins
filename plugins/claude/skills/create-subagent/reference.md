# Subagent Frontmatter Reference

Complete reference for YAML frontmatter fields in subagent markdown files.

## All Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier using lowercase letters and hyphens |
| `description` | Yes | When Claude should delegate to this subagent |
| `tools` | No | Tools the subagent can use. Inherits all if omitted |
| `disallowedTools` | No | Tools to deny, removed from inherited or specified list |
| `model` | No | Model to use: `sonnet`, `opus`, `haiku`, or `inherit`. Defaults to `inherit` |
| `permissionMode` | No | Permission handling mode |
| `skills` | No | Skills to preload into subagent context at startup |
| `hooks` | No | Lifecycle hooks scoped to this subagent |

## Models

| Model | Best For |
|-------|----------|
| `sonnet` | Balanced performance and speed |
| `opus` | Most capable, complex reasoning |
| `haiku` | Fast, cost-effective, lighter tasks |
| `inherit` | Match main conversation (default) |

## Permission Modes

| Mode | Behavior |
|------|----------|
| `default` | Standard permission checking with prompts |
| `acceptEdits` | Auto-accept file edits |
| `dontAsk` | Auto-deny prompts (allowed tools still work) |
| `bypassPermissions` | Skip all permission checks (use with caution) |
| `plan` | Plan mode (read-only exploration) |

## Tool Restrictions

### Available Tools

Common tools to restrict:

```yaml
# Read-only exploration
tools: Read, Grep, Glob

# File modifications
tools: Read, Write, Edit, Glob

# Shell operations
tools: Bash, Read

# Web access
tools: WebFetch, WebSearch

# Specific bash commands
tools: Bash(git *), Bash(npm *)
```

### Deny Specific Tools

```yaml
tools: Read, Write, Bash
disallowedTools: Edit
```

## Preloading Skills

Inject skill content into subagent context at startup:

```yaml
---
name: api-developer
description: Implement API endpoints following conventions
skills:
  - api-conventions
  - error-handling-patterns
---
```

Full skill content is injected, not just made available. Subagents don't inherit skills from parent.

## Hooks

### Subagent-Scoped Hooks

Define hooks in frontmatter that run only while subagent is active:

```yaml
---
name: safe-executor
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/run-linter.sh"
  Stop:
    - hooks:
        - type: command
          command: "./scripts/cleanup.sh"
---
```

### Hook Events

| Event | Matcher | When |
|-------|---------|------|
| `PreToolUse` | Tool name | Before subagent uses a tool |
| `PostToolUse` | Tool name | After subagent uses a tool |
| `Stop` | (none) | When subagent finishes |

### Conditional Tool Validation

Example: Allow only read-only SQL queries:

```yaml
---
name: db-reader
tools: Bash
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-readonly-query.sh"
---
```

Validation script (`./scripts/validate-readonly-query.sh`):

```bash
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if echo "$COMMAND" | grep -iE '\b(INSERT|UPDATE|DELETE|DROP)\b' > /dev/null; then
  echo "Blocked: Only SELECT queries allowed" >&2
  exit 2  # Exit code 2 blocks the operation
fi
exit 0
```

## CLI Definition

Define subagents via CLI flag (session-only):

```bash
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer",
    "prompt": "You are a senior code reviewer...",
    "tools": ["Read", "Grep", "Glob"],
    "model": "sonnet"
  }
}'
```

Use `prompt` for system prompt (equivalent to markdown body).

## Background vs Foreground

- **Foreground**: Blocks main conversation, permission prompts pass through
- **Background**: Runs concurrently, pre-approves permissions, auto-denies unapproved

To background a running task: Press **Ctrl+B**

## Resuming Subagents

Subagents can be resumed to continue work:

```
Use the code-reviewer subagent to review auth module
[Agent completes]

Continue that code review and analyze authorization logic
[Claude resumes with full previous context]
```

## Disabling Subagents

Prevent Claude from using specific subagents:

```json
{
  "permissions": {
    "deny": ["Task(Explore)", "Task(my-custom-agent)"]
  }
}
```

Or via CLI:

```bash
claude --disallowedTools "Task(Explore)"
```
