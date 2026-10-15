# Repository instructions

This file is the canonical, agent-independent source of repository policy. Essential rules live here directly; do not rely on agent-specific import syntax to load them.

## Repository map

- `kubernetes/apps/<namespace>/<app>/`: application Flux Kustomizations (`ks.yaml`), HelmReleases, chart sources, and configuration. Each namespace folder has a `namespace.yaml` and a `kustomization.yaml` listing its apps.
- `kubernetes/flux/cluster/`: Flux entry point (`cluster-apps`) and cluster-wide patches applied to every child Kustomization and HelmRelease.
- `kubernetes/components/`: reusable Kustomize components: `alerts`, `ext-auth` (Authelia in front of a route), `gpu`, `kopiur` (`backup`, `secret`) and `zeroscaler`.
- `talos/`: Talos templates (`cluster.yaml.j2`, `controlplane.yaml.j2`, `schematic.yaml.j2`), `nodes/` overrides and recipes (`mod.just`). `bootstrap/`: helmfile and kustomize bootstrap with recipes.
- `docker/<group>/<app>/`: Compose stacks for the NAS Docker host, deployed by Doco-CD from `.doco-cd.yaml`.
- `docs/guides/` and `docs/mkdocs.guides.yml`: the housemate guides (public), built and served by the `help` app. Technical documentation is **not** in this repository; it lives in a separate private repository.
- `.github/workflows/`: Konflate PR summary, image check, Renovate, tagging and label sync. `.renovaterc.json5`: Renovate configuration.
- `.mise/config.toml`: tool versions and environment (`KUBECONFIG`, `TALOSCONFIG`, `FLATE_PATH`). `.justfile` and `mod.just` files: operational commands. `.lefthook.toml`: git hooks (formatting).
- Git-ignored and local only: `kubeconfig`, `talosconfig`, `.private/`, `.claude/worktrees/`.

## Project conventions

- This repository manages live infrastructure through GitOps. Flux can reconcile changes under `kubernetes/` soon after merge, and Doco-CD redeploys `docker/` stacks from `main`. Consider rendered resources and deployment impact, not only the source diff.
- Kubernetes applications live under `kubernetes/apps/<namespace>/<app>/`. Follow neighbouring applications rather than assuming a layout from another home-ops repository.
- `metadata.namespace` is intentionally omitted on application HelmReleases and Flux Kustomizations. The namespace folder's `kustomization.yaml` sets the namespace of the Flux Kustomizations, and each application's Flux Kustomization sets `spec.targetNamespace` for its deployed resources. Do not add redundant namespaces or flag their absence without checking that chain. Namespace manifests use the literal name `_`, which the namespace kustomization renames.
- Cluster-wide defaults are patched onto every HelmRelease in `kubernetes/flux/cluster/ks.yaml` (CRD handling, rollback and remediation). Do not repeat them in individual HelmReleases.
- Application workloads use Flux HelmReleases with `spec.chartRef` pointing to a per-app `OCIRepository` in `ocirepository.yaml`, nearly all on the bjw-s `app-template` chart. Follow the add-app skill for scaffolding. Existing raw manifests and operator-managed resources are not automatically violations.
- Prefer immutable `@sha256:` digests for container images (Renovate maintains them). OCI Helm chart sources use `OCIRepository.spec.ref.tag`; do not apply the container-image digest convention to chart references. A small number of upstream chart and Talos images are unpinned by the owner's decision.
- Commit and pull request titles use Conventional Commits with a scope: `feat(<app>): ...`, `fix(<app>): ...`, `docs(guides): ...`, `chore(<scope>): ...`. Renovate uses `fix(container): update image ...` and similar.
- YAML starts with `---` and a `# yaml-language-server: $schema=...` comment when a schema exists. When editing YAML, read `.agents/instructions/sorting.instructions.md`, keep to the ordering the file and its neighbours already use, and avoid unrelated sorting churn. Do not reorder configuration embedded in string fields.
- For dependency reviews, verify upstream changes using available read-only release notes, changelogs, source comparisons, or image metadata. Helm chart and container-image reviews require upstream evidence, not only Renovate's description. Report unavailable evidence as unverified; never invent tool results or compatibility claims.
- Keep component-specific documentation alongside its configuration. Do not copy another home-ops repository's paths, architecture, or operational commands without checking this tree.

## Exposure, network and workload security

