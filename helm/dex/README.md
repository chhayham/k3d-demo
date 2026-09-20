# Dex Helm Chart

A Helm chart for [Dex](https://dexidp.io/), the OpenID Connect (OIDC) identity provider.

This chart deploys a **standalone** Dex server that:

- Terminates TLS centrally through **Traefik** (Gateway API) and serves `https://dex.localhost/dex`.
- Provides a **GitHub** connector for OIDC logins.
- Ships with **static clients** pre-registered for **Argo CD** and **Headlamp**.
- Creates a Gateway API `HTTPRoute` that attaches to the Traefik gateway (`websecure` entrypoint).

TLS is terminated **centrally** by the Traefik ingress workflow using one shared, cert-manager issued `*.localhost` wildcard certificate (see `manifests/traefik/certificate.yaml` and `helm/traefik/values.yaml`) — this chart intentionally does **not** create a per-service Certificate.

## Prerequisites

- Kubernetes 1.26+
- [Gateway API](https://gateway-api.sigs.k8s.io/) installed
- **Traefik** running as the ingress gateway (this repo: `helm/traefik`), with the shared `*.localhost` wildcard TLS configured on its `websecure` listener.
- **cert-manager** installed, with the `selfsigned-cluster-issuer` ClusterIssuer available (produces the shared `localhost-tls` cert via `manifests/traefik/certificate.yaml`).

## Install

```bash
helm repo add dexidp https://charts.dexidp.io   # only if pulling the upstream chart; this repo installs ./helm/dex

helm upgrade --install dex ./helm/dex \
  --namespace dex \
  --create-namespace \
  --set dex.github.clientId=your-github-client-id \
  --set dex.github.clientSecret=your-github-client-secret
```

## Configuration

The full set of tunables is documented inline in [`values.yaml`](./values.yaml). The most important keys:

| Key | Default | Description |
|---|---|---|
| `issuer.url` | `https://dex.localhost/dex` | Public issuer URL (what browsers see). |
| `internalUrl` | `http://dex.dex.svc.cluster.local:5556/dex` | In-cluster URL for Argo CD / Headlamp / pods. |
| `service.port` | `5556` | Port Dex listens on / Service exposes. |
| `dex.github.clientId` | *required* | GitHub OAuth App client ID. |
| `dex.github.clientSecret` | *required* | GitHub OAuth App client secret. |
| `dex.github.baseURL` | `https://github.com` | Change for GitHub Enterprise. |
| `dex.staticClients` | `argocd`, `headlamp` | Pre-registered OIDC clients. |
| `dex.extraConnectors` | `[]` | Escape hatch for additional connectors. |
| `httpRoute.enabled` | `true` | Render a Gateway API `HTTPRoute`. |
| `httpRoute.parentRefs` | traefik gateway | Gateway API parent references. |
| `httpRoute.hostnames` | `dex.localhost` | Hostnames the route serves. |

### Static clients for Argo CD and Headlamp

The chart ships two static clients by default:

```yaml
dex:
  staticClients:
    - id: "argocd"
      name: "Argo CD"
      secret: "argocd-client-secret"
    - id: "headlamp"
      name: "Headlamp"
      secret: "ZXhhbXBsZS1hcHAtc2VjcmV0"
```

Point each application's OIDC config at these values:

- **Argo CD** (`argocd-rbac.yaml` / `argocd-cm`):
  ```yaml
  argocd:
    oidc.config: |
      name: Dex
      issuer: https://dex.localhost/dex     # public
      clientID: argocd
      clientSecret: <argocd-client-secret>
  ```
  In-cluster components that talk to Dex directly (e.g. Argo CD's `argocd-redis`) can use `internalUrl`.

- **Headlamp** (already wired in `argocd/applications/headlamp.yaml`):
  ```yaml
  config:
    oidc:
      clientID: headlamp
      clientSecret: ZXhhbXBsZS1hcHAtc2VjcmV0
      issuerURL: http://dex.dex.svc.cluster.local:5556/dex
      scopes: "openid profile email groups"
      useCookie: true
  ```

> ⚠️ The default secrets are placeholders. Rotate them in `values.yaml` and in each application's OIDC config before using this in anything but a local dev cluster.

### GitHub OAuth App

1. Go to <https://github.com/settings/developers> → **New OAuth App**.
2. Set:
   - **Homepage URL**: `https://dex.localhost`
   - **Authorization callback URL**: `https://dex.localhost/dex/callback`
3. Copy the client ID and secret into `dex.github.clientId` / `dex.github.clientSecret`.

## Uninstalling

```bash
helm uninstall dex -n dex
kubectl delete namespace dex
```

This removes the Dex resources. The shared TLS secret `localhost-tls` (ns `traefik`) is owned by the Traefik ingress workflow (`manifests/traefik/certificate.yaml`) and is **intentionally not** deleted here.

## Development notes

- Storage is `type: memory` by default. Dex will forget all users on pod restart. For anything durable, switch to a Postgres/MySQL `storage` block via `dex.extraConnectors` (or extend the chart).
- TLS is **not** handled by this chart. Traefik terminates TLS centrally with the shared `*.localhost` wildcard cert (`localhost-tls`, produced by cert-manager via `manifests/traefik/certificate.yaml`). `dex.localhost` is covered by that wildcard; if you add a new hostname pattern it must be added to that Certificate's `dnsNames`. The chart also does not create the Traefik `IngressRoute`/gateway config — that is owned by the `traefik` chart in this repo.
