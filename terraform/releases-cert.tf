# Cert Manager + Trust Manager + the raw cert-manager manifests.
#
# The script installs cert-manager, then trust-manager, then applies the
# self-signed-cert-issuer.yaml and trust-bundle.yaml manifests (which use the
# trust.cert-manager.io CRDs, so they must come after trust-manager).

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_chart_version
  namespace        = local.ns_names.cert_manager
  create_namespace = true
  timeout          = var.helm_timeout_minutes
  values           = [file(local.cert_manager)]
  depends_on       = [null_resource.gateway_api_crds]
}

resource "helm_release" "trust_manager" {
  name             = "trust-manager"
  repository       = "oci://quay.io/jetstack/charts"
  chart            = "trust-manager"
  namespace        = local.ns_names.cert_manager
  create_namespace = true
  timeout          = var.helm_timeout_minutes
  depends_on       = [helm_release.cert_manager]
}

# Multi-doc manifest (Bundle + ClusterIssuers + Certificate) -> kubectl apply.
resource "null_resource" "cert_manager_self_signed_cert_issuer" {
  triggers = {
    cluster_name = var.cluster_name
  }
  depends_on = [helm_release.trust_manager]

  provisioner "local-exec" {
    command = "kubectl apply -f ${local.cert_self_signed}"
  }
}

# Multi-doc manifest (Bundle) -> kubectl apply. Applied after the issuer file,
# mirroring the script's ordering.
resource "null_resource" "cert_manager_trust_bundle" {
  triggers = {
    cluster_name = var.cluster_name
  }
  depends_on = [helm_release.trust_manager, null_resource.cert_manager_self_signed_cert_issuer]

  provisioner "local-exec" {
    command = "kubectl apply -f ${local.cert_trust_bundle}"
  }
}
