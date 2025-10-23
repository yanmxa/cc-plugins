---
argument-hint: "[category/name] [--update] or leave empty for interactive creation"
description: "Extract and save current session workflow as a reusable slash command"
allowed-tools: [Write, Edit, Glob, Read, Bash, AskUserQuestion]
---

Extract and save the current or most recent session workflow as a reusable slash command file. Supports creating new commands, updating existing ones, and interactive guided creation.

## Usage Examples

- `git/draft-pr` - Create new command from recent workflow
- `git/commit-push --update` - Update existing command with improvements
- Leave empty - Interactive mode with guided questions

## Command Creation Process

1. **Determine Mode**:
   - If `--update` flag: Update existing command
   - If command name provided: Auto mode - analyze recent workflow
   - If no arguments: Interactive mode - ask guided questions

2. **Analyze Workflow**: Extract recent session patterns, tool usage, and command sequences

3. **Generate Command File**:
   - Create at `~/.claude/commands/category/name.md`
   - Add YAML frontmatter with argument-hint, description, allowed-tools
   - Write implementation steps consolidating workflow actions
   - Include usage examples and notes

4. **Update Mode** (when using `--update`):
   - Read existing command file
   - Preserve metadata unless workflow significantly changed
   - Merge or enhance implementation steps
   - Add newly used tools to allowed-tools list

## Naming & Location

**Format**: `category/name` → command file path

**Personal Commands**: `~/.claude/commands/category/name.md`
- Available across all projects
- For individual workflows

**Project Commands**: `./.claude/commands/category/name.md`
- Shared with team via git
- For project-specific workflows

**Examples**:
- `git/draft-pr` → `~/.claude/commands/git/draft-pr.md` (personal)
- `docker/build` → `./.claude/commands/docker/build.md` (project)
- `jira/clone-issue` → `~/.claude/commands/jira/clone-issue.md` (personal)

**Auto-detection** (interactive mode with no name):
- Git operations → `git/workflow`
- Node/npm → `node/workflow`
- Docker → `docker/workflow`
- Test operations → `test/workflow`
- Jira → `jira/workflow`
- AWS → `aws/workflow`

## Command File Structure

```markdown
---
argument-hint: [describe expected arguments and defaults]
description: Brief action-oriented description
allowed-tools: [Bash, Read, Write, Edit, etc.]
---

Brief description of command purpose and when to use it.

## Implementation Steps

1. **Major Action**: Description of what to do (consolidate related actions)
2. **Next Step**: Clear actionable instruction
3. **Final Step**: Verification or cleanup

## Usage Examples

- `/category/name arg1` - Example scenario
- `/category/name --flag` - Another scenario

## Notes
- Prerequisites or dependencies
- Related commands
- Important considerations
```

## Interactive Questions

When in interactive mode, ask:

1. **Purpose**: What should this command do?
   - Automate git operations
   - Run tests or builds
   - Manage external services (Jira, AWS, Docker)
   - Code generation or scaffolding

2. **Scope**: Where should this command be available?
   - Personal use only (save to ~/.claude/commands/)
   - Share with team (save to ./.claude/commands/ for git tracking)

3. **Tools**: Which tools are needed? (multi-select)
   - File operations (Read, Write, Edit, Glob)
   - Shell commands (Bash)
   - User interaction (AskUserQuestion)
   - All tools (no restrictions)

4. **Arguments**: How should arguments be handled?
   - All as single value
   - Multiple positional arguments
   - With default values
   - No arguments needed

## Workflow Extraction

When analyzing recent workflow:

1. **Track Tool Usage**: Identify frequently used tools
2. **Find Patterns**: Detect repeated action sequences
3. **Extract Commands**: Capture successful bash commands and operations
4. **Consolidate Steps**: Group micro-actions into major steps (avoid excessive detail)
5. **Infer Metadata**: Set appropriate allowed-tools based on actual usage

## Update Mode Details

When updating with `--update` flag:

1. Preserve original description and argument-hint unless workflow changed significantly
2. Merge new steps with existing implementation steps
3. Add new tools to allowed-tools if used in recent workflow
4. Enhance usage examples with recent successful executions
5. Update notes with lessons learned or edge cases discovered

## Output Format

After creation:

```text
✅ Command created: /category/name
   Location: ~/.claude/commands/category/name.md
   Tools: [list of allowed-tools]

🔍 Usage: /category/name [arguments]
```

After update:

```text
✅ Command updated: /category/name
   Location: ~/.claude/commands/category/name.md

🔄 Changes:
   - [Summary of what changed]
```

## Best Practices

**Description**:

- Start with action verb (e.g., "Create", "Run", "Update")
- Keep under 100 characters
- Be specific and clear

**Implementation Steps**:

- Consolidate related actions (avoid micro-steps)
- Use descriptive step names
- Mention argument usage naturally in descriptions
- Include verification or error handling

**Allowed Tools**:

- Only list tools actually needed
- Omit for unrestricted access
- Use minimal set for security

## Examples

```bash
# Interactive creation
/claude:create-command

# Create from recent git workflow
/claude:create-command git/sync-upstream

# Update existing command with improvements
/claude:create-command git/commit-push --update

# Create project-specific test command
/claude:create-command test/e2e-debug
```

## Notes

- Commands expand to full prompts when invoked
- Keep focused on one specific workflow
- Test thoroughly before sharing with team
- Use `--update` to refine based on real usage
- Commands run in current working directory context
