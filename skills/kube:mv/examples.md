# kube:mv Examples

Practical examples for moving Kubernetes resources between clusters.

## Basic Usage Examples

### Example 1: Move Secret Between Contexts

Move a database credential secret from the current context to a staging cluster:

```bash
kube-mv.sh secret/db-credentials \
  --target-context staging \
  -n production
```

**What happens:**
1. Exports `secret/db-credentials` from namespace `production` in current context
2. Removes cluster-specific metadata
3. Applies to `staging` context in namespace `production`
4. Verifies the secret exists in target

### Example 2: Copy ConfigMap Between Kubeconfig Files

Copy application configuration from one cluster to another using kubeconfig files:

```bash
kube-mv.sh configmap/app-config \
  --source-kubeconfig ~/.kube/dev-cluster.yaml \
  --target-kubeconfig ~/.kube/prod-cluster.yaml \
  -n default
```

**Use case:** Moving configuration between completely separate clusters with different kubeconfig files.

### Example 3: Move Service Account with Namespace Creation

Move a service account to a new cluster, creating the namespace if it doesn't exist:

```bash
kube-mv.sh serviceaccount/ci-deployer \
  --target-context production \
  -n ci-cd \
  --create-namespace
```

**What happens:**
1. Checks if namespace `ci-cd` exists in target
2. Creates namespace if needed
3. Moves the service account

### Example 4: Move Deployment with Overwrite

Replace an existing deployment in the target cluster:

```bash
kube-mv.sh deployment/web-app \
  --source-context dev \
  --target-context staging \
  -n applications \
  --overwrite
```

**Use case:** Updating a deployment that already exists in the target cluster.

## Advanced Examples

### Example 5: Dry Run Before Migration

Preview what would happen without making changes:

```bash
kube-mv.sh secret/tls-certificate \
  --target-context production \
  -n ingress \
  --dry-run
```

**Best practice:** Always use `--dry-run` first for critical resources.

### Example 6: Move Multiple Secrets (Shell Loop)

Move multiple secrets at once:

```bash
for secret in db-creds api-keys service-token; do
  kube-mv.sh secret/$secret \
    --target-context staging \
    -n production
done
```

### Example 7: Move Cluster-Scoped Resources

Move a ClusterRole (no namespace needed):

```bash
kube-mv.sh clusterrole/pod-reader \
  --target-context production
```

**Note:** Cluster-scoped resources don't require `-n` flag.

### Example 8: Cross-Cloud Migration

Move resources from GKE to EKS:

```bash
# Set up contexts first
kubectl config use-context gke-production  # Source
kubectl config set-context eks-production  # Target

# Move secret
kube-mv.sh secret/cloud-credentials \
  --source-context gke-production \
  --target-context eks-production \
  -n kube-system
```

### Example 9: Disaster Recovery Scenario

Quickly move critical secrets to backup cluster:

```bash
#!/bin/bash
# dr-migrate.sh - Disaster recovery secret migration

CRITICAL_SECRETS=(
  "secret/database-master"
  "secret/api-keys"
  "secret/tls-wildcard"
)

for secret in "${CRITICAL_SECRETS[@]}"; do
  echo "Migrating $secret..."
  kube-mv.sh $secret \
    --source-context production \
    --target-context dr-backup \
    -n critical-services \
    --create-namespace \
    --overwrite
done

echo "DR migration complete"
```

### Example 10: Namespace Migration

Move all configs from one namespace to another cluster:

```bash
#!/bin/bash
# migrate-namespace.sh

SOURCE_CONTEXT="old-cluster"
TARGET_CONTEXT="new-cluster"
NAMESPACE="myapp"

# Get all configmaps
CONFIGS=$(kubectl --context=$SOURCE_CONTEXT get configmap -n $NAMESPACE -o name)

# Get all secrets
SECRETS=$(kubectl --context=$SOURCE_CONTEXT get secret -n $NAMESPACE -o name | grep -v "default-token")

# Move configs
for resource in $CONFIGS; do
  kube-mv.sh $resource \
    --source-context $SOURCE_CONTEXT \
    --target-context $TARGET_CONTEXT \
    -n $NAMESPACE \
    --create-namespace
done

# Move secrets
for resource in $SECRETS; do
  kube-mv.sh $resource \
    --source-context $SOURCE_CONTEXT \
    --target-context $TARGET_CONTEXT \
    -n $NAMESPACE
done
```

