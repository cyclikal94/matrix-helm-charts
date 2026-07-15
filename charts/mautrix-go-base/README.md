# mautrix-go-base [![mautrix-go-base chart version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-go-base%5B0%5D.version&label=mautrix-go-base&logo=helm&style=for-the-badge)](https://github.com/cyclikal94/matrix-helm-charts/tree/main/charts/mautrix-go-base)

Shared Helm library chart for mautrix Go bridge wrappers.

> [!TIP]
> Not interested in the nitty-gritty technical details? Start with the [INSTALLATION](../../INSTALLATION.md) guide!.

## Purpose

This chart centralizes Kubernetes resource templates and shared helper logic so bridge-specific charts only define:

- Bridge-specific managed config and reserved path declarations
- Bridge command and startup args
- Registration file key and regex defaults
- Chart metadata, schema, and examples

## Wrapper Contract

A wrapper chart that depends on this library must define these helpers:

- `<chart>.runtimeSecretKeys`: YAML list of runtime secret keys in `values.registration`.
- `<chart>.bridgeCommand`: YAML list for container `command`.
- `<chart>.bridgeArgs`: YAML list for container `args`.
- `<chart>.managedConfig`: Helm-managed config YAML mapping.
- `<chart>.reservedBasePaths`: comma-separated reserved dotted paths in `config.baseExtra`.
- `<chart>.reservedNetworkPaths`: comma-separated reserved dotted paths in `config.networkExtra` (relative to `network`).
- `<chart>.mergedConfig`: final merged bridge config as YAML mapping (normally include `mautrix-go-base.bridgev2MergedConfig`).
- `<chart>.registrationFileKey`: appservice registration configmap key name.
- `<chart>.registrationConfig`: registration YAML document.
- `<chart>.defaultRegistrationUserRegex`: default user namespace regex when `registration.userRegex` is empty.
- `<chart>.doublePuppetRegistrationFileKey`: default double puppet registration configmap key name.
- `<chart>.doublePuppetUserRegex`: regex for double puppet registration users namespace.

`mautrix-go-base.bridgev2MergedConfig` performs strict parsing/validation and merge:

1. Parse `values.config.baseExtra` and `values.config.networkExtra` as YAML maps.
2. Fail if `baseExtra` contains top-level `network`.
3. Fail if `baseExtra` contains top-level `logging` (use top-level `values.logging`).
4. Fail if `networkExtra` contains nested `network`.
5. Fail on overlaps with wrapper-declared reserved paths.
6. Inject managed bridge logging as stdout `pretty-colored` with `min_level` from top-level `values.logging` (default `info`).
7. Inject managed local double puppet secret at `double_puppet.secrets[homeserver.domain]`.
8. Merge as: `baseExtra` + `{network: networkExtra}` + `managedConfig` + managed logging + managed double puppet + managed env config prefix (managed wins).

## Runtime Postgres password injection

When `database.postgres.password.existingSecret` is set, the library never reads the Secret at template time (no `lookup`), so rendering works offline (plain `helm template`, ArgoCD/Flux repo-side rendering):

- `mautrix-go-base.databaseConnectionString` renders the URI with a literal `$(MAUTRIX_HELM_DATABASE_PASSWORD)` placeholder instead of the password.
- The bridge StatefulSet defines `MAUTRIX_HELM_DATABASE_PASSWORD` via `secretKeyRef` and `MAUTRIX_HELM_CONFIG_DATABASE__URI` with the placeholder URI; the kubelet expands the `$(VAR)` reference at container start.
- `mautrix-go-base.bridgev2MergedConfig` injects `env_config_prefix: MAUTRIX_HELM_CONFIG_`, so mautrix-go (v0.26.1+, bridge releases `v0.2512.0`+) overrides `database.uri` from that env var at startup.
- `mautrix-go-base.databasePostgresPasswordChecksum` hashes only the Secret name/key in this mode, never the value; rotation therefore needs an external reloader.

`values.config.baseExtra` cannot set `env_config_prefix` while `existingSecret` is set. The password must be URI-safe because the runtime substitution cannot URL-encode it.

## Kubernetes Behavior

Templates in this library follow mautrix Kubernetes guidance:

- Direct bridge command (no startup script)
- `--no-update` support via wrapper args
- Read-only config mount at `/data`
- Singleton bridge StatefulSet (`replicas: 1`)
- `publishNotReadyAddresses: true`
- Optional probes only (disabled by default)

## New Go Bridge Checklist

If you want to make a new Go Bridge chart, simply:

1. Copy `charts/mautrix-whatsapp` to a new chart name.
2. Update `Chart.yaml` metadata and image defaults.
3. Update wrapper helpers in `templates/_helpers.tpl`:
    - `registrationFileKey`
    - `defaultRegistrationUserRegex`
    - `managedConfig`
    - `reservedBasePaths`
    - `reservedNetworkPaths`
    - `doublePuppetRegistrationFileKey`
    - `doublePuppetUserRegex`
    - `mergedConfig` include call to `mautrix-go-base.bridgev2MergedConfig`
    - any bridge-specific config defaults
4. Keep Kubernetes runtime shape unchanged unless bridge behavior requires it.
5. Update `values.yaml`, `values.schema.json`, and examples.
6. Update chart README and root docs tables.
7. Validate with `helm lint` and `helm template` across all example values.
