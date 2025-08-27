#!/bin/bash

# Script to fix ImagePullBackOff and ContainerCreating issues in Kind clusters by pre-loading images
# macOS compatible version without timeout command dependency
# Usage: ./load-image-to-kind-cluster.sh [kind-cluster-name]

set -e

CLUSTER_NAME=${1:-"hub"}

echo "🔧 Loading images to Kind cluster: $CLUSTER_NAME"

# Check if Kind cluster exists
echo "🔍 Checking Kind cluster..."
if ! kind get clusters | grep -q "^$CLUSTER_NAME$"; then
    echo "❌ ERROR: Kind cluster '$CLUSTER_NAME' not found"
    echo "Available clusters:"
    kind get clusters
    exit 1
fi

# Set kubectl context
echo "🔧 Setting kubectl context..."
if ! kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null 2>&1; then
    echo "❌ ERROR: Failed to set kubectl context"
    exit 1
fi

# Quick connectivity check
echo "🔍 Checking cluster connectivity..."
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "❌ ERROR: Cannot connect to cluster"
    exit 1
fi

# Get problematic pods
echo "🔍 Scanning for problematic pods..."
get_failed_pods() {
    local reason=$1
    kubectl get pods -A -o jsonpath="{range .items[?(@.status.containerStatuses[*].state.waiting.reason==\"$reason\")]}{.metadata.namespace}{\" \"}{.metadata.name}{\" \"}{.spec.containers[*].image}{\"\\n\"}{end}" 2>/dev/null || true
}

FAILED_PODS=""
for reason in "ImagePullBackOff" "ErrImagePull" "ContainerCreating"; do
    FAILED_PODS+=$(get_failed_pods "$reason")
done

if [ -z "$FAILED_PODS" ]; then
    echo "✅ No pods found with image pull issues"
    exit 0
fi

FAILED_COUNT=$(echo "$FAILED_PODS" | grep -v '^$' | wc -l || echo "0")
echo "🚨 Found $FAILED_COUNT pods with issues"

# Extract unique images (limit to 5 for faster processing)
IMAGES=$(echo "$FAILED_PODS" | awk '{for(i=3; i<=NF; i++) if($i ~ /:/ && $i !~ /^[0-9]+$/) print $i}' | sort -u | head -5)

if [ -z "$IMAGES" ]; then
    echo "❌ No valid images found"
    exit 1
fi

IMAGE_COUNT=$(echo "$IMAGES" | wc -l)
echo "📦 Processing $IMAGE_COUNT images"

# Process images
echo "$IMAGES" | while read -r image; do
    if [ -n "$image" ]; then
        echo "  📥 Processing $image..."
        
        # Pull image
        if docker pull "$image" >/dev/null 2>&1; then
            echo "  📤 Loading into cluster..."
            if kind load docker-image "$image" --name "$CLUSTER_NAME" >/dev/null 2>&1; then
                echo "  ✅ Success: $image"
            else
                echo "  ❌ Failed to load: $image"
            fi
        else
            echo "  ❌ Failed to pull: $image"
        fi
    fi
done

# Restart failed pods
echo "🔄 Restarting failed pods..."
echo "$FAILED_PODS" | head -10 | while IFS=' ' read -r namespace pod_name _; do
    if [ -n "$namespace" ] && [ -n "$pod_name" ]; then
        echo "  🔄 Restarting $pod_name in $namespace"
        kubectl delete pod "$pod_name" -n "$namespace" --grace-period=0 --force >/dev/null 2>&1 || true
    fi
done

echo "⏳ Waiting for pods to restart..."
sleep 10

# Quick verification
echo "🔍 Verification..."
REMAINING_ISSUES=""
for reason in "ImagePullBackOff" "ErrImagePull"; do
    REMAINING_ISSUES+=$(get_failed_pods "$reason")
done

if [ -z "$REMAINING_ISSUES" ]; then
    echo "✅ Image loading completed successfully!"
else
    REMAINING_COUNT=$(echo "$REMAINING_ISSUES" | grep -v '^$' | wc -l || echo "0")
    echo "⚠️  $REMAINING_COUNT issues may remain. Check: kubectl get pods -A | grep -E 'ImagePull|ContainerCreating'"
fi

echo "🎉 Script completed"