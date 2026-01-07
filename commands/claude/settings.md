---
argument-hint: [setting-content] [--project|--user]
description: Update Claude Code settings with permissions, env vars, and announcements
allowed-tools: [Read, Write, Edit, Bash]
---

Update Claude Code settings file with permissions (allow/deny), environment variables, and company announcements. Supports both user-level and project-level configuration.

## Arguments

- `setting-content`: JSON object or key-value to add/update in settings
- `--project`: Update project-level settings (./.claude/settings.local.json)
- `--user`: Update user-level settings (~/.claude/settings.json) (default)

## Implementation Steps

1. **Parse Arguments**: Extract setting content and determine target file
   - Default to user-level: `~/.claude/settings.json`
   - If `--project` flag: `./.claude/settings.local.json`
   - If no arguments, display current settings from both files

2. **Read Current Settings**: Load the appropriate settings file
   - If file doesn't exist, create directory and file with minimal structure: `{ "$schema": "https://json.schemastore.org/claude-code-settings.json" }`
   - Parse existing JSON to preserve all current settings

3. **Merge Settings**: Apply the new settings to existing configuration
   - If input is JSON object: deep merge with existing settings
   - Preserve existing values not specified in update
   - For arrays (permissions.allow, permissions.deny): append new items, avoid duplicates

4. **Write Updated Settings**: Save the modified JSON back to file
   - Format JSON with proper indentation (2 spaces)
   - Ensure valid JSON structure

5. **Display Result**: Show what was updated
   - Show the relevant section that was modified
   - Inform user which file was updated

## Settings File Structure

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Bash(npm run lint)",
      "Bash(npm run test:*)",
      "Read(~/.zshrc)"
    ],
    "deny": [
      "Bash(curl:*)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)"
    ]
  },
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp"
  },
  "companyAnnouncements": [
    "Welcome to Acme Corp! Review our code guidelines at docs.acme.com",
    "Reminder: Code reviews required for all PRs",
    "New security policy in effect"
  ],
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "make fmt"
          }
        ]
      }
    ]
  },
  "enabledPlugins": {
    "claude@cc-plugins": true,
    "git@cc-plugins": true
  }
}
```

## Permission Pattern Examples

### Tool Permissions
- `Bash(git commit:*)` - Git commit commands
- `Bash(kubectl:*)` - All kubectl commands
- `Bash(npm run test:*)` - NPM test scripts
- `Read(/path/to/directory/**)` - Read files in directory
- `WebFetch(domain:github.com)` - Fetch from GitHub

### Skill and Command Permissions
- `Skill(my-prs)` - Allow the my-prs skill
- `SlashCommand(/git:commit-push:*)` - Slash commands

### MCP Tool Permissions
- `mcp__kubernetes-mcp-server__pods_list` - MCP tools

## Usage Examples

### Add permissions to allow list
```bash
/claude/settings '{"permissions":{"allow":["Bash(git commit:*)","Skill(my-prs)"]}}'
```

### Add to deny list (protect sensitive files)
```bash
/claude/settings '{"permissions":{"deny":["Read(./.env)","Read(./secrets/**)"]}}'
```

### Set environment variables
```bash
/claude/settings '{"env":{"CLAUDE_CODE_ENABLE_TELEMETRY":"1"}}'
```

### Add company announcements
```bash
/claude/settings '{"companyAnnouncements":["New security policy in effect"]}'
```

### Update project-level settings
```bash
/claude:settings '{"permissions":{"allow":["Bash(make:*)"]}}' --project
```

### Show current settings
```bash
/claude/settings
```

## Settings File Locations

- **User-level**: `~/.claude/settings.json` - Applies to all projects globally
- **Project-level**: `./.claude/settings.local.json` - Applies only to current project (usually git-ignored)

Project-level settings override user-level settings.

## Common Use Cases

### 1. Auto-approve common development commands
```json
{
  "permissions": {
    "allow": [
      "Bash(npm run:*)",
      "Bash(git status)",
      "Bash(git diff:*)",
      "Bash(make:*)",
      "Bash(go test:*)"
    ]
  }
}
```

### 2. Protect sensitive files and commands
```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Bash(rm -rf:*)",
      "Bash(git push --force:*)"
    ]
  }
}
```

### 3. Enable specific skills and commands
```json
{
  "permissions": {
    "allow": [
      "Skill(my-prs)",
      "SlashCommand(/jira:*)",
      "SlashCommand(/git:commit-push)"
    ]
  }
}
```

### 4. Set up post-tool hooks (auto-format on save)
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "make fmt"
          }
        ]
      }
    ]
  }
}
```

## Notes

- Changes take effect immediately without restarting Claude Code
- Use project-level settings for team-shared configurations
- Project settings typically use `settings.local.json` (git-ignored)
- Permissions use glob patterns with `*` for wildcards
- Arrays in settings are merged (new items appended)
- Objects in settings are deep-merged
- Always use valid JSON format for setting-content argument
