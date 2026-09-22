# Core control-plane apps: Traefik (Gateway API provider), Argo CD, Argo Rollouts.

resource "helm_release" "traefik" {
  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = var.traefik_chart_version
  namespace        = local.ns_names.traefik
  create_namespace = true
  timeout          = var.helm_timeout_minutes
  values           = [file(local.traefik)]
  depends_on       = [null_resource.gateway_api_crds, helm_release.cert_manager, helm_release.trust_manager]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argo_cd_chart_version
  namespace        = local.ns_names.argocd
  create_namespace = true
  timeout          = var.helm_timeout_minutes
  values           = [file(local.argocd)]
  depends_on       = [null_resource.gateway_api_crds, helm_release.traefik]
}

resource "helm_release" "argo_rollouts" {
  name             = "argo-rollouts"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-rollouts"
  version          = var.argo_rollouts_chart_version
  namespace        = local.ns_names.argo_rollouts
  create_namespace = true
  timeout          = var.helm_timeout_minutes
  depends_on       = [helm_release.argocd]
}
