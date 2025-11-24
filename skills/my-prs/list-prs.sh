#!/bin/bash
# List all open pull requests authored by the current user across all repositories
# with status indicators and clickable links, grouped by repository

set -euo pipefail

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed"
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed"
    echo "Install it using: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

echo "**Your Open PRs:**"
echo ""

# Get all open PRs to find unique repositories
repos=$(gh search prs --author "@me" --state=open --limit 100 2>/dev/null | awk '{print $1}' | sort -u)

if [ -z "$repos" ]; then
    echo "No open pull requests found."
    exit 0
fi

# Process each repository
while IFS= read -r repo; do
    # Skip empty lines
    [ -z "$repo" ] && continue

    # Get PRs for this repository with detailed information
    prs=$(gh pr list --repo "$repo" --author "@me" --state open \
        --json number,title,url,baseRefName,reviewDecision,isDraft 2>/dev/null)

    # Skip if no PRs found
    if [ -z "$prs" ] || [ "$prs" = "[]" ]; then
        continue
    fi

    # Print repository header
    echo "**$repo:**"

    # Format and print each PR
    echo "$prs" | jq -r '.[] |
        (if .isDraft then " 🚧"
         elif .reviewDecision == "APPROVED" then " ✅"
         elif .reviewDecision == "CHANGES_REQUESTED" then " ⚠️"
         else " 👀"
         end) +
        " #\(.number) - \(.title) (→ \(.baseRefName))\n  \(.url)"'

    echo ""
done <<< "$repos"

# Print legend
echo "**Legend:**"
echo "- 👀 Needs review"
echo "- ✅ Approved"
echo "- ⚠️ Changes requested"
echo "- 🚧 Draft"
