# mautrix-meta [![mautrix-meta chart version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-meta%5B0%5D.version&label=mautrix-meta&logo=helm&style=for-the-badge)](https://github.com/cyclikal94/matrix-helm-charts/tree/main/charts/mautrix-meta)

A Matrix-Meta puppeting bridge. See [mautrix/meta](https://github.com/mautrix/meta) for details.

> [!TIP]
> Not interested in the nitty-gritty technical details? Start with the [INSTALLATION](../../INSTALLATION.md) guide!.

## Overview

This chart deploys `mautrix-meta` with:

- Singleton bridge `StatefulSet` (replicas fixed at 1)
- Bridge `Service` with `publishNotReadyAddresses: true`
- Runtime config `Secret` (`config.yaml`)
- Registration ConfigMap in release namespace and optional duplicate in Synapse namespace
- Automatic double puppeting registration resources (runtime Secret + ConfigMap)
- Optional bundled Postgres `StatefulSet`

Default image/app version tracks upstream image/git tag `v0.2602.0` (release `v26.02`).

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
helm dependency build ./charts/mautrix-meta
helm upgrade --install mautrix-meta ./charts/mautrix-meta -f mautrix-meta-values.yaml
```

Install from published OCI registry (preferred):

```bash
helm upgrade --install mautrix-meta oci://ghcr.io/cyclikal94/matrix-helm-charts/mautrix-meta -n mautrix-meta --create-namespace --values mautrix-meta-values.yaml
```

Install from published Helm repository (legacy-compatible):

```bash
helm repo add matrix-helm-charts https://cyclikal94.github.io/matrix-helm-charts
helm repo update
helm upgrade --install mautrix-meta matrix-helm-charts/mautrix-meta -n mautrix-meta --create-namespace --values mautrix-meta-values.yaml
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

- ConfigMap: `<release>-mautrix-meta-registration`
- Key: `appservice-registration-meta.yaml`

Set `registration.synapseNamespace` if Synapse runs in a different namespace (for example `ess`).
An additional registration ConfigMap copy is created only when `registration.synapseNamespace` is non-empty and different from the release namespace.
No registration ConfigMap is rendered when `registration.existingSecret` is set; see Runtime secret generation below.

For ESS, add the appservice ConfigMap in Synapse values:

```yaml
synapse:
  appservices:
    - configMap: <release>-mautrix-meta-registration
      configMapKey: appservice-registration-meta.yaml
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

- from chart-managed Secret (default `<release>-mautrix-meta-runtime-secrets`) when it already exists
- auto-generated 64-hex-char values when `registration.autoGenerate=true` and `registration.managedSecret.enabled=true` (default behavior)

The resolved values are used for:

- `registration.asToken`
- `registration.hsToken`

Do not set these to `generate`; leave empty for chart-managed generation.

### Registration tokens from an existing Secret (GitOps-safe)

When `registration.existingSecret` is set (Secret with keys `asToken` and `hsToken`), the chart never reads the Secret at template time, so rendering works fully offline (plain `helm template`, ArgoCD/Flux repo-side rendering). The bridge reads both tokens at runtime instead:

- The StatefulSet defines `MAUTRIX_HELM_CONFIG_APPSERVICE__AS_TOKEN` and `MAUTRIX_HELM_CONFIG_APPSERVICE__HS_TOKEN` via `secretKeyRef`.
- The chart sets `env_config_prefix: MAUTRIX_HELM_CONFIG_` in the bridge config, so the bridge overrides `appservice.as_token`/`hs_token` from those env vars at startup. Like the Postgres mechanism, this requires a bridge release `v0.2512.0` or newer.
- Inline `registration.asToken`/`hsToken` are mutually exclusive with `registration.existingSecret`.
- Rotating the tokens in the Secret does not restart the bridge; pair with a reload mechanism such as [stakater/Reloader](https://github.com/stakater/Reloader).

**The chart does not render the registration ConfigMap in this mode** (the tokens are not available at template time), so you must provide the registration file to the homeserver from the same secret source. The easiest way to get the exact file content is to render it once with placeholder tokens:

```bash
helm template <release> charts/mautrix-meta \
  --set homeserver.domain=<domain> \
  --set registration.asToken=REPLACE_AS_TOKEN \
  --set registration.hsToken=REPLACE_HS_TOKEN \
  --set registration.autoGenerate=false \
  -s templates/registration-configmap.yaml
```

Store that file (with the real tokens) next to the tokens themselves — for example in Vault, delivered by Vault Secrets Operator as a Secret in the Synapse namespace via a [destination transformation template](https://developer.hashicorp.com/vault/docs/platform/k8s/vso/secret-transformation). ESS accepts Secret references for appservices:

```yaml
synapse:
  appservices:
    - secret: mautrix-meta-registration
      secretKey: appservice-registration-meta.yaml
```

For deterministic GitOps rendering, set `registration.autoGenerate=false` and provide secrets directly or via a pre-created `registration.existingSecret`.
The Postgres password from `database.postgres.password.existingSecret` is GitOps-safe by design: it is resolved at runtime, never at template time (see the Postgres section below).

## Bridge config model

Bridge config is split into two channels:

- `config.baseExtra`: shared bridgev2 config merged at top-level. See upstream bridgev2 example in [`mautrix/go`](https://github.com/mautrix/go/blob/main/bridgev2/matrix/mxmain/example-config.yaml).
- `config.networkExtra`: bridge-specific config merged under top-level `network`. See upstream Meta connector example in [`mautrix/meta`](https://github.com/mautrix/meta/blob/main/pkg/connector/example-config.yaml).

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
    os_name: Mautrix-Meta bridge
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

If `database.postgres.password.value` is empty and `database.postgres.password.existingSecret` is unset, the chart reuses the chart-managed Postgres Secret when present, otherwise it generates a 64-hex-char password for bundled Postgres on first install.

`database.postgres.password.value` and `database.postgres.password.existingSecret` are mutually exclusive. The existing Secret is used for both bundled and external Postgres when set. Switching between password sources is allowed, and it is the operator's responsibility to ensure the selected password matches the database.

When `database.postgres.password.existingSecret` is set, the chart never reads the Secret at template time. Rendering works fully offline (plain `helm template`, ArgoCD/Flux repo-side rendering) and the password is injected at runtime instead:

- The bridge StatefulSet reads the password into the `MAUTRIX_HELM_DATABASE_PASSWORD` env var via `secretKeyRef` (`existingSecret`/`existingSecretKey`).
- Kubernetes expands it into the `MAUTRIX_HELM_CONFIG_DATABASE__URI` env var holding the full connection URI.
- The chart sets `env_config_prefix: MAUTRIX_HELM_CONFIG_` in the bridge config, so the bridge overrides `database.uri` from that env var at startup. The rendered config file itself only contains a non-secret placeholder URI.

Requirements and caveats for `existingSecret`:

- Requires bridge env config support from mautrix-go v0.26.1+ (bridge releases `v0.2512.0` and newer).
- The password is inserted into the URI without URL-encoding at runtime; it must not contain URI-reserved characters (`@`, `/`, `:`, `?`, `#`, `%`, spaces). Typical generated alphanumeric passwords (Vault, CloudNativePG, ...) are fine.
- Rotating the password in the referenced Secret does not restart the bridge; pair with a reload mechanism such as [stakater/Reloader](https://github.com/stakater/Reloader) or roll the StatefulSet manually after rotation.
- `values.config.baseExtra` cannot set `env_config_prefix` while `existingSecret` is set; the chart manages it.

Disable bundled Postgres and use external DB:

```yaml
postgres:
  enabled: false

database:
  postgres:
    host: postgres.example.com
    port: 5432
    user: mautrix_meta
    password:
      value: replace_me
      # Or use an external Secret instead of `value` (see above):
      # existingSecret: my-postgres-password
      # existingSecretKey: password
    database: mautrix_meta
    sslMode: require
```

See: `values.external.example.yaml`

## Example Values Files

- `values.example.yaml`: absolute minimal chart input.
- `values.matrix.example.yaml`: recommended Matrix/ESS-focused mautrix-meta config example.
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
helm dependency build ./charts/mautrix-meta
helm lint ./charts/mautrix-meta -f ./charts/mautrix-meta/values.example.yaml
```

## Verify

```bash
kubectl get pods,svc -l app.kubernetes.io/instance=mautrix-meta -n meta
kubectl get configmap <release>-mautrix-meta-registration -n meta
kubectl get configmap <release>-mautrix-meta-registration -n <synapse-namespace>
```

## Docs

- [Bridge setup with Docker](https://docs.mau.fi/bridges/general/docker-setup.html?bridge=meta)
- [Initial bridge config](https://docs.mau.fi/bridges/general/initial-config.html#mautrix-meta)
- [Registering appservices](https://docs.mau.fi/bridges/general/registering-appservices.html)
- [mautrix-meta repository](https://github.com/mautrix/meta)
