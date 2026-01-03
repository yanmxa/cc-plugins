#!/bin/bash

# kube-mv.sh - Move Kubernetes resources between clusters securely
# This script transfers resources without exposing sensitive data like passwords

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SOURCE_CONTEXT=""
SOURCE_KUBECONFIG=""
TARGET_CONTEXT=""
TARGET_KUBECONFIG=""
NAMESPACE=""
CREATE_NAMESPACE=false
OVERWRITE=false
DRY_RUN=false
RESOURCE=""
TEMP_FILE="/tmp/kube-mv-$$.yaml"

# Cleanup function
cleanup() {
    rm -f "$TEMP_FILE"
}
trap cleanup EXIT

# Usage function
usage() {
    cat <<EOF
Usage: kube-mv.sh <resource-type/name> [options]

Move Kubernetes resources between clusters without exposing sensitive content.

Arguments:
  resource-type/name              Resource to move (e.g., secret/my-secret, configmap/app-config)

Options:
  --source-context <context>      Source cluster context (default: current context)
  --source-kubeconfig <path>      Source cluster kubeconfig file
  --target-context <context>      Target cluster context
  --target-kubeconfig <path>      Target cluster kubeconfig file
  -n, --namespace <namespace>     Namespace for namespaced resources
  --create-namespace              Create target namespace if it doesn't exist
  --overwrite                     Overwrite resource if it already exists (uses 'replace')
  --dry-run                       Show what would be done without applying
  -h, --help                      Show this help message

Examples:
  # Move secret from current context to staging
  kube-mv.sh secret/db-creds --target-context staging -n prod

  # Move configmap between kubeconfig files
  kube-mv.sh configmap/app-config \\
    --source-kubeconfig ./cluster-a.yaml \\
    --target-kubeconfig ./cluster-b.yaml \\
    -n default

  # Move with namespace creation
  kube-mv.sh secret/tls-cert \\
    --target-context prod \\
    -n ingress \\
    --create-namespace

  # Dry run first
  kube-mv.sh deployment/nginx \\
    --target-context staging \\
    -n web \\
    --dry-run

EOF
    exit 1
}

# Parse arguments
if [ $# -eq 0 ]; then
    usage
fi

RESOURCE="$1"
shift

while [ $# -gt 0 ]; do
    case "$1" in
        --source-context)
            SOURCE_CONTEXT="$2"
            shift 2
            ;;
        --source-kubeconfig)
            SOURCE_KUBECONFIG="$2"
            shift 2
            ;;
        --target-context)
            TARGET_CONTEXT="$2"
            shift 2
            ;;
        --target-kubeconfig)
            TARGET_KUBECONFIG="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --create-namespace)
            CREATE_NAMESPACE=true
            shift
            ;;
        --overwrite)
            OVERWRITE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}" >&2
            usage
            ;;
    esac
done

# Validate inputs
if [ -z "$RESOURCE" ]; then
    echo -e "${RED}Error: Resource not specified${NC}" >&2
    usage
fi

if [ -z "$TARGET_CONTEXT" ] && [ -z "$TARGET_KUBECONFIG" ]; then
    echo -e "${RED}Error: Target context or kubeconfig must be specified${NC}" >&2
    usage
fi

# Parse resource type and name
if [[ "$RESOURCE" =~ ^([a-z0-9-]+)/(.+)$ ]]; then
    RESOURCE_TYPE="${BASH_REMATCH[1]}"
    RESOURCE_NAME="${BASH_REMATCH[2]}"
else
    # Try splitting by space
    RESOURCE_TYPE="${RESOURCE%% *}"
    RESOURCE_NAME="${RESOURCE#* }"
    if [ "$RESOURCE_TYPE" = "$RESOURCE_NAME" ]; then
        echo -e "${RED}Error: Invalid resource format. Use 'type/name' or 'type name'${NC}" >&2
        exit 1
    fi
fi

# Build kubectl command prefixes
SOURCE_CMD="kubectl"
TARGET_CMD="kubectl"

if [ -n "$SOURCE_CONTEXT" ]; then
    SOURCE_CMD="$SOURCE_CMD --context=$SOURCE_CONTEXT"
elif [ -n "$SOURCE_KUBECONFIG" ]; then
    SOURCE_CMD="$SOURCE_CMD --kubeconfig=$SOURCE_KUBECONFIG"
fi

if [ -n "$TARGET_CONTEXT" ]; then
    TARGET_CMD="$TARGET_CMD --context=$TARGET_CONTEXT"
elif [ -n "$TARGET_KUBECONFIG" ]; then
    TARGET_CMD="$TARGET_CMD --kubeconfig=$TARGET_KUBECONFIG"
fi

# Add namespace if specified
NAMESPACE_FLAG=""
if [ -n "$NAMESPACE" ]; then
    NAMESPACE_FLAG="-n $NAMESPACE"
fi

# Display operation summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kubernetes Resource Migration${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Resource Type: ${GREEN}$RESOURCE_TYPE${NC}"
echo -e "Resource Name: ${GREEN}$RESOURCE_NAME${NC}"
if [ -n "$NAMESPACE" ]; then
    echo -e "Namespace:     ${GREEN}$NAMESPACE${NC}"
else
    echo -e "Namespace:     ${YELLOW}cluster-scoped${NC}"
fi
echo ""

# Determine source display
if [ -n "$SOURCE_CONTEXT" ]; then
    echo -e "Source:        ${GREEN}context: $SOURCE_CONTEXT${NC}"
elif [ -n "$SOURCE_KUBECONFIG" ]; then
    echo -e "Source:        ${GREEN}kubeconfig: $SOURCE_KUBECONFIG${NC}"
