# YAML ordering conventions

These describe how this repository's manifests are already ordered. They are not a request to re-sort existing files: **match the file you are editing and its neighbours, and avoid unrelated sorting churn.** Apply them to new files and to new keys.

## All Kubernetes manifests

- Top-level fields: `apiVersion`, `kind`, `metadata`, `spec`.
- `metadata`: `name`, `namespace` (usually omitted, see `AGENTS.md`), `annotations`, `labels`.
- Do not sort or reformat YAML embedded in string fields (for example `configMap` data, Gatus or Homepage config, Cilium comments).

## Flux Kustomizations (`ks.yaml`)

`spec` keys are alphabetical, which is what almost every `ks.yaml` already does:

`components`, `dependsOn`, `interval`, `path`, `postBuild`, `prune`, `sourceRef`, `targetNamespace`, `wait`

(`healthChecks`, `healthCheckExprs` and `timeout` slot in alphabetically when needed.) Entries under `components` and `dependsOn` are listed alphabetically.

## App `kustomization.yaml`

`resources` lists `./externalsecret.yaml`, then the HelmRelease and OCIRepository files, then `./networkpolicy.yaml` when present. Existing files vary (some put `./helmrelease.yaml` before `./ocirepository.yaml`); keep what the file has. In a namespace's `kustomization.yaml`, app entries (`./<app>/ks.yaml`) are alphabetical; commented-out entries stay in place.

## app-template HelmReleases

Applies only to HelmReleases whose `ocirepository.yaml` has `url: oci://ghcr.io/bjw-s-labs/helm/app-template`. For any other chart, do not apply these rules.

- `spec`: `interval`, `chartRef`, `values`. Both `interval`/`chartRef` orders exist in the repository; keep whichever order the file already uses.
- `spec.values`: in the order the chart documents and most apps use: `controllers`, `defaultPodOptions`, `service`, `route`, `persistence` (some files put `defaultPodOptions` first). Any other top-level values follow; do not alphabetize existing files.
- `controllers.<name>`: `replicas`, `strategy`, `annotations`, `labels`, `pod`, `initContainers`, `containers` (only the keys that are present; `initContainers` then `containers` last).
- `containers.<name>` and `initContainers.<name>`: `image`, `command`/`args`, `env`, `envFrom`, `probes`, `securityContext`, `resources`.
- `resources`: `requests` then `limits`.
- `service.<name>`: `controller`, `type`, `ports` (only those present).
- `route.<name>`: `annotations`, `hostnames`, `parentRefs`, `rules`.
- `persistence.<name>`: `type` (or `existingClaim`), then source fields (`server`, `path`, `name`), then `globalMounts` or `advancedMounts` last.
- The order of siblings such as `persistence.config` and `persistence.data` does not matter; only the keys inside each item.
- Whenever an `enabled` field is present, it comes first in its section.

## CiliumNetworkPolicy

`apiVersion`, `kind`, `metadata`, `spec`; in `spec`: `endpointSelector`, then `ingress` (rules in this order: the gateway or direct callers first, then LoadBalancer or entity rules, then the reply rules last), each rule as `fromEndpoints` or `fromEntities`, then `toPorts`. Put the comment explaining a rule directly above it.

## Quick check before sorting a HelmRelease

1. Confirm the chart is app-template (sidecar `ocirepository.yaml`).
2. Look at two neighbouring apps and follow them.
3. Change only the lines you are editing.
