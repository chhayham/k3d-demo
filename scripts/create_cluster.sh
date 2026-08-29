#!/usr/bin/env bash
# -e: Exit immediately if any command exits with a non-zero status
# -u: Exit if an undefined variable is referenced
# -o pipefail: Return the exit status of the last command in a pipeline that failed
# -x: Print each command before executing it (useful for debugging)
set -euox pipefail

cluster_name="${1:-demo}"
nodes="${2:-3}"
# nodes="1"
argo_cd_chart_version=9.4.3
argo_rollouts_chart_version=2.40.6
kargo_chart_version=1.11.2
cert_manager_chart_version=v1.21.1
calico_chart_version=v3.31.4
kube_prometheus_stack_chart_version=88.5.4
traefik_chart_version=41.4.0

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
    --wait
fi

# Install Gateway API and Traefik

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/standard-install.yaml
helm show crds traefik/traefik | kubectl apply --server-side --force-conflicts -f -

helm repo add traefik https://traefik.github.io/charts
helm upgrade --install traefik traefik/traefik \
  --create-namespace \
  --namespace traefik \
  --version $traefik_chart_version \
  --set ingressRoute.dashboard.enabled=true \
  --set ingressRoute.dashboard.matchRule='Host(`dashboard.localhost`)' \
  --set ingressRoute.dashboard.entryPoints={web} \
  --set providers.kubernetesGateway.enabled=true \
  --set gateway.listeners.web.namespacePolicy.from=All

# kubectl create namespace tigera-operator --dry-run=client -o yaml | kubectl apply -f -
# helm repo add projectcalico https://docs.tigera.io/calico/charts
# helm upgrade --install calico projectcalico/tigera-operator --version $calico_chart_version --namespace tigera-operator \
#   --wait

helm upgrade --install cert-manager cert-manager \
  --repo https://charts.jetstack.io \
  --version $cert_manager_chart_version \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --wait

helm upgrade --install trust-manager oci://quay.io/jetstack/charts/trust-manager \
  --namespace cert-manager \
  --wait
kubectl apply -f manifests/self-signed-cert-issuer.yaml
kubectl apply -f manifests/trust-bundle.yaml


helm upgrade --install argocd argo-cd \
  --repo https://argoproj.github.io/argo-helm \
  --version $argo_cd_chart_version \
  --namespace argocd \
  --create-namespace \
  --set 'configs.secret.argocdServerAdminPassword=$2a$10$5vm8wXaSdbuff0m9l21JdevzXBzJFPCi8sy6OOnpZMAG.fOXL7jvO' \
  --set dex.enabled=false \
  --set notifications.enabled=false \
  --set global.domain=argocd.localhost \
  --set server.extensions.enabled=true \
  --set 'server.extensions.extensionList[0].name=argo-rollouts' \
  --set 'server.extensions.extensionList[0].env[0].name=EXTENSION_URL' \
  --set 'server.extensions.extensionList[0].env[0].value=https://github.com/argoproj-labs/rollout-extension/releases/download/v0.3.7/extension.tar' \
  --wait
kubectl apply -f manifests/cm-argocd.yaml
kubectl rollout restart deployment argocd-server -n argocd
kubectl apply -f manifests/ingressroute-argocd.yaml


helm upgrade --install argo-rollouts argo-rollouts \
  --repo https://argoproj.github.io/argo-helm \
  --version $argo_rollouts_chart_version \
  --create-namespace \
  --namespace argo-rollouts \
  --wait

# Password is 'admin'
helm upgrade --install kargo \
  oci://ghcr.io/akuity/kargo-charts/kargo \
  --version=$kargo_chart_version \
  --namespace kargo \
  --create-namespace \
  --set api.adminAccount.passwordHash='$2a$10$Zrhhie4vLz5ygtVSaif6o.qN36jgs6vjtMBdM6yrU1FOeiAAMMxOm' \
  --set api.adminAccount.tokenSigningKey=iwishtowashmyirishwristwatch \
  --set api.host=kargo.localhost \
  --set api.tls.enabled=false \
  --set api.tls.terminatedUpstream=false \
  --wait
kubectl apply -f manifests/ingressroute-kargo.yaml

# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
#   --version $kube_prometheus_stack_chart_version \
#   --create-namespace \
#   --namespace monitoring \
#   --set prometheus.service.type=NodePort \
#   --set prometheus.service.nodePort=30904 \
#   --set prometheus.servicePerReplica.type=NodePort \
#   --set prometheus.servicePerReplica.nodePort=30905 \
#   --set prometheusOperator.admissionWebhooks.enabled=true \
#   --set prometheusOperator.admissionWebhooks.certManager.enabled=true \
#   --set grafana.service.type=NodePort \
#   --set grafana.service.nodePort=30906 \
#   --set grafana.adminPassword="admin" \
#   --set alertmanager.service.type=NodePort \
#   --set alertmanager.service.nodePort=30907 \
#   --wait
