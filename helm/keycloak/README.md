# Keycloak Helm Chart

A Helm chart for [Keycloak](https://www.keycloak.org/), the OpenID Connect (OIDC) identity provider.

The chart is based on the [keycloak-quickstarts](https://github.com/keycloak/keycloak-quickstarts)
`kubernetes/keycloak.yaml` reference: with **default values** it renders exactly that file
(`StatefulSet keycloak` + `Service keycloak` + headless `Service keycloak-discovery` +
`Deployment postgres` + `Service postgres`, all in a single namespace, `app: keycloak` /
`app: postgres` labels).

Keycloak serves **plain HTTP on 8080**; TLS terminates centrally at the Traefik gateway
(`websecure` listener) using the shared `*.localhost` wildcard cert
(`localhost-tls`, produced by cert-manager via `manifests/traefik/certificate.yaml`) —
same pattern as every other service in this stack.

## Resources rendered (defaults)

| Kind | Name | Purpose |
|---|---|---|
| `StatefulSet` | `keycloak` | Keycloak server (image `quay.io/keycloak/keycloak:26.7.4`, `args: ["start"]`) |
| `Service` | `keycloak` | ClusterIP, port `8080` → targetPort `http` |
| `Service` | `keycloak-discovery` | Headless (StatefulSet `serviceName`) for JGroups discovery |
| `Deployment` | `postgres` | PostgreSQL 17 (`mirror.gcr.io/postgres:17`) with **ephemeral** `emptyDir` storage |
| `Service` | `postgres` | ClusterIP, port `5432` |

Optional (off by default):

| Kind | Name | Purpose |
|---|---|---|
| `HTTPRoute` | `keycloak` | Routes `https://keycloak.localhost` via the Traefik gateway (`websecure`) |

## Install

```bash
helm upgrade --install keycloak ./helm/keycloak \
  --namespace keycloak \
  --create-namespace \
  --wait
```

> Note: with `replicas: 2` (quickstart default) this is ~3.4 GiB of memory requests in
> total. For a small local cluster consider `--set replicas=1`.

Enable Traefik routing (for the demo stack):

```bash
helm upgrade keycloak ./helm/keycloak \
  --namespace keycloak \
  --set httpRoute.enabled=true \
  --wait
```

## Values

| Key | Default | Description |
|---|---|---|
| `image.repository` / `image.tag` | `quay.io/keycloak/keycloak` / `26.7.4` | Keycloak server image. |
| `replicas` | `2` | Keycloak replicas (quickstart default; one-by-one rolling updates). |
| `admin.username` / `admin.password` | `admin` / `admin` | Bootstrap admin (`KC_BOOTSTRAP_ADMIN_*`). Override for anything beyond a local demo. |
| `keycloak.proxyHeaders` | `xforwarded` | `KC_PROXY_HEADERS` — respect Traefik's forwarded headers. |
| `keycloak.httpEnabled` | `true` | `KC_HTTP_ENABLED` — plain HTTP; TLS at the gateway. |
| `keycloak.hostnameStrict` | `false` | `KC_HOSTNAME_STRICT` — explorative setup, no strict hostname. |
| `keycloak.healthEnabled` | `true` | `KC_HEALTH_ENABLED` — exposes `/health/*` on port 9000 (probes). |
| `keycloak.cache` | `ispn` | `KC_CACHE` — Infinispan with JGroups node discovery. |
| `keycloak.extraEnv` | `[]` | Escape hatch: extra env vars (e.g. `KC_LOG_LEVEL`). |
| `service.type` / `service.port` | `ClusterIP` / `8080` | Keycloak service. |
| `discoveryService.enabled` | `true` | Headless service used as the StatefulSet `serviceName`. |
| `resources` | req 500m/1700Mi, lim 2000m/2000Mi | Keycloak container resources (quickstart defaults). |
| `probes.startup/readiness/liveness` | `/health/{started,ready,live}` on `9000` | Management-interface probes (quickstart thresholds). |
| `postgres.enabled` | `true` | Toggle the bundled PostgreSQL. |
| `postgres.image` | `mirror.gcr.io/postgres:17` | PostgreSQL image. |
| `postgres.username` / `postgres.password` / `postgres.database` | `keycloak` | DB credentials (`POSTGRES_*` + `KC_DB_*`). |
| `postgres.storage.enabled` | `false` | `false` = `emptyDir` (quickstart default, data lost when the pod stops); `true` = PVC. |
| `db.provider` / `db.host` / `db.database` | `postgres` / `postgres` / `keycloak` | `KC_DB`, `KC_DB_URL_HOST`, `KC_DB_URL_DATABASE`. |
| `httpRoute.enabled` | `false` | Render the Gateway API `HTTPRoute` (off so the default render matches the quickstarts reference). |
| `httpRoute.hostnames` | `keycloak.localhost` | Hostnames the route serves (covered by the shared `*.localhost` cert). |

## Configuring realms, clients, and the GitHub IdP

Unlike Dex, Keycloak's OIDC configuration is **runtime state** (stored in the database),
not static config. After the server is up:

1. Log in to the admin console — `https://keycloak.localhost` (needs
   `httpRoute.enabled=true`) or port-forward:
   `kubectl port-forward -n keycloak svc/keycloak 8080:8080`.
2. Create a realm, e.g. `argocd` (or `demo`).
3. Create **confidential** OIDC clients (client authentication **ON**) for the consumers:
   - `argocd` — valid redirect URIs: `https://argocd.localhost/auth/callback`
   - `headlamp` — valid redirect URIs: `https://headlamp.localhost/*` (match Headlamp's
     `--oidc-callback`/host)
   - Note each client's **secret** (Admin console → Clients → Credentials).
4. Add a **GitHub identity provider** (provider: `github`) with the OAuth App
   client id/secret (callback `https://keycloak.localhost/realms/<realm>/broker/github/endpoint`).

Consumers then point at the Keycloak issuer:

```
https://keycloak.localhost/realms/<realm>
```

- Argo CD: `oidc.config` → `issuer` + `clientID: argocd` + `clientSecret: <from console>`.
- Headlamp: `issuerURL` + `clientID: headlamp` + `clientSecret: <from console>`
  (keep `--oidc-skip-tls-verify` for the self-signed `*.localhost` cert).

### In-cluster issuer access (same prerequisite as Dex)

In-cluster consumers (Argo CD server, Headlamp) must resolve `keycloak.localhost` and trust
the self-signed `*.localhost` CA:

- **DNS**: a CoreDNS `hosts` entry pointing `keycloak.localhost` at the Traefik
  (ClusterIP) — see `scripts/create_cluster.sh` (Dex equivalent: `dex.localhost`).
- **TLS trust**: Argo CD must trust the `localhost-tls` CA
  (`SSL_CERT_FILE=/etc/dex-ca/ca.crt` from the `dex-ca` ConfigMap) or skip verification.

## Verification

```bash
helm lint helm/keycloak
helm template keycloak ./helm/keycloak | kubectl apply --dry-run=client -f -
kubectl -n keycloak get sts keycloak -w          # wait for 2/2 (or 1/1)
kubectl -n keycloak exec deploy/postgres -- \
  pg_isready -U keycloak
```

## References

- Quickstart reference: <https://github.com/keycloak/keycloak-quickstarts/blob/main/kubernetes/keycloak.yaml>
- Keycloak server configuration via env vars: <https://www.keycloak.org/docs/latest/server_admin/#configuring-the-server>
- JGroups / clustering: <https://www.keycloak.org/docs/latest/server_admin/#jgroups>
