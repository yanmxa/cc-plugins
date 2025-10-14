---
argument-hint: [registry or full-image-urls]
description: Update MGH component images and restart operator, manager, and agent pods
allowed-tools: [Bash]
---

Update the image registry or full image URLs for Multicluster Global Hub components (operator, manager, agent), then restart all components by deleting their leader election leases and pods.

## Implementation Steps

1. **Get MGH instance namespace**: Run `kubectl get mgh -A` to identify the namespace where the MGH instance is running

2. **Update component images**:
   - If `$ARGUMENTS` is a registry (e.g., quay.io/myan): Update environment variables `RELATED_IMAGE_MULTICLUSTER_GLOBAL_HUB_MANAGER` and `RELATED_IMAGE_MULTICLUSTER_GLOBAL_HUB_AGENT` to `$ARGUMENTS/multicluster-global-hub-manager:latest` and `$ARGUMENTS/multicluster-global-hub-agent:latest`
   - If `$ARGUMENTS` contains full image URLs: Parse and set manager and agent images accordingly
   - Verify the operator deployment image is using the correct registry/image

3. **Delete leases and restart all pods**: Delete all three leader election leases (multicluster-global-hub-operator-lock, multicluster-global-hub-manager-lock, multicluster-global-hub-agent-lock) and delete all corresponding pods using label selectors in a single chained command

## Notes
- Supports both registry-only updates (e.g., `quay.io/myan`) and full image URLs
- The operator deployment image should match the target registry
- Deleting leases ensures pods start immediately without waiting for lease acquisition
- The namespace is typically `multicluster-global-hub` unless customized
- Manager typically runs with 2 replicas, both will be restarted
- All components will acquire new leases and use updated images upon restart
