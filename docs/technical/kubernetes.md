# Kubernetes & Flux

## Layout

```text
kubernetes/
  apps/<namespace>/
    kustomization.yaml      # lists each app's ks.yaml
    <app>/
      ks.yaml               # Flux Kustomization for the app
      app/
        kustomization.yaml
        helmrelease.yaml    # bjw-s app-template values
        ocirepository.yaml  # chart source (app-template)
        externalsecret.yaml # secrets from 1Password (if needed)
  components/               # reusable Kustomize components
  flux/cluster/ks.yaml      # root Flux Kustomization
```

Flux walks `kubernetes/apps`, finds each namespace's `kustomization.yaml`, and applies every `ks.yaml` it lists.

## Components

Components are added in an app's `ks.yaml` under `spec.components`:

| Component       | Effect                                                                                                           |
| --------------- | ---------------------------------------------------------------------------------------------------------------- |
| `kopiur/backup` | Creates the PVC, snapshot policy/schedule and restore for `${APP}` (see [Storage & backups](storage-backups.md)) |
| `ext-auth`      | Puts the app behind Authelia with an Envoy `SecurityPolicy` (see [Authentication](authentication.md))            |
| `zeroscaler`    | Scales the app to zero when idle                                                                                 |
| `gpu`           | GPU scheduling                                                                                                   |
| `alerts`        | Alerting rules (applied at namespace level)                                                                      |

`postBuild.substitute.APP` feeds the `${APP}` variable that components use. Optional knobs include `KOPIUR_CAPACITY`, `KOPIUR_STORAGECLASS` and `KOPIUR_ACCESSMODES`.

## HelmRelease conventions

- Every app uses the bjw-s **app-template** chart through an `OCIRepository`.
- `reloader.stakater.com/auto: "true"` restarts pods when their ConfigMaps or Secrets change.
- Images are pinned by tag and digest, and Renovate bumps both.
- Routes are declared in the HelmRelease (`route:`) and attach to a Gateway (`envoy-external` or `envoy-internal`).
- Homepage and Gatus pick up their entries from `gethomepage.dev/*` and `gatus.home-operations.com/*` annotations on the route.

## Day-to-day commands

```sh
export KUBECONFIG=~/Projects/f9-homelab/kubeconfig
flux get ks -A                 # Kustomizations and their status
flux get hr -A                 # HelmReleases
flux reconcile ks <name> --with-source
kubectl -n default logs deploy/<app>
```

The repo wraps common tasks in `just` recipes (`just` lists them). Tool versions are pinned by `mise`.
