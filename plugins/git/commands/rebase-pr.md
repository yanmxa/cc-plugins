---
argument-hint: [pr_number] [base_branch] - PR number and base branch (default: upstream/main)
description: Rebase a PR against a base branch and force push updates
allowed-tools: [Bash]
---

Rebase a pull request against a specified base branch (default: upstream/main) and force push the updates.

## Implementation Steps

1. **Fetch Latest Changes**: Fetch updates from upstream repository to ensure we have the latest commits
2. **Checkout PR Branch**: Switch to the PR branch using `gh pr checkout $1` if PR number provided, otherwise stay on current branch
3. **Rebase Against Base**: Rebase current branch against specified base branch (default: upstream/main if $2 not provided)
4. **Force Push Updates**: Push the rebased branch with `--force-with-lease` to update the PR safely

## Notes
- If no rebase branch is specified, defaults to upstream/main
- If no PR is specified, rebase current branch against base branch and push
- Use `--force-with-lease` for safer force pushing that prevents overwriting unexpected changes
- The command handles both specific PR rebasing and current branch rebasing scenarios
- Prerequisites: Must have upstream remote configured and appropriate permissions to push
- Remember to sign-off commits if making any new commits during the process