# Variables for the k3d-demo Terraform module.
#
# Everything cluster-specific lives here with defaults that mirror
# scripts/create_cluster.sh, so the same module can target any cluster by
# overriding these (via -var, a tfvars file, or a terraform workspace).
#
#   terraform apply -var cluster_name=cluster-a -var kubeconfig=~/.kube/cluster-a
#   terraform workspace new cluster-a && terraform apply -var cluster_name=cluster-a

variable "cluster_name" {
  description = "Logical name of the target k3d cluster (used for outputs / naming)."
  type        = string
  default     = "demo"
}

variable "kubeconfig" {
  description = "Path to the kubeconfig file used to reach the target cluster. Leave empty to use KUBECONFIG / the default kubeconfig."
  type        = string
  default     = ""
}

variable "helm_timeout_minutes" {
  description = "Timeout (minutes) for each Helm install/upgrade operation."
  type        = number
  default     = 15
}

# Chart versions (defaults mirror scripts/create_cluster.sh). See variables-charts.tf for the rest.

variable "cert_manager_chart_version" {
  description = "cert-manager chart version (charts.jetstack.io)."
  type        = string
  default     = "v1.21.1"
}

variable "traefik_chart_version" {
  description = "Traefik chart version (traefik.github.io/charts)."
  type        = string
  default     = "41.6.0"
}

variable "argo_cd_chart_version" {
  description = "Argo CD chart version (argoproj.github.io/argo-helm)."
  type        = string
  default     = "9.4.3"
}

variable "argo_rollouts_chart_version" {
  description = "Argo Rollouts chart version (argoproj.github.io/argo-helm)."
  type        = string
  default     = "2.40.6"
}
