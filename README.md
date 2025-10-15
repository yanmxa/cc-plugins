# Claude Code Plugins Collection

> Claude Code plugins for lazy developers (in a good way) - automate and capture workflows to reclaim your time

A collection of [Claude Code plugins](https://www.anthropic.com/news/claude-code-plugins) that turn repetitive tasks into one-liners.

**Repository**: [https://github.com/yanmxa/claude-code-plugins](https://github.com/yanmxa/claude-code-plugins)

## Plugins

### claude-dev

A meta-development plugin that enables Claude Code to create new slash commands from current workflows, making it easy to capture and reuse common patterns.

### git-toolkit

Comprehensive Git workflow automation plugin providing slash commands for commit, push, PR creation, worktree management, code review, and more.

## Installation

```bash
# Add this repository as a plugin marketplace
/plugin marketplace add github:yanmxa/claude-code-plugins

# Install individual plugins
/plugin install claude-dev
/plugin install git-toolkit

# Or browse available plugins
/plugin marketplace list
```

## Use Cases

- **Workflow Automation**: Convert manual multi-step processes into single slash commands
- **Team Standards**: Share consistent development practices across teams
- **Productivity**: Reduce repetitive typing and errors in common operations
- **Self-Improvement**: Use claude-dev to continuously extend Claude Code capabilities based on your workflows

## About Claude Code Plugins

Claude Code plugins are custom collections of slash commands, agents, MCP servers, and hooks that install with a single command. They enable sharing productivity workflows, enforcing development standards, connecting to internal tools, and bundling related customizations.

Learn more: [Claude Code Plugins Announcement](https://www.anthropic.com/news/claude-code-plugins)

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for new plugin ideas or improvements to existing commands.

## License

MIT License - feel free to use and adapt these plugins for your own workflows.
