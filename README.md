# Matrix Helm Charts

## Overview

**Note:** I am actively testing each helm chart and plan to make `1.0.0` releases only after each have been tested / considered ready. For now, `ntfy`, `matrix-appservice-irc` and the two Python-based Mautrix bridges `mautrix-telegram` / `mautrix-googlechat` have been confirmed tested and working, hence `0.9.X` versions, but are due a `1.0.0` after further testing of different configurations / deployments.

A collection of helm charts to deploy services alongside Matrix, with example `values.yaml` files, initially focused on [ESS Community](https://github.com/element-hq/ess-helm) but should work with any Matrix deployment.

## Usage

### OCI Registry (Preferred)

All charts are published as OCI artifacts on GHCR:

```bash
helm upgrade --install <release-name> oci://ghcr.io/cyclikal94/matrix-helm-charts/<chart-name> --namespace <namespace> --create-namespace --values <values-file>
```

### HTTP Registry (Legacy-Compatible)

The legacy index-based repository remains available:

```bash
helm repo add matrix-helm-charts https://cyclikal94.github.io/matrix-helm-charts
helm repo update
helm upgrade --install <release-name> matrix-helm-charts/<chart-name> --namespace <namespace> --create-namespace --values <values-file>
```

## Components

| Link | Component | Helm Chart Version | App Version | Repository | Description |
| --- | --- | --- | --- | --- | --- |
| [📎](charts/ntfy/README.md) | `ntfy` | `0.9.6` | `v2.17.0` | [binwiederhier/ntfy](https://github.com/binwiederhier/ntfy) | HTTP-based pub-sub notification service. Use to provide Matrix push notifications on Android without Google. |
| [📎](charts/matrix-appservice-irc/README.md) | `matrix-appservice-irc` | `0.9.13` | `release-4.0.0` | [matrix-org/matrix-appservice-irc](https://github.com/matrix-org/matrix-appservice-irc) | IRC bridge for Matrix. |

### Mautrix Bridges

#### Python Bridges

| Link | Component | Helm Chart Version | App Version | Repository | Description |
| --- | --- | --- | --- | --- | --- |
| [📎](charts/mautrix-telegram/README.md) | `mautrix-telegram` | `0.9.1` | `v0.15.3` | [mautrix/telegram](https://github.com/mautrix/telegram) | A Matrix-Telegram hybrid puppeting/relaybot bridge. |
| [📎](charts/mautrix-googlechat/README.md) | `mautrix-googlechat` | `0.9.0` | `v0.5.2` | [mautrix/googlechat](https://github.com/mautrix/googlechat) | A Matrix-Google Chat puppeting bridge. |

#### Go Bridges

For the go bridges, in order to reduce duplication, they use a common base chart, which is then extended by specific charts for each bridge.

| Link | Component | Helm Chart Version | App Version | Repository | Description |
| --- | --- | --- | --- | --- | --- |
| [📎](charts/mautrix-go-base/README.md) | `mautrix-go-base` | `0.1.3` | `0.0.0` | N/A | The base chart used for all `mautrix-` go bridges. |
| [📎](charts/mautrix-whatsapp/README.md) | `mautrix-whatsapp` | `0.1.5` | `v0.2602.0` | [mautrix/whatsapp](https://github.com/mautrix/whatsapp) | A Matrix-WhatsApp puppeting bridge based on [whatsmeow](https://github.com/tulir/whatsmeow). |
| [📎](charts/mautrix-twitter/README.md) | `mautrix-twitter` | `0.1.0` | `v0.2511.0` | [mautrix/twitter](https://github.com/mautrix/twitter) | A Matrix-Twitter DM puppeting bridge. |
| [📎](charts/mautrix-bluesky/README.md) | `mautrix-bluesky` | `0.1.0` | `v0.2510.0` | [mautrix/bluesky](https://github.com/mautrix/bluesky) | A Matrix-Bluesky DM puppeting bridge. |
| [📎](charts/mautrix-signal/README.md) | `mautrix-signal` | `0.1.0` | `v0.2602.2` | [mautrix/signal](https://github.com/mautrix/signal) | A Matrix-Signal puppeting bridge. |
| [📎](charts/mautrix-slack/README.md) | `mautrix-slack` | `0.1.0` | `v0.2602.0` | [mautrix/slack](https://github.com/mautrix/slack) | A Matrix-Slack puppeting bridge based on [slack-go](https://github.com/slack-go/slack). |
| [📎](charts/mautrix-gmessages/README.md) | `mautrix-gmessages` | `0.1.0` | `v0.2602.0` | [mautrix/gmessages](https://github.com/mautrix/gmessages) | A Matrix-Google Messages puppeting bridge. |
| [📎](charts/mautrix-gvoice/README.md) | `mautrix-gvoice` | `0.1.0` | `v0.2511.0` | [mautrix/gvoice](https://github.com/mautrix/gvoice) | A Matrix-Google Voice puppeting bridge. |
| [📎](charts/mautrix-linkedin/README.md) | `mautrix-linkedin` | `0.1.0` | `v0.2602.0` | [mautrix/linkedin](https://github.com/mautrix/linkedin) | A Matrix-LinkedIn puppeting bridge. |
| [📎](charts/mautrix-zulip/README.md) | `mautrix-zulip` | `0.1.0` | `v0.2511.0` | [mautrix/zulip](https://github.com/mautrix/zulip) | A Matrix-Zulip puppeting bridge. |
