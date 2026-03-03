# k3d_demo

Small demo for running Argo CD, Argo Rollouts, Cert-Manager, Calico and Kargo on a local k3d cluster.

## Prerequisites
- Docker (Mac), recommend using Rancher Desktop
- k3d
- kubectl
- helm

## Quick start
Run the cluster creation script:
```bash
./scripts/create_cluster.sh [cluster-name] [agent-nodes]
# defaults: cluster-name=demo, agent-nodes=3
```

The script installs:
- Calico (projectcalico/tigera-operator)
- cert-manager (jetstack)
- Argo CD (argoproj/argo-helm)
- Argo Rollouts (argoproj/argo-helm)
- Kargo (ghcr.io/akuity/kargo-charts)

Chart versions used in the script:
- Argo CD: 9.4.3
- Argo Rollouts: 2.40.6
- cert-manager: 1.19.3
- calico: 3.31.4

## Services / Ports (NodePort)
- Argo CD server: http://<k3d-host>:31443 (admin password: `admin`)
- Kargo API: http://<k3d-host>:31444 (admin password: `admin`)
- Kargo external webhooks: 31445

Notes:
- The script uses bcrypt hashes for stored passwords and self-signed certificates for local demo use.
- To remove the cluster:
```bash
k3d cluster delete <cluster-name>
```
