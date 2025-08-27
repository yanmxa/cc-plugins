# Claude Code Configuration

Personal Claude Code configuration and workflow automation setup.

## 🚀 Overview

This repository contains custom workflows, hooks, and MCP integrations to enhance Claude Code productivity through:

- **Custom Commands**: Pre-built workflows for common development tasks
- **Smart Hooks**: Audio-enabled confirmation system for better UX
- **ScriptFlow MCP**: Efficient script workflow management and automation

## 📁 Structure

```text
.claude/
├── commands/           # Custom workflow commands
│   ├── git/           # Git workflow automation
│   └── globalhub/     # Project-specific workflows
├── configs/           # Configuration files
│   ├── hooks/         # Hook configurations
│   │   └── notifications/  # Audio notification files
│   └── scriptflow/    # ScriptFlow MCP scripts and configs
└── CLAUDE.md         # Global instructions and guidelines
```

## 🔧 Commands Workflows

### Git Workflows (`commands/git/`)

- **`commit.md`**: Git commit guide with best practices
- **`draft-pr.md`**: Automated PR creation workflow  
- **`review-pr.md`**: Systematic PR review process

### Project Workflows (`commands/globalhub/`)

- **`update-manifests.md`**: Global Hub manifest synchronization with scriptflow-mcp

## ⚙️ Configs

### Hooks (`configs/hooks/`)

Audio-enabled confirmation system that provides:

- **Sound notifications**: Confirmation and success audio cues
- **Interactive feedback**: Enhanced user experience during command execution
- **Error prevention**: Audio prompts for destructive operations

**Notification sounds:**

- `confirm.mp3`: Plays when user confirmation is needed
- `success.mp3`: Plays when operations complete successfully

### ScriptFlow MCP (`configs/scriptflow/`)

Powerful script workflow management system for managing shell, Node.js, and Python scripts. Converts workflows into executable scripts with parameter handling.

#### 🔧 Installation

```bash
claude mcp add scriptflow -e SCRIPTFLOW_SCRIPTS_DIR=~/.claude/configs/scriptflow -- npx -y scriptflow-mcp
```

**Reference**: [ScriptFlow MCP GitHub Repository](https://github.com/yanmxa/scriptflow-mcp)

#### 💡 Benefits

##### Commands + ScriptFlow = Double Efficiency

- Convert natural language to executable scripts
- Reusable and version-controlled workflows
- More efficient workflow execution reducing repetitive token consumption
- Reduced latency from multiple LLM interactions, making workflows consume less time

## 🛠 How It Works

1. **Command Definition**: Define workflows in `commands/` using markdown templates
2. **ScriptFlow Integration**: Reference ScriptFlow scripts for complex automation
3. **Hook Notifications**: Get audio feedback during execution
4. **Parameter Parsing**: Natural language converted to script parameters automatically

## 🎯 Benefits

- **Productivity**: Automated common workflows reduce repetitive tasks
- **Consistency**: Standardized processes ensure reliable results
- **Feedback**: Audio notifications provide clear execution status
- **Flexibility**: Easy to extend and customize for new use cases
- **Integration**: Seamless workflow between commands, scripts, and hooks

## 📚 Usage Examples

### Simple Git Commit

```text
Use: commands/git/commit.md
Result: Guided commit process with best practices
```

### Create Feature PR

```text
Use: commands/git/draft-pr.md
Result: Automated branch + commit + PR creation
```

### Update Manifests

```text
Use: commands/globalhub/update-manifests.md  
Example: "update branch release-1.6"
Result: ScriptFlow executes manifest sync workflow
```

## 🚀 Getting Started

1. Clone this configuration to `~/.claude/`
2. Install ScriptFlow MCP (see installation command above)
3. Configure audio notifications (ensure sound files are present)
4. Start using commands with natural language parameters

The combination of structured commands, intelligent scripting, and audio feedback creates a powerful development workflow that gets twice the work done with half the effort.
