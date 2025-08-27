# Update Global Hub Bundle Manifests

This command updates the global hub bundle manifests from the hub-of-hubs operator bundle using scriptflow.

## Usage

Parse `$ARGUMENTS` to extract parameters, then run:
```
/mcp scriptflow run update-globalhub-manifests <extracted-branch> [extracted-source-path] [extracted-target-path]
```

## Parameter Extraction

Parse `$ARGUMENTS` to extract:
- `<branch-name>` - Required. Extract the branch name from phrases like "update the branch release-1.6" or "branch release-1.6"
- `[source-path]` - Optional. Extract from phrases like "source path /custom/path" or "from /custom/path"  
- `[target-path]` - Optional. Extract from phrases like "target path /custom/path" or "to /custom/path"

## Parsing Examples

- `"update the branch release-1.6"` → `release-1.6`
- `"branch release-1.6 with source /custom/source"` → `release-1.6 /custom/source`
- `"update branch main from /src/manifests to /dest/manifests"` → `main /src/manifests /dest/manifests`

## Examples

### Basic usage with default paths
Input: `"update the branch release-1.6"`
Execute: `/mcp scriptflow run update-globalhub-manifests release-1.6`

### With custom source path  
Input: `"update branch release-1.6 with source /custom/source/manifests"`
Execute: `/mcp scriptflow run update-globalhub-manifests release-1.6 /custom/source/manifests`

### With custom source and target paths
Input: `"update branch release-1.6 from /custom/source/manifests to /custom/target/manifests"`
Execute: `/mcp scriptflow run update-globalhub-manifests release-1.6 /custom/source/manifests /custom/target/manifests`

## Default Paths

- **Source**: `/Users/myan/Workspace/hub-of-hubs/operator/bundle/manifests`
- **Target**: `/Users/myan/Workspace/multicluster-global-hub-operator-bundle/bundle/manifests`

## What This Command Does

1. Switches to the specified base branch
2. Creates a new branch with format `update-manifests-YYYYMMDD`
3. Replaces the target manifests directory with the source manifests
4. Commits changes with sign-off
5. Pushes the new branch to origin
6. Creates a pull request against the base branch

## Prerequisites

- Git repository must be in the correct directory
- Source manifests directory must exist
- GitHub CLI (`gh`) must be configured
- Proper git credentials for pushing and creating PRs

## Output

The command will output:
- Process status and progress
- New branch name
- PR URL when successfully created

## Common Use Cases

- **Release preparation**: Update manifests for a new release branch
- **Sync updates**: Keep manifests in sync between repositories
- **Automated updates**: Part of CI/CD pipeline for manifest updates