else
    CURRENT_CONTEXT=$($SOURCE_CMD config current-context 2>/dev/null || echo "unknown")
    echo -e "Source:        ${GREEN}current context: $CURRENT_CONTEXT${NC}"
fi

# Determine target display
if [ -n "$TARGET_CONTEXT" ]; then
    echo -e "Target:        ${GREEN}context: $TARGET_CONTEXT${NC}"
elif [ -n "$TARGET_KUBECONFIG" ]; then
    echo -e "Target:        ${GREEN}kubeconfig: $TARGET_KUBECONFIG${NC}"
fi

echo ""
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
    echo ""
fi

# Step 1: Export resource from source
echo -e "${BLUE}[1/4]${NC} Exporting resource from source cluster..."

if ! $SOURCE_CMD get $RESOURCE_TYPE $RESOURCE_NAME $NAMESPACE_FLAG -o yaml > "$TEMP_FILE" 2>/dev/null; then
    echo -e "${RED}Error: Failed to get resource from source cluster${NC}" >&2
    echo -e "${RED}Please check that the resource exists and you have proper permissions${NC}" >&2
    exit 1
fi

echo -e "${GREEN}✓${NC} Resource exported successfully"

# Step 2: Clean metadata
echo -e "${BLUE}[2/4]${NC} Cleaning cluster-specific metadata..."

# Remove cluster-specific metadata fields
if command -v yq &> /dev/null; then
    # Use yq if available (more reliable)
    yq eval 'del(.metadata.resourceVersion, .metadata.uid, .metadata.creationTimestamp, .metadata.selfLink, .metadata.managedFields, .status)' -i "$TEMP_FILE"
else
    # Fallback to sed (less reliable but works without yq)
    sed -i.bak -e '/resourceVersion:/d' \
               -e '/uid:/d' \
               -e '/creationTimestamp:/d' \
               -e '/selfLink:/d' \
               -e '/managedFields:/,/^[^ ]/d' \
               -e '/^status:/,/^[^ ]/d' "$TEMP_FILE"
    rm -f "$TEMP_FILE.bak"
fi

echo -e "${GREEN}✓${NC} Metadata cleaned"

# Step 3: Create namespace if needed
if [ "$CREATE_NAMESPACE" = true ] && [ -n "$NAMESPACE" ]; then
    echo -e "${BLUE}[3/4]${NC} Checking target namespace..."

    if ! $TARGET_CMD get namespace $NAMESPACE &>/dev/null; then
        if [ "$DRY_RUN" = false ]; then
            echo -e "  Creating namespace ${GREEN}$NAMESPACE${NC}..."
            $TARGET_CMD create namespace $NAMESPACE
            echo -e "${GREEN}✓${NC} Namespace created"
        else
            echo -e "  ${YELLOW}Would create namespace: $NAMESPACE${NC}"
        fi
    else
        echo -e "${GREEN}✓${NC} Namespace already exists"
    fi
else
    echo -e "${BLUE}[3/4]${NC} Skipping namespace creation"
fi

# Step 4: Apply to target
echo -e "${BLUE}[4/4]${NC} Applying resource to target cluster..."

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}Would apply the following resource:${NC}"
    echo ""
    cat "$TEMP_FILE" | grep -E "^(kind|metadata):" | head -10
    echo ""
    echo -e "${YELLOW}DRY RUN complete. No changes made.${NC}"
    exit 0
fi

# Check if resource exists in target
RESOURCE_EXISTS=false
if $TARGET_CMD get $RESOURCE_TYPE $RESOURCE_NAME $NAMESPACE_FLAG &>/dev/null; then
    RESOURCE_EXISTS=true
fi

if [ "$RESOURCE_EXISTS" = true ]; then
    if [ "$OVERWRITE" = true ]; then
        echo -e "  ${YELLOW}Resource exists, replacing...${NC}"
        if ! $TARGET_CMD replace -f "$TEMP_FILE"; then
            echo -e "${RED}Error: Failed to replace resource in target cluster${NC}" >&2
            exit 1
        fi
    else
        echo -e "  ${YELLOW}Resource exists, applying...${NC}"
        if ! $TARGET_CMD apply -f "$TEMP_FILE"; then
            echo -e "${RED}Error: Failed to apply resource to target cluster${NC}" >&2
            echo -e "${YELLOW}Tip: Use --overwrite flag to force replacement${NC}" >&2
            exit 1
        fi
    fi
else
    if ! $TARGET_CMD apply -f "$TEMP_FILE"; then
        echo -e "${RED}Error: Failed to apply resource to target cluster${NC}" >&2
        exit 1
    fi
fi

echo -e "${GREEN}✓${NC} Resource applied to target cluster"

# Step 5: Verify
echo ""
echo -e "${BLUE}Verifying...${NC}"
if $TARGET_CMD get $RESOURCE_TYPE $RESOURCE_NAME $NAMESPACE_FLAG &>/dev/null; then
    echo -e "${GREEN}✓${NC} Resource verified in target cluster"
else
    echo -e "${RED}✗${NC} Warning: Could not verify resource in target cluster" >&2
fi

# Success summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Migration completed successfully${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Resource: ${GREEN}$RESOURCE_TYPE/$RESOURCE_NAME${NC}"
if [ -n "$NAMESPACE" ]; then
    echo -e "Namespace: ${GREEN}$NAMESPACE${NC}"
fi
echo -e "Target: Successfully applied"
echo ""
echo -e "${YELLOW}⚠️  Note: Resource content was not displayed for security reasons${NC}"
echo ""
