# Installation Guide

This guide is the quickest way to install one of the charts in this repository for a Matrix setup.

Generally speaking, I'd advise to start with minimal configuration.

For a first deployment, only change what is required to get started, then once working you can try component-specific config.

## Before You Start

You should have:

- A working Kubernetes cluster
- Helm 3 installed on your machine
- A Matrix homeserver that your cluster can reach
- The name of the chart you want to install

Installable chart names are:

- `ntfy`
- `matrix-appservice-irc`
- `mautrix-bluesky`
- `mautrix-gmessages`
- `mautrix-googlechat`
- `mautrix-gvoice`
- `mautrix-linkedin`
- `mautrix-meta`
- `mautrix-signal`
- `mautrix-slack`
- `mautrix-telegram`
- `mautrix-twitter`
- `mautrix-whatsapp`
- `mautrix-zulip`

## 1. Choose Your Chart

Pick the chart that matches the service or bridge you want to run.

Example:

```bash
export CHART=mautrix-whatsapp
```

If you are installing `ntfy` instead, set:

```bash
export CHART=ntfy
```

## 2. Download the Matrix Example Values File

Every installable chart in this repository includes a Matrix-focused example values file. Download that file first and use it as your starting point:

```bash
curl -L "https://raw.githubusercontent.com/cyclikal94/matrix-helm-charts/main/charts/${CHART}/values.matrix.example.yaml" -o "${CHART}-values.yaml"
```

This gives you a local file such as `mautrix-whatsapp-values.yaml`.

## 3. Configure Your Values File

Open the file you just downloaded and replace the obvious placeholder values with your real details. Just follow the guidance of the comments within the file.

For a first install, leave everything else alone unless you already know you need to change it.

The `values.matrix.example.yaml` files are intended to be the easiest starting point for Matrix and ESS Community deployments.

## 4. Install the Chart

Install with the published OCI chart using the chart name as both the Helm release name and the namespace:

```bash
helm upgrade --install "${CHART}" "oci://ghcr.io/cyclikal94/matrix-helm-charts/${CHART}" \
  --namespace "${CHART}" \
  --create-namespace \
  --values "./${CHART}-values.yaml"
```

This uses the standard defaults from the chart and creates the namespace for you if it does not already exist.

## 5. Wait for the Deployment to Start

Watch the new namespace until the pod is running:

```bash
kubectl get pods -n "${CHART}" -w
```

Once the pod is ready, the chart itself is installed.

If any pod has an issue, use the following to understand why:

```bash
# Make sure to replace `POD_NAME` with the name of the erroring pod!
kubectl logs POD_NAME -n "${CHART}"
kubectl describe pod POD_NAME -n "${CHART}"
```

> [!TIP]
> Installing a bridge? If you see `as_token` issues, this can be expected at this stage as you still need to link up those credentials with your Synapse per the following steps!

## 6. Start Using It

What happens next depends on what you installed.

### If You Installed a Bridge

This applies to `matrix-appservice-irc` and all `mautrix-*` charts.

After the Helm install:

1. Add the generated appservice registration ConfigMap to your Synapse deployment.

    To do this with ESS Community, simply create a new `values.yaml` called `appservices.yaml` like so:

    ```yaml
    synapse:
      appservices:
        # Replace `mautrix-whatsapp` / `whatsapp` with the chart name of your choice
        - configMap: mautrix-whatsapp-registration
          configMapKey: appservice-registration-whatsapp.yaml
    ```

2. Redeploy Synapse so it starts using that registration.

    To do this with ESS Community, simply redeploy using the same `helm upgrade` command, but make sure to include this `appservices.yaml` file as an extra `--values`:

    ```bash
    helm upgrade --install --namespace "ess" ess \
        oci://ghcr.io/element-hq/ess-helm/matrix-stack \
        -f ~/ess-config-values/hostnames.yaml \
        -f ~/ess-config-values/tls.yaml \
        -f ~/ess-config-values/appservices.yaml \
        --wait
    ```

3. Start a DM with the bridge bot in Matrix.

    By default, usually named after the bridge itself, i.e. `whatsappbot`, so if your homeserver was `example.com` with users like `@user:example.com`, you would start a DM with `@whatsappbot:example.com`.

4. Follow the bot prompts to sign in or connect your account.

### If You Installed `ntfy`

After the Helm install:

1. Open the hostname you configured for `ntfy`.
2. Confirm the service is reachable in your browser or client.
3. Point your Matrix client or UnifiedPush-compatible app at that `ntfy` server.

## 7. Making it your own!

This guide is intentionally simple. After your first install command, use the specific chart README for how to further configure.

You can find chart READMEs under [`charts/`](./charts/).

All charts are designed to be as minimal as possible, so they defer most configuration to the underlying component's native config.

Check out each component's associated repo / linked config examples to learn more.
