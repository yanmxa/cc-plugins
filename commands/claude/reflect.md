---
argument-hint: "[#|memory] [--user] - Reflect on session to improve prompts or memory"
description: Analyze recent session interactions to propose improvements to prompt files or CLAUDE.md
allowed-tools: [Read, Edit, Glob, Bash]
---

Analyze the current session's recent interactions to learn from the experience and propose improvements to prompt files (commands, skills, agents) or memory files (CLAUDE.md).

## Arguments

- `#` or `memory` - Update CLAUDE.md instead of prompt files (default: project-level `.claude/CLAUDE.md`)
- `--user` - When used with `#` or `memory`, update user-level `~/.claude/CLAUDE.md` instead

## Implementation Steps

### 1. Determine Target Mode

Parse arguments to determine what to improve:
- If argument is `#` or `memory`: Target CLAUDE.md file
  - With `--user`: `~/.claude/CLAUDE.md`
  - Without: `./.claude/CLAUDE.md` (project-level)
- Otherwise: Target recently invoked prompt files

### 2. Analyze Current Session

Review the recent conversation to identify:

1. **Invoked Prompt Files**: Find commands, skills, or agents that were called
   - Look for `/command:name` invocations
   - Identify skill activations
   - Find agent delegations

2. **Interaction Patterns**: Analyze how the prompts performed
   - Did the prompt achieve the intended goal?
   - Were there corrections or clarifications needed?
   - Did the user provide additional guidance?
   - Were there errors or unexpected behaviors?

3. **Learning Opportunities**: Extract insights
   - Missing steps in implementation
   - Unclear instructions that needed clarification
   - Edge cases not handled
   - Better approaches discovered during execution

### 3. Locate Prompt Files

For each identified prompt file, find its location:

```bash
# Commands
~/.claude/commands/**/*.md
./.claude/commands/**/*.md

# Skills
~/.claude/skills/**/SKILL.md
~/.claude/skills/**/skill.md
./.claude/skills/**/SKILL.md

# Agents
~/.claude/agents/*.md
./.claude/agents/*.md

# Plugin commands/skills
~/.claude/plugins/*/commands/*.md
~/.claude/plugins/*/skills/**/SKILL.md
```

### 4. Propose Improvements

For **Prompt Files** (commands, skills, agents):

1. Read the current prompt file
2. Analyze gaps between prompt instructions and actual execution
3. Propose specific improvements:
   - Add missing implementation steps
   - Clarify ambiguous instructions
   - Add error handling for discovered edge cases
   - Update examples based on real usage
   - Refine allowed-tools list if needed

For **Memory Files** (CLAUDE.md):

1. Read the current CLAUDE.md
2. Extract learnings from session:
   - New patterns or workflows discovered
   - Preferences expressed by user
   - Project-specific conventions learned
   - Common commands or tools used
3. Propose additions:
   - New guidelines or best practices
   - Updated command references
   - Project-specific notes

### 5. Present Improvements

Format proposed changes clearly:

```
📝 Proposed Improvements for: [file path]

## Current Issues Found
1. [Issue description from session experience]
2. [Another issue]

## Suggested Changes

### [Section/Step to modify]
**Before:**
[current text]

**After:**
[improved text]

### [Another section]
...

## Rationale
- [Why this change helps]
- [What session experience led to this]
```

### 6. Apply Changes (with confirmation)

Ask user if they want to apply the proposed changes:
- Show diff preview
- Apply changes using Edit tool
- Confirm successful update

## Usage Examples

```bash
# Reflect on session and improve recently used prompt files
/claude:reflect

# Update project-level CLAUDE.md with learnings (equivalent)
/claude:reflect #
/claude:reflect memory

# Update user-level CLAUDE.md with learnings
/claude:reflect # --user
/claude:reflect memory --user
```

## Example Improvements

### Command Improvement Example
```markdown
## Before (plugin:bump)
### 2. Detect Changed Plugins
Find plugins with modifications using git diff...

## After (improved)
### 2. Detect Changed Plugins
Find plugins with modifications:
- Check uncommitted changes: `git status --porcelain plugins/`
- Check recent commits: `git diff HEAD~1 --name-only -- plugins/`
- **Note**: If changes were already pushed, check recent commit history
```

### Memory Improvement Example
```markdown
## Added to CLAUDE.md

### Plugin Version Management
- After updating plugin files, run `/plugin:bump` to update version
- Check recent commits if changes are already pushed
- Use `--minor` for feature additions, `--patch` for fixes
```

## Notes

- Focuses on actionable, specific improvements
- Preserves existing structure while enhancing content
- Learning is based on actual session experience, not hypothetical scenarios
- Changes are proposed first, applied only with user confirmation
- For memory mode, avoids duplicating existing content
