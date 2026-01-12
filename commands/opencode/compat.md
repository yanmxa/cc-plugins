---
argument-hint: "[--user|--project|--all]"
description: "Validate and fix Claude Code configs for OpenCode compatibility"
allowed-tools: ["Bash", "Read", "Edit", "Glob", "Grep", "TodoWrite"]
---

Validate that Claude Code commands, skills, and plugins can be correctly loaded by OpenCode. Automatically fix YAML frontmatter issues that cause parsing errors.

## Implementation Steps

1. **Determine Scope**: Check arguments to determine which paths to validate
   - `--user` or no args: Validate `~/.claude/` (user level)
   - `--project`: Validate `./.claude/` (project level)
   - `--all`: Validate both paths

2. **Set Environment Variable**: Export the config directory for OpenCode
   ```bash
   export OPENCODE_CONFIG_DIR="$HOME/.claude"  # for user level
   # or
   export OPENCODE_CONFIG_DIR="./.claude"  # for project level
   ```

3. **Run Initial Test**: Execute `opencode run "hello world"` to check for errors
   - Capture stderr to identify parsing failures
   - If successful, report "All configs are compatible"

4. **Parse Error Messages**: If errors occur, extract:
   - File path causing the error
   - Line number and column
   - Error type (usually YAML frontmatter parsing)

5. **Fix Common Issues**: For each problematic file:

   **Issue: Unquoted values with brackets**
   ```yaml
   # Before (fails)
   argument-hint: [arg1] (description)

   # After (works)
   argument-hint: "[arg1] (description)"
   ```

   **Issue: Multi-line arrays in frontmatter**
   ```yaml
   # Before (may fail)
   allowed-tools:
     - Bash
     - Read

   # After (works)
   allowed-tools: ["Bash", "Read"]
   ```

   **Issue: Unquoted special characters**
   ```yaml
   # Before (fails)
   description: Sync cluster's config: important!

   # After (works)
   description: "Sync cluster's config: important!"
   ```

6. **Iterate Until Success**: After each fix:
   - Re-run `opencode run "hello world"`
   - If new errors appear, fix them
   - Continue until no errors remain

7. **Report Results**: Summarize:
   - Number of files scanned
   - Number of files fixed
   - List of changes made

## Batch Fix Commands

Use these patterns to fix common issues across all files:

```bash
# Find files with unquoted argument-hint containing brackets
grep -r "argument-hint: \[" ~/.claude/commands/

# Fix argument-hint values (add quotes)
find ~/.claude/commands -name "*.md" -exec grep -l "argument-hint: \[" {} \; | \
  while read file; do
    sed -i '' 's/^argument-hint: \(.*\)$/argument-hint: "\1"/' "$file"
  done
```

## Usage Examples

- `/opencode:compatibility` - Validate user-level configs (~/.claude/)
- `/opencode:compatibility --project` - Validate project-level configs (./.claude/)
- `/opencode:compatibility --all` - Validate both user and project configs
- `/opencode:compatibility --user` - Explicitly validate user-level only

## Notes

- OpenCode uses stricter YAML parsing than Claude Code
- Always quote string values containing special characters: `[]():'"`
- Inline array format `["a", "b"]` is more reliable than multi-line
- OpenCode reads from `.claude/` directories when OPENCODE_CONFIG_DIR is set
- Both `skills/` and `commands/` directories are scanned
- After fixing, changes work with both Claude Code and OpenCode
