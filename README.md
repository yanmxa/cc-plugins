# Claude Code Configuration

Personal Claude Code setup with custom slash commands, ScriptFlow MCP integration, and audio hooks.

## Key Features

### Slash Commands

- **Jira integration**: Issue management and PR linking
- **Project automation**: Custom workflows for specific projects

### ScriptFlow MCP

Converts natural language workflows into executable scripts for better efficiency and lower latency.

**Installation:**

```bash
claude mcp add scriptflow -e SCRIPTFLOW_SCRIPTS_DIR=~/.claude/configs/scriptflow -- npx -y scriptflow-mcp
```

**Reference**: [ScriptFlow MCP](https://github.com/yanmxa/scriptflow-mcp)

### Audio Hooks

Audio notifications for command execution feedback.

**Setup** in `~/.claude/settings.json`:

```json
"hooks": {
  "Notification": [{
    "matcher": "",
    "hooks": [{"type": "command", "command": "afplay ~/.claude/configs/hooks/notifications/confirm.mp3"}]
  }],
  "Stop": [{
    "matcher": "",
    "hooks": [{"type": "command", "command": "afplay ~/.claude/configs/hooks/notifications/success.mp3"}]
  }]
}
```

## Usage Examples

```bash
# Jira workflow
/jira:my-issues 7d john.doe

# Project automation
/globalhub:update-manifests release-1.6
```

## Getting Started

### Clone the Repository

Clone this repository into your `~/.claude` directory to enable all configurations:

```bash
# Backup your existing .claude directory if it exists
mv ~/.claude ~/.claude.backup

# Clone the repository
git clone -b claude-code-settings https://github.com/yanmxa/cc-plugins.git ~/.claude

# Or if you already have a .claude directory, merge the configs
cd ~/.claude
git init
git remote add origin https://github.com/yanmxa/cc-plugins.git
git fetch origin claude-code-settings
git checkout claude-code-settings
```

### Setup Steps

1. Install ScriptFlow MCP (if not already installed)
2. Configure audio hooks in [settings.json](settings.json) if desired
3. Start using the slash commands or create your own
