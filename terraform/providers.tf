# Providers talk to the target cluster. Both use config_path, which is
# parameterized by var.kubeconfig so the same module can target different
# clusters; when var.kubeconfig is empty we fall back to the KUBECONFIG env
# var / default kubeconfig.
#
# kubectl (used by the null_resource steps for the Gateway API CRDs and the
# cert-manager manifests) honours the KUBECONFIG env var, so set it to match
# var.kubeconfig when running terraform, e.g.:
#   export KUBECONFIG=~/.kube/cluster-a && terraform apply -var kubeconfig=$KUBECONFIG

provider "kubernetes" {
  config_path = var.kubeconfig != "" ? var.kubeconfig : null
}

# The hashicorp/helm v2.x provider takes config_path directly at the top level
# (it has no nested "kubernetes" block).
provider "helm" {
  kubernetes = { config_path = var.kubeconfig != "" ? var.kubeconfig : null }
}
