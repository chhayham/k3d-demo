#!/usr/bin/env bash
set -euo pipefail

# Usage: check_cluster.sh [CLUSTER_NAME] [TIMEOUT_SECONDS]
CLUSTER_NAME="${1:-k3d-demo}"
TIMEOUT="${2:-120}"

command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required"; exit 2; }

# echo "Checking cluster '${CLUSTER_NAME}' (timeout ${TIMEOUT}s) ..."

# echo "Waiting for all nodes to be Ready..."
# end=$((SECONDS+TIMEOUT))
# while [ $SECONDS -lt $end ]; do
#   not_ready=$(
#     kubectl get nodes --no-headers 2>/dev/null | awk '{print $2}' | grep -v '^Ready' || true
#   )
#   if [ -z "$$not_ready" ]; then
#     echo "All nodes Ready"
#     break
#   fi
#   sleep 2
# done
# if [ $SECONDS -ge $end ]; then
#   echo "Timeout waiting for nodes to be Ready"
#   kubectl get nodes || true
#   exit 3
# fi

# echo "Waiting for deployments to become available (namespace: default)..."
# kubectl wait --for=condition=available --timeout=${TIMEOUT}s deployment --all || true

# echo "Waiting for pods to be ready..."
# kubectl wait --for=condition=ready --timeout=${TIMEOUT}s pod --all || true

# echo "Checking demo service at http://127.0.0.1:8080 ..."
# if curl -sfS --max-time 5 http://127.0.0.1:8080 >/dev/null; then
#   echo "Service reachable"
# else
#   echo "Service not reachable on http://127.0.0.1:8080"
#   exit 4
# fi

# echo "Cluster checks passed"
