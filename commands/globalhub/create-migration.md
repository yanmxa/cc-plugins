---
argument-hint: <migration-description>
description: Create a ManagedClusterMigration CR to migrate clusters between hubs
allowed-tools: [Bash]
---

Create a ManagedClusterMigration custom resource to migrate one or more managed clusters from a source hub to a target hub. Parse the description to extract source hub, target hub, and cluster names.

## Implementation Steps

1. **Get MGH namespace**: Run `kubectl get mgh -A` to identify the namespace where the MGH instance is running (typically `multicluster-global-hub`)

2. **Parse migration description**: Parse `$ARGUMENTS` to extract:
   - Source hub: Look for patterns like "from X", "source: X", or explicit hub names
   - Target hub: Look for patterns like "to Y", "target: Y", or destination hub names
   - Cluster names: Extract cluster names from the description
   - Handle various formats: "cluster1 from hub1 to local-cluster", "migrate cluster1,cluster2 from hub1 to hub2", etc.

3. **Create ManagedClusterMigration CR**: Use `kubectl apply -f -` with heredoc to create a ManagedClusterMigration resource with:
   - `apiVersion`: `global-hub.open-cluster-management.io/v1alpha1`
   - `kind`: `ManagedClusterMigration`
   - `metadata.name`: Auto-generated based on migration (e.g., `migrate-{cluster}-from-{source}-to-{target}`)
   - `metadata.namespace`: The MGH namespace
   - `spec.from`: Extracted source hub (required)
   - `spec.to`: Extracted target hub (required)
   - `spec.includedManagedClusters`: List of extracted cluster names (optional, mutually exclusive with includedManagedClustersPlacementRef)
   - `spec.includedManagedClustersPlacementRef`: Reference to a Placement resource name (optional, mutually exclusive with includedManagedClusters)
   - `spec.supportedConfigs.stageTimeout`: Timeout duration for each migration stage (optional, e.g., "5m", "10m")

## Notes
- Accepts flexible description formats:
  - "cluster1 from hub1 to local-cluster"
  - "migrate cluster1,cluster2 from hub1 to hub2"
  - "move cluster1 and cluster2 from hub1 to local-cluster"
  - "from hub1 to local-cluster: cluster1, cluster2"
- The CR supports two ways to specify clusters (mutually exclusive):
  - `includedManagedClusters`: Explicit list of cluster names (default for this command)
  - `includedManagedClustersPlacementRef`: Reference to a Placement resource in the source hub's global hub agent namespace
- Migration phases: Pending → Validating → Initializing → Deploying → Registering → Rollbacking → Cleaning → Completed/Failed
- Migration condition types: MigrationStarted, ResourceValidated, ResourceInitialized, ClusterRegistered, ResourceDeployed, ResourceRolledBack, ResourceCleaned
- The namespace must match the MGH instance namespace
- Multiple clusters can be migrated in a single operation
- Optional configurations:
  - `stageTimeout`: Set custom timeout for each migration stage (default is used if not specified)
