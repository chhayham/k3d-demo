# =============================================================================
# k3d-demo platform  (Terraform)
#
# Mirrors scripts/create_cluster.sh for everything that runs INSIDE the cluster.
# Out of scope (kept in the shell scripts / GitOps, by design):
#   - the k3d cluster itself (created by scripts/create_cluster.sh)
#   - the ArgoCD Application manifests (scripts/deploy_argocd_apps.sh)
#
# State is stored locally in this directory (terraform/terraform.tfstate).
# Target a different cluster by overriding the variables (see variables.tf):
#   terraform plan  -var cluster_name=cluster-a -var kubeconfig=~/.kube/cluster-a
#   terraform apply -var cluster_name=cluster-a -var kubeconfig=~/.kube/cluster-a
# =============================================================================

locals {
  # Local (in-repo) Helm chart used by the kargo/monitoring HTTPRoutes.
  local_httproute = "${path.module}/../helm/httproute"

  # Namespaces the script creates (--create-namespace).
  ns_names = {
    cert_manager  = "cert-manager"
    traefik       = "traefik"
    argocd        = "argocd"
    argo_rollouts = "argo-rollouts"
    kargo         = "kargo"
    monitoring    = "monitoring"
    keda          = "keda"
    dex           = "dex"
  }

  # Values files (relative to the repo root, i.e. one level above this dir).
  cert_manager   = "${path.module}/../helm/cert-manager/values.yaml"
  traefik        = "${path.module}/../helm/traefik/values.yaml"
  argocd         = "${path.module}/../helm/argocd/values.yaml"
  kargo          = "${path.module}/../helm/kargo/values.yaml"
  loki           = "${path.module}/../helm/loki/values.yaml"
  prometheus     = "${path.module}/../helm/prometheus/values.yaml"
  keda           = "${path.module}/../helm/keda/values.yaml"
  fluent_bit     = "${path.module}/../helm/fluent/fluent-bit/values.yaml"
  dex            = "${path.module}/../helm/dex/values.yaml"
  kargo_hrp      = "${path.module}/../manifests/httproutes/kargo-values.yaml"
  monitoring_hrp = "${path.module}/../manifests/httproutes/monitoring-values.yaml"

  # Raw kubectl manifests.
  cert_self_signed  = "${path.module}/../manifests/cert-manager/self-signed-cert-issuer.yaml"
  cert_trust_bundle = "${path.module}/../manifests/cert-manager/trust-bundle.yaml"
}

# Namespaces (created before the Helm releases that target them).
resource "kubernetes_namespace_v1" "platform" {
  for_each = toset(values(local.ns_names))
  metadata {
    name = each.value
  }
}

# Gateway API CRDs. The script applies the released standard-install.yaml with
# `kubectl apply --server-side`. That file is multi-doc, so it is applied with
# kubectl rather than a single kubernetes_manifest resource.
resource "null_resource" "gateway_api_crds" {
  triggers = {
    version      = var.gateway_api_crds_version
    cluster_name = var.cluster_name
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.gateway_api_crds_version}/standard-install.yaml"
  }
}
