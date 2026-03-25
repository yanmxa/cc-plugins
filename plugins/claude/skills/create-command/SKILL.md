---
name: create-command
description: Extract and save current session workflow as a reusable slash command. Use when user says "create command", "save this as command", or wants to automate a workflow.
argument-hint: "[category/name] [--update] or leave empty for interactive mode"
allowed-tools: [Write, Edit, Glob, Read, Bash, AskUserQuestion]
disable-model-invocation: true
---

# Create Command

Extract and save the current session workflow as a reusable slash command file. Commands are user-invoked shortcuts that expand to full prompts.

## Quick Start

```bash
# Interactive mode - guided creation
/create-command

# Auto mode - create from name
/create-command git/sync-upstream

# Update existing command
/create-command git/commit-push --update
```

## Command Locations

| Location | Path | Scope |
|----------|------|-------|
| Personal | `~/.claude/commands/category/name.md` | All projects |
| Project | `.claude/commands/category/name.md` | This project |

## Creation Process

### 1. Determine Mode

- **With `--update`**: Update existing command
- **With name**: Auto mode - analyze recent workflow
- **No arguments**: Interactive mode - ask questions

### 2. Interactive Mode Questions

Use AskUserQuestion with these prompts:

**Question 1 - Purpose**:
- Header: "Purpose"
- Question: "What should this command do?"
- Options:
  - "Automate git operations" - Commits, PRs, branches
  - "Run tests or builds" - Test suites, build scripts
  - "Manage services" - Jira, AWS, Docker
  - "Code generation" - Scaffolding, templates

**Question 2 - Scope**:
- Header: "Scope"
- Question: "Where should this command be available?"
- Options:
  - "Personal (Recommended)" - ~/.claude/commands/
  - "Project" - .claude/commands/ (git tracked)

**Question 3 - Tools** (multiSelect: true):
- Header: "Tools"
- Question: "Which tools are needed?"
- Options:
  - "File operations" - Read, Write, Edit, Glob
  - "Shell commands" - Bash
  - "User interaction" - AskUserQuestion
  - "All tools" - No restrictions

### 3. Analyze Workflow

When extracting from recent session:

1. Track frequently used tools
2. Find repeated action sequences
3. Capture successful bash commands
4. Consolidate micro-actions into major steps
5. Infer appropriate allowed-tools

### 4. Generate Command File

Write to appropriate location:

```bash
# Personal
~/.claude/commands/category/name.md

# Project
.claude/commands/category/name.md
```

### 5. Command File Template

```markdown
---
argument-hint: [expected arguments]
description: Brief action-oriented description
allowed-tools: [Bash, Read, Write]
---

Brief description of command purpose.

## Implementation Steps

1. **Step One**: What to do first
2. **Step Two**: Next action
3. **Step Three**: Verification

## Usage Examples

- `/category/name arg1` - Example scenario
- `/category/name --flag` - Another scenario

## Notes

- Prerequisites
- Related commands
```

## Update Mode

When using `--update` flag:

1. Read existing command file
2. Preserve metadata unless workflow changed
3. Merge new steps with existing
4. Add new tools to allowed-tools
5. Enhance usage examples

## Naming Convention

**Format**: `category/name`

**Auto-detection** (interactive mode):
- Git operations → `git/workflow`
- Node/npm → `node/workflow`
- Docker → `docker/workflow`
- Test operations → `test/workflow`
- Jira → `jira/workflow`

## Best Practices

**Description**:
- Start with action verb ("Create", "Run", "Update")
- Keep under 100 characters
- Be specific and clear

**Implementation Steps**:
- Consolidate related actions
- Use descriptive step names
- Include verification/error handling

**Allowed Tools**:
- Only list tools actually needed
- Omit for unrestricted access

## Commands vs Skills vs Subagents

| Feature | Command | Skill | Subagent |
|---------|---------|-------|----------|
| Invocation | User-only (`/name`) | User or Claude | User or Claude |
| Context | Main conversation | Main conversation | Isolated |
| Best For | Quick automation | Domain expertise | Complex workflows |
| Format | Single `.md` file | Folder with `SKILL.md` | Single `.md` file |

**Use commands for**:
- User-triggered shortcuts
- Simple, repeatable workflows
- Quick automation

## Output Format

After creation:

```
Command created: /category/name
Location: ~/.claude/commands/category/name.md
Tools: [list of allowed-tools]

Usage: /category/name [arguments]
```

After update:

```
Command updated: /category/name
Location: ~/.claude/commands/category/name.md

Changes:
- [Summary of what changed]
```

## Examples

```bash
# Interactive creation
/create-command

# Create from recent git workflow
/create-command git/sync-upstream

# Update existing command
/create-command git/commit-push --update

# Create project-specific command
/create-command test/e2e-debug
```

## Notes

- Commands expand to full prompts when invoked
- Keep focused on one specific workflow
- Test thoroughly before sharing with team
- Use `--update` to refine based on real usage
