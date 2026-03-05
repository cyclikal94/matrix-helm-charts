# Matrix Helm Charts

## Overview

A collection of helm charts to deploy Matrix-related components into Kubernetes, with example `values.yaml` files pre-configured for use with Matrix.

All charts are created and tested against a deployed [ESS Community](https://github.com/element-hq/ess-helm) instance but should work with any Matrix deployment accessible from your cluster.

## Usage

Generally speaking, installation / usage follows these steps:

1. You configure a `values.yaml` file for your environment then deploy the helm chart using it. (Matrix-specific `values.yaml` files in this repository are provided as examples, just replace the placeholder values).
2. Point your Synapse deployment at the generated App Service Registration file, i.e. if using ESS Community, just redeploy with the sample `values.yaml` per the chart `README.md`.
3. Start a DM with the bot `@componentnamebot:example.com`, i.e. `@whatsappbot:example.com`, login etc.

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

Components are organised into categories copying the [matrix.org Ecosystem](https://matrix.org/ecosystem/) section. As such components will be either `Clients`, `Bridges`, `Servers`, or `Integrations` - where components aren't present on [matrix.org](https://matrix.org/ecosystem/) I'll do my best to put them in an appropriate category. The remaining catefories of `SDKs`, `Distribution` and `Hosting` are unlikely to be applicable here.

Given this is new, I'm actively looking for useful new charts to make, I'm prioritising projects listed on [matrix.org Ecosystem](https://matrix.org/ecosystem/) likely filtering on a "Maturity" of `Stable` / `Beta` - if you have suggestions, please do raise an issue!

> [!NOTE]
> Please note that I am actively testing each helm chart and plan to make `1.0.0` releases only after each have been tested / considered ready. For now, `ntfy`, `matrix-appservice-irc` and the two Python-based Mautrix bridges `mautrix-telegram` / `mautrix-googlechat` have been confirmed tested and working, hence `0.9.X` versions, but are due a `1.0.0` after further testing of different configurations / deployments.

### Tools

- [![ntfy](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.ntfy%5B0%5D.version&label=ntfy&logo=helm)](charts/ntfy/README.md) [![binwiederhier/ntfy](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.ntfy%5B0%5D.appVersion&label=binwiederhier%2Fntfy&logo=github)](https://github.com/binwiederhier/ntfy)
    - HTTP-based pub-sub notification service.
    - You can use this to provide Matrix push notifications on Android without Google.

### Bridges

- [![matrix-appservice-irc](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.matrix-appservice-irc%5B0%5D.version&label=matrix-appservice-irc&logo=helm)](charts/matrix-appservice-irc/README.md) [![matrix-org/matrix-appservice-irc](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.matrix-appservice-irc%5B0%5D.appVersion&label=matrix-org%2Fmatrix-appservice-irc&logo=github)](https://github.com/matrix-org/matrix-appservice-irc)
    - IRC bridge for Matrix.

### Mautrix Bridges

Given there are so many `mautrix` bridges, I'm collating them under a dedicated section. They also, for the most part, all use the same base chart and so setup (`values.yaml` / App Service Registration) is the same for all.

#### Python Bridges

- [![mautrix-googlechat](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-googlechat%5B0%5D.version&label=mautrix-googlechat&logo=helm)](charts/mautrix-googlechat/README.md) [![mautrix/googlechat](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-googlechat%5B0%5D.appVersion&label=mautrix%2Fgooglechat&logo=github)](https://github.com/mautrix/googlechat)
    - A Matrix-Google Chat puppeting bridge.

- [![mautrix-telegram](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-telegram%5B0%5D.version&label=mautrix-telegram&logo=helm)](charts/mautrix-telegram/README.md) [![mautrix/telegram](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-telegram%5B0%5D.appVersion&label=mautrix%2Ftelegram&logo=github)](https://github.com/mautrix/telegram)
    - A Matrix-Telegram hybrid puppeting/relaybot bridge.

#### Go Bridges

For the go bridges, in order to reduce duplication, they use a common base chart, which is then extended by specific charts for each bridge.

Double puppetting is enabled by default, and as such, any charts sharing the same `mautrix-go-base` chart version will use the same double puppet App Service registration automatically.

> [!NOTE]
> The `mautrix-go-base` components are in-progress, though `mautrix-whatsapp` and `mautrix-linkedin` have been deployed and appear to be working (including Double Puppetting) but YMMV so for now they are `1.0.X` until I can fully test.

##### Base Chart

- [![mautrix-go-base](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-go-base%5B0%5D.version&label=mautrix-go-base&logo=helm)](charts/mautrix-go-base/README.md) [![cyclikal94/matrix-helm-charts](https://img.shields.io/badge/cyclikal94%2Fmatrix--helm--charts-N%2FA-blue?logo=github)](https://github.com/cyclikal94/matrix-helm-charts)
    - The base chart used for all `mautrix-` go bridges.

##### Bridge Charts

- [![mautrix-bluesky](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-bluesky%5B0%5D.version&label=mautrix-bluesky&logo=helm)](charts/mautrix-bluesky/README.md) [![mautrix/bluesky](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-bluesky%5B0%5D.appVersion&label=mautrix%2Fbluesky&logo=github)](https://github.com/mautrix/bluesky)
    - A Matrix-Bluesky DM puppeting bridge.

- [![mautrix-gmessages](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-gmessages%5B0%5D.version&label=mautrix-gmessages&logo=helm)](charts/mautrix-gmessages/README.md) [![mautrix/gmessages](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-gmessages%5B0%5D.appVersion&label=mautrix%2Fgmessages&logo=github)](https://github.com/mautrix/gmessages)
    - A Matrix-Google Messages puppeting bridge.

- [![mautrix-gvoice](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-gvoice%5B0%5D.version&label=mautrix-gvoice&logo=helm)](charts/mautrix-gvoice/README.md) [![mautrix/gvoice](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-gvoice%5B0%5D.appVersion&label=mautrix%2Fgvoice&logo=github)](https://github.com/mautrix/gvoice)
    - A Matrix-Google Voice puppeting bridge.

- [![mautrix-linkedin](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-linkedin%5B0%5D.version&label=mautrix-linkedin&logo=helm)](charts/mautrix-linkedin/README.md) [![mautrix/linkedin](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-linkedin%5B0%5D.appVersion&label=mautrix%2Flinkedin&logo=github)](https://github.com/mautrix/linkedin)
    - A Matrix-LinkedIn puppeting bridge.

- [![mautrix-meta](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-meta%5B0%5D.version&label=mautrix-meta&logo=helm)](charts/mautrix-meta/README.md) [![mautrix/meta](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-meta%5B0%5D.appVersion&label=mautrix%2Fmeta&logo=github)](https://github.com/mautrix/meta)
    - A Matrix-Meta puppeting bridge.

- [![mautrix-signal](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-signal%5B0%5D.version&label=mautrix-signal&logo=helm)](charts/mautrix-signal/README.md) [![mautrix/signal](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-signal%5B0%5D.appVersion&label=mautrix%2Fsignal&logo=github)](https://github.com/mautrix/signal)
    - A Matrix-Signal puppeting bridge.

- [![mautrix-slack](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-slack%5B0%5D.version&label=mautrix-slack&logo=helm)](charts/mautrix-slack/README.md) [![mautrix/slack](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-slack%5B0%5D.appVersion&label=mautrix%2Fslack&logo=github)](https://github.com/mautrix/slack)
    - A Matrix-Slack puppeting bridge based on [slack-go](https://github.com/slack-go/slack).

- [![mautrix-twitter](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-twitter%5B0%5D.version&label=mautrix-twitter&logo=helm)](charts/mautrix-twitter/README.md) [![mautrix/twitter](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-twitter%5B0%5D.appVersion&label=mautrix%2Ftwitter&logo=github)](https://github.com/mautrix/twitter)
    - A Matrix-Twitter DM puppeting bridge.

- [![mautrix-whatsapp](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-whatsapp%5B0%5D.version&label=mautrix-whatsapp&logo=helm)](charts/mautrix-whatsapp/README.md) [![mautrix/whatsapp](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-whatsapp%5B0%5D.appVersion&label=mautrix%2Fwhatsapp&logo=github)](https://github.com/mautrix/whatsapp)
    - A Matrix-WhatsApp puppeting bridge based on [whatsmeow](https://github.com/tulir/whatsmeow).

- [![mautrix-zulip](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-zulip%5B0%5D.version&label=mautrix-zulip&logo=helm)](charts/mautrix-zulip/README.md) [![mautrix/zulip](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-zulip%5B0%5D.appVersion&label=mautrix%2Fzulip&logo=github)](https://github.com/mautrix/zulip)
    - A Matrix-Zulip puppeting bridge.

## Credits

This project has been a bunch of work, but it is nothing without the underlying projects these charts deploy. These charts could not exist without the people who built and maintain those cool things, so credit and thanks goes to them.

- [@binwiederhier](https://github.com/binwiederhier) / [binwiederhier/ntfy](https://github.com/binwiederhier/ntfy) contributors, this was the original chart / plan for this project, created to be able to deploy `ntfy` alongside `ess-helm` easily.
- [@matrix.org](https://github.com/matrix-org) / [matrix-org/matrix-appservice-irc](https://github.com/matrix-org/matrix-appservice-irc) contributors, this was the first helm chart I setup that meant I had to figure out App Service Registration via the charts. Hopefully the way it works makes sense!
- [@tulir](https://github.com/tulir) / [@mautrix](https://github.com/mautrix) contributors, it's kinda crazy how many bridges there are and that they all nicely work the same. It meant after creating the `mautrix-go-base` chart and getting `mautrix-whatsapp` working, it was just copy/paste for the rest! As this point, they are the bulk of these charts so... you should seriously check out the repos links above!
