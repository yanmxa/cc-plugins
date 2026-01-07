---
argument-hint: [target-kubeconfig-path] (path to target cluster's kubeconfig file)
description: Sync current cluster's pull secret to another OpenShift cluster
allowed-tools: [Bash, Read, Write, TodoWrite]
---

Synchronize the pull secret from the current OpenShift cluster to a target cluster specified by kubeconfig path. This command securely extracts the pull secret from `openshift-config/pull-secret`, cleans metadata to avoid conflicts, and applies it to the target cluster.

## Implementation Steps

1. **Create Todo List**: Track the sync process with tasks for extraction, application, verification, and cleanup

2. **Extract Current Pull Secret**: Save the pull secret from current cluster to a temporary file without displaying sensitive content
   - Use `oc get secret/pull-secret -n openshift-config -o json > /tmp/current-pull-secret.json`

3. **Clean Metadata**: Create a sanitized version removing cluster-specific metadata (UID, resourceVersion, creationTimestamp, etc.) to prevent conflicts
   - Read the temporary file
   - Create new JSON with only: apiVersion, data, kind, metadata.name, metadata.namespace, and type fields
   - Write to `/tmp/clean-pull-secret.json`

4. **Apply to Target Cluster**: Use the provided kubeconfig path argument to apply the cleaned pull secret
   - Run `oc apply -f /tmp/clean-pull-secret.json --kubeconfig="[target-kubeconfig-path]"`
   - If conflict occurs, this approach handles it by only including essential fields

5. **Clean Up**: Remove temporary files to protect sensitive credentials
   - Delete `/tmp/current-pull-secret.json` and `/tmp/clean-pull-secret.json`
   - Mark all todos as completed

## Usage Examples

- `/ocp/sync-pull-secret /path/to/target-cluster.kubeconfig` - Sync pull secret to target cluster
- `/ocp/sync-pull-secret ~/Downloads/cluster-bot-*.kubeconfig` - Sync to cluster-bot kubeconfig

## Notes

- Requires `oc` CLI to be installed and current context set to source cluster
- Target kubeconfig path must be absolute or relative to current directory
- Temporary files are automatically cleaned up after operation
- Pull secret includes authentication for: cloud.openshift.com, quay.io, registry.connect.redhat.com, registry.redhat.io
- If target cluster is unreachable, the apply operation will show an error but cleanup still occurs
- Uses `oc apply` which may show warnings about missing annotations - this is expected and can be ignored
