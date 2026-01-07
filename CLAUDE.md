# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository (`~/.claude`) serves dual purposes:
1. **Shared Plugins Repository** (`cc-plugins`): Publishable Claude Code plugins for workflow automation
2. **Personal Configuration**: Custom skills, commands, agents, and settings for local use

## Repository Structure

### Shared Plugins (Published to cc-plugins marketplace)

These plugins are tracked in git and published for others to install:

```
plugins/
├── claude/           # Meta-development plugin - create new slash commands from workflows
│   └── commands/     # /create-command, /create-skill, /create-subagent
└── git/              # Git workflow automation plugin
    ├── commands/     # /compact-commits, /create-pr, /create-worktree, /push-updates, /rebase-pr
    └── skills/       # pr, my-prs, create-pr skills
```

### Custom User Configuration (Local only, not published)

Personal productivity configurations tracked in git but not published:

```
commands/             # Custom slash commands organized by domain
├── aws/              # EC2 instance management (ec2-create, ec2-start, ec2-stop)
├── claude/           # Claude settings management
├── codex/            # OpenAI Codex integration
├── dev/              # Development environment setup
├── globalhub/        # Global Hub specific commands
├── jira/             # Jira workflow commands (my-issues, sprint-issues, gh-issue)
├── kube/             # Kubernetes utilities (kube magic)
├── ocp/              # OpenShift commands
└── report/           # Status report generation (weekly, quarterly)

skills/               # Custom skills with scripts
├── clone-database/   # Clone MySQL/PostgreSQL from remote to local
├── fetch-remote/     # Download files via SSH/SCP or HTTP
├── init-mysql-mac/   # MySQL server setup on macOS
├── init-postgres-mac/# PostgreSQL with pgvector on macOS
├── kube:mv/          # Move K8s resources between clusters
└── link-jira-pr/     # Cross-link Jira issues with GitHub PRs

agents/               # Custom subagents
└── ml-engineer.md    # Machine Learning Engineering specialist

scripts/              # Shell scripts used by skills/commands
├── jira-my-issues.sh
├── kube-magic.sh
└── kube-magic-cli.sh

hooks/                # Event hooks
└── notifications/    # Audio notifications (confirm.mp3, success.mp3)
```

## Plugin Marketplaces

Three marketplaces are configured in `plugins/known_marketplaces.json`:

| Marketplace | Source | Description |
|-------------|--------|-------------|
| `cc-plugins` | Local directory | This repository's shared plugins |
| `acm-workflows-plugins` | stolostron/acm-workflows | Red Hat ACM team plugins (jira-tools, qe-toolkit) |
| `claude-plugins-official` | anthropics/claude-plugins-official | Official Anthropic plugins |

## Installed Plugins

Active plugins configured in `settings.json`:

- `claude@cc-plugins` - Meta-development for creating new commands/skills
- `git@cc-plugins` - Git workflow automation
- `jira-tools@acm-workflows-plugins` - Jira operations and test planning
- `gopls-lsp@claude-plugins-official` - Go language server support

## Key Commands Reference

### Git Workflow (from git plugin)
- `/compact-commits` - Squash all PR commits into one with DCO sign-off
- `/create-pr` or `/pr` - Fork, branch, commit, and submit PRs
- `/create-worktree` - Create git worktree with intelligent naming
- `/push-updates` - Commit with sign-off and push to origin
- `/rebase-pr` - Rebase PR(s) against target base branch
- `/my-prs` - Display GitHub PRs across all repositories

### Jira Workflow (custom)
- `/jira:my-issues [7d|14d|30d]` - List your assigned Jira issues
- `/jira:sprint-issues` - Sprint issues grouped by assignee
- `/jira:gh-issue` - Manage Global Hub Jira issues

### Reports (custom)
- `/report:weekly-report [7d]` - Generate categorized weekly status report
- `/report:quarterly-report` - Comprehensive quarterly work report
- `/report:quarterly-goal` - Quarterly goal statements with progress tracking

### Infrastructure (custom)
- `/aws:ec2-create` - Create AWS EC2 instance
- `/aws:ec2-start` / `/aws:ec2-stop` - Start/stop EC2 instances
- `/kube:magic` - Interactive Kubernetes commands with fzf
- `/ocp:sync-pull-secret` - Sync pull secret between OpenShift clusters

## Guidelines

### Test Writing
- Ensure test code is easy to debug; avoid excessive nesting
- Run only user-specified or change-related test cases
- If an error occurs, exit immediately to debug the first issue

### Security
- Never display or transmit keys/credentials over network; load locally

### Git Best Practices
- Avoid `git add .`; only commit necessary modified files
- Create PRs using the `/pr` skill
- Use `jira-tools:jira-administrator` agent for Jira operations

## Settings Configuration

Key settings in `settings.json`:
- Always thinking enabled
- Notification hooks: Audio feedback on Notification and Stop events
- Auto-allowed commands: `jira sprint:*`, `jira me:*`, `git add:*`, `git push:*`

## Development Notes

### Adding New Shared Plugins
1. Create plugin directory under `plugins/`
2. Add `.claude-plugin/plugin.json` manifest
3. Add commands under `commands/` and skills under `skills/`
4. Commit and push to update the marketplace

### Adding Custom Commands/Skills
1. Create markdown file in appropriate `commands/` or `skills/` subdirectory
2. Use frontmatter for metadata (name, description, allowed-tools)
3. Commands/skills are available immediately (no installation needed)
