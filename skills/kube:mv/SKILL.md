---
name: kube:mv
description: Move Kubernetes resources (secrets, configmaps, etc.) from one cluster to another without exposing sensitive content. Use when migrating resources between clusters, copying configurations across environments, or moving secrets securely. Keywords - kubectl move, cluster migration, copy secret, transfer configmap, cross-cluster resources.
allowed-tools: [Bash, AskUserQuestion]
---

# kube:mv - Kubernetes Resource Migration

Securely move Kubernetes resources between clusters using a helper script that never exposes sensitive data.

## When to Use This Skill

- Moving secrets between development/staging/production clusters
- Migrating configmaps across different Kubernetes environments
- Copying resources from source cluster to target cluster
- Cross-cluster resource synchronization
- Any scenario requiring "kubectl get X from cluster A and apply to cluster B"

## Parameters

The skill uses a helper script `kube-mv.sh` with the following parameters:

```bash
kube-mv.sh <resource-type/name> [options]

Options:
  --source-context <context>      Source cluster context (default: current context)
  --source-kubeconfig <path>      Source cluster kubeconfig file
  --target-context <context>      Target cluster context (required if no target-kubeconfig)
  --target-kubeconfig <path>      Target cluster kubeconfig file (required if no target-context)
  -n, --namespace <namespace>     Namespace for namespaced resources
  --create-namespace              Create target namespace if it doesn't exist
  --overwrite                     Overwrite resource if it already exists
  --dry-run                       Show what would be done without applying
```

## Instructions

### Step 1: Ensure Script Exists

Check if the helper script is available:

```bash
if [ ! -f ~/.claude/skills/kube:mv/scripts/kube-mv.sh ]; then
    echo "Installing kube-mv script..."
    # Script should be created as part of skill installation
fi

chmod +x ~/.claude/skills/kube:mv/scripts/kube-mv.sh
```

### Step 2: Parse User Request

Extract from user's request:
1. Resource type and name (e.g., "secret/db-credentials" or "secret db-credentials")
2. Source context/kubeconfig (optional, defaults to current)
3. Target context/kubeconfig (required)
4. Namespace (required for namespaced resources)

### Step 3: Build and Execute Command

Use the script to perform the migration:

```bash
~/.claude/skills/kube:mv/scripts/kube-mv.sh <resource-type>/<name> \
  --target-context <target> \
  -n <namespace>
```

### Step 4: Handle Output

The script will:
- Export the resource without showing content
- Clean metadata
- Apply to target cluster
- Verify success
- Clean up temporary files
- Report status

## Examples

### Example 1: Move Secret Using Context Names

```bash
# User: "Move secret/db-credentials from prod namespace to staging cluster"
~/.claude/skills/kube:mv/scripts/kube-mv.sh secret/db-credentials \
  --target-context staging \
  -n prod
```

### Example 2: Move ConfigMap Between Kubeconfig Files

```bash
# User: "Copy configmap/app-config from cluster-a.kubeconfig to cluster-b.kubeconfig"
~/.claude/skills/kube:mv/scripts/kube-mv.sh configmap/app-config \
  --source-kubeconfig /path/to/cluster-a.kubeconfig \
  --target-kubeconfig /path/to/cluster-b.kubeconfig \
  -n default
```

### Example 3: Move with Namespace Creation

```bash
# User: "Move secret/tls-cert to new cluster, create namespace if needed"
~/.claude/skills/kube:mv/scripts/kube-mv.sh secret/tls-cert \
  --target-context production \
  -n ingress \
  --create-namespace
```

### Example 4: Dry Run First

```bash
# User: "Show me what would happen if I move this deployment"
~/.claude/skills/kube:mv/scripts/kube-mv.sh deployment/nginx \
  --target-context staging \
  -n web \
  --dry-run
```

## Best Practices

1. **Security**: Script never displays sensitive data in output
2. **Verification**: Always verify the resource exists in target after migration
3. **Dry Run**: Use `--dry-run` for critical resources to preview changes
4. **Namespace Creation**: Use `--create-namespace` when target namespace might not exist
5. **Backup**: Consider backing up existing resources before overwriting

## Output Format

The script provides clean, informative output:

```
✅ Resource moved successfully

Source: current-context (or specified context)
Target: target-context
Resource: secret/db-credentials
Namespace: prod

Verification: Resource exists in target cluster
```

## Tool Usage

This skill primarily uses the Bash tool to execute the helper script. The script handles all kubectl interactions internally.

Use AskUserQuestion when:
- Target context/kubeconfig is not specified
- Namespace is missing for namespaced resources
- Clarification needed on overwrite behavior
