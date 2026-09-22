# Monitoring: Loki -> kube-prometheus-stack -> HTTPRoutes.
# The script installs Loki before kube-prometheus-stack.

resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana-community.github.io/helm-charts"
  chart            = "loki"
  version          = var.loki_chart_version
  namespace        = local.ns_names.monitoring
  create_namespace = true
  timeout          = var.helm_timeout_minutes
  values           = [file(local.loki)]
  depends_on       = [helm_release.kube_prometheus_stack]
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.kube_prometheus_stack_chart_version
  namespace        = local.ns_names.monitoring
  create_namespace = true
  timeout          = var.helm_timeout_minutes
  values           = [file(local.prometheus)]
  depends_on       = [helm_release.cert_manager, null_resource.cert_manager_self_signed_cert_issuer]
}

# monitoring-httproute: local ./helm/httproute chart in the default namespace;
# HTTPRoutes (Prometheus, Grafana, Alertmanager, Loki) reference traefik-gateway.
resource "helm_release" "monitoring_httproute" {
  name             = "monitoring-httproute"
  chart            = local.local_httproute
  namespace        = "monitoring"
  create_namespace = false
  timeout          = var.helm_timeout_minutes
  values           = [file(local.monitoring_hrp)]
  depends_on       = [helm_release.traefik, helm_release.kube_prometheus_stack, null_resource.gateway_api_crds]
}