## Integration Examples

### Example 11: GitOps Integration

Use in CI/CD pipeline:

```bash
# .gitlab-ci.yml or similar
promote-to-staging:
  script:
    - kube-mv.sh configmap/app-config \
        --source-context dev \
        --target-context staging \
        -n applications
    - kube-mv.sh secret/app-secrets \
        --source-context dev \
        --target-context staging \
        -n applications
```

### Example 12: With Helm Values

Move Helm chart secrets between environments:

```bash
# Move database credentials for Helm chart
kube-mv.sh secret/postgres-credentials \
  --source-context dev \
  --target-context staging \
  -n database

# Apply Helm chart in target
helm upgrade --install myapp ./chart \
  --kube-context staging \
  -n database
```

## Troubleshooting Examples

### Example 13: Resource Already Exists

If you get "resource already exists" error:

```bash
# Option 1: Use --overwrite
kube-mv.sh secret/my-secret \
  --target-context staging \
  -n prod \
  --overwrite

# Option 2: Delete first, then move
kubectl --context=staging delete secret/my-secret -n prod
kube-mv.sh secret/my-secret \
  --target-context staging \
  -n prod
```

### Example 14: Different API Versions

If source and target have different K8s versions:

```bash
# Export with specific API version
kubectl --context=old-cluster get deployment/myapp -n prod -o yaml \
  | kubectl convert --local -o yaml --output-version=apps/v1 \
  | kubectl --context=new-cluster apply -f -
```

## Common Workflows

### Multi-Environment Promotion

```bash
# Dev → Staging → Production pipeline

# 1. Dev to Staging
kube-mv.sh configmap/app-config \
  --source-context dev \
  --target-context staging \
  -n myapp

# 2. Staging to Production (after testing)
kube-mv.sh configmap/app-config \
  --source-context staging \
  --target-context production \
  -n myapp \
  --create-namespace
```

### Blue-Green Deployment Support

```bash
# Copy resources to green environment
for resource in $(kubectl get secret -n blue -o name); do
  kube-mv.sh $resource \
    --source-context production \
    --target-context production \
    -n green \
    --create-namespace
done
```

## Security Best Practices

### Example 15: Using Service Account Tokens

Move service account tokens for automation:

```bash
# Move CI/CD service account
kube-mv.sh serviceaccount/gitlab-runner \
  --target-context new-cluster \
  -n gitlab

# Move associated secrets (if not auto-created)
kube-mv.sh secret/gitlab-runner-token-xxxxx \
  --target-context new-cluster \
  -n gitlab
```

### Example 16: Certificate Rotation

Move TLS certificates during rotation:

```bash
# Move new certificate
kube-mv.sh secret/tls-cert-new \
  --target-context production \
  -n ingress-nginx \
  --dry-run

# Verify dry run looks good, then apply
kube-mv.sh secret/tls-cert-new \
  --target-context production \
  -n ingress-nginx
```

## Tips

1. **Always use --dry-run first** for production migrations
2. **Use --create-namespace** to avoid "namespace not found" errors
3. **Use --overwrite** carefully - it replaces existing resources
4. **Check permissions** on both source and target clusters before starting
5. **Verify** resources after migration with `kubectl get`
6. **Backup** critical resources before overwriting
7. **Test** migrations in dev/staging environments first
8. **Use shell loops** to migrate multiple resources efficiently
9. **Avoid moving default secrets** (like service account tokens that are auto-generated)
10. **Document** your migrations for audit purposes
