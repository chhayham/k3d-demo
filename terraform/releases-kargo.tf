# Kargo delivery platform + its HTTPRoute (local ./helm/httproute chart).

resource "helm_release" "kargo" {
  name             = "kargo"
  repository       = "oci://ghcr.io/akuity/kargo-charts"
  chart            = "kargo"
  version          = var.kargo_chart_version
  namespace        = local.ns_names.kargo
  create_namespace = true
  timeout          = var.helm_timeout_minutes
  values           = [file(local.kargo)]
  depends_on       = [null_resource.gateway_api_crds, helm_release.argocd]
}

# kargo-httproute: local chart installed in the default namespace (the script
# passes no namespace); the HTTPRoute's own namespace is set in the values file.
# Depends on Traefik (provides traefik-gateway) and Kargo (kargo-api backend).
resource "helm_release" "kargo_httproute" {
  name             = "kargo-httproute"
  chart            = local.local_httproute
  namespace        = "kargo"
  create_namespace = false
  timeout          = var.helm_timeout_minutes
  values           = [file(local.kargo_hrp)]
  depends_on       = [helm_release.traefik, helm_release.kargo, null_resource.gateway_api_crds]
}