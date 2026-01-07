---
argument-hint: "<type>:<name> <plugin> - Move command/skill/agent to shared plugin (e.g., command:bump-version git)"
description: Move a custom command, skill, or agent to a shared plugin and bump minor version
allowed-tools: [Bash, Read, Write, Edit, Glob]
---

Move a custom command, skill, or agent from personal configuration to a shared plugin directory, then bump the plugin's minor version.

## Arguments

- `<type>:<name>` - The item to share:
  - `command:<category/name>` - e.g., `command:plugin/bump-version`
  - `skill:<name>` - e.g., `skill:link-jira-pr`
  - `agent:<name>` - e.g., `agent:ml-engineer`
- `<plugin>` - Target plugin name (e.g., `git`, `claude`)

## Implementation Steps

### 1. Parse Arguments

Extract from arguments:
- **Type**: `command`, `skill`, or `agent`
- **Name**: The item name (may include category for commands)
- **Plugin**: Target plugin name

### 2. Validate Source and Target

**Source paths**:
- Commands: `~/.claude/commands/<category>/<name>.md`
- Skills: `~/.claude/skills/<name>/` (directory with SKILL.md)
- Agents: `~/.claude/agents/<name>.md`

**Target paths**:
- Commands: `~/.claude/plugins/<plugin>/commands/<name>.md`
- Skills: `~/.claude/plugins/<plugin>/skills/<name>/`
- Agents: `~/.claude/plugins/<plugin>/agents/<name>.md`

Verify:
1. Source exists
2. Target plugin exists (`plugins/<plugin>/.claude-plugin/plugin.json`)
3. Target doesn't already exist (or confirm overwrite)

### 3. Move the Item

**For commands**:
```bash
# Create target directory if needed
mkdir -p ~/.claude/plugins/<plugin>/commands/

# Copy command file
cp ~/.claude/commands/<category>/<name>.md ~/.claude/plugins/<plugin>/commands/<name>.md
```

**For skills** (copy entire directory):
```bash
# Create target directory if needed
mkdir -p ~/.claude/plugins/<plugin>/skills/

# Copy skill directory
cp -r ~/.claude/skills/<name>/ ~/.claude/plugins/<plugin>/skills/<name>/
```

**For agents**:
```bash
# Create target directory if needed
mkdir -p ~/.claude/plugins/<plugin>/agents/

# Copy agent file
cp ~/.claude/agents/<name>.md ~/.claude/plugins/<plugin>/agents/<name>.md
```

### 4. Bump Plugin Minor Version

Read current version from `plugins/<plugin>/.claude-plugin/plugin.json` and bump minor:
- `1.0.3` → `1.1.0`
- `2.1.5` → `2.2.0`

Update the plugin.json file.

### 5. Clean Up Source (Optional)

Ask user if they want to remove the original source file/directory after successful move.

### 6. Report Results

```
✅ Shared to plugin: <plugin>

📦 Moved:
   <type>: <name>
   From: ~/.claude/<type>s/<name>
   To:   ~/.claude/plugins/<plugin>/<type>s/<name>

📈 Version bumped:
   <plugin>: X.Y.Z → X.(Y+1).0

💡 Next steps:
   - Review changes: git diff plugins/<plugin>/
   - Commit: /git:push-updates
```

## Usage Examples

```bash
# Move a command to git plugin
/plugin:share command:plugin/bump-version git

# Move a skill to claude plugin
/plugin:share skill:link-jira-pr claude

# Move an agent to a plugin
/plugin:share agent:ml-engineer claude

# Move command with nested category
/plugin:share command:jira/my-issues jira-tools
```

## Notes

- Only moves to plugins under `~/.claude/plugins/` (shared plugins)
- Uses minor version bump by default (feature addition)
- Preserves directory structure for skills (includes scripts, etc.)
- Does not automatically delete source - asks for confirmation
- If target exists, warns and asks for confirmation before overwriting
