---
title: Terraform Bootstrap
description: Generate a parameterized Terraform module under terraform/ that mirrors scripts/create_cluster.sh (k3d cluster + ArgoCD apps excluded)
---

# Terraform Bootstrap

Read `scripts/create_cluster.sh` as the canonical source for every Helm release, chart repo,
chart version, namespace, values file, and `kubectl apply` manifest, and consult the referenced
`helm/*/values.yaml` and `manifests/...` files so the Terraform output matches the script exactly.

## Out of scope (do NOT provision)

- The k3d cluster itself (create / delete / bootstrap).
- The ArgoCD Application manifests in `argocd/applications/*.yaml` -- these are a separate
  GitOps step (`scripts/deploy_argocd_apps.sh`) and must stay outside Terraform.

## Requirements

1. Location and state
   - Put all Terraform files under `terraform/`.
   - Use a local backend so state is stored in the `terraform/` directory (`terraform.tfstate`).

2. Parameterized for multiple clusters
   - Expose input `variable` blocks (with sensible defaults) for everything cluster-specific:
     `cluster_name`, kubeconfig path/context (or API host + client cert/key/token), and
     chart versions / namespaces / hosts.
   - Support multiple clusters with `terraform workspace` and/or `-var` overrides so the same
     module can target any cluster by changing the cluster variable (and kubeconfig).
   - Do not hardcode a cluster name, kubeconfig path, or chart version in a resource.

3. Provision the in-cluster platform (mirror `scripts/create_cluster.sh` exactly)
   - Gateway API CRDs: `kubectl apply` of `standard-install.yaml`, via `kubernetes_manifest`
     with the URL and `server_side_apply = true`.
   - cert-manager (chart `cert-manager`, repo `https://charts.jetstack.io`, ns `cert-manager`,
     values `helm/cert-manager/values.yaml`), trust-manager (oci://jetstack), and the
     `manifests/cert-manager/*.yaml` manifests.
   - Traefik (chart `traefik/traefik`, ns `traefik`, values `helm/traefik/values.yaml`).
   - ArgoCD (chart `argo-cd`, repo `https://argoproj.github.io/argo-helm`, ns `argocd`,
     values `helm/argocd/values.yaml`) and argo-rollouts (ns `argo-rollouts`).
   - Kargo (oci://ghcr.io/akuity/kargo-charts/kargo, ns `kargo`, values `helm/kargo/values.yaml`).
   - loki (grafana-community, ns `monitoring`) -- install before kube-prometheus-stack.
   - kube-prometheus-stack (prometheus-community, ns `monitoring`, values `helm/prometheus/values.yaml`).
   - KEDA (kedacore, ns `keda`, values `helm/keda/values.yaml`).
   - fluent-bit (fluent, ns `monitoring`, values `helm/fluent/fluent-bit/values.yaml`).
   - dex (dexidp, ns `dex`, values `helm/dex/values.yaml`).
   - Use `helm_release` for charts and `kubernetes_manifest` / `kubernetes_namespace` for the
     raw manifests and namespaces.

4. Scope clarification
   - "Functions deployed to the Kubernetes cluster" means the platform workloads, Helm releases,
     CRDs, and manifests above (the in-cluster components), NOT the ArgoCD Application objects
     and NOT serverless/cloud functions.

## Deliverables

- A complete, runnable Terraform module under `terraform/`:
  - `versions.tf` (terraform plus `hashicorp/kubernetes`, `hashicorp/helm`, `hashicorp/null`).
  - `variables.tf` (parameterized, with defaults).
  - `main.tf` (namespaces + Helm releases + CRD/manifests).
  - `outputs.tf` (example outputs of what is provisioned: namespaces, release names, chart
    versions, key service/host endpoints, and cluster name).
- Keep it idempotent: `terraform plan` / `terraform apply` should be safe to re-run.
- Note the multi-cluster usage (how to switch cluster via `-var` and/or workspaces).

## Acceptance criteria

- `terraform validate` passes.
- The planned resources match `scripts/create_cluster.sh` component-for-component, with no k3d
  cluster resources and no ArgoCD Application manifests.
- A second cluster can be targeted by changing only the cluster variable or kubeconfig.
