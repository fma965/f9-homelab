---
name: renovate-review
description: Review Renovate dependency updates in this Flux/GitOps homelab repository, including Helm OCI charts, container tags/digests, Talos/Kubernetes, GitHub Actions, mise tools and Docker Compose. Investigate rendered impact, upstream changes and actual repository dependencies before recommending a merge.
---

# Review a Renovate PR in f9-homelab

Determine **what changes on deployment and whether this repository relies on the old behavior**. Flux can reconcile `kubernetes/` changes soon after merge and Doco-CD redeploys `docker/` stacks from `main`. This skill supplements `.agents/instructions/pr-review.instructions.md`; `AGENTS.md` remains authoritative. There is no automated reviewer: use it when asked to review a Renovate pull request interactively.

## 1. Establish the update and deployment footprint

- Identify every dependency and old/new version, digest or chart tag. Renovate groups may contain several independent upgrades (Talos, Kubernetes, Rook-Ceph, Flux Operator, Intel device plugins and mise tools are grouped by `.renovaterc.json5`). Applications live under `kubernetes/apps/<namespace>/<app>/`; shared components under `kubernetes/components/`. Trace all consumers of a changed component before judging impact.
- Distinguish **OCIRepository chart tag** updates, **container image/digest** updates (Kubernetes HelmReleases and `docker/` Compose files), **HelmRelease values** changes, **Talos/Kubernetes** upgrades, **GitHub Actions**, **mise tools** (`.mise/config.toml`) and Renovate preset changes. An OCI chart is pinned by `ref.tag`, not a container-style `@sha256:` digest; do not flag that as missing image pinning.
- The actual rendered resources, not the one-line git diff, determine most Helm/Flux compatibility risks.
- Some updates auto-merge (`.renovaterc.json5`): digests of `home-operations` and `fma965` images, GitHub Actions minor/patch/digest after a release-age delay, Grafana dashboards, Renovate presets and a weekly `kube-prometheus-stack` bump. A reviewer asked about one of these still checks the same things, but keeps the answer short.

## 2. Inspect the rendered change (when applicable)

Prefer evidence that already exists:

- The **Konflate** comment on the pull request, or its API: `https://konflate.f9.casa/api/prs/<number>/summary` (send `Accept: text/markdown`). It lists affected resources, additions and removals, image changes and render errors. If Konflate did not render the PR, say **unverified**, never "unchanged" or "safe".
- Locally: `flate diff all --path ./kubernetes/flux/cluster --base origin/main` and `flate test all --path ./kubernetes/flux/cluster`. Do not claim to have run them unless you did; a SKILL.md grants no shell or cluster access.

Pay special attention to resource names, label **values** as well as keys, selectors, ports, services, RBAC, storage classes, CRDs, probes, immutable fields and persistent-volume behavior. A render may omit CRDs and Secret data; their absence is not evidence of no change. One unrelated rendering failure is not proof that the upgraded chart fails.

For a digest-only container refresh with unchanged repository and tag, a rendered digest change plus consistent upstream metadata is usually enough: do not invent Kubernetes breaking changes.

## 3. Verify upstream changes

Begin with the PR's Release Notes, but inspect upstream when they are absent, truncated, a major or `0.x`-minor bump, a jump across several versions, or a chart or image with material runtime changes. **For Helm charts and images, `AGENTS.md` requires real upstream evidence through available read-only tools**, not just the Renovate description.

