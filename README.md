# Matrix Helm Charts

## Overview

**Note:** I am actively testing each helm chart and plan to make `1.0.0` releases only after each have been tested / considered ready. For now, `ntfy`, `matrix-appservice-irc` and the two Python-based Mautrix bridges `mautrix-telegram` / `mautrix-googlechat` have been confirmed tested and working, hence `0.9.X` versions, but are due a `1.0.0` after further testing of different configurations / deployments.

A collection of helm charts to deploy services alongside Matrix, with example `values.yaml` files, initially focused on [ESS Community](https://github.com/element-hq/ess-helm) but should work with any Matrix deployment.

## Components

| Component | Helm Chart Version | App Version | Repository | Description |
| --- | --- | --- | --- | --- |
| `ntfy` | `0.9.5` | `v2.17.0` | [binwiederhier/ntfy](https://github.com/binwiederhier/ntfy) | HTTP-based pub-sub notification service. Use to provide Matrix push notifications on Android without Google. |
| `matrix-appservice-irc` | `0.9.13` | `release-4.0.0` | [matrix-org/matrix-appservice-irc](https://github.com/matrix-org/matrix-appservice-irc) | IRC bridge for Matrix. |

### Mautrix Bridges

#### Python Bridges

| Component | Helm Chart Version | App Version | Repository | Description |
| --- | --- | --- | --- | --- |
| `mautrix-telegram` | `0.9.1` | `v0.15.3` | [mautrix/telegram](https://github.com/mautrix/telegram) | A Matrix-Telegram hybrid puppeting/relaybot bridge. |
| `mautrix-googlechat` | `0.9.0` | `v0.5.2` | [mautrix/googlechat](https://github.com/mautrix/googlechat) | A Matrix-Google Chat puppeting bridge. |
