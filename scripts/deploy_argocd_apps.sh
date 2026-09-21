#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f argocd/applications/headlamp.yaml
kubectl apply -f manifests/headlamp/headlamp_sa.yaml

# kubectl apply -f argocd/applications/harbor.yaml

kubectl apply -f argocd/applications/gowebservice.yaml

# kubectl apply -f argocd/applications/dex.yaml

