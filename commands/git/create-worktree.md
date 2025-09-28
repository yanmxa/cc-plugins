---
argument-hint: [worktree-name-or-description] [source-branch]
description: Create a git worktree with intelligent naming and branch creation
allowed-tools: [Bash, TodoWrite]
---

Creates a new git worktree with automatic naming conventions and branch management. Supports optional parameters for customization.

## Implementation Steps

1. **Plan Worktree Creation**: Create todo list to track worktree creation and navigation tasks

2. **Determine Worktree Configuration**:
   - If `$1` provided: Use as worktree name/description to generate appropriate directory name and branch name
   - If `$1` not provided: Analyze current git status and staged changes to auto-generate meaningful worktree and branch names
   - Use `$2` as source branch if provided, otherwise default to current branch

3. **Create Worktree with Smart Naming**:
   - Generate worktree directory using format: `../project-name__feature-name` (double underscore separator)
   - Create new branch with descriptive name based on the worktree purpose
   - Use command: `git worktree add ../worktree-directory -b branch-name source-branch`

4. **Navigate to New Worktree**: Switch to the newly created worktree directory and confirm successful creation

5. **Complete Task Tracking**: Mark all todo items as completed

## Notes
- Uses double underscore (`__`) separator between project name and feature name for clear visual distinction
- Automatically handles branch name conflicts by generating unique names
- If no parameters provided, analyzes git diff and status to suggest appropriate names
- Worktree is created in parent directory to avoid conflicts with current repository
- Source branch defaults to current branch if not specified

## Usage Examples
- `/git:create-worktree integration-logs` - Creates worktree for integration log work
- `/git:create-worktree "fix auth bug" develop` - Creates worktree from develop branch for auth fix
- `/git:create-worktree` - Auto-generates name based on current changes