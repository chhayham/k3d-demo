#!/usr/bin/env bash
# -e: Exit immediately if any command exits with a non-zero status
# -u: Exit if an undefined variable is referenced
# -o pipefail: Return the exit status of the last command in a pipeline that failed
# -x: Print each command before executing it (useful for debugging)
set -euox pipefail

cluster_name="${1:-demo}"
nodes="${2:-3}"

rancher_kubernetes_version=v1.36.4-k3s1

# argo_cd_chart_version=9.4.3
# argo_rollouts_chart_version=2.40.6
# kargo_chart_version=1.11.2
# cert_manager_chart_version=v1.21.1
# calico_chart_version=v3.31.4
# kube_prometheus_stack_chart_version=88.5.4
# traefik_chart_version=41.5.0
# keda_chart_version=2.20.2
# loki_chart_version=18.12.1
# fluent_bit_chart_version=0.58.2
# dex_chart_version=0.24.1

# gateway_api_crds_version=v1.6.1

if k3d cluster list 2>/dev/null | awk '{print $1}' | grep -qx "$cluster_name"; then
  echo "k3d cluster '$cluster_name' already exists"
else
  k3d cluster create $cluster_name \
    --port 80:80@loadbalancer \
    --port 443:443@loadbalancer \
    --port 8080:8080@loadbalancer \
    --k3s-arg "--disable=traefik@server:0" \
    --servers 1 \
    --agents $nodes \
    --image rancher/k3s:$rancher_kubernetes_version \
    --wait
fi

cd terraform && terraform init \
   && terraform validate \
   && terraform apply -var cluster_name=$cluster_name -var kubeconfig=~/.kube/config -auto-approve

# Install cert-manager, trust-manager, and self-signed-cert-issuer
# install gateway api crds for services that need a gateway
# kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/$gateway_api_crds_version/standard-install.yaml

# helm upgrade --install cert-manager cert-manager \
#   --repo https://charts.jetstack.io \
#   --version $cert_manager_chart_version \
#   --namespace cert-manager \
#   --create-namespace \
#   -f helm/cert-manager/values.yaml \
#   --wait

# helm upgrade --install trust-manager oci://quay.io/jetstack/charts/trust-manager \
#   --namespace cert-manager \
#   --wait
# kubectl apply -f manifests/cert-manager/self-signed-cert-issuer.yaml
# kubectl apply -f manifests/cert-manager/trust-bundle.yaml

# # Install Traefik

# helm show crds traefik/traefik | kubectl apply --server-side --force-conflicts -f -

# helm repo add traefik https://traefik.github.io/charts
# helm upgrade --install traefik traefik/traefik \
#   --create-namespace \
#   --namespace traefik \
#   --version $traefik_chart_version \
#   -f helm/traefik/values.yaml \
#   --wait

# # Install ArgoCD, Rollouts, and Kargo
# helm upgrade --install argocd argo-cd \
#   --repo https://argoproj.github.io/argo-helm \
#   --version $argo_cd_chart_version \
#   --namespace argocd \
#   --create-namespace \
#   -f helm/argocd/values.yaml \
#   --wait

# helm upgrade --install argo-rollouts argo-rollouts \
#   --repo https://argoproj.github.io/argo-helm \
#   --version $argo_rollouts_chart_version \
#   --create-namespace \
#   --namespace argo-rollouts \
#   --wait

# # Password is 'admin'
# helm upgrade --install kargo \
#   oci://ghcr.io/akuity/kargo-charts/kargo \
#   --version=$kargo_chart_version \
#   --namespace kargo \
#   --create-namespace \
#   -f helm/kargo/values.yaml \
#   --wait
  
# helm upgrade --install kargo-httproute ./helm/httproute \
#   -f manifests/httproutes/kargo-values.yaml \
#   --wait

# # Install Loki before kube-prometheus-stack
#  helm repo add grafana-community https://grafana-community.github.io/helm-charts
#  helm upgrade --install loki grafana-community/loki \
#    --version $loki_chart_version \
#    -f helm/loki/values.yaml \
#    --namespace monitoring \
#    --create-namespace \
#    --wait

# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
#   --version $kube_prometheus_stack_chart_version \
#   --create-namespace \
#   --namespace monitoring \
#   -f helm/prometheus/values.yaml \
#   --wait

# helm upgrade --install monitoring-httproute ./helm/httproute \
#   -f manifests/httproutes/monitoring-values.yaml \
#   --wait

# # Install Kubernetes Event-Driven Autoscaling(KEDA)
# helm repo add kedacore https://kedacore.github.io/charts  
# helm upgrade --install keda kedacore/keda \
#   --version $keda_chart_version \
#   --namespace keda \
#   --create-namespace \
#   -f helm/keda/values.yaml \
#   --wait

# # Install Fluent-Bit
# helm repo add fluent https://fluent.github.io/helm-charts

# helm upgrade --install fluent-bit fluent/fluent-bit \
#   --version=0.58.2 \
#   --create-namespace \
#   --namespace monitoring \
#   -f helm/fluent/fluent-bit/values.yaml \
#   --wait

# # Install Dex
# helm repo add dexidp https://charts.dexidp.io

# helm upgrade --install dex dexidp/dex \
#   --version $dex_chart_version \
#   --create-namespace \
#   --namespace dex \
#   -f helm/dex/values.yaml \
#   --wait  
