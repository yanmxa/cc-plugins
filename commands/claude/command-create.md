---
argument-hint: "[category/name] or leave empty for auto-detection"
description: "Extract and save current session workflow as a reusable slash command"
allowed-tools: [Write, Edit, MultiEdit, Glob, Read]
---

Extract and save the current or most recent session workflow as a reusable slash command file.

## Usage Examples
- `git/draft-pr` - Save as git category, draft-pr command
- `docker/build-prod` - Save as docker category, build-prod command
- Leave empty - Auto-detect category and use generic name

## Command Creation Process

1. **Extract Workflow**: Capture the current session's workflow and consolidate into high-level steps
2. **Generate Path**: Create save path using category/name format in `~/.claude/commands/`
3. **Create Slash Command**: Write structured markdown with frontmatter metadata
4. **Add Placeholders**: Replace workflow specifics with argument placeholders

## Naming & Location

**Format**: `category/name` → `~/.claude/commands/category/name.md`

**Examples**:
- `git/draft-pr` → `~/.claude/commands/git/draft-pr.md`
- `docker/build` → `~/.claude/commands/docker/build.md`
- `test/run-unit` → `~/.claude/commands/test/run-unit.md`

**Auto-detection** (when no arguments provided):
- Git operations → `git/workflow`
- Node/npm operations → `node/workflow`
- Docker operations → `docker/workflow`
- Test operations → `test/workflow`
- Default → `general/workflow`

## Generated Slash Command Structure

```markdown
---
argument-hint: [describe expected arguments]
description: Brief description of what this command does
allowed-tools: [tools actually used in workflow - e.g., Bash, Read, Edit, Write]
---

Brief description of the command purpose.

## Implementation Steps

1. **Major Step**: Consolidated description with `$ARGUMENTS` placeholders (combine multiple small actions)
2. **Key Action**: Description with `$1`, `$2` for specific arguments (avoid micro-steps)
3. **Final Step**: Verification or cleanup (group related actions together)

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
- **Workflow Consolidation**: Groups small actions into fewer, substantial steps
- **Argument Placeholder Replacement**: Converts specific values to reusable placeholders
- **Directory Auto-creation**: Creates category subdirectories as needed
- **Tool Permission Inference**: Sets allowed-tools based on tools actually used in the workflow