- Each app is reached through the Envoy gateways in the `network` namespace: `envoy-internal` (home network and VPN only) and `envoy-external` (public). Put admin and management tools on `envoy-internal`. Use `envoy-external` only for apps that must be reachable from the internet. Hostnames are `<app>.f9.casa`.
- A public route that has no login of its own gets Authelia through the `ext-auth` component (set `APP` in the Flux Kustomization). An app that does OIDC itself does not need it. Every public MCP server needs an API-key `SecurityPolicy` at the gateway, a read-only upstream token and a least-privilege service account.
- Network policy is being rolled out (risk M15). Apps get a `CiliumNetworkPolicy` (ingress, and egress for public or credential-holding pods) in `networkpolicy.yaml` next to their HelmRelease: allow the gateway pods on the container port, plus the specific callers. **A reply that returns through a Service is evaluated as new traffic to the pod and dropped**, so allow the pods the app calls through Services (`kube-dns`, Postgres, Dragonfly, LLDAP, ...), or for an app that calls many Services allow `fromEntities: cluster` on the ephemeral port range `32768`-`60999` only. Cilium does not see traffic on Multus interfaces (Home Assistant, Music Assistant, Bambuddy) or hostNetwork pods. **Egress:** once an `egress` section exists everything else is dropped, so allow `kube-dns` on 53 and **allow every in-cluster egress target back in under `ingress`** (the reply rule above applies to egress rules too). Internet hosts use `toFQDNs`, which needs `rules: dns: - matchPattern: "*"` on the DNS rule and **CoreDNS `autopath` left off** (it is off on purpose; do not re-add it or set per-pod `ndots`). Take hostnames from `cilium-dbg fqdn cache list` and Hubble, not guesses, and look for start-up dependencies on the internet before restricting. After a policy lands, check Hubble (`https://hubble.f9.casa`, or `hubble observe --verdict DROPPED`) for `Policy denied DROPPED`.
- Workloads run non-root with `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true` and `capabilities: drop: [ALL]` (add a `tmpfs`/`emptyDir` for `/tmp`). Most namespaces enforce Pod Security `baseline`; `kube-system`, `o11y` and `rook-ceph` are `privileged`. A pod that needs more must be placed deliberately.
- Add the `gatus.home-operations.com/endpoint` and `gethomepage.dev/*` annotations on routes that should appear on the status page and Homepage, as neighbouring apps do.

## Secrets and operational safety

- Never commit plaintext credentials, resolved secrets, kubeconfigs, or Talos client configuration (`kubeconfig` and `talosconfig` in the repository root are git-ignored; keep them that way). Kubernetes application secrets come from External Secrets backed by 1Password (`ClusterSecretStore` `onepassword-connect`); keep secret values out of inline Helm values.
- Talos templates (`talos/*.j2`) are rendered with `minijinja-cli` and resolved with `op inject`, so they contain `op://` references. Docker-host stacks take secrets from `.doco-cd.yaml` `external_secrets` (`op://kubernetes/<item>/<field>`). Follow those mechanisms rather than requiring Kubernetes External Secrets outside Kubernetes.
- Local template rendering can resolve real credentials. Do not include resolved output in logs, responses, or committed files.
- This repository is public. Do not put internal IP plans, firewall details, weaknesses or the home WAN address in it; technical documentation and the risk register live in the private repository. Comments may cite register IDs (for example `M15`).
- Treat persistent-volume changes, CloudNativePG (`postgres17` in `database`) bootstrap, recovery and backup settings, kopiur backup policies, NFS mounts from the NAS, resource renames, and Flux `prune`/`suspend` changes as potential data-loss or availability risks. Inspect affected consumers and rendered changes before recommending them. Do not replace recovery with `initdb` as a generic fix.
- Repository edits do not authorize live infrastructure changes. Do not apply, reconcile, upgrade, delete, reset, restart or reload anything on the cluster, the NAS or UniFi unless the user explicitly requests that operation. A server-side dry run (`kubectl apply --dry-run=server`) creates nothing and is fine when cluster access has been given.
- Do not rename or delete a `docker/` stack directory casually: Doco-CD removes stacks whose directory disappears.

## Validation

Use the repository's mise-managed tools and inspect `just --list` for available recipes. `lefthook` formats files on commit (the Markdown formatter skips `docs/`, whose MkDocs syntax it would mangle).

For Kubernetes manifest changes, inspect the rendered impact when tools and network access permit:

```sh
flate test all --path ./kubernetes/flux/cluster
flate diff all --path ./kubernetes/flux/cluster --base origin/main
```

These commands may fetch upstream sources. The Konflate workflow also posts a rendered summary on each pull request (`https://konflate.f9.casa/api/prs/<number>/summary`). Neither replaces checking CRDs, secrets, or runtime behavior omitted from rendered output. For documentation-only changes, targeted reference and whitespace checks are sufficient. Report which checks ran and any validation gaps; do not claim an unavailable render or test passed.

For Talos or Kubernetes upgrades, read `talos/cluster.yaml.j2` (installer and kubelet images), `talos/controlplane.yaml.j2` (control-plane images), the node overrides under `talos/nodes/` and the recipes in `talos/mod.just`. Verify the target Kubernetes version against the specific Talos release's published support matrix and cite it in reviews; an unchecked pairing is unverified, not implicitly compatible.

## Task guidance

Read the matching skill before performing these tasks:

- Add a Kubernetes application: `.agents/skills/add-app/SKILL.md`.
- Deploy or change a stack on the NAS Docker host: `.agents/skills/add-docker-app/SKILL.md`.
- Review a Renovate update: `.agents/skills/renovate-review/SKILL.md`.
- Review a pull request: also read `.agents/instructions/pr-review.instructions.md`. Renovate guidance supplements, rather than replaces, the general review procedure.

Detailed task guidance does not grant tool permissions or override repository policy. Markdown references are not automatic includes; load the applicable guidance explicitly.

## Instruction ownership

- Keep shared policy in this file, task workflows in `.agents/skills/`, and detailed conditional guidance in `.agents/instructions/`. Do not duplicate policy in task files.
- `CLAUDE.md` and `.claude/skills` are compatibility symlinks to the canonical instructions and skills. Keep agent-specific directories limited to adapters and configuration, not alternative copies of shared guidance.
- Keep personal model preferences, credentials, permissions, and MCP configuration in user-level configuration, not in this repository.
