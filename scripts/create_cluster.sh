#!/usr/bin/env bash
# -e: Exit immediately if any command exits with a non-zero status
# -u: Exit if an undefined variable is referenced
# -o pipefail: Return the exit status of the last command in a pipeline that failed
# -x: Print each command before executing it (useful for debugging)
set -euox pipefail

cluster_name="${1:-demo}"
# nodes="${2:-3}"
nodes="1"
argo_cd_chart_version=9.4.3
argo_rollouts_chart_version=2.40.6
cert_manager_chart_version=v1.19.3
calico_chart_version=v3.31.4
kube_prometheus_stack_chart_version=v0.93.1

if k3d cluster list 2>/dev/null | awk '{print $1}' | grep -qx "$cluster_name"; then
  echo "k3d cluster '$cluster_name' already exists"
else
  k3d cluster create $cluster_name \
    --no-lb \
    --k3s-arg '--disable=traefik@server:0' \
    -p '31443-31445:31443-31445@servers:0:direct' \
    -p '32080-32082:32080-32082@servers:0:direct' \
    -p '31200-31202:31200-31202@servers:0:direct' \
    -p '30904-30908:30904-30908@servers:0:direct' \
    --k3s-arg '--flannel-backend=none@server:*' \
    --k3s-arg '--disable-network-policy@server:*' \
    --k3s-arg '--cluster-cidr=192.168.65.0/24@server:*' \
    --servers 1 \
    --agents $nodes \
    --wait
fi

kubectl create namespace tigera-operator --dry-run=client -o yaml | kubectl apply -f -
helm repo add projectcalico https://docs.tigera.io/calico/charts
helm upgrade --install calico projectcalico/tigera-operator --version $calico_chart_version --namespace tigera-operator \
  --wait

helm upgrade --install cert-manager cert-manager \
  --repo https://charts.jetstack.io \
  --version $cert_manager_chart_version \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --wait

helm upgrade --install argocd argo-cd \
  --repo https://argoproj.github.io/argo-helm \
  --version $argo_cd_chart_version \
  --namespace argocd \
  --create-namespace \
  --set 'configs.secret.argocdServerAdminPassword=$2a$10$5vm8wXaSdbuff0m9l21JdevzXBzJFPCi8sy6OOnpZMAG.fOXL7jvO' \
  --set dex.enabled=false \
  --set notifications.enabled=false \
  --set server.service.type=NodePort \
  --set server.service.nodePortHttp=31443 \
  --set server.extensions.enabled=true \
  --set 'server.extensions.extensionList[0].name=argo-rollouts' \
  --set 'server.extensions.extensionList[0].env[0].name=EXTENSION_URL' \
  --set 'server.extensions.extensionList[0].env[0].value=https://github.com/argoproj-labs/rollout-extension/releases/download/v0.3.7/extension.tar' \
  --wait

helm upgrade --install argo-rollouts argo-rollouts \
  --repo https://argoproj.github.io/argo-helm \
  --version $argo_rollouts_chart_version \
  --create-namespace \
  --namespace argo-rollouts \
  --wait

# Password is 'admin'
helm upgrade --install kargo \
  oci://ghcr.io/akuity/kargo-charts/kargo \
  --namespace kargo \
  --create-namespace \
  --set api.service.type=NodePort \
  --set api.service.nodePort=31444 \
  --set api.adminAccount.passwordHash='$2a$10$Zrhhie4vLz5ygtVSaif6o.qN36jgs6vjtMBdM6yrU1FOeiAAMMxOm' \
  --set api.adminAccount.tokenSigningKey=iwishtowashmyirishwristwatch \
  --set externalWebhooksServer.service.type=NodePort \
  --set externalWebhooksServer.service.nodePort=31445 \
  --wait

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --version $kube_prometheus_stack_chart_version \
  --create-namespace \
  --namespace monitoring \
  --set prometheus.service.type=NodePort \
  --set prometheus.service.nodePort=30904 \
  --set prometheus.servicePerReplica.type=NodePort \
  --set prometheus.servicePerReplica.nodePort=30905 \
  --set prometheusOperator.admissionWebhooks.enabled=true \
  --set prometheusOperator.admissionWebhooks.certManager.enabled=true \
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=30906 \
  --set grafana.adminPassword="admin" \
  --wait
