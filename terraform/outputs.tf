# =============================================================================
# Outputs - an example of what this module provisions.
# =============================================================================

output "cluster_name" {
  description = "Logical name of the target cluster."
  value       = var.cluster_name
}

output "namespaces" {
  description = "Namespaces created for the platform components."
  value       = sort(values(local.ns_names))
}

output "helm_releases" {
  description = "Map of every Helm release to its name, namespace, and chart version."
  value = {
    cert-manager          = { name = helm_release.cert_manager.name, namespace = local.ns_names.cert_manager, version = var.cert_manager_chart_version }
    trust-manager         = { name = helm_release.trust_manager.name, namespace = local.ns_names.cert_manager, version = "(latest)" }
    traefik               = { name = helm_release.traefik.name, namespace = local.ns_names.traefik, version = var.traefik_chart_version }
    argocd                = { name = helm_release.argocd.name, namespace = local.ns_names.argocd, version = var.argo_cd_chart_version }
    argo-rollouts         = { name = helm_release.argo_rollouts.name, namespace = local.ns_names.argo_rollouts, version = var.argo_rollouts_chart_version }
    kargo                 = { name = helm_release.kargo.name, namespace = local.ns_names.kargo, version = var.kargo_chart_version }
    kargo-httproute       = { name = helm_release.kargo_httproute.name, namespace = "default", version = "(local ./helm/httproute)" }
    loki                  = { name = helm_release.loki.name, namespace = local.ns_names.monitoring, version = var.loki_chart_version }
    kube-prometheus-stack = { name = helm_release.kube_prometheus_stack.name, namespace = local.ns_names.monitoring, version = var.kube_prometheus_stack_chart_version }
    monitoring-httproute  = { name = helm_release.monitoring_httproute.name, namespace = "default", version = "(local ./helm/httproute)" }
    keda                  = { name = helm_release.keda.name, namespace = local.ns_names.keda, version = var.keda_chart_version }
    fluent-bit            = { name = helm_release.fluent_bit.name, namespace = local.ns_names.monitoring, version = var.fluent_bit_chart_version }
    dex                   = { name = helm_release.dex.name, namespace = local.ns_names.dex, version = var.dex_chart_version }
  }
}

output "endpoints" {
  description = "Hosts exposed through the Traefik Gateway (websecure)."
  value = {
    argocd       = "https://argocd.localhost"
    kargo        = "https://kargo.localhost"
    prometheus   = "https://monitoring.localhost"
    grafana      = "https://grafana.localhost"
    alertmanager = "https://alertmanager.localhost"
    loki         = "https://loki.localhost"
    dex          = "https://dex.localhost"
    goweb        = "https://goweb.localhost"
    headlamp     = "https://headlamp.localhost"
  }
}

output "gateway_api_crds_version" {
  description = "Gateway API CRDs version applied to the cluster."
  value       = var.gateway_api_crds_version
}
