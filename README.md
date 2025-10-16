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

1. Copy to `~/.claude/`
2. Install ScriptFlow MCP
3. Configure audio hooks in settings.json
4. Start using or creating commands
