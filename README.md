![Matrix Helm Charts](https://cyclikal.dev/matrix-helm-charts/assets/banner.svg)

# Matrix Helm Charts

## Overview

A collection of helm charts to deploy Matrix-related components into Kubernetes, with example `values.yaml` files pre-configured for use with Matrix.

All charts are created and tested against a deployed [ESS Community](https://github.com/element-hq/ess-helm) instance but should work with any Matrix deployment accessible from your cluster.

Feel free to join the Matrix Room to discuss:

[![Matrix](https://img.shields.io/matrix/matrix-helm%3Amatrix.org?fetchMode=summary&style=for-the-badge&logo=matrix&label=%23matrix-helm:matrix.org)](https://matrix.to/#/#matrix-helm:matrix.org)

## Usage

Generally speaking, installation / usage follows these steps:

1. You configure a `values.yaml` file for your environment then deploy the helm chart using it. (Matrix-specific `values.yaml` files in this repository are provided as examples, just replace the placeholder values).
2. Point your Synapse deployment at the generated App Service Registration file, i.e. if using ESS Community, just redeploy with the sample `values.yaml` per the chart `README.md`.
3. Start a DM with the bot `@componentnamebot:example.com`, i.e. `@whatsappbot:example.com`, login etc.

> [!TIP]
> You should start with the [INSTALLATION](INSTALLATION.md) guide!

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

> [!TIP]
> Click on the desired helm charts' badge to be taken to its README for detailed deployment information.


Components are organised into categories copying the [matrix.org Ecosystem](https://matrix.org/ecosystem/) section. As such components will be either `Clients`, `Bridges`, `Servers`, or `Integrations` - where components aren't present on [matrix.org](https://matrix.org/ecosystem/) I'll do my best to put them in an appropriate category. The remaining catefories of `SDKs`, `Distribution` and `Hosting` are unlikely to be applicable here.

Given this is new, I'm actively looking for useful new charts to make, I'm prioritising projects listed on [matrix.org Ecosystem](https://matrix.org/ecosystem/) likely filtering on a "Maturity" of `Stable` / `Beta` - if you have suggestions, please do raise an issue!

### Integrations

<table><tr><td>

[![ntfy](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.ntfy%5B0%5D.version&label=ntfy%20Helm%20Chart&logo=helm&style=for-the-badge)](charts/ntfy/README.md)

</td><td align="right">

[![binwiederhier/ntfy](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.ntfy%5B0%5D.appVersion&label=binwiederhier%2Fntfy&logo=github&style=for-the-badge)](https://github.com/binwiederhier/ntfy)

</td></tr><tr><td colspan="2">

HTTP-based pub-sub notification service. Useful to allow providing Matrix push notifications on Android without Google. You'll need to be using a Matrix Android client that supports serving push notification via UnifiedPush, i.e. `Element X`.

</td></tr></table>

<table><tr><td>

[![baibot](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.baibot%5B0%5D.version&label=baibot%20Helm%20Chart&logo=helm&style=for-the-badge)](charts/baibot/README.md)

</td><td align="right">

[![etkecc/baibot](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.baibot%5B0%5D.appVersion&label=etkecc%2Fbaibot&logo=github&style=for-the-badge)](https://github.com/etkecc/baibot)

</td></tr><tr><td colspan="2">

AI bot for Matrix built by etke.cc. This chart keeps the upstream YAML config model intact while adding Kubernetes-friendly secret handling for authentication, persistence encryption keys, and static agent API keys.

</td></tr></table>

### Bridges

<table><tr><td>

[![matrix-appservice-irc](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.matrix-appservice-irc%5B0%5D.version&label=matrix-appservice-irc%20Helm%20Chart&logo=helm&style=for-the-badge)](charts/matrix-appservice-irc/README.md)

</td><td align="right">

[![matrix-org/matrix-appservice-irc](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.matrix-appservice-irc%5B0%5D.appVersion&label=matrix-org%2Fmatrix-appservice-irc&logo=github&style=for-the-badge)](https://github.com/matrix-org/matrix-appservice-irc)

</td></tr><tr><td colspan="2">

IRC bridge for Matrix. This bridge allows you to join IRC channels and chat to IRC users via Matrix rooms. For capabilities etc. check it's entry on [matrix.org IRC Bridges](https://matrix.org/ecosystem/bridges/irc/).

</td></tr></table>

### Mautrix Bridges

Given there are so many `mautrix` bridges, I'm collating them under a dedicated section. They also, for the most part, all use the same base chart and so setup (`values.yaml` / App Service Registration) is the same for all.

#### Python Bridges

<table><tr><td>

[![mautrix-googlechat](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-googlechat%5B0%5D.version&label=mautrix-googlechat%20Helm%20Chart&logo=helm&style=for-the-badge)](charts/mautrix-googlechat/README.md)

</td><td align="right">

[![mautrix/googlechat](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-googlechat%5B0%5D.appVersion&label=mautrix%2Fgooglechat&logo=github&style=for-the-badge)](https://github.com/mautrix/googlechat)

</td></tr><tr><td colspan="2">

A Matrix-Google Chat puppeting bridge. For all 5 of you using Google Chat this will allow continuing those conversations in Matrix. No it's not, Allo, Hangouts or Meet - why do/did they have so many. I think this is some holdover from Google+. For capabilities etc. check it's entry on [matrix.org Google Chat Bridges](https://matrix.org/ecosystem/bridges/google_chat/). For hands-on `mautrix` docs, check [docs.mau.fi](https://docs.mau.fi/bridges/), just note you only need to care about the custom configuration (everything else is handled by the chart).

</td></tr></table>

<table><tr><td>

[![mautrix-telegram](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-telegram%5B0%5D.version&label=mautrix-telegram%20Helm%20Chart&logo=helm&style=for-the-badge)](charts/mautrix-telegram/README.md)

</td><td align="right">

[![mautrix/telegram](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-telegram%5B0%5D.appVersion&label=mautrix%2Ftelegram&logo=github&style=for-the-badge)](https://github.com/mautrix/telegram)

</td></tr><tr><td colspan="2">

A Matrix-Telegram hybrid puppeting/relaybot bridge. Note this is a `mautrix` python bridge, so I believe will eventually be replaced with a go variant. For capabilities etc. check it's entry on [matrix.org Telegram Bridges](https://matrix.org/ecosystem/bridges/telegram/). For hands-on `mautrix` docs, check [docs.mau.fi](https://docs.mau.fi/bridges/), just note you only need to care about the custom configuration (everything else is handled by the chart).

</td></tr></table>

#### Go Bridges

Double puppetting is enabled by default, and as such, any charts sharing the same `mautrix-go-base` chart version will use the same double puppet App Service registration automatically.

<table><tr><td>

[![mautrix-go-base](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-go-base%5B0%5D.version&label=mautrix-go-base%20Helm%20Chart&logo=helm&style=for-the-badge)](charts/mautrix-go-base/README.md)

</td><td align="right">

[![cyclikal94/matrix-helm-charts](https://img.shields.io/badge/cyclikal94%2Fmatrix--helm--charts-N%2FA-blue?logo=github&style=for-the-badge)](https://github.com/cyclikal94/matrix-helm-charts)

</td></tr><tr><td colspan="2">

The base chart used for all `mautrix-` go bridges. Created in order to reduce duplication, all dependant charts use this base chart, then extend as needed for bridge specifics.

</td></tr></table>

<table><tr><td>

[![mautrix-bluesky](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-bluesky%5B0%5D.version&label=mautrix-bluesky%20Helm%20Chart&logo=helm&style=for-the-badge)](charts/mautrix-bluesky/README.md)

</td><td align="right">

[![mautrix/bluesky](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-bluesky%5B0%5D.appVersion&label=mautrix%2Fbluesky&logo=github&style=for-the-badge)](https://github.com/mautrix/bluesky)

</td></tr><tr><td colspan="2">

A Matrix-Bluesky DM puppeting bridge. No category for Bluesky bridges on [matrix.org Ecosystem Bridges](https://matrix.org/ecosystem/bridges/) for this one. For hands-on `mautrix` docs, check [docs.mau.fi](https://docs.mau.fi/bridges/), just note you only need to care about the custom configuration (everything else is handled by the chart).

</td></tr></table>

<table><tr><td>

[![mautrix-gmessages](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-gmessages%5B0%5D.version&label=mautrix-gmessages%20Helm%20Chart&logo=helm&style=for-the-badge)](charts/mautrix-gmessages/README.md)

</td><td align="right">

[![mautrix/gmessages](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-gmessages%5B0%5D.appVersion&label=mautrix%2Fgmessages&logo=github&style=for-the-badge)](https://github.com/mautrix/gmessages)

</td></tr><tr><td colspan="2">

A Matrix-Google Messages puppeting bridge. For capabilities etc. check it's entry on [matrix.org SMS Bridges](https://matrix.org/ecosystem/bridges/sms/). For hands-on `mautrix` docs, check [docs.mau.fi](https://docs.mau.fi/bridges/), just note you only need to care about the custom configuration (everything else is handled by the chart).

</td></tr></table>

<table><tr><td>

[![mautrix-gvoice](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-gvoice%5B0%5D.version&label=mautrix-gvoice%20Helm%20Chart&logo=helm&style=for-the-badge)](charts/mautrix-gvoice/README.md)

</td><td align="right">

[![mautrix/gvoice](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-gvoice%5B0%5D.appVersion&label=mautrix%2Fgvoice&logo=github&style=for-the-badge)](https://github.com/mautrix/gvoice)

</td></tr><tr><td colspan="2">

A Matrix-Google Voice puppeting bridge. No category for Google Voice bridges on [matrix.org Ecosystem Bridges](https://matrix.org/ecosystem/bridges/) for this one. For hands-on `mautrix` docs, check [docs.mau.fi](https://docs.mau.fi/bridges/), just note you only need to care about the custom configuration (everything else is handled by the chart).

</td></tr></table>

<table><tr><td>

[![mautrix-linkedin](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-linkedin%5B0%5D.version&label=mautrix-linkedin%20Helm%20Chart&logo=helm&style=for-the-badge)](charts/mautrix-linkedin/README.md)

</td><td align="right">

[![mautrix/linkedin](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-linkedin%5B0%5D.appVersion&label=mautrix%2Flinkedin&logo=github&style=for-the-badge)](https://github.com/mautrix/linkedin)

</td></tr><tr><td colspan="2">

A Matrix-LinkedIn puppeting bridge. For capabilities etc. check it's entry on [matrix.org LinkedIn Bridges](https://matrix.org/ecosystem/bridges/linkedin/). For hands-on `mautrix` docs, check [docs.mau.fi](https://docs.mau.fi/bridges/), just note you only need to care about the custom configuration (everything else is handled by the chart).

</td></tr></table>

<table><tr><td>

[![mautrix-meta](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-meta%5B0%5D.version&label=mautrix-meta%20Helm%20Chart&logo=helm&style=for-the-badge)](charts/mautrix-meta/README.md) 

</td><td align="right">

[![mautrix/meta](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-meta%5B0%5D.appVersion&label=mautrix%2Fmeta&logo=github&style=for-the-badge)](https://github.com/mautrix/meta)

</td></tr><tr><td colspan="2">

A Matrix-Meta puppeting bridge. For capabilities etc. check it's entry on [matrix.org Instagram Bridges](https://matrix.org/ecosystem/bridges/instagram/), don't let the link fool you, it also does Facebook Messaging. For hands-on `mautrix` docs, check [docs.mau.fi](https://docs.mau.fi/bridges/), just note you only need to care about the custom configuration (everything else is handled by the chart).

</td></tr></table>

<table><tr><td>

[![mautrix-signal](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-signal%5B0%5D.version&label=mautrix-signal%20Helm%20Chart&logo=helm&style=for-the-badge)](charts/mautrix-signal/README.md)

</td><td align="right">

[![mautrix/signal](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-signal%5B0%5D.appVersion&label=mautrix%2Fsignal&logo=github&style=for-the-badge)](https://github.com/mautrix/signal)

</td></tr><tr><td colspan="2">

A Matrix-Signal puppeting bridge. For capabilities etc. check it's entry on [matrix.org Signal Bridges](https://matrix.org/ecosystem/bridges/signal/). For hands-on `mautrix` docs, check [docs.mau.fi](https://docs.mau.fi/bridges/), just note you only need to care about the custom configuration (everything else is handled by the chart).

</td></tr></table>

<table><tr><td>

[![mautrix-slack](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-slack%5B0%5D.version&label=mautrix-slack%20Helm%20Chart&logo=helm&style=for-the-badge)](charts/mautrix-slack/README.md)

</td><td align="right">

[![mautrix/slack](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-slack%5B0%5D.appVersion&label=mautrix%2Fslack&logo=github&style=for-the-badge)](https://github.com/mautrix/slack)

</td></tr><tr><td colspan="2">

A Matrix-Slack puppeting bridge based on [slack-go](https://github.com/slack-go/slack). For capabilities etc. check it's entry on [matrix.org Slack Bridges](https://matrix.org/ecosystem/bridges/slack/). For hands-on `mautrix` docs, check [docs.mau.fi](https://docs.mau.fi/bridges/), just note you only need to care about the custom configuration (everything else is handled by the chart).

</td></tr></table>

<table><tr><td>

[![mautrix-twitter](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-twitter%5B0%5D.version&label=mautrix-twitter%20Helm%20Chart&logo=helm&style=for-the-badge)](charts/mautrix-twitter/README.md)

</td><td align="right">

[![mautrix/twitter](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-twitter%5B0%5D.appVersion&label=mautrix%2Ftwitter&logo=github&style=for-the-badge)](https://github.com/mautrix/twitter)

</td></tr><tr><td colspan="2">

A Matrix-Twitter DM puppeting bridge. For capabilities etc. check it's entry on [matrix.org X Bridges](https://matrix.org/ecosystem/bridges/X/). For hands-on `mautrix` docs, check [docs.mau.fi](https://docs.mau.fi/bridges/), just note you only need to care about the custom configuration (everything else is handled by the chart).

</td></tr></table>

<table><tr><td>

[![mautrix-whatsapp](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-whatsapp%5B0%5D.version&label=mautrix-whatsapp%20Helm%20Chart&logo=helm&style=for-the-badge)](charts/mautrix-whatsapp/README.md)

</td><td align="right">

[![mautrix/whatsapp](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-whatsapp%5B0%5D.appVersion&label=mautrix%2Fwhatsapp&logo=github&style=for-the-badge)](https://github.com/mautrix/whatsapp)

</td></tr><tr><td colspan="2">

A Matrix-WhatsApp puppeting bridge based on [whatsmeow](https://github.com/tulir/whatsmeow). For capabilities etc. check it's entry on [matrix.org Whatsapp Bridges](https://matrix.org/ecosystem/bridges/whatsapp/). For hands-on `mautrix` docs, check [docs.mau.fi](https://docs.mau.fi/bridges/), just note you only need to care about the custom configuration (everything else is handled by the chart).

</td></tr></table>

<table><tr><td>

[![mautrix-zulip](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-zulip%5B0%5D.version&label=mautrix-zulip%20Helm%20Chart&logo=helm&style=for-the-badge)](charts/mautrix-zulip/README.md)

</td><td align="right">

[![mautrix/zulip](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/gh-pages/index.yaml&query=%24.entries.mautrix-zulip%5B0%5D.appVersion&label=mautrix%2Fzulip&logo=github&style=for-the-badge)](https://github.com/mautrix/zulip)

</td></tr><tr><td colspan="2">

A Matrix-Zulip puppeting bridge. For capabilities etc. check it's entry on [matrix.org Zulip Bridges](https://matrix.org/ecosystem/bridges/zulip/). For hands-on `mautrix` docs, check [docs.mau.fi](https://docs.mau.fi/bridges/), just note you only need to care about the custom configuration (everything else is handled by the chart).

</td></tr></table>

## Credits

This project has been a bunch of work, but it is nothing without the underlying projects these charts deploy. These charts could not exist without the people who built and maintain those cool things, so credit and thanks goes to them.

- [@binwiederhier](https://github.com/binwiederhier) / [binwiederhier/ntfy](https://github.com/binwiederhier/ntfy) contributors, this was the original chart / plan for this project, created to be able to deploy `ntfy` alongside `ess-helm` easily.
- [@matrix.org](https://github.com/matrix-org) / [matrix-org/matrix-appservice-irc](https://github.com/matrix-org/matrix-appservice-irc) contributors, this was the first helm chart I setup that meant I had to figure out App Service Registration via the charts. Hopefully the way it works makes sense!
- [@tulir](https://github.com/tulir) / [@mautrix](https://github.com/mautrix) contributors, it's kinda crazy how many bridges there are and that they all nicely work the same. It meant after creating the `mautrix-go-base` chart and getting `mautrix-whatsapp` working, it was just copy/paste for the rest! As this point, they are the bulk of these charts so... you should seriously check out the repos links above!
