# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Claude Code plugins collection repository that provides productivity-focused slash commands for development workflows. The repository contains two main plugins:

- **claude**: Meta-development plugin for creating new slash commands, skills, and subagents from current workflows
- **git**: Git workflow automation plugin for commit/push, PR management, worktree creation, and code review

## Repository Structure

```
cc-plugins/
├── plugins/
│   ├── claude/
│   │   ├── .claude-plugin/plugin.json    # Plugin metadata (version 1.0.3)
│   │   └── commands/
│   │       ├── create-command.md          # Extract workflows into reusable commands
│   │       ├── create-skill.md            # Create model-invoked skills
│   │       └── create-subagent.md         # Create specialized subagents
│   └── git/
│       ├── .claude-plugin/plugin.json     # Plugin metadata (version 1.0.0)
│       └── commands/
│           ├── commit-push.md             # Commit with sign-off and push
│           ├── compact-commits.md         # Compact PR commits
│           ├── create-pr.md               # Create pull requests
│           ├── create-worktree.md         # Create git worktrees
│           ├── rebase-pr.md               # Rebase PRs
│           └── review-pr.md               # Review pull requests
└── .claude/
    └── commands/
        └── claude/
            └── sync-settings.md           # Sync from claude-code-settings branch
```

## Plugin Architecture

### Plugin Structure
Each plugin follows the Claude Code plugin specification:
- `.claude-plugin/plugin.json`: Metadata file containing name, description, version, and author
- `commands/*.md`: Slash command definitions with YAML frontmatter
- `agents/*.md`: Specialized agent definitions (if applicable)
- `skills/*.md`: Model-invoked skill definitions (if applicable)

### Command File Format
All command files use markdown with YAML frontmatter:
```yaml
---
argument-hint: "[arg-description] or defaults"
description: "Brief action-oriented description"
allowed-tools: [Bash, Read, Write, Edit, etc.]  # Optional
---
```

### Version Management
Plugin versions follow semantic versioning in `.claude-plugin/plugin.json`:
- Major: Breaking changes
- Minor: New features
- Patch: Bug fixes and minor improvements

## Development Workflow

### Testing Changes
Since this repository contains slash command definitions (markdown files), testing involves:
1. Making changes to command markdown files
2. Testing the commands in a Claude Code session
3. Verifying the expanded prompts work correctly
4. Ensuring YAML frontmatter is valid

### Versioning Plugins
When modifying plugin commands:
1. Update the command file in `plugins/*/commands/`
2. Bump the version in `plugins/*/.claude-plugin/plugin.json`
3. Follow semantic versioning based on change type
4. Commit changes with descriptive message

### Syncing from Settings Branch
Use `/claude:sync-settings` to pull commands/agents/skills from the `claude-code-settings` branch:
- Fetches latest from `origin/claude-code-settings`
- Syncs files to corresponding plugin directories
- Automatically bumps patch versions for updated plugins
- Use `--dry-run` to preview changes

## Key Command Behaviors

### create-worktree Command
- Uses double underscore (`__`) separator: `../project-name__feature-name`
- Supports editor integration flags: `--cursor`, `--code`, `--tmux`
- Auto-generates names from git diff if not provided
- Creates branch from source branch (defaults to current)

### create-command Command
- Supports two modes: auto (with name) and interactive (without name)
- Update mode with `--update` flag preserves metadata and merges improvements
- Personal commands: `~/.claude/commands/` (cross-project)
- Project commands: `./.claude/commands/` (team-shared via git)
- Format: `category/name` → `~/.claude/commands/category/name.md`

### create-skill Command
- Skills are model-invoked (not user-invoked like commands)
- Description must include WHAT and WHEN for discoverability
- Personal: `~/.claude/skills/skill-name/`
- Project: `./.claude/skills/skill-name/`
- Can include supporting files: `reference.md`, `examples.md`, `scripts/`

### commit-push Command
- Uses conventional commit format with sign-off
- Default behavior: commit and push to origin
- Use `--no-push` to commit only
- Reviews git status, diff, and recent commits before committing

## Common Tasks

### Adding a New Command to a Plugin
```bash
# 1. Create the command file
vim plugins/git/commands/new-command.md

# 2. Add YAML frontmatter with argument-hint, description, allowed-tools
# 3. Write implementation steps and usage examples
# 4. Bump plugin version in plugins/git/.claude-plugin/plugin.json
# 5. Test the command in Claude Code
# 6. Commit changes
```

### Creating a New Plugin
```bash
# 1. Create plugin directory structure
mkdir -p plugins/new-plugin/.claude-plugin
mkdir -p plugins/new-plugin/commands

# 2. Create plugin.json
cat > plugins/new-plugin/.claude-plugin/plugin.json <<EOF
{
  "name": "new-plugin",
  "description": "Description here",
  "version": "1.0.0",
  "author": {
    "name": "Your Name",
    "email": "your.email@example.com"
  }
}
EOF

# 3. Add commands to plugins/new-plugin/commands/
# 4. Update README.md to document the new plugin
```

## Installation Usage
Users install plugins from this repository using:
```bash
/plugin marketplace add https://github.com/yanmxa/cc-plugins
/plugin install claude
/plugin install git
```

## Notes

- No build/compile/test commands needed - this is a documentation repository
- Changes are validated through actual usage in Claude Code sessions
- YAML frontmatter syntax must be valid (proper indentation, quotes)
- Use forward slashes (Unix style) in all file paths
- Command descriptions should start with action verbs and be under 100 characters
