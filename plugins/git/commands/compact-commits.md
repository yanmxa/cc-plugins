---
argument-hint: [pr_number]
description: Compact all commits in a GitHub PR into a single commit with comprehensive message and DCO sign-off
allowed-tools: [Bash]
---

Compact multiple commits in a GitHub Pull Request into a single commit while preserving all changes and creating a comprehensive commit message with proper DCO sign-off.

## Implementation Steps

1. **Examine PR Structure**: View the PR details and commit history to understand what needs to be compacted using `gh pr view $1`
2. **Checkout PR Branch**: Switch to the PR branch using `gh pr checkout $1` to work with the commits locally
3. **Compact Commits**: Use `git reset --soft HEAD~N` (where N is number of commits) to stage all changes from multiple commits, then create a single comprehensive commit with `git commit --signoff`
4. **Force Push Update**: Push the compacted commit back to the PR branch using `git push --force-with-lease` to update the remote PR
5. **Verify Results**: Confirm the PR now shows only one commit with all the original changes preserved and proper DCO sign-off

## Notes
- This command is useful for cleaning up PR history before merging
- Preserves all code changes while creating a clean, single commit
- Includes DCO sign-off required by many projects
- The comprehensive commit message includes all relevant details from the original commits
- Uses `--force-with-lease` for safer force pushing
- Works with any GitHub repository that has PR access