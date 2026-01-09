---
argument-hint: "[major|minor|patch|version] - Bump plugin version (default: patch)"
description: Detect changed plugins and bump their version in plugin.json
allowed-tools: [Bash, Read, Edit, Glob]
---

Detect which plugins have been modified and bump their version numbers accordingly.

## Arguments

- `major` - Bump major version (1.0.0 → 2.0.0)
- `minor` - Bump minor version (1.0.0 → 1.1.0)
- `patch` - Bump patch version (1.0.0 → 1.0.1) **[default]**
- `[version]` - Set specific version (e.g., "2.0.0")

## Implementation Steps

### 1. Parse Arguments

Determine bump type from arguments:
- If specific version provided (e.g., "2.0.0"), use that
- If `major`, bump major version
- If `minor`, bump minor version
- If `patch` or no flag, bump patch version

### 2. Detect Changed Plugins

Find plugins with modifications (excluding cache, repos, marketplaces, installed_plugins.json, known_marketplaces.json):

```bash
# Get list of changed files in plugins/ directory (excluding non-plugin dirs)
git diff --name-only HEAD -- plugins/ | grep -v -E '^plugins/(cache|repos|marketplaces|installed_plugins|known_marketplaces)'

# Also check staged changes
git diff --cached --name-only -- plugins/ | grep -v -E '^plugins/(cache|repos|marketplaces|installed_plugins|known_marketplaces)'

# Check untracked files in plugins/ (excluding non-plugin dirs)
git ls-files --others --exclude-standard plugins/ | grep -v -E '^plugins/(cache|repos|marketplaces|installed_plugins|known_marketplaces)'
```

Extract unique plugin names from changed paths (e.g., `plugins/git/commands/...` → `git`).

**Important**: Only process directories that have `.claude-plugin/plugin.json` - these are the actual plugin sources.

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

### 4. Report Results

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
```

## Notes

- Only bumps source plugins at `plugins/<name>/.claude-plugin/plugin.json`
- Excludes `plugins/cache/`, `plugins/repos/`, `plugins/marketplaces/` (managed by plugin system)
- Does not modify custom commands/skills in root `commands/` or `skills/`
- If no plugins have changes, reports "No plugin changes detected"
- Version format must be semantic versioning (X.Y.Z)
