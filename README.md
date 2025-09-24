# Claude Code Configuration

Personal Claude Code configuration and workflow automation setup.

## 🚀 Overview

This repository contains custom workflows, hooks, and MCP integrations to enhance Claude Code productivity through:

- **Slash Commands**: Pre-built workflows with automatic command creation capabilities
- **ScriptFlow Integration**: Efficient script workflow management and automation
- **Smart Configurations**: Audio hooks, MCP settings, and system integrations

## 📁 Structure

```text
.claude/
├── commands/           # Custom slash command workflows
│   ├── claude/         # Meta-commands for command creation
│   ├── git/            # Git workflow automation
│   ├── jira/           # Jira integration workflows
│   └── globalhub/      # Project-specific workflows
├── configs/            # Configuration files
│   ├── hooks/          # Hook configurations with audio notifications
│   └── scriptflow/     # ScriptFlow MCP scripts and configs
└── CLAUDE.md          # Global instructions and guidelines
```

## 🔧 Slash Commands

### Self-Creating Commands (`commands/claude/`)

- **`command-create.md`**: Automatically extract and save current session workflows as reusable slash commands
  - **Usage**: `/claude:command-create [category/name]` or leave empty for auto-detection
  - **Auto-detection**: Analyzes workflow patterns to categorize appropriately

### Available Command Categories

- **Git Workflows** (`commands/git/`): Commit, PR creation, and review processes
- **Jira Integration** (`commands/jira/`): Issue management and GitHub PR linking
- **Project Workflows** (`commands/globalhub/`): Project-specific automation workflows

## 📜 ScriptFlow MCP (Supplement)

Powerful script workflow management system that converts natural language workflows into executable scripts.

### 🔧 Installation

```bash
claude mcp add scriptflow -e SCRIPTFLOW_SCRIPTS_DIR=~/.claude/configs/scriptflow -- npx -y scriptflow-mcp
```

**Reference**: [ScriptFlow MCP GitHub Repository](https://github.com/yanmxa/scriptflow-mcp)

### 💡 Commands + ScriptFlow = Double Efficiency

- **Convert workflows**: Natural language → executable scripts
- **Reusable automation**: Version-controlled workflows
- **Reduced token consumption**: More efficient workflow execution
- **Lower latency**: Less LLM interactions, faster execution

### Script Management

ScriptFlow scripts are stored in `configs/scriptflow/` and can be:
- **Created**: Convert any workflow to a reusable script
- **Executed**: Run with parameters through slash commands
- **Managed**: List, edit, and remove scripts as needed

## ⚙️ Configurations

### Hooks (`configs/hooks/`)

Audio-enabled confirmation system that provides:

- **Sound notifications**: Confirmation and success audio cues
- **Interactive feedback**: Enhanced user experience during command execution
- **Error prevention**: Audio prompts for destructive operations

**Notification sounds:**

- `confirm.mp3`: Plays when user confirmation is needed
- `success.mp3`: Plays when operations complete successfully

**Setup**: Add to your `~/.claude/settings.json`:

```json
"hooks": {
  "Notification": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "afplay ~/.claude/configs/hooks/notifications/confirm.mp3"
        }
      ]
    }
  ],
  "Stop": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "afplay ~/.claude/configs/hooks/notifications/success.mp3"
        }
      ]
    }
  ]
}
```

### ScriptFlow Scripts (`configs/scriptflow/`)

Automated scripts created and managed through ScriptFlow MCP:
- Shell scripts for system operations
- Node.js scripts for complex automation
- Python scripts for data processing
- Parameter handling and validation

## 🛠 How It Works

1. **Slash Commands**: Use pre-built workflows or create new ones automatically
2. **Command Creation**: `/claude:command-create` extracts current session workflows
3. **ScriptFlow Integration**: Complex automation through executable scripts
4. **Hook Notifications**: Audio feedback during execution
5. **Parameter Parsing**: Natural language converted to command/script parameters

## 🎯 Benefits

- **Productivity**: Automated common workflows reduce repetitive tasks
- **Consistency**: Standardized processes ensure reliable results
- **Feedback**: Audio notifications provide clear execution status
- **Flexibility**: Easy to extend and customize for new use cases
- **Integration**: Seamless workflow between commands, scripts, and hooks

## 📚 Usage Examples

### Create New Command from Session

```text
# After completing a workflow:
/claude:command-create docker/build-prod
# Result: Saves current session as reusable docker/build-prod.md command
```

### Git Operations

```text
/git:commit-push --push
# Result: Commits changes with sign-off and pushes to origin
```

### Jira Integration

```text
/jira:my-issues
# Result: Shows current sprint issues organized by status

/jira:my-issues 7d john.doe
# Result: Shows john.doe's issues from last 7 days
```

### Project Automation

```text
/globalhub:update-manifests release-1.6
# Result: ScriptFlow executes manifest sync workflow
```

## 🚀 Getting Started

1. **Clone Configuration**: Copy this setup to `~/.claude/`
2. **Install ScriptFlow**: Run the MCP installation command
3. **Configure Audio**: Add hooks to `settings.json` and ensure sound files exist
4. **Start Creating**: Use existing commands or create new ones with `/claude:command-create`

The combination of self-creating slash commands, intelligent scripting, and audio feedback creates a powerful development workflow that evolves with your needs while providing instant productivity gains.
