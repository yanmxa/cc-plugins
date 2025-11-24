#!/bin/bash
# Display all open PRs for the current user across repositories
# Usage: show-prs.sh [--require-review]

set -e

# Parse arguments
REQUIRE_REVIEW=false
if [ "$1" = "--require-review" ]; then
    REQUIRE_REVIEW=true
fi

if [ "$REQUIRE_REVIEW" = true ]; then
    echo "**Pull Requests Requiring Your Review:**"
    echo ""

    # Get PRs that require the user's review
    prs=$(gh search prs --review-requested=@me --state=open --limit 100 --json repository,number,title,url,author,updatedAt,isDraft)

    if [ "$(echo "$prs" | jq '. | length')" -eq 0 ]; then
        echo "No pull requests require your review."
        exit 0
    fi

    # Group by repository and format
    echo "$prs" | jq -r 'group_by(.repository.nameWithOwner) | .[] |
        "**" + .[0].repository.nameWithOwner + ":**\n" +
        (map(
            (if .isDraft then " 🚧" else " 👀" end) +
            " #\(.number) - \(.title)\n" +
            "   Author: @\(.author.login) | Updated: \(.updatedAt | fromdateiso8601 | strftime("%Y-%m-%d"))\n" +
            "   \(.url)"
        ) | join("\n\n")) + "\n"'

    echo "**Legend:**"
    echo "- 👀 Awaiting your review"
    echo "- 🚧 Draft (review requested)"
else
    echo "**Your Open PRs:**"
    echo ""

    # Get all repositories with open PRs
    repos=$(gh search prs --author "@me" --state=open --limit 100 --json repository | jq -r '.[].repository.nameWithOwner' | sort -u)

    if [ -z "$repos" ]; then
        echo "No open pull requests found."
        exit 0
    fi

    # Process each repository
    while IFS= read -r repo; do
        echo "**${repo}:**"

        # Get PR details for this repository
        gh pr list --repo "$repo" --author "@me" --state open \
            --json number,title,url,baseRefName,reviewDecision,isDraft | \
            jq -r '.[] |
                (if .isDraft then " 🚧"
                 elif .reviewDecision == "APPROVED" then " ✅"
                 elif .reviewDecision == "CHANGES_REQUESTED" then " ⚠️"
                 else " 👀"
                 end) + " #\(.number) - \(.title) (→ \(.baseRefName))\n  \(.url)"'

        echo ""
    done <<< "$repos"

    echo "**Legend:**"
    echo "- 👀 Needs review"
    echo "- ✅ Approved"
    echo "- ⚠️ Changes requested"
    echo "- 🚧 Draft"
fi
