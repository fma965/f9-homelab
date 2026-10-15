# PR review conventions

General review procedure for pull requests in this repository. It supplements `AGENTS.md`, which is the authoritative source of project conventions; follow its namespace, image-pinning, upstream-evidence and task-guidance rules. Do not flag explicitly intentional patterns as concerns or "for awareness" notes.

There is no automated AI reviewer in this repository. This file is for an agent asked to review a pull request interactively (read-only unless told otherwise).

## Gathering the change

- Read the PR and the diff with `gh pr view <number>` and `gh pr diff <number>`. Identify every file, not only the headline change.
- Get the **rendered** impact. A one-line values or chart change can fan out across many resources, and a harmless-looking diff can rename a selector or a resource.
    - The Konflate workflow comments a rendered summary on each PR; the same data is at `https://konflate.f9.casa/api/prs/<number>/summary` (send `Accept: text/markdown`).
    - Locally: `flate diff all --path ./kubernetes/flux/cluster --base origin/main` and `flate test all --path ./kubernetes/flux/cluster`.
    - If neither is available, say the rendered impact is **unverified**; do not call the change "unchanged" or "safe".
- Do not claim to have run a command or fetched a result that you did not.

## What to check

- **Blast radius:** which Kustomizations, HelmReleases, namespaces and consumers are affected. Search the repository for the actual consumers of anything renamed or removed (selectors, ServiceMonitors, alerts, NetworkPolicies, HTTPRoutes, PDBs, `dependsOn`, service DNS names).
- **Data and availability:** persistent volumes, kopiur backups, CloudNativePG, NFS mounts, `prune`/`suspend`, resource renames, immutable fields. Treat these as high risk (see `AGENTS.md`).
- **Exposure:** a route moved to `envoy-external`, a new public route without Authelia or an API-key policy, a new `LoadBalancer`, a relaxed `securityContext`, new capabilities or a namespace Pod Security change.
- **Network policy:** for a new or changed `CiliumNetworkPolicy`, check the reply paths through Services (`kube-dns`, databases, other apps), the gateway pods on the container port, and Multus or hostNetwork pods that Cilium does not cover. Hubble drop checks belong in the post-merge steps.
- **Secrets:** nothing in plaintext, 1Password field names that really exist, `op://` references only where the mechanism allows them.
- **Docs and the register:** a change that alters exposure or policy should mention the matching documentation or risk-register update (those live in the private repository).
- **Conventions:** the ordering and scaffolding in `.agents/instructions/sorting.instructions.md` and the add-app skill. A documented repository convention is not a finding.

## Findings

- A finding names the changed line, the affected consumer or path, the concrete failure mode, and the evidence (rendered diff, upstream notes, a search result). Do not invent a blocker where no consumer in this repository is affected; note it briefly instead.
- Separate verified impact from unavailable evidence. Use **Unknown / needs verification** rather than asserting a failure or a pass.

## Compact reviews

For Renovate digest-only container image updates where the repository and tag are unchanged and the diff only changes `@sha256:` values, keep the review short: a recommendation, the changed files, and any meaningful caveat. Skip empty sections.

Renovate pull requests also follow `.agents/skills/renovate-review/SKILL.md`.
