---
argument-hint: "[major|minor|patch] [--marketplace] [version] - Bump plugin version (default: patch)"
description: Detect changed plugins and bump their version in plugin.json
allowed-tools: [Bash, Read, Edit, Glob]
---

Detect which plugins have been modified and bump their version numbers accordingly.

## Arguments

- `major` - Bump major version (1.0.0 → 2.0.0)
- `minor` - Bump minor version (1.0.0 → 1.1.0)
- `patch` - Bump patch version (1.0.0 → 1.0.1) **[default]**
- `--marketplace` - Also update marketplace cache version
- `[version]` - Set specific version (e.g., "2.0.0")

## Implementation Steps

### 1. Parse Arguments

Determine bump type from arguments:
- If specific version provided (e.g., "2.0.0"), use that
- If `major`, bump major version
- If `minor`, bump minor version
- If `patch` or no flag, bump patch version
- Note if `--marketplace` flag is present

### 2. Detect Changed Plugins

Find plugins with modifications:

```bash
# Get list of changed files in plugins/ directory
git diff --name-only HEAD -- plugins/

# Also check staged changes
git diff --cached --name-only -- plugins/

# Check untracked files in plugins/
git ls-files --others --exclude-standard plugins/
```

Extract unique plugin names from changed paths (e.g., `plugins/git/commands/...` → `git`).

### 3. Bump Version for Each Changed Plugin

For each detected plugin:

1. **Read current version** from `plugins/<plugin>/.claude-plugin/plugin.json`
2. **Calculate new version**:
   - Parse version: `major.minor.patch`
   - Apply bump logic based on argument
3. **Update plugin.json** using Edit tool

Version bump logic:
```
major: X.Y.Z → (X+1).0.0
minor: X.Y.Z → X.(Y+1).0
patch: X.Y.Z → X.Y.(Z+1)
```

### 4. Update Marketplace Cache (if --marketplace)

If `--marketplace` flag is set, also update the cached plugin version at:
`plugins/cache/<marketplace>/<plugin>/<version>/.claude-plugin/plugin.json`

### 5. Report Results

Output summary of version changes:

```
✅ Plugin versions bumped:

   git: 1.1.1 → 1.1.2
   claude: 1.0.3 → 1.0.4

📁 Updated files:
   plugins/git/.claude-plugin/plugin.json
   plugins/claude/.claude-plugin/plugin.json
```

## Usage Examples

```bash
# Auto-detect changed plugins, bump patch version (default)
/plugin:bump

# Bump minor version for changed plugins
/plugin:bump minor

# Bump major version
/plugin:bump major

# Set specific version
/plugin:bump 2.0.0

# Bump and also update marketplace cache
/plugin:bump patch --marketplace
```

## Notes

- Only bumps plugins under `plugins/` directory (shared plugins)
- Does not modify custom commands/skills in root `commands/` or `skills/`
- If no plugins have changes, reports "No plugin changes detected"
- Version format must be semantic versioning (X.Y.Z)
