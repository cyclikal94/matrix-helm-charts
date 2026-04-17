# mautrix-twitter [![mautrix-twitter chart version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-twitter%5B0%5D.version&label=mautrix-twitter&logo=helm&style=for-the-badge)](https://github.com/cyclikal94/matrix-helm-charts/tree/main/charts/mautrix-twitter)

A Matrix-Twitter puppeting bridge. See [mautrix/twitter](https://github.com/mautrix/twitter) for details.

> [!TIP]
> Not interested in the nitty-gritty technical details? Start with the [INSTALLATION](../../INSTALLATION.md) guide!.

## Overview

This chart deploys `mautrix-twitter` with:

- Singleton bridge `StatefulSet` (replicas fixed at 1)
- Bridge `Service` with `publishNotReadyAddresses: true`
- Runtime config `Secret` (`config.yaml`)
- Registration ConfigMap in release namespace and optional duplicate in Synapse namespace
- Automatic double puppeting registration resources (runtime Secret + ConfigMap)
- Optional bundled Postgres `StatefulSet`

Default image/app version tracks upstream image/git tag `v0.2604.0`.

## Kubernetes behavior

This chart follows mautrix Kubernetes guidance:

- No startup script usage
- Bridge runs with direct command and `--no-update`
- No registration file mounted in bridge pod
- `/data` mounted read-only
- Singleton runtime (`StatefulSet`, 1 replica)
- `publishNotReadyAddresses: true`
- Probe endpoints are available, but probes are disabled by default

## Quick Start

Create a minimal values file:

```yaml
homeserver:
  domain: matrix.example.com
```

Install:

```bash
helm dependency build ./charts/mautrix-twitter
helm upgrade --install mautrix-twitter ./charts/mautrix-twitter -f mautrix-twitter-values.yaml
```

Install from published OCI registry (preferred):

```bash
helm upgrade --install mautrix-twitter oci://ghcr.io/cyclikal94/matrix-helm-charts/mautrix-twitter -n mautrix-twitter --create-namespace --values mautrix-twitter-values.yaml
```

Install from published Helm repository (legacy-compatible):

```bash
helm repo add matrix-helm-charts https://cyclikal94.github.io/matrix-helm-charts
helm repo update
helm upgrade --install mautrix-twitter matrix-helm-charts/mautrix-twitter -n mautrix-twitter --create-namespace --values mautrix-twitter-values.yaml
```

## Required values

- `homeserver.domain`

Validation is enforced by `values.schema.json`.

## Logging

Set top-level `logging` to control bridge log level.

Allowed values:

- `panic`
- `fatal`
- `error`
- `warn`
- `info`
- `debug`
- `trace`

## Registration ConfigMap model

The chart renders registration in release namespace as:

- ConfigMap: `<release>-mautrix-twitter-registration`
- Key: `appservice-registration-twitter.yaml`

Set `registration.synapseNamespace` if Synapse runs in a different namespace (for example `ess`).
An additional registration ConfigMap copy is created only when `registration.synapseNamespace` is non-empty and different from the release namespace.

For ESS, add the appservice ConfigMap in Synapse values:

```yaml
synapse:
  appservices:
    - configMap: <release>-mautrix-twitter-registration
      configMapKey: appservice-registration-twitter.yaml
```

## Double Puppeting

Automatic double puppeting is enabled by default (`doublePuppet.enabled=true`).

The chart manages:

- `double_puppet.secrets[homeserver.domain]` in bridge config
- a second appservice registration ConfigMap for double puppeting
- optional double puppet runtime Secret values (`asToken`, `hsToken`, `senderLocalpart`)

Default double puppet registration ID is:

- `doublepuppet-<mautrix-go-base-version>`

You can override this with `doublePuppet.registration.id`.
Default ConfigMap name is `<doublePuppet.registration.id>-registration` (override with `doublePuppet.registration.configMapName`).

Reuse behavior:

- When `doublePuppet.reuseExisting.enabled=true` (default), the chart looks up an existing double puppet registration ConfigMap in Synapse namespace and reuses its `as_token` when found.
- On RBAC/API lookup failures, rendering fails fast.

You can still define other bridgev2 `double_puppet` fields in `config.baseExtra` (for example `servers` and `allow_discovery`).
Do not set the local homeserver entry in `double_puppet.secrets`; Helm manages that key.

When not reusing an existing registration, add the double puppet registration ConfigMap to Synapse appservices:

```yaml
synapse:
  appservices:
    - configMap: <doublePuppet registration configmap name>
      configMapKey: appservice-registration-doublepuppet.yaml
```

## Runtime secret generation

If unset, the chart resolves these in this order:

- from `registration.existingSecret` (keys `asToken`, `hsToken`) when set
- from chart-managed Secret (default `<release>-mautrix-twitter-runtime-secrets`) when it already exists
- auto-generated 64-hex-char values when `registration.autoGenerate=true` and `registration.managedSecret.enabled=true` (default behavior)

The resolved values are used for:

- `registration.asToken`
- `registration.hsToken`

Do not set these to `generate`; leave empty for chart-managed generation.

For deterministic GitOps rendering, set `registration.autoGenerate=false` and provide secrets directly or via a pre-created `registration.existingSecret`.

## Bridge config model

Bridge config is split into two channels:

- `config.baseExtra`: shared bridgev2 config merged at top-level. See upstream bridgev2 example in [`mautrix/go`](https://github.com/mautrix/go/blob/main/bridgev2/matrix/mxmain/example-config.yaml).
- `config.networkExtra`: bridge-specific config merged under top-level `network`. See upstream connector example in [`mautrix/twitter`](https://github.com/mautrix/twitter/blob/main/pkg/connector/example-config.yaml).

`config.networkExtra` must contain raw network keys only (not a nested `network:` block).
`config.baseExtra` must not contain top-level `network`.
`config.baseExtra` must not contain top-level `logging`; use top-level `logging` value instead.

The chart reserves and manages these paths:

- `homeserver.address`
- `homeserver.domain`
- `appservice.address`
- `appservice.hostname`
- `appservice.port`
- `appservice.id`
- `appservice.bot.username`
- `appservice.as_token`
- `appservice.hs_token`
- `database.type`
- `database.uri`
- `logging`
- `double_puppet.secrets[homeserver.domain]`

If `config.baseExtra` overlaps any managed path, template rendering fails.
You may set `double_puppet.servers`, `double_puppet.allow_discovery`, and non-local `double_puppet.secrets` entries in `config.baseExtra`.

`bridge.permissions` is required by bridgev2 and should be set in `config.baseExtra`.

Example:

```yaml
logging: debug

config:
  baseExtra: |
    bridge:
      permissions:
        "*": relay
        "@admin:example.com": admin
  networkExtra: |
    os_name: connector-specific bridge
    browser_name: Linux
```

The chart always injects bridge logging config as:

```yaml
logging:
  min_level: <values.logging>
  writers:
    - type: stdout
      format: pretty-colored
```

## Postgres

Bundled Postgres is enabled by default.

Disable bundled Postgres and use external DB:

```yaml
postgres:
  enabled: false

database:
  postgres:
    host: postgres.example.com
    port: 5432
    user: mautrix_twitter
    password:
      value: replace_me
    database: mautrix_twitter
    sslMode: require
```

See: `values.external.example.yaml`

## Example Values Files

- `values.example.yaml`: absolute minimal chart input.
- `values.matrix.example.yaml`: recommended Matrix/ESS-focused mautrix-twitter config example.
- `values.external.example.yaml`: external Postgres example.
- `values.secrets.yaml`: external Secret example for runtime secrets.

## Liveness/Readiness probes

Endpoints are available at:

- `/_matrix/mau/live`
- `/_matrix/mau/ready`

Probe configuration is optional and disabled by default:

- `probes.liveness.enabled`
- `probes.readiness.enabled`

## Linting

```bash
helm dependency build ./charts/mautrix-twitter
helm lint ./charts/mautrix-twitter -f ./charts/mautrix-twitter/values.example.yaml
```

## Verify

```bash
kubectl get pods,svc -l app.kubernetes.io/instance=mautrix-twitter -n twitter
kubectl get configmap <release>-mautrix-twitter-registration -n twitter
kubectl get configmap <release>-mautrix-twitter-registration -n <synapse-namespace>
```

## Docs

- [Bridge setup with Docker](https://docs.mau.fi/bridges/general/docker-setup.html?bridge=twitter)
- [Initial bridge config](https://docs.mau.fi/bridges/general/initial-config.html#mautrix-twitter)
- [Registering appservices](https://docs.mau.fi/bridges/general/registering-appservices.html)
- [mautrix-twitter repository](https://github.com/mautrix/twitter)
