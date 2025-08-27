#!/bin/bash
# Update Global Hub operator/manager/agent registry without changing image names/tags.

set -e
unset HTTP_PROXY HTTPS_PROXY

NEW_REGISTRY="$1"
NAMESPACE="${2:-multicluster-global-hub}"
DEPLOYMENT="multicluster-global-hub-operator"
LEASE_NAME="multicluster-global-hub-operator-lock"

[[ -z "$NEW_REGISTRY" ]] && echo "Usage: $0 <new-registry> [namespace]" && exit 1

run_kubectl() {
    env -i PATH="$PATH" HOME="$HOME" KUBECONFIG="$KUBECONFIG" kubectl "$@"
}

# Ensure KUBECONFIG exists
[[ -z "$KUBECONFIG" && -f "$HOME/.kube/config" ]] && export KUBECONFIG="$HOME/.kube/config"
[[ ! -f "$KUBECONFIG" ]] && echo "No KUBECONFIG found" && exit 1

echo "🚀 Updating Global Hub images to registry: $NEW_REGISTRY"

# Connectivity check
run_kubectl cluster-info >/dev/null || { echo "kubectl connection failed"; exit 1; }

# Verify namespace and deployment
run_kubectl get ns "$NAMESPACE" >/dev/null
run_kubectl get deploy "$DEPLOYMENT" -n "$NAMESPACE" >/dev/null

# Extract current images/tags
get_image() {
    run_kubectl get deploy "$DEPLOYMENT" -n "$NAMESPACE" -o json | jq -r "$1"
}

OPERATOR_IMAGE=$(get_image '.spec.template.spec.containers[0].image')
MANAGER_IMAGE=$(get_image '.spec.template.spec.containers[0].env[] | select(.name=="RELATED_IMAGE_MULTICLUSTER_GLOBAL_HUB_MANAGER") | .value')
AGENT_IMAGE=$(get_image '.spec.template.spec.containers[0].env[] | select(.name=="RELATED_IMAGE_MULTICLUSTER_GLOBAL_HUB_AGENT") | .value')

OPERATOR_TAG=$(basename "$OPERATOR_IMAGE")
MANAGER_TAG=$(basename "$MANAGER_IMAGE")
AGENT_TAG=$(basename "$AGENT_IMAGE")

NEW_OPERATOR_IMAGE="$NEW_REGISTRY/$OPERATOR_TAG"
NEW_MANAGER_IMAGE="$NEW_REGISTRY/$MANAGER_TAG"
NEW_AGENT_IMAGE="$NEW_REGISTRY/$AGENT_TAG"

echo -e "📦 Current:\n  Operator: $OPERATOR_IMAGE\n  Manager:  $MANAGER_IMAGE\n  Agent:    $AGENT_IMAGE"

if [[ "$OPERATOR_IMAGE" == "$NEW_OPERATOR_IMAGE" && "$MANAGER_IMAGE" == "$NEW_MANAGER_IMAGE" && "$AGENT_IMAGE" == "$NEW_AGENT_IMAGE" ]]; then
    echo "✅ Registry already set — restarting..."
else
    echo "🔄 Updating images..."
    run_kubectl delete lease "$LEASE_NAME" -n "$NAMESPACE" >/dev/null 2>&1 || true

    # Update operator
    run_kubectl patch deploy "$DEPLOYMENT" -n "$NAMESPACE" --type='json' \
        -p="[ {\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/image\",\"value\":\"$NEW_OPERATOR_IMAGE\"} ]"

    # Update manager & agent env vars
    MANAGER_INDEX=$(get_image '.spec.template.spec.containers[0].env | to_entries[] | select(.value.name=="RELATED_IMAGE_MULTICLUSTER_GLOBAL_HUB_MANAGER") | .key')
    AGENT_INDEX=$(get_image '.spec.template.spec.containers[0].env | to_entries[] | select(.value.name=="RELATED_IMAGE_MULTICLUSTER_GLOBAL_HUB_AGENT") | .key')
    run_kubectl patch deploy "$DEPLOYMENT" -n "$NAMESPACE" --type='json' \
        -p="[ {\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/env/$MANAGER_INDEX/value\",\"value\":\"$NEW_MANAGER_IMAGE\"},
              {\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/env/$AGENT_INDEX/value\",\"value\":\"$NEW_AGENT_IMAGE\"} ]"
fi

echo "🔄 Restarting deployment..."
run_kubectl rollout restart deploy "$DEPLOYMENT" -n "$NAMESPACE"
run_kubectl rollout status deploy "$DEPLOYMENT" -n "$NAMESPACE" --timeout=30s || echo "Rollout in progress..."

echo -e "✅ Done. New Images:\n  Operator: $NEW_OPERATOR_IMAGE\n  Manager:  $NEW_MANAGER_IMAGE\n  Agent:    $NEW_AGENT_IMAGE"
