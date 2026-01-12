---
argument-hint: "<repo-url> <problem-description> [--contribute]"
description: Explore OSS issues and optionally contribute fixes - research by default, add --contribute for full PR workflow
---

Explore open source projects to investigate issues. Default is research mode (read-only). Add `--contribute` flag to execute full contribution workflow with fix and PR.

## Input Parameters

- **repo-url**: Repository URL (e.g., `https://github.com/org/repo` or `org/repo`)
- **problem-description**: Description of the bug or issue to investigate
- **--contribute**: Optional flag to enable full contribution mode (fork, fix, issue, PR)

---

## Default: Research Mode

Investigate the problem without making changes.

### 1. Clone Repository

- Clone the repository if not already local (read-only, no fork needed)
- Checkout the main/dev branch

### 2. Search Related Issues

- Search GitHub issues for related problems:
  ```bash
  gh issue list --repo <upstream> --search "<keywords>" --state all
  ```
- Check closed issues for previous fixes or workarounds
- Read through discussions for context

### 3. Explore Codebase

- Use Grep/Glob to find relevant files based on keywords
- Read key files to understand the implementation
- Trace the code flow related to the problem
- Use git log/blame to find related commits

### 4. Output Research Summary

Summarize findings:
- Related issues found (with links)
- Root cause hypothesis
- Affected files and functions
- Potential fix approaches
- Complexity assessment (simple/medium/complex)

Ask: "Do you want to proceed to contribute? Run with --contribute flag."

---

## With --contribute: Full Contribution Mode

Complete workflow including fix and PR.

### 1. Setup Repository

- Clone repo if not local
- Create fork if not exists: `gh repo fork`
- Configure remotes:
  - `origin` → user's fork
  - `upstream` → original repository
- Fetch latest from upstream

### 2. Research Phase

- Search GitHub issues for related problems
- Explore codebase to understand implementation
- Identify root cause and affected files

### 3. Implement Fix

- Create branch: `git checkout -b fix/<name> upstream/main`
- Make code changes
- Add/update tests
- Run tests to verify

### 4. Commit

- Stage necessary files only
- Commit with sign-off:
  ```bash
  git commit -s -m "fix: description

  Detailed explanation.

  Ref: <related-commit>

  Signed-off-by: Name <email>"
  ```

### 5. Create Issue

- Create issue in upstream:
  ```bash
  gh issue create --repo <upstream> --title "<title>" --body "<body>"
  ```
- Include: problem description, root cause, proposed fix

### 6. Submit PR

- Push: `git push -u origin <branch>`
- Create PR:
  ```bash
  gh pr create --repo <upstream> --base <main> --head <user>:<branch>
  ```
- Link to issue (Fixes #xxx)

---

## Usage Examples

```bash
# Research mode (default) - investigate only
/oss:explore anomalyco/opencode "commands lose prefix in nested directories"

# Contribute mode - full workflow with fix and PR
/oss:explore anomalyco/opencode "nested commands lose prefix" --contribute
```

## Notes

- Start without --contribute to understand complexity first
- Check CONTRIBUTING.md for project guidelines
- Keep commits atomic and well-documented
