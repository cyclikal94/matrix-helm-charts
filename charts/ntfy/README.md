# ntfy [![ntfy chart version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.ntfy%5B0%5D.version&label=ntfy&logo=helm&style=for-the-badge)](https://github.com/cyclikal94/matrix-helm-charts/tree/main/charts/ntfy)

ntfy (pronounced "notify") is a simple HTTP-based pub-sub notification service. See [binwiederhier/ntfy](https://github.com/binwiederhier/ntfy) for details.

> [!TIP]
> Not interested in the nitty-gritty technical details? Start with the [INSTALLATION](../../INSTALLATION.md) guide!.

## Overview

This chart deploys ntfy with a ConfigMap, Service, StatefulSet, and Ingress.

## Prerequisites

- Kubernetes cluster
- Helm 3.x
- Ingress controller (defaults assume `traefik`)
- Default StorageClass (or set `persistence.storageClassName`)

## Quick Start

Create a minimal values file:

```yaml
host: ntfy.example.com
```

Install:

```bash
helm upgrade --install ntfy ./charts/ntfy -f ntfy-values.yaml
```

Install from published OCI registry (preferred):

```bash
helm upgrade --install ntfy oci://ghcr.io/cyclikal94/matrix-helm-charts/ntfy -n ntfy --create-namespace --values ntfy-values.yaml
```

Install from published Helm repository (legacy-compatible):

```bash
helm repo add matrix-helm-charts https://cyclikal94.github.io/matrix-helm-charts
helm repo update
helm upgrade --install ntfy matrix-helm-charts/ntfy -n ntfy --create-namespace --values ntfy-values.yaml
```

## Naming

- By default, resource names are release-scoped.
- Example: release `prod` renders names like `prod-ntfy` and `prod-ntfy-ingress`.
- Set `nameOverride` or `fullnameOverride` only when you need fixed/custom names.

## Required Values

- `host` is required.
- Validation is enforced by `values.schema.json`; Helm will fail fast if `host` is missing or empty.
- If deploying to Matrix, you should replace `visitor-request-limit-exempt-hosts` with your Synapse domain.

## Linting

Because `host` is required, lint with a values file:

```bash
helm lint ./charts/ntfy -f ./charts/ntfy/values.example.yaml
```

Or lint with your own values file containing at least:

```yaml
host: ntfy.example.com
```

## Example Values Files

- `values.example.yaml`: absolute minimal chart input (`host` only).
- `values.matrix.example.yaml`: recommended Matrix/ESS-focused ntfy config example.
- `values.selfsigned.example.yaml`: self-signed/custom TLS secret example; typically merged with the Matrix example.

## Defaults

- All optional values and defaults are in `values.yaml`.
- View defaults directly with:

```bash
helm show values ./charts/ntfy
```

## Health Probes

The chart enables HTTP readiness and liveness probes by default using ntfy's health endpoint:

- Path: `/v1/health`
- Expected response: HTTP 200 with `{"healthy":true}`

Probe settings are configurable under `probes.readiness` and `probes.liveness`.

## Metrics and ServiceMonitor

If you enable metrics in ntfy config:

```yaml
config:
  extra: |
    enable-metrics: true
```

the chart automatically creates a `ServiceMonitor` (Prometheus Operator CRD) that scrapes:

- Service port: `http`
- Path: `/metrics`
- Interval: `30s`

For Prometheus discovery label selectors (for example kube-prometheus-stack), you can add labels:

```yaml
serviceMonitor:
  labels:
    release: monitoring
```

## TLS Options

### cert-manager (default)

By default, the chart adds this ingress annotation:

`cert-manager.io/cluster-issuer: letsencrypt-prod`

You can change issuer:

```yaml
host: ntfy.example.com
ingress:
  clusterIssuer: letsencrypt-staging
```

### Self-signed or custom certificate secret

Create a TLS secret in the target namespace:

```bash
kubectl -n <namespace> create secret tls ntfy-tls --cert=ntfy.crt --key=ntfy.key
```

Then disable issuer annotation and use your secret:

```yaml
host: ntfy.example.com
ingress:
  clusterIssuer: ""
  tls:
    enabled: true
    secretName: ntfy-tls
```

Ready-to-use file: `values.selfsigned.example.yaml`

You can supply multiple `values.yaml` files so you could also deploy with the `values.matrix.example.yaml `:

```bash
helm upgrade --install ntfy ./charts/ntfy \
  -f charts/ntfy/values.matrix.example.yaml \
  -f charts/ntfy/values.selfsigned.example.yaml
```

**Note:** Both examples define `host` so you should ensure both are correct (or the last provided will apply).

## Matrix/ESS Example

For Matrix/Element deployments, use custom ntfy server config for UnifiedPush-style access control (for example `auth-access` entries).

Ready-to-use file: `values.matrix.example.yaml`

## Verify

```bash
kubectl get pods,svc -l app.kubernetes.io/instance=ntfy -n ntfy
kubectl get ingress -l app.kubernetes.io/instance=ntfy -n ntfy
```
