# matrix-appservice-irc [![matrix-appservice-irc chart version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.matrix-appservice-irc%5B0%5D.version&label=matrix-appservice-irc&logo=helm&style=for-the-badge)](https://github.com/cyclikal94/matrix-helm-charts/tree/main/charts/matrix-appservice-irc)

This is an IRC bridge for Matrix. See [matrix-org/matrix-appservice-irc](https://github.com/matrix-org/matrix-appservice-irc) for details.

> [!TIP]
> Not interested in the nitty-gritty technical details? Start with the [INSTALLATION](../../INSTALLATION.md) guide!.

## Overview

This chart deploys matrix-appservice-irc with a ConfigMap, Service, Deployment(s), optional bundled Redis/Postgres StatefulSets, and media proxy Ingress.

## Prerequisites

- Kubernetes cluster
- Helm 3.x
- Ingress controller (defaults assume `traefik`)

## Quick Start

Create a minimal values file:

```yaml
host: irc-media.example.com
homeserver:
  url: http://ess-synapse.ess.svc.cluster.local:8008
  domain: matrix.example.com
```

Install:

```bash
helm upgrade --install matrix-appservice-irc ./charts/matrix-appservice-irc -f matrix-appservice-irc-values.yaml
```

Install from published OCI registry (preferred):

```bash
helm upgrade --install matrix-appservice-irc oci://ghcr.io/cyclikal94/matrix-helm-charts/matrix-appservice-irc -n matrix-appservice-irc --create-namespace --values matrix-appservice-irc-values.yaml
```

Install from published Helm repository (legacy-compatible):

```bash
helm repo add matrix-helm-charts https://cyclikal94.github.io/matrix-helm-charts
helm repo update
helm upgrade --install matrix-appservice-irc matrix-helm-charts/matrix-appservice-irc -n matrix-appservice-irc --create-namespace --values matrix-appservice-irc-values.yaml
```

## Naming

- By default, resource names are release-scoped.
- Example: release `prod` renders names like `prod-matrix-appservice-irc`, `prod-matrix-appservice-irc-media-proxy`, and `prod-matrix-appservice-irc-registration`.
- Set `nameOverride` or `fullnameOverride` only when you need fixed/custom names.

## Required Values

- `host` is required.
- `homeserver.domain` is required and should match Synapse `server_name`.
- Validation is enforced by `values.schema.json`; Helm will fail fast when required values are missing or empty.
- `registration.asToken` and `registration.hsToken` are optional; when omitted, the chart resolves them in this order:
  - from `registration.existingSecret` (keys `asToken`/`hsToken`) when set
  - from chart-managed Secret (default `<release>-matrix-appservice-irc-registration-tokens`) when it already exists
  - auto-generated 64-hex-char values when `registration.autoGenerate=true` and `registration.managedSecret.enabled=true` (default behavior)

For deterministic GitOps rendering, set `registration.autoGenerate=false` and provide tokens directly or via a pre-created `registration.existingSecret`.

You can still provide tokens manually if desired:

```bash
openssl rand -hex 32
openssl rand -hex 32
```

## Media Proxy Signing Key

`mediaProxy.signingKeyPath` now mounts from a Kubernetes Secret (instead of ephemeral `emptyDir` storage).

If `mediaProxy.signingKey` is unset, the chart resolves it in this order:

- from `mediaProxy.existingSecret` using key `mediaProxy.signingKeySecretKey` when set
- from chart-managed Secret (default `<release>-matrix-appservice-irc-media-proxy-signing-key`) when it already exists
- auto-generated key content when `mediaProxy.autoGenerate=true` and `mediaProxy.managedSecret.enabled=true` (default behavior)

For deterministic GitOps rendering, set `mediaProxy.autoGenerate=false` and provide key content directly or via a pre-created `mediaProxy.existingSecret`.

## Bridge Config Model

`config.extra` is parsed as YAML and merged into generated `config.yaml`.

This lets users supply bridge-specific preferences (for example `ircService.servers`) in upstream config format without the chart needing to expose every bridge option as first-class Helm values.

The chart always manages these paths and reserves them:

- `homeserver.url`
- `homeserver.domain`
- `ircService.mediaProxy.signingKeyPath`
- `ircService.mediaProxy.ttlSeconds`
- `ircService.mediaProxy.bindPort`
- `ircService.mediaProxy.publicUrl`
- `database.engine`
- `database.connectionString`
- `ircClients.mode`
- `connectionPool.redisUrl`
- `connectionPool.persistConnectionsOnShutdown`

If `config.extra` overlaps any reserved path above, template rendering fails.

## Linting

Because some configuration options are required, lint with a values file:

```bash
helm lint ./charts/matrix-appservice-irc -f ./charts/matrix-appservice-irc/values.example.yaml
```

Or lint with your own values file containing at least:

```yaml
host: irc-media.example.com
homeserver:
  domain: matrix.example.com
```

## Example Values Files

- `values.example.yaml`: absolute minimal chart input (`host` + `homeserver`).
- `values.matrix.example.yaml`: recommended Matrix/ESS-focused matrix-appservice-irc config example.
- `values.selfsigned.example.yaml`: self-signed/custom TLS secret example; typically merged with the Matrix example.
- `values.external.example.yaml`: external Redis/Postgres example.
- `values.secrets.yaml`: external Secret example for registration/media-proxy signing key management.

## Defaults

- All optional values and defaults are in `values.yaml`.
- View defaults directly with:

```bash
helm show values ./charts/matrix-appservice-irc
```

## TLS Options

### cert-manager (default)

By default, the chart adds this ingress annotation:

`cert-manager.io/cluster-issuer: letsencrypt-prod`

You can change issuer:

```yaml
host: irc-media.example.com
ingress:
  clusterIssuer: letsencrypt-staging
```

### Self-signed or custom certificate secret

Create a TLS secret in the target namespace:

```bash
kubectl -n <namespace> create secret tls matrix-appservice-irc-media-proxy-tls --cert=tls.crt --key=tls.key
```

Then disable issuer annotation and use your secret:

```yaml
host: irc-media.example.com
ingress:
  clusterIssuer: ""
  tls:
    enabled: true
    secretName: matrix-appservice-irc-media-proxy-tls
```

Ready-to-use file: `values.selfsigned.example.yaml`

You can supply multiple `values.yaml` files so you could also deploy with the `values.matrix.example.yaml`:

```bash
helm upgrade --install matrix-appservice-irc ./charts/matrix-appservice-irc \
  -f charts/matrix-appservice-irc/values.matrix.example.yaml \
  -f charts/matrix-appservice-irc/values.selfsigned.example.yaml
```

**Note:** Both examples define `host` so you should ensure both are correct (or the last provided will apply).

## Synapse Registration ConfigMap

Registration data is always rendered in the bridge ConfigMap in the release namespace.

Set `registration.synapseNamespace` if Synapse runs in a different namespace (for example `ess`).
An additional registration ConfigMap copy is created only when `registration.synapseNamespace` is non-empty and different from the release namespace.

For ESS, add the appservice ConfigMap in Synapse values:

```yaml
synapse:
  appservices:
    - configMap: <release>-matrix-appservice-irc-registration
      configMapKey: appservice-registration-irc.yaml
```

## External Redis/Postgres Example

Ready-to-use file: `values.external.example.yaml`

Equivalent inline values:

```yaml
postgres:
  enabled: false
redis:
  enabled: false
  url: redis://redis.example.com:6379/0
database:
  postgres:
    host: postgres.example.com
    port: 5432
    user: matrix_irc
    password:
      value: replace_me
    database: matrix_irc
    sslMode: prefer
```

## Verify

```bash
kubectl get pods,svc -l app.kubernetes.io/instance=matrix-appservice-irc -n matrix-appservice-irc
kubectl get ingress -l app.kubernetes.io/instance=matrix-appservice-irc -n matrix-appservice-irc
kubectl get configmap <release>-matrix-appservice-irc-registration -n <synapse-namespace>
```

## Troubleshooting

If bridge logs show `No mapped channels` or `IGNORE not mapped`, Synapse/appservice wiring is likely working, but no Matrix<->IRC channel mapping exists yet. Create/join mappings via the bot commands (`!help`) and mapped aliases/rooms.

## Docs

- [Bridge setup](https://matrix-org.github.io/matrix-appservice-irc/latest/bridge_setup.html)
- [Usage](https://matrix-org.github.io/matrix-appservice-irc/latest/usage.html)
- [Connection pooling](https://matrix-org.github.io/matrix-appservice-irc/latest/connection_pooling.html)
- [Config sample](https://github.com/matrix-org/matrix-appservice-irc/blob/develop/config.sample.yaml)
