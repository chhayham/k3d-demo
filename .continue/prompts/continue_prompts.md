---
name: create-dex-helm-chart
description: Create Helm chart for Dex service
invokable: true
---

# Task

Create Helm chart for Dex service

## Context

- Relevant files:
  - `helm/dex` — the chart (source of truth for the Dex deployment)
  - `helm/traefik` — owns the Gateway API config; `websecure` listener now references the shared `localhost-tls` wildcard secret
  - `manifests/traefik/certificate.yaml` — SINGLE SOURCE OF TRUTH for ingress TLS (cert-manager `*.localhost` → secret `localhost-tls` in ns `traefik`)
  - `argocd/applications/*.yaml` — Argo CD Application-of-Applications; headlamp app references clientID `headlamp` + the standalone Dex issuer
  - `helm/argocd/values.yaml` — Argo CD `oidc.config` (issuer + client id/secret) for the standalone Dex
  - `manifests/cert-manager/self-signed-cert-issuer.yaml` — defines `selfsigned-cluster-issuer`
  - `scripts/create_cluster.sh` — bootstrap; installs local `./helm/dex` chart, runs `helm lint` first
  - `.continue/prompts/continue_prompts.md` — this file
- Related components / services:
  - Traefik (Gateway API ingress + central TLS termination for every `*.localhost` service)
  - cert-manager (self-signed ClusterIssuer convention shared with traefik & argocd charts)
  - Argo CD (static client `argocd`), Headlamp (static client `headlamp`), GitHub OAuth App (OIDC connector — managed **outside** this project)

## Requirements

- [x] Dex must be reachable from any namespace and pod → ClusterIP Service `dex:5556`, internal URL `http://dex.dex.svc.cluster.local:5556/dex`
- [x] Dex will be behind Traefik proxy using https endpoints → HTTPRoute `dex.localhost` → `traefik-gateway` (websecure); public issuer `https://dex.localhost/dex`
- [x] Dex will use cert-manager to generate certificates for Traefik proxy → satisfied by the shared `*.localhost` wildcard cert (see Decisions: TLS is central, not per-service)
- [x] Dex will have a github connector for oidc → connector `github`, redirectURI auto-computed `{{ issuer }}/callback`, clientId/clientSecret are placeholders in values.yaml
- [x] Dex will have a static client connector for ArgoCD and Headlamp services → staticClients `argocd` + `headlamp`

## Expected Outcome

- [x] Helm chart with example values.yaml file
- [x] Helm chart with README.md file

## Decisions Made

- **Dex is a standalone service** (not embedded under `argocd.localhost/api/dex`). Public issuer `https://dex.localhost/dex`; in-cluster URL `http://dex.dex.svc.cluster.local:5556/dex`.
- **OIDC issuer invariant:** every client's `issuer` must EXACTLY equal Dex's `issuer` (the `iss` claim), and its `clientSecret` must equal the Dex static-client secret. Both consumers aligned to the standalone issuer:
  - Argo CD `oidc.config`: issuer `https://dex.localhost/dex`, clientID `argocd`, clientSecret `argocd-client-secret` (was `https://dex.localhost` + `cGFzc3dvcmQ=`).
  - Headlamp: issuerURL `https://dex.localhost/dex`, clientID `headlamp`, clientSecret `ZXhhbXBsZS1hcHAtc2VjcmV0` (was the internal `http://dex.dex.svc.cluster.local:5556/dex`).
- **TLS is one separate, central ingress workflow — NOT per-service.** Every service behind Traefik uses `*.localhost`, so the gateway terminates TLS with ONE shared wildcard cert. `manifests/traefik/certificate.yaml` (Certificate `traefik-localhost-tls`, dnsNames `*.localhost`) is the single source of truth and produces secret `localhost-tls` in ns `traefik`; the `websecure` listener references it. Services (dex, argocd, kargo, …) only add an HTTPRoute hostname — they create NO certs.
- Dex chart: per-service `dex-tls-secret` cert REMOVED (template is a no-op, `certManager` values dropped, docs updated).
- `selfsigned-cluster-issuer` used (matches traefik/argocd chart conventions); Let's Encrypt not viable on local k3d
- Gateway API HTTPRoute instead of Ingress/IngressRoute
- Dex serves plain HTTP on 5556; TLS terminates at the gateway
- GitHub OAuth App credentials are supplied **outside** this project — the chart ships placeholders only.
- `create_cluster.sh` installs the local `./helm/dex` chart and runs `helm lint helm/dex` first; no `manifests/dex/*.yaml` references remain.

## Follow-ups

- [x] Validate chart: `helm lint helm/dex` now runs in `scripts/create_cluster.sh` before install; optional extra: `helm template dex ./helm/dex` render check
- [x] Clean up `manifests/dex/certificates.yaml` (broken/duplicate issuer + certificate) — dir removed from disk; dangling refs in `scripts/create_cluster.sh` fixed
- [~] Create GitHub OAuth App (callback `https://dex.localhost/dex/callback`) + real `dex.github.clientId`/`clientSecret` — **skipped, handled outside this project**
- [x] TLS workflow: dex per-service cert removed; shared `*.localhost` wildcard (`localhost-tls`) owned by the Traefik ingress workflow
- [x] Remove the now-dead openssl block from `scripts/create_cluster.sh` — **done (user, manually)**; no `local-selfsigned-tls` / `openssl` references remain anywhere in the repo. (For a long-lived cluster, also run `kubectl delete secret local-selfsigned-tls -n traefik`.)
- [x] Reconcile/decide issuer + client ids/secrets — **done**: Dex is **standalone** (`https://dex.localhost/dex`). Argo CD `oidc.config` (issuer + `argocd` secret) and Headlamp (`headlamp` client) both now match the `helm/dex` static clients. (Pre-existing embedded issuer `argocd.localhost/api/dex` + `argo-cd`/`argo-cd-cli`/`argo-cd-pkce` clients fully removed.)
- [ ] **Runtime prerequisite (verify on a live cluster):** in-cluster pods (Argo CD, Headlamp) must be able to resolve `dex.localhost` to reach the standalone Dex — e.g. `hostAliases` on the Argo CD / Headlamp pods pointing `dex.localhost` at the Traefik ingress, or a CoreDNS tweak. Headlamp already passes `--oidc-skip-tls-verify`; Argo CD must trust the self-signed `localhost-tls` CA (or skip verify) when fetching `{issuer}/.well-known/…` and `{issuer}/keys`.

## Notes

- Constraints (performance, compatibility, style):
  - Helm v2 chart, standard `_helpers.tpl` conventions (match `helm/service-monitors` repo style, incl. globalLabels merge pattern)
  - k3d local demo — self-signed certs, memory storage acceptable
- Open questions / decisions to make:
  - ~~Keep standalone `dex.localhost` issuer or revert to Argo-embedded issuer?~~ → **Settled: standalone** (`https://dex.localhost/dex`); see Decisions Made.
  - (TLS architecture settled: central wildcard — no per-service certs)
- Tooling note (this session): ripgrep-based search skips hidden dirs — `.continue/` is never seen by `grep_search`; the file read tool intermittently drops lines from some files; `edit_existing_file` fails with false "does not exist" errors, so multi-line edits are applied via full-file rewrite + targeted grep verification. Use targeted greps to verify on-disk state.
