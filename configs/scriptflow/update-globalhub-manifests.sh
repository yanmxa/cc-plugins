#!/bin/bash

# Script to update manifests from hub-of-hubs operator bundle
# Usage: ./update-globalhub-manifests.sh <base-branch> [source-manifests-path] [target-manifests-path]
# Example: ./update-globalhub-manifests.sh release-1.6
# Example: ./update-globalhub-manifests.sh release-1.6 /path/to/source/manifests /path/to/target/manifests

set -e

# Change to the correct directory
cd /Users/myan/Workspace/multicluster-global-hub-operator-bundle

# Check if base branch is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <base-branch> [source-manifests-path] [target-manifests-path]"
    echo "Example: $0 release-1.6"
    echo "Example: $0 release-1.6 /custom/source/manifests /custom/target/manifests"
    exit 1
fi

BASE_BRANCH=$1
DATE=$(date +%Y%m%d)
NEW_BRANCH="update-manifests-${DATE}"

# Default paths
DEFAULT_SOURCE_PATH="/Users/myan/Workspace/hub-of-hubs/operator/bundle/manifests"
DEFAULT_TARGET_PATH="/Users/myan/Workspace/multicluster-global-hub-operator-bundle/bundle/manifests"

# Use provided paths or defaults
SOURCE_MANIFESTS_PATH=${2:-$DEFAULT_SOURCE_PATH}
TARGET_MANIFESTS_PATH=${3:-$DEFAULT_TARGET_PATH}

echo "Starting manifest update process..."
echo "Working directory: $(pwd)"
echo "Base branch: ${BASE_BRANCH}"
echo "New branch: ${NEW_BRANCH}"
echo "Source manifests: ${SOURCE_MANIFESTS_PATH}"
echo "Target manifests: ${TARGET_MANIFESTS_PATH}"

# Check if source manifests directory exists
if [ ! -d "${SOURCE_MANIFESTS_PATH}" ]; then
    echo "Error: Source manifests directory not found at ${SOURCE_MANIFESTS_PATH}"
    exit 1
fi

# Get the target directory (parent of manifests)
TARGET_DIR=$(dirname "${TARGET_MANIFESTS_PATH}")
if [ ! -d "${TARGET_DIR}" ]; then
    echo "Error: Target directory not found at ${TARGET_DIR}"
    exit 1
fi

# Switch to base branch
echo "Switching to base branch: ${BASE_BRANCH}"
git checkout ${BASE_BRANCH}

# Create new branch from base branch
echo "Creating new branch: ${NEW_BRANCH}"
# Delete existing branch if it exists
git branch -D ${NEW_BRANCH} 2>/dev/null || true
git checkout -b ${NEW_BRANCH}

# Replace manifests directory
echo "Replacing manifests directory..."
rm -rf ${TARGET_MANIFESTS_PATH}
cp -r ${SOURCE_MANIFESTS_PATH} ${TARGET_DIR}/

# Check if there are any changes
if git diff --quiet; then
    echo "No changes detected. Exiting."
    git checkout ${BASE_BRANCH}
    git branch -d ${NEW_BRANCH}
    exit 0
fi

# Add and commit changes
echo "Adding and committing changes..."
git add $(dirname ${TARGET_MANIFESTS_PATH})/manifests/
git commit -s -m "$(cat <<EOF
Update manifests from hub-of-hubs operator bundle

Updated the manifests directory with the latest version from hub-of-hubs operator bundle to ensure consistency and latest changes.

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"

# Push branch to origin (force push in case branch exists remotely)
echo "Pushing branch to origin..."
git push -f -u origin ${NEW_BRANCH}

# Create PR
echo "Creating pull request..."
PR_URL=$(gh pr create --base ${BASE_BRANCH} --title "Update manifests from hub-of-hubs operator bundle" --body "$(cat <<EOF
## Summary
- Updated manifests directory with the latest version from hub-of-hubs operator bundle
- Ensures consistency between repositories and includes latest changes

## Test plan
- [ ] Verify manifest files are correctly updated
- [ ] Check bundle validation passes
- [ ] Confirm no breaking changes in CSV

🤖 Generated with [Claude Code](https://claude.ai/code)
EOF
)")

echo "✅ Process completed successfully!"
echo "Branch created: ${NEW_BRANCH}"
echo "PR created: ${PR_URL}"
echo ""
echo "Next steps:"
echo "1. Review the changes in the PR"
echo "2. Wait for CI checks to pass"
echo "3. Merge the PR when ready"