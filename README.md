# cc-plugins

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin marketplace — install skills to automate Git, Jira, and meta-development workflows directly in your terminal.

## Quick Start

```bash
# Add marketplace
/plugin marketplace add https://github.com/yanmxa/cc-plugins

# Install plugins
/plugin install git
/plugin install jira
/plugin install claude
```

## Plugins

### git

Automates the full Git workflow — commit/push with DCO sign-off, create PRs (fork + branch + submit), list PRs across repos, squash commits, and batch rebase.

```
Bundled scripts: 01-fork-and-setup.sh, 03-create-pr.sh, show-prs.sh
```

### jira

Jira Cloud REST API v3 CLI and shell library. Sprint boards, issue CRUD, JQL search, workflow transitions, comments, links, and ADF builders — all from the terminal.

```
Bundled: jira-ops CLI + jira-ops.sh sourceable library
```

### claude

Meta-development plugin for extending Claude Code itself — extract workflows into reusable slash commands or create specialized subagents.

## How It Works

Each plugin bundles skills with `SKILL.md` definitions and supporting scripts. Skills use `${CLAUDE_SKILL_DIR}` for portable paths, so they work regardless of where Claude Code installs them.

```
plugins/
├── claude/                        # Meta-development
│   └── skills/
│       ├── create-command/
│       └── create-subagent/
├── git/                           # Git automation
│   └── skills/git/
│       └── scripts/               # Fork, PR, show-prs
└── jira/                          # Jira operations
    └── skills/jira/
        ├── scripts/               # CLI + shell library
        └── references/            # API docs
```

## Contributing

PRs and issues welcome.

## License

MIT
