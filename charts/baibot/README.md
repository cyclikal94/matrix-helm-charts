# baibot [![baibot chart version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.baibot%5B0%5D.version&label=baibot&logo=helm&style=for-the-badge)](https://github.com/cyclikal94/matrix-helm-charts/tree/main/charts/baibot)

baibot is an AI bot for Matrix built by [etke.cc](https://github.com/etkecc/baibot). See [etkecc/baibot](https://github.com/etkecc/baibot) for upstream details.

> [!TIP]
> Not interested in the nitty-gritty technical details? Start with the [INSTALLATION](../../INSTALLATION.md) guide!.

## Overview

This chart deploys `baibot` with:

- a singleton `StatefulSet`
- a generated config `Secret` containing `config.yml`
- an optional chart-managed runtime support `Secret` for generated persistence encryption keys
- a persistent `/data` volume by default

It intentionally does **not** create a `Service`, `Ingress`, or appservice registration resources because upstream `baibot` runs as an outbound Matrix client bot and does not document an inbound HTTP listener.

## Quick Start

Create a minimal values file:

```yaml
user:
  password: change_me

config:
  extra: |
    homeserver:
      server_name: matrix.example.com
      url: http://ess-synapse.ess.svc.cluster.local:8008

    user:
      mxid_localpart: baibot
      name: baibot
      avatar: null

    access:
      admin_patterns:
        - "@admin:matrix.example.com"

    initial_global_config:
      handler:
        catch_all: null
        text_generation: null
        text_to_speech: null
        speech_to_text: null
        image_generation: null
      user_patterns:
        - "@*:matrix.example.com"
```

Install:

```bash
helm upgrade --install baibot ./charts/baibot -f baibot-values.yaml
```

Install from published OCI registry (preferred):

```bash
helm upgrade --install baibot oci://ghcr.io/cyclikal94/matrix-helm-charts/baibot -n baibot --create-namespace --values baibot-values.yaml
```

Install from published Helm repository (legacy-compatible):

```bash
helm repo add matrix-helm-charts https://cyclikal94.github.io/matrix-helm-charts
helm repo update
helm upgrade --install baibot matrix-helm-charts/baibot -n baibot --create-namespace --values baibot-values.yaml
```

## Config model

`config.extra` is the main upstream configuration surface. You should define almost all baibot settings there exactly as upstream expects.

The chart only manages a small set of sensitive paths:

- `user.password`
- `user.access_token`
- `user.device_id`
- `user.encryption.recovery_passphrase`
- `user.encryption.recovery_reset_allowed`
- `persistence.session_encryption_key`
- `persistence.config_encryption_key`
- `persistence.data_dir_path`
- `agents.static_definitions[*].config.api_key` when `agents.apiKeys.existingSecret` is used

If Helm is actively managing one of those paths, setting the same path inside `config.extra` fails template rendering.

If `config.extra` defines `persistence.session_encryption_key` or `persistence.config_encryption_key`, automatic generation for that specific key is disabled.

## User secrets

You can either set the sensitive `user.*` values directly in Helm values, or provide them via an existing Kubernetes Secret.

Supported user Secret keys are:

- `password`
- `accessToken`
- `deviceId`
- `recoveryPassphrase`
- `recoveryResetAllowed`

Create a user Secret with plain values:

```bash
kubectl -n <namespace> create secret generic baibot-user \
  --from-literal=password='change_me' \
  --from-literal=recoveryPassphrase='long-and-secure-passphrase-here' \
  --from-literal=recoveryResetAllowed='false'
```

Then reference it:

```yaml
user:
  existingSecret: baibot-user
```

## Persistence secrets

The chart always sets `persistence.data_dir_path: /data`.

For the encryption keys, you may:

- set them directly in Helm values
- provide them via an existing Secret
- let the chart auto-generate them while `persistence.enabled=true`, which is the default

Supported persistence Secret keys are:

- `sessionEncryptionKey`
- `configEncryptionKey`

Create a persistence Secret with plain values:

```bash
kubectl -n <namespace> create secret generic baibot-persistence \
  --from-literal=sessionEncryptionKey="$(openssl rand -hex 32)" \
  --from-literal=configEncryptionKey="$(openssl rand -hex 32)"
```

Then reference it:

```yaml
persistence:
  existingSecret: baibot-persistence
```

If neither key is supplied and `persistence.enabled=true`, the chart generates stable 64-hex-char keys and stores them in a chart-managed support Secret.

## Agent API keys

Define the full `agents:` structure in `config.extra`.

If you want to keep static agent API keys out of `config.extra`, provide a Secret whose keys match the agent ids:

```bash
kubectl -n <namespace> create secret generic baibot-agent-api-keys \
  --from-literal=openai='YOUR_API_KEY_HERE' \
  --from-literal=anthropic='YOUR_API_KEY_HERE'
```

Then reference it:

```yaml
agents:
  apiKeys:
    existingSecret: baibot-agent-api-keys
```

When this is enabled:

- a secret key named `openai` injects `config.api_key` into the agent with `id: openai`
- a secret key named `anthropic` injects `config.api_key` into the agent with `id: anthropic`
- rendering fails if the same agent already sets `config.api_key` inline in `config.extra`

## Persistence behaviour

Bundled persistence is enabled by default via a PVC mounted at `/data`.

Disable persistence only for throwaway or test installs:

```yaml
persistence:
  enabled: false
```

When persistence is disabled, baibot loses local session data on restart and encrypted-room recovery becomes fragile.

If you need to override the PVC defaults, these optional values are also supported:

- `persistence.accessMode`
- `persistence.size`
- `persistence.storageClassName`

## Example values files

- `values.example.yaml`: absolute minimal example with inline placeholders.
- `values.matrix.example.yaml`: Matrix-oriented ready skeleton, including static agent structure.
- `values.secrets.yaml`: external Secret example for user, persistence, and agent API keys.

## Linting

```bash
helm lint ./charts/baibot -f ./charts/baibot/values.example.yaml
helm lint ./charts/baibot -f ./charts/baibot/values.matrix.example.yaml
```

If you use `user.existingSecret`, `persistence.existingSecret`, or `agents.apiKeys.existingSecret`, local `helm template` or `helm lint` runs may fail until those Secrets exist in the target namespace.

## Verify

```bash
kubectl get pods -l app.kubernetes.io/instance=baibot -n baibot
kubectl get secret -l app.kubernetes.io/instance=baibot -n baibot
```

After the bot is running:

1. Invite the bot account to a room.
2. Configure handlers or create agents if needed.
3. Run `!bai config status` in the room to confirm the effective configuration.

## Upstream docs

- [Installation](https://github.com/etkecc/baibot/blob/main/docs/installation.md)
- [Configuration](https://github.com/etkecc/baibot/blob/main/docs/configuration/README.md)
- [Authentication](https://github.com/etkecc/baibot/blob/main/docs/configuration/authentication.md)
- [Agents](https://github.com/etkecc/baibot/blob/main/docs/agents.md)
