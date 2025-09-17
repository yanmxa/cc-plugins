---
argument-hint: No arguments required
description: Fix Claude Code auto-update issues using automated ScriptFlow script
allowed-tools: [mcp__scriptflow__script_run, Bash]
---

Fix Claude Code auto-update failures using the automated ScriptFlow script.

## Implementation Steps

1. **Run ScriptFlow auto-fix script**: Execute the automated script that handles the entire fix process
   ```bash
   mcp__scriptflow__script_run claude-fix-auto-update
   ```

## Notes

- Use this when you see errors like "Auto-update failed · Try claude doctor or npm i -g @anthropic-ai/claude-code"
- The `claude doctor` command may fail with terminal interface issues, so this manual approach is more reliable
- This workflow handles the common ENOTEMPTY errors when npm can't overwrite existing directories
- After completion, auto-updates should work normally again
- Works on macOS with Homebrew-installed Node.js (adjust paths for other systems)

## Common Error Patterns

- `ENOTEMPTY: directory not empty, rename`
- `Raw mode is not supported on the current process.stdin`
- Auto-update failures in Claude Code