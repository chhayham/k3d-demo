# k3d_demo

Small demo for running Argo CD, Argo Rollouts, Cert-Manager, Calico, Kargo, Dex, and kube-prometheus-stack on a local k3d cluster.

> **Note:** This project is intended for demo purposes only. It is not hardened for production use — it ships default credentials (e.g. `admin`/`admin`), self-signed certificates, and wide NodePort exposure suitable only for local experimentation.

## Prerequisites

- Docker (Mac), recommend using Rancher Desktop
- k3d
- kubectl
- helm
- make

## VM resource settings

On macOS the cluster runs inside the Rancher Desktop VM, so its resources must be sized for the whole stack (Argo CD, Argo Rollouts, Kargo, Harbor, Calico, monitoring, …):

- **Rancher Desktop**: Preferences > Virtual Machine — set **CPUs: 2** and **Memory: 8 GB** (minimum recommended), then restart the VM.

## Quick start

The recommended way is to use the Makefile:

```bash
make install [CLUSTER_NAME=<name> NODES=<n>]
```

Other useful targets:

| Target | Description |
|---|---|
| `make prereqs` | Verify required tools (k3d, kubectl, helm) |
| `make create-cluster` | Create the k3d cluster (skips creation if it already exists) |
| `make update-cluster` | Alias for `create-cluster` |
| `make check-cluster` | Verify cluster health |
| `make deploy-argocd-apps` | Deploy the Argo CD applications |
| `make install` | prereqs + create-cluster + deploy-argocd-apps |
| `make reset` | Delete and recreate the cluster |
| `make delete-cluster` / `make clean` | Delete the cluster |

You can also run the scripts directly, e.g.:

```bash
./scripts/create_cluster.sh [cluster-name]
# default: cluster-name=demo (agent nodes are currently fixed to 1 in the script)

./scripts/check_cluster.sh [cluster-name] [timeout-seconds]   # default timeout: 120s

./scripts/deploy_argocd_apps.sh [cluster-name]

./scripts/delete_cluster.sh [cluster-name]
```

## What gets installed

Cluster-level (by `scripts/create_cluster.sh`):

- Calico (`projectcalico/tigera-operator`) v3.31.4
- cert-manager (jetstack) v1.19.3
- Argo CD (`argoproj/argo-helm`) 9.4.3, with the Argo Rollouts extension
- Argo Rollouts (`argoproj/argo-helm`) 2.40.6
- Kargo (`ghcr.io/akuity/kargo-charts`)
- kube-prometheus-stack (`prometheus-community`) 88.5.4

GitOps applications (deployed to Argo CD by `scripts/deploy_argocd_apps.sh`):

- Headlamp 0.40.0 — Kubernetes dashboard
- Harbor 2.15.0 — container registry
- GoWebService 0.1.0 — sample Go web service
- Dex 0.24.1 -- OpenID Connect identity provider

## Services / Ports (NodePort)

| Service | URL | Notes |
|---|---|---|
| Argo CD server | http://localhost:31443 | user `admin`, password `admin` |
| Kargo API | http://localhost:31444 | user `admin`, password `admin` |
| Kargo external webhooks | http://localhost:31445 | |
| Headlamp dashboard | http://localhost:31201 | see Notes for the access token |
| Prometheus | http://localhost:30904 | per-replica service on 30905 |
| Grafana | http://localhost:30906 | user `admin`, password `admin` |
| Alertmanager | http://localhost:30907 | |
| GoWebService | http://localhost:31080 | |
| Harbor | https://localhost:30003 | user `admin`, password `admin` |
| Dex | http://localhost:30056 | user `admin`, password `admin` |

## Notes

- If running arm64 MacOS, ensure rosetta is enabled in Rancher Desktop.

- The scripts use bcrypt hashes for stored passwords and self-signed certificates for local demo use.
- To remove the cluster:

```bash
make delete-cluster CLUSTER_NAME=<cluster-name>
# or directly:
k3d cluster delete <cluster-name>
```

- To generate an access token for the Headlamp dashboard use the following command:

```bash
kubectl create token headlamp-admin -n kube-system
```

- To test dex from terminal use the following command:

```bash
curl -L -X POST 'http://localhost:30056/dex/token' \
-H 'Authorization: Basic ZXhhbXBsZS1hcHA6WlhoaGJYQnNaUzFoY0hBdGMyVmpjbVYw' \
-H 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'grant_type=password' \
--data-urlencode 'scope=openid' \
--data-urlencode 'username=admin@example.com' \
--data-urlencode 'password=password'
```

- Add self signed CA to keychain on MacOS

```bash
kubectl get secret localhost-tls -n traefik -o jsonpath='{.data.ca\.crt}' | base64 --decode > cert-manager-ca.crt
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain cert-manager-ca.crt
```
