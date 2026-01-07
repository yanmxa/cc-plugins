---
argument-hint: [registry or full-image-urls] [--csv]
description: Update MGH component images and restart operator, manager, and agent pods
allowed-tools: [Bash, Read, Edit]
---

Update the image registry or full image URLs for Multicluster Global Hub components (operator, manager, agent), then restart all components. Supports two modes: direct deployment update (default) or CSV-based update (with `--csv` flag).

## Implementation Steps

1. **Parse arguments**:
   - Check if `$ARGUMENTS` contains `--csv` flag
   - Extract image specification (registry or full URLs)
   - If registry only (e.g., `quay.io/myan`): Construct full URLs as `$ARGUMENTS/multicluster-global-hub-{operator,manager,agent}:latest`
   - If full URLs: Parse operator, manager, and agent images
   - Set variables: `OPERATOR_IMAGE`, `MANAGER_IMAGE`, `AGENT_IMAGE`, `USE_CSV`

2. **Update images based on mode**:

   **Default Mode (Direct Deployment Update)**:
   - Update operator deployment image directly:
     ```bash
     kubectl set image deployment/multicluster-global-hub-operator \
       multicluster-global-hub-operator=$OPERATOR_IMAGE -n multicluster-global-hub
     ```
   - Update operator deployment env vars for manager and agent:
     ```bash
     kubectl set env deployment/multicluster-global-hub-operator \
       RELATED_IMAGE_MULTICLUSTER_GLOBAL_HUB_MANAGER=$MANAGER_IMAGE \
       RELATED_IMAGE_MULTICLUSTER_GLOBAL_HUB_AGENT=$AGENT_IMAGE \
       -n multicluster-global-hub
     ```

   **CSV Mode (with `--csv` flag)**:
   - Get CSV name and export to `/tmp/mgh-csv.yaml`
   - Use Edit tool to update:
     * Operator deployment image (~line 1034)
     * `RELATED_IMAGE_MULTICLUSTER_GLOBAL_HUB_MANAGER` env var (~line 1025)
     * `RELATED_IMAGE_MULTICLUSTER_GLOBAL_HUB_AGENT` env var (~line 1027)
   - Apply: `kubectl apply -f /tmp/mgh-csv.yaml`

3. **Clean leases and restart deployments**:
   ```bash
   kubectl delete lease multicluster-global-hub-{operator,manager,agent}-lock -n multicluster-global-hub && \
   kubectl rollout restart deployment/multicluster-global-hub-{operator,manager,agent} -n multicluster-global-hub
   ```

4. **Verify updates**: Show pod images for all three components

## Usage Examples

- `/globalhub:update-images quay.io/myan` - Update to quay.io/myan registry (direct deployment mode)
- `/globalhub:update-images quay.io/myan --csv` - Update via CSV for persistence
- `/globalhub:update-images quay.io/myan/operator:v1.6.0 quay.io/myan/manager:v1.6.0 quay.io/myan/agent:v1.6.0` - Specific versions

## Notes

- **Default mode**: Direct deployment update using `kubectl set image/env` - faster, 2 commands
- **CSV mode**: Updates ClusterServiceVersion - ensures changes persist through operator upgrades
- **Lease cleanup**: Prevents waiting for lease acquisition timeout (60s+)
- **Two-step workflow** (default): Update deployment → Restart
- **Three-step workflow** (CSV mode): Export CSV → Edit → Apply → Restart
- Namespace defaults to `multicluster-global-hub`
- Manager runs with 2 replicas; both restart automatically
