---
argument-hint: [pr_number] [base_branch] - PR number (optional, defaults to all PRs) and base branch (default: upstream/main)
description: Rebase a PR or all open PRs against a base branch and force push updates
allowed-tools: [Bash, TodoWrite, Read, Edit]
---

Rebase a pull request against a specified base branch and force push the updates. If no PR number is specified, rebases all open PRs.

## Usage

### Rebase All Open PRs
```bash
/git:rebase-pr [base_branch]
```

### Rebase Single PR
```bash
/git:rebase-pr <pr_number> [base_branch]
```

## Implementation Steps

### Determine Mode

1. **Parse Arguments**: Check if first argument is a PR number or a branch name
   - If first argument is numeric: Single PR mode
   - If first argument is non-numeric or empty: Batch mode (all PRs)
   - Extract base_branch from appropriate position

### Single PR Mode (when pr_number is provided)

1. **Fetch Latest Changes**: Fetch updates from the remote repository to ensure we have the latest commits (optional, can skip if local is recent)
2. **Checkout PR Branch**: Switch to the PR branch using `gh pr checkout <pr_number>`
3. **Rebase Against Base**: Rebase current branch against specified base branch (default: upstream/main)
4. **Handle Conflicts**: If conflicts occur, stop and report to user for manual resolution
5. **Force Push Updates**: Push the rebased branch with `--force-with-lease` to update the PR safely

### Batch Mode (when no pr_number is provided)

1. **Create Todo List**: Create a todo list to track all PRs that need rebasing
2. **List All Open PRs**: Use `gh pr list --author "@me" --state open` to get all user's open PRs
3. **Check Worktrees**: Use `git worktree list` to identify which PRs are in worktrees vs main directory
4. **Process Each PR Sequentially**:
   - Update todo status to "in_progress" for current PR
   - For worktree branches: Navigate to worktree directory and run `git rebase <base_branch>`
   - For non-worktree branches: Use `gh pr checkout <pr_number>` then rebase
   - If rebase succeeds and branch is up-to-date: Mark as completed, continue to next PR
   - If rebase succeeds with changes: Force push with `--force-with-lease`, mark as completed
   - If rebase has conflicts:
     - Read the conflicted files
     - Resolve conflicts using Edit tool
     - Stage resolved files with `git add`
     - Continue rebase with `git rebase --continue`
     - Force push after successful resolution
   - Mark PR as completed in todo list
   - Handle push failures (e.g., network issues) with retry logic
5. **Summary Report**: Display final status of all PRs (success/failed/skipped)

## Parameters

- `pr_number`: The GitHub PR number to rebase (optional, if not provided will rebase all open PRs)
- `base_branch`: The base branch to rebase against, can include remote (e.g., upstream/main, origin/develop). Default: upstream/main

## Examples

```bash
# Rebase all open PRs against upstream/main (default)
/git:rebase-pr

# Rebase all open PRs against main
/git:rebase-pr main

# Rebase all open PRs against origin/develop
/git:rebase-pr origin/develop

# Rebase single PR #2067 against upstream/main (default)
/git:rebase-pr 2067

# Rebase single PR #2067 against main
/git:rebase-pr 2067 main

# Rebase single PR #2067 against origin/develop
/git:rebase-pr 2067 origin/develop
```

## Notes

- **Automatic Mode Detection**: The command automatically detects whether to rebase a single PR or all PRs based on whether a numeric PR number is provided
- **Conflict Handling**: When conflicts occur in batch mode, the tool will attempt to resolve simple conflicts automatically using the Edit tool. For complex conflicts, it will stop and ask user for guidance
- **Worktree Support**: The command automatically detects and handles PRs in git worktrees by navigating to the worktree directory before rebasing
- **Force Push Safety**: Uses `--force-with-lease` for safer force pushing that prevents overwriting unexpected changes
- **Todo Tracking**: Uses TodoWrite tool to track progress when rebasing multiple PRs
- **Network Issues**: If push fails due to network issues, the command will retry once before reporting failure
- **Skip Up-to-date PRs**: PRs that are already up-to-date with the base branch are quickly marked as completed without requiring a push
- **Prerequisites**:
  - GitHub CLI (`gh`) must be authenticated
  - Must have appropriate permissions to push to origin
  - If using remote/branch format (e.g., upstream/main), the remote must be configured
- **Sign-off**: Remember to sign-off commits if making any new commits during the conflict resolution process
- **Base Branch Default**: If base_branch is not specified, defaults to `upstream/main`