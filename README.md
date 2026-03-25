# Claude Code Plugins Collection

> Productivity-focused Claude Code plugins — automate Git, Jira, and meta-development workflows

A collection of [Claude Code plugins](https://www.anthropic.com/news/claude-code-plugins) that streamline common development tasks.

## Plugins

### git

Git workflow automation with two skills:

| Skill | Description |
|-------|-------------|
| **pr** | Full PR lifecycle — create, list, compact commits, rebase. Includes fork detection, DCO sign-off, and idempotent scripts. |
| **push** | Commit with sign-off and push to origin. Conventional commit format. |

### jira

Jira Cloud REST API v3 CLI and shell library:

| Skill | Description |
|-------|-------------|
| **jira** | Sprint board, issue CRUD, JQL search, workflow transitions, comments, links, and ADF builders. Bundled CLI (`jira-ops`) and sourceable shell library (`jira-ops.sh`). |

### claude

Meta-development plugin for extending Claude Code itself:

| Skill | Description |
|-------|-------------|
| **create-command** | Extract current workflows into reusable slash commands |
| **create-subagent** | Create specialized subagents with custom instructions |

## Installation

```bash
# Add this repository as a plugin marketplace
/plugin marketplace add https://github.com/yanmxa/cc-plugins

# Install individual plugins
/plugin install git
/plugin install jira
/plugin install claude

# Browse available plugins
/plugin marketplace list
```

## Architecture

Skills use `${CLAUDE_SKILL_DIR}` for portable script paths — works both as user-scope skills and installed plugins.

```
plugins/
├── claude/           # Meta-development skills
├── git/              # PR lifecycle + push
│   └── skills/
│       ├── pr/       # create, list, compact, rebase PRs
│       └── push/     # commit + push with sign-off
└── jira/             # Jira CLI and shell library
    └── skills/
        └── jira/     # Full Jira operations
```

## Contributing

Contributions welcome! Submit pull requests or open issues for new plugin ideas or improvements.

## License

MIT License
