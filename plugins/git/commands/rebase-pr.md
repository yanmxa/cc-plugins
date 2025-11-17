---
argument-hint: [pr_number] [remote] - PR number (optional, defaults to all PRs) and remote name (optional, defaults to PR's target remote)
description: Rebase a PR or all open PRs against their target base branch and force push updates
allowed-tools: [Bash, TodoWrite, Read, Edit]
---

Rebase a pull request against its target base branch (from the PR's merge target) and force push the updates. If no PR number is specified, rebases all open PRs.

## Usage

### Rebase All Open PRs
```bash
/git:rebase-pr [remote]
```

### Rebase Single PR
```bash
/git:rebase-pr <pr_number> [remote]
```

## Implementation Steps

### Determine Mode

1. **Parse Arguments**: Check if first argument is a PR number or a remote name
   - If first argument is numeric: Single PR mode
   - If first argument is non-numeric or empty: Batch mode (all PRs)
   - Extract remote name from appropriate position (optional)

### Single PR Mode (when pr_number is provided)

1. **Get PR Information**: Use `gh pr view <pr_number> --json baseRefName,headRepository,isCrossRepository` to get:
   - `baseRefName`: The target branch this PR will merge into (e.g., "main", "develop")
   - `headRepository`: The source repository info
   - `isCrossRepository`: Whether this is a fork PR
2. **Determine Remote and Base Branch**:
   - If `remote` argument is provided: Use `<remote>/<baseRefName>`
   - If PR is cross-repository (fork): Use `upstream/<baseRefName>`
   - Otherwise: Use `origin/<baseRefName>`
3. **Fetch Latest Changes**: Run `git fetch <remote>` to ensure we have the latest commits from the target remote
4. **Checkout PR Branch**: Switch to the PR branch using `gh pr checkout <pr_number>`
5. **Rebase Against Target Base**: Rebase current branch against `<remote>/<baseRefName>`
6. **Handle Conflicts**: If conflicts occur, stop and report to user for manual resolution
7. **Force Push Updates**: Push the rebased branch with `--force-with-lease` to update the PR safely

### Batch Mode (when no pr_number is provided)

1. **Create Todo List**: Create a todo list to track all PRs that need rebasing
2. **List All Open PRs**: Use `gh pr list --author "@me" --state open --json number,headRefName,baseRefName,isCrossRepository` to get all user's open PRs with their target branches
3. **Check Worktrees**: Use `git worktree list` to identify which PRs are in worktrees vs main directory
4. **Process Each PR Sequentially**:
   - Update todo status to "in_progress" for current PR
   - Get PR's `baseRefName` and `isCrossRepository` from the PR list
   - Determine remote: Use provided remote, or `upstream` for forks, or `origin` for same-repo PRs
   - Fetch latest changes: `git fetch <remote>`
   - For worktree branches: Navigate to worktree directory and run `git rebase <remote>/<baseRefName>`
   - For non-worktree branches: Use `gh pr checkout <pr_number>` then rebase against `<remote>/<baseRefName>`
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
- `remote`: The remote name to fetch and rebase against (optional, defaults to `upstream` for fork PRs or `origin` for same-repo PRs)

## Examples

```bash
# Rebase all open PRs against their target branches (auto-detects upstream/origin)
/git:rebase-pr

# Rebase all open PRs, explicitly using upstream remote
/git:rebase-pr upstream

# Rebase all open PRs using origin remote
/git:rebase-pr origin

# Rebase single PR #2067 against its target branch (auto-detects remote)
/git:rebase-pr 2067

# Rebase single PR #2067 using upstream remote
/git:rebase-pr 2067 upstream

# Rebase single PR #2067 using origin remote
/git:rebase-pr 2067 origin
```

## Notes

- **Automatic Mode Detection**: The command automatically detects whether to rebase a single PR or all PRs based on whether a numeric PR number is provided
- **Target Branch Detection**: Each PR is rebased against its actual target branch (from `baseRefName`) rather than a hardcoded branch. For example:
  - PR targeting `main` → rebases against `upstream/main` or `origin/main`
  - PR targeting `develop` → rebases against `upstream/develop` or `origin/develop`
  - PR targeting `release-1.0` → rebases against `upstream/release-1.0` or `origin/release-1.0`
- **Remote Selection**:
  - For fork PRs (`isCrossRepository: true`): Defaults to `upstream` remote
  - For same-repo PRs: Defaults to `origin` remote
  - User can override by providing explicit remote name
- **Conflict Handling**: When conflicts occur in batch mode, the tool will attempt to resolve simple conflicts automatically using the Edit tool. For complex conflicts, it will stop and ask user for guidance
- **Worktree Support**: The command automatically detects and handles PRs in git worktrees by navigating to the worktree directory before rebasing
- **Force Push Safety**: Uses `--force-with-lease` for safer force pushing that prevents overwriting unexpected changes
- **Todo Tracking**: Uses TodoWrite tool to track progress when rebasing multiple PRs
- **Network Issues**: If push fails due to network issues, the command will retry once before reporting failure
- **Skip Up-to-date PRs**: PRs that are already up-to-date with the base branch are quickly marked as completed without requiring a push
- **Prerequisites**:
  - GitHub CLI (`gh`) must be authenticated
  - Must have appropriate permissions to push to PR branch
  - The appropriate remote (`upstream` or `origin`) must be configured
- **Sign-off**: Remember to sign-off commits if making any new commits during the conflict resolution process