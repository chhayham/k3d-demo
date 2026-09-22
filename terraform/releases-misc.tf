# KEDA, Fluent Bit, and Dex.

resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  version          = var.keda_chart_version
  namespace        = local.ns_names.keda
  create_namespace = true
  timeout          = var.helm_timeout_minutes
  values           = [file(local.keda)]
}

resource "helm_release" "fluent_bit" {
  name             = "fluent-bit"
  repository       = "https://fluent.github.io/helm-charts"
  chart            = "fluent-bit"
  version          = var.fluent_bit_chart_version
  namespace        = local.ns_names.monitoring
  create_namespace = true
  timeout          = var.helm_timeout_minutes
  values           = [file(local.fluent_bit)]
}

resource "helm_release" "dex" {
  name             = "dex"
  repository       = "https://charts.dexidp.io"
  chart            = "dex"
  version          = var.dex_chart_version
  namespace        = local.ns_names.dex
  create_namespace = true
  timeout          = var.helm_timeout_minutes
  values           = [file(local.dex)]
}