- **OCI chart:** `crane config <chart>:<version>` (`references/registry.md`) prints its `Chart.yaml` at the old and new tag, including `appVersion` and `sources`. Find its source in the app's `ocirepository.yaml`, follow the publisher's chart releases and templates and compare versions. For mirrored `ghcr.io/home-operations/charts-mirror/<chart>`, use the `home-operations/charts-mirror` metadata to find the real chart source. When the chart's `appVersion` changes, read the underlying application's release notes too. An `app-template` bump affects every app that uses it.
- **Container image:** resolve the upstream project from the image owner or the `org.opencontainers.image.source` label. When `crane` is available, read the **pinned digest's** config (`references/registry.md`): its `version` and `revision` labels show what it was built from, to compare with the release reviewed here, and its platform list must include `linux/amd64`. For `ghcr.io/home-operations/*`, also look at `home-operations/containers` build history for digest-only changes. Check revision, source and created metadata when available.
- **Talos / Kubernetes:** the Talos installer image tag and the kubelet image are in `talos/cluster.yaml.j2`, the control-plane component images (`kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, `kube-proxy`) are in `talos/controlplane.yaml.j2`, node overrides are under `talos/nodes/controlplane/`; the upgrade recipes are in `talos/mod.just`; the `talos` CLI version is in `.mise/config.toml` and must match. Verify the **specific Talos release supports the target Kubernetes version** against the published Sidero/Talos support matrix before concluding compatibility, and cite it. A patch bump alone is not proof.
- **Docker Compose images:** compare the upstream release for the stack's image, then read the stack under `docker/<group>/<app>/` for volumes, ports and secrets that the new version might change.
- **CI action / mise tool / Renovate preset:** read the upstream release or compare, then check this repository's `.github/workflows/`, `.mise/config.toml`, `.lefthook.toml` or `.renovaterc.json5` for the inputs or options it uses.
- Follow referenced upstream issues and PRs when a changelog only says "See #123". Do not infer changed defaults or a migration from a release-note headline.

Check raised minimum versions, removed APIs or fields, changed auth, storage or network defaults, one-way migrations, and security advisories relevant to the deployed configuration. If an upstream source cannot be verified, label the evidence gap honestly.

## 4. Search for repository-specific exposure

Search the **actual consumers** of anything removed or renamed, not just whether the new value is set explicitly:

- Under `kubernetes/`, inspect selectors and labels in Prometheus `ServiceMonitor`s, alerts and dashboards, **`CiliumNetworkPolicy`s** (they select pods by label and allow specific container ports, so a renamed label or changed port breaks the app), HTTPRoutes and gateway `SecurityPolicy`s (`ext-auth`, API keys), PDBs, Flux `dependsOn`/`healthChecks`, `values`/`valuesFrom`/`postRenderers`, service DNS names and CRD instances.
- Trace application Kustomizations and shared-component usage from `kubernetes/flux/cluster/`. Cilium, Envoy Gateway, External Secrets, Rook-Ceph, CloudNativePG, Dragonfly and kopiur updates merit close inspection for compatibility and data safety where affected.
- For `app-template` or other shared chart changes, look for several affected HelmReleases. Chart defaults can change even when the values in this repository do not.
- In `docker/` and `talos/`, search the corresponding consumers rather than assuming everything is a Kubernetes release.

A documented repository convention is **not** a finding. Apply the namespace and image-pinning policies in `AGENTS.md`; do not substitute generic linting heuristics for this repository's deployment conventions.

## 5. Verdict and evidence

- Respect `AGENTS.md`. A breaking change with **no affected consumer in this repository** is a brief observation, not an invented blocker.
- A finding identifies the **changed line**, the **affected consumer or path**, the concrete failure mode, and the supporting rendered or upstream evidence. Confirm a replacement name or value from upstream manifests rather than guessing a fix.
- Escalate documented risks: unsupported Talos/Kubernetes pairings, CRD or schema incompatibilities, data-loss or storage mutations, new security relaxations, unexpected suspend or prune, and selector or resource renames that break live consumers. For uncertain evidence, report **Unknown / needs verification** instead of asserting a failure or a successful test.
- For an ordinary same-tag digest refresh, keep the review **compact**: recommendation, what changed, and any meaningful caveat. Skip empty sections.
- Do not fabricate Konflate results, upstream comparisons, tool calls or post-merge checks.
