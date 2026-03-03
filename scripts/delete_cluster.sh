#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${1:-k3d-demo}"

echo "Deleting k3d cluster '${CLUSTER_NAME}'..."
k3d cluster delete "${CLUSTER_NAME}" || true

echo "Done."
