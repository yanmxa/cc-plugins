---
argument-hint: [category:name] or leave empty for auto-detection
description: Extract and save current session workflow as a reusable command
allowed-tools: Write, Edit, MultiEdit, Glob, Read
---

# Save Current Workflow as Command

Extract and save the current or most recent session workflow as a structured markdown command file.

## Usage Examples
- `/save git:draft-pr` - Save as git category, draft-pr command
- `/save docker:build-prod` - Save as docker category, build-prod command  
- `/save` - Auto-detect category and use generic name

## Command Creation Process

1. **Extract Workflow**: Capture the current session's workflow steps
2. **Generate Path**: Create save path using category:name format
3. **Create Command**: Write structured markdown command with frontmatter
4. **Add Arguments**: Replace workflow specifics with `$ARGUMENTS` placeholders

## Naming & Location

**Format**: `category:name` → `.claude/commands/category/name.md`

**Examples**:
- `git:draft-pr` → `~/.claude/commands/git/draft-pr.md`
- `docker:build` → `~/.claude/commands/docker/build.md`
- `test:run-unit` → `~/.claude/commands/test/run-unit.md`

**Auto-detection** (when no arguments provided):
- Git operations → `git:workflow`
- Node/npm operations → `node:workflow`
- Docker operations → `docker:workflow`
- Test operations → `test:workflow`
- Default → `general:workflow`

## Generated Command Structure

```markdown
---
argument-hint: [describe expected arguments]
description: Brief description of what this command does
allowed-tools: [relevant tools based on workflow]
---

Brief description of the command purpose.

## Implementation Steps

1. **Step Name**: Description with `$ARGUMENTS` placeholders
2. **Step Name**: Description with `$1`, `$2` for specific arguments
3. **Step Name**: Final verification or cleanup steps

## Notes
- Context about when to use this command
- Prerequisites or dependencies
- Related commands or alternatives
```

## Argument Handling

- `$ARGUMENTS` - All arguments passed to command
- `$1`, `$2`, `$3` - Individual positional arguments
- Place placeholders where dynamic values should be inserted

**Example**: 
Original workflow: "Create PR for feature-auth branch"
Saved command: "Create PR for `$ARGUMENTS` branch"

## Features

- **Smart Category Detection**: Analyzes workflow patterns for appropriate categorization
- **Frontmatter Generation**: Adds appropriate metadata based on tools used
- **Argument Placeholder Replacement**: Converts specific values to reusable placeholders
- **Directory Auto-creation**: Creates category subdirectories as needed
- **Tool Permission Inference**: Sets allowed-tools based on workflow analysis