#!/bin/bash

# Link Jira Issue and PR
# Cross-links Jira issues with GitHub pull requests by adding the PR link to the Jira issue comment 
# and the Jira link to the PR description. Automatically manages issue status, sprint, and story points.
#
# Usage: jira-pr-link <issue-key> <pr-url> [story-points]
# Example: jira-pr-link ACM-25088 https://github.com/stolostron/multicluster-global-hub/pull/2032 3

set -e

# Parse arguments
if [ $# -lt 2 ]; then
    echo "❌ Error: Missing required arguments"
    echo "Usage: jira-pr-link <issue-key> <pr-url> [story-points]"
    echo "Example: jira-pr-link ACM-25088 https://github.com/stolostron/multicluster-global-hub/pull/2032 3"
    exit 1
fi

ISSUE_KEY="$1"
PR_URL="$2"
STORY_POINTS="${3:-}"

# Extract repo and PR number from URL
# Example: https://github.com/stolostron/multicluster-global-hub/pull/2032
if [[ ! "$PR_URL" =~ github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
    echo "❌ Error: Invalid GitHub PR URL format"
    echo "Expected: https://github.com/owner/repo/pull/number"
    exit 1
fi

REPO_OWNER="${BASH_REMATCH[1]}"
REPO_NAME="${BASH_REMATCH[2]}"
PR_NUMBER="${BASH_REMATCH[3]}"
REPO="$REPO_OWNER/$REPO_NAME"

echo "🔗 Linking Jira issue $ISSUE_KEY with PR #$PR_NUMBER from $REPO"
echo ""

# Step 1: Gather information in parallel (simulated with background jobs)
echo "📥 Gathering information..."

# Get Jira issue details
JIRA_OUTPUT=$(jira issue view "$ISSUE_KEY" 2>&1) || {
    echo "❌ Error: Failed to fetch Jira issue $ISSUE_KEY"
    exit 1
}

# Get PR details
PR_OUTPUT=$(gh pr view "$PR_NUMBER" --repo "$REPO" 2>&1) || {
    echo "❌ Error: Failed to fetch PR #$PR_NUMBER from $REPO"
    exit 1
}

# Extract PR title and body
PR_TITLE=$(echo "$PR_OUTPUT" | grep "^title:" | sed 's/^title:[[:space:]]*//')
PR_BODY=$(echo "$PR_OUTPUT" | sed -n '/^--$/,$ p' | tail -n +2)

# Extract issue status (looking for the status emoji indicator)
ISSUE_STATUS=$(echo "$JIRA_OUTPUT" | grep -oE "(🚧 New|▶️ In Progress|✅ Done)" | sed 's/^[^[:space:]]*[[:space:]]*//' || echo "Unknown")

# Extract story points from Jira output (if exists in custom fields)
CURRENT_STORY_POINTS=$(echo "$JIRA_OUTPUT" | grep -i "story.point" | grep -oE "[0-9]+" | head -1 || echo "")

echo "✓ Issue Status: $ISSUE_STATUS"
echo "✓ Current Story Points: ${CURRENT_STORY_POINTS:-Not set}"
echo ""

# Step 2: Update GitHub PR description
echo "📝 Updating GitHub PR description..."

# Check if Jira link already exists in PR body
if echo "$PR_BODY" | grep -q "$ISSUE_KEY"; then
    echo "ℹ️  Jira issue already referenced in PR description, skipping PR update"
else
    # Prepend Jira link to existing PR body
    NEW_PR_BODY="## Related Jira Issue
https://issues.redhat.com/browse/$ISSUE_KEY

$PR_BODY"
    
    gh pr edit "$PR_NUMBER" --repo "$REPO" --body "$NEW_PR_BODY" || {
        echo "⚠️  Warning: Failed to update PR description"
    }
    echo "✓ Added Jira issue link to PR description"
fi
echo ""

# Step 3: Add PR link to Jira issue
echo "💬 Adding PR link to Jira issue..."

# Check if PR link already exists in comments
EXISTING_COMMENTS=$(jira issue view "$ISSUE_KEY" 2>&1 | grep -c "$PR_URL" || echo "0")

if [ "$EXISTING_COMMENTS" -gt 0 ]; then
    echo "ℹ️  PR link already exists in Jira comments, skipping comment addition"
else
    # Create concise comment with PR link
    COMMENT="Related GitHub PR: $PR_URL

$PR_TITLE"
    
    jira issue comment add "$ISSUE_KEY" "$COMMENT" || {
        echo "⚠️  Warning: Failed to add comment to Jira issue"
    }
    echo "✓ Added PR link to Jira issue"
fi
echo ""

# Step 4: Transition status if needed
if [ "$ISSUE_STATUS" = "New" ]; then
    echo "🔄 Transitioning issue from 'New' to 'In Progress'..."
    jira issue move "$ISSUE_KEY" "In Progress" || {
        echo "⚠️  Warning: Failed to transition issue status"
    }
    echo "✓ Issue transitioned to 'In Progress'"
    echo ""
fi

# Step 5: Add to current sprint if not assigned
echo "🏃 Checking sprint assignment..."

# Get current active sprint
ACTIVE_SPRINT=$(jira sprint list --table 2>&1 | grep "active" | awk '{print $1}' | head -1)

if [ -z "$ACTIVE_SPRINT" ]; then
    echo "⚠️  Warning: No active sprint found, skipping sprint assignment"
else
    # Check if issue is already in a sprint (simplified check)
    if echo "$JIRA_OUTPUT" | grep -q "Sprint:"; then
        echo "ℹ️  Issue already assigned to a sprint"
    else
        echo "📌 Adding issue to active sprint (ID: $ACTIVE_SPRINT)..."
        jira sprint add "$ACTIVE_SPRINT" "$ISSUE_KEY" || {
            echo "⚠️  Warning: Failed to add issue to sprint"
        }
        echo "✓ Added to active sprint"
    fi
fi
echo ""

# Step 6: Set story points
if [ -n "$CURRENT_STORY_POINTS" ]; then
    echo "ℹ️  Story points already set: $CURRENT_STORY_POINTS"
elif [ -n "$STORY_POINTS" ]; then
    echo "📊 Setting story points to $STORY_POINTS..."
    jira issue edit "$ISSUE_KEY" --no-input --custom "story-points=$STORY_POINTS" || {
        echo "⚠️  Warning: Failed to set story points"
    }
    echo "✓ Story points set to $STORY_POINTS"
else
    echo "⚠️  Story points not set. Provide as third argument to set automatically."
    echo "   Example: jira-pr-link $ISSUE_KEY $PR_URL 3"
fi

echo ""
echo "✅ Successfully linked $ISSUE_KEY with PR #$PR_NUMBER"
echo "🔗 Jira: https://issues.redhat.com/browse/$ISSUE_KEY"
echo "🔗 PR: $PR_URL"
