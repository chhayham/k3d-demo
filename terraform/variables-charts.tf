# Chart versions (continued) - defaults mirror scripts/create_cluster.sh.

variable "kargo_chart_version" {
  description = "Kargo chart version (oci://ghcr.io/akuity/kargo-charts/kargo)."
  type        = string
  default     = "1.11.2"
}

variable "loki_chart_version" {
  description = "Loki chart version (grafana-community.github.io/helm-charts)."
  type        = string
  default     = "18.12.1"
}

variable "kube_prometheus_stack_chart_version" {
  description = "kube-prometheus-stack chart version (prometheus-community.github.io/helm-charts)."
  type        = string
  default     = "88.5.4"
}

variable "keda_chart_version" {
  description = "KEDA chart version (kedacore.github.io/charts)."
  type        = string
  default     = "2.20.2"
}

variable "fluent_bit_chart_version" {
  description = "Fluent Bit chart version (fluent.github.io/helm-charts)."
  type        = string
  default     = "0.58.2"
}

variable "dex_chart_version" {
  description = "Dex chart version (charts.dexidp.io)."
  type        = string
  default     = "0.24.1"
}

variable "gateway_api_crds_version" {
  description = "Gateway API CRDs version applied via kubectl (standard-install.yaml)."
  type        = string
  default     = "v1.6.1"
}
