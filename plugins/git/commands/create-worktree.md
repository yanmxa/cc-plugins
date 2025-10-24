---
argument-hint: [worktree-name-or-description] [source-branch] [--cursor|--code|--tmux]
description: Create a git worktree with intelligent naming and branch creation
allowed-tools: [Bash, TodoWrite]
---

Creates a new git worktree with automatic naming conventions and branch management. Supports optional parameters for customization and integration with editors/tmux.

## Implementation Steps

1. **Plan Worktree Creation**: Create todo list to track worktree creation and navigation tasks

2. **Parse Arguments**:
   - Check if arguments contain `--cursor`, `--code`, or `--tmux` flags
   - Extract worktree name/description from remaining arguments (filter out flags)
   - Extract source branch if provided (second non-flag argument)

3. **Determine Worktree Configuration**:
   - If worktree name provided: Use as worktree name/description to generate appropriate directory name and branch name
   - If not provided: Analyze current git status and staged changes to auto-generate meaningful worktree and branch names
   - Use source branch if provided, otherwise default to current branch

4. **Create Worktree with Smart Naming**:
   - Generate worktree directory using format: `../project-name__feature-name` (double underscore separator)
   - Create new branch with descriptive name based on the worktree purpose
   - Use command: `git worktree add ../worktree-directory -b branch-name source-branch`

5. **Open in Editor/Terminal** (if flag specified):
   - If `--cursor` flag: Run `cursor <worktree-absolute-path>` to open in Cursor editor
   - If `--code` flag: Run `code <worktree-absolute-path>` to open in VS Code
   - If `--tmux` flag: Run `tmux split-window -h -c <worktree-absolute-path>` to split pane in current tmux session and cd to worktree
   - If no flag: Skip this step

6. **Complete Task Tracking**: Mark all todo items as completed

## Notes
- Uses double underscore (`__`) separator between project name and feature name for clear visual distinction
- Automatically handles branch name conflicts by generating unique names
- If no parameters provided, analyzes git diff and status to suggest appropriate names
- Worktree is created in parent directory to avoid conflicts with current repository
- Source branch defaults to current branch if not specified

## Editor/Terminal Integration
- `--cursor`: Opens the worktree in Cursor editor after creation
- `--code`: Opens the worktree in VS Code after creation
- `--tmux`: Creates a horizontal split pane in current tmux session and navigates to worktree
- Flags can be placed anywhere in the command arguments
- Only one editor/terminal flag should be used at a time

## Usage Examples
- `/git:create-worktree integration-logs` - Creates worktree for integration log work
- `/git:create-worktree "fix auth bug" develop` - Creates worktree from develop branch for auth fix
- `/git:create-worktree` - Auto-generates name based on current changes
- `/git:create-worktree fix-e2e --cursor` - Creates worktree and opens in Cursor editor
- `/git:create-worktree "add feature" --code` - Creates worktree and opens in VS Code
- `/git:create-worktree refactor develop --tmux` - Creates worktree from develop and opens in new tmux pane
- `/git:create-worktree --cursor bug-fix` - Creates worktree and opens in Cursor (flag can be anywhere)