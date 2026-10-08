# Adding an app

Copy an existing app that is similar. `it-tools` (stateless), `homebox` (Postgres plus OIDC) and `paperless` (storage, forward auth) are good templates.

## Checklist (Kubernetes)

1. Create `kubernetes/apps/<ns>/<app>/` with `ks.yaml` and `app/`.
2. In `app/`, add `kustomization.yaml`, `helmrelease.yaml` and `ocirepository.yaml` (copy another app's, as they all use app-template).
3. Add `./<app>/ks.yaml` to the namespace's `kustomization.yaml` (alphabetical).
4. Decide on persistence:
    - Config on Ceph with backups: add `../../../../components/kopiur/backup` to the `ks.yaml` components (and `dependsOn` rook-ceph-cluster).
    - Bulk data: an NFS persistence entry to `nas.main.internal:/mnt/F9/...`.
    - Postgres: an `init-db` container using `postgres-init` plus an `ExternalSecret` (see Homebox).
5. Secrets: an `ExternalSecret` and a 1Password item with the same name.
6. Route: a `route:` block with `hostnames`, a `parentRef` to `envoy-external` (or `envoy-internal`), and Homepage/Gatus annotations.
7. Protection:
    - Add `ext-auth` to `ks.yaml`, **or** configure OIDC.
    - Add the hostname to the right Authelia rule.
8. Open a PR. Flux applies it after merge.

## Checklist (Docker)

1. Create `docker/<group>/<stack>/compose.yaml`.
2. Add an entry to `.doco-cd.yaml` (`name`, `working_dir`, `external_secrets` if needed).
3. For locally built images, use `build:` and **not** a shared `image:` name.
4. Merge. Doco-CD deploys within a few minutes.

## Then document it

- Add a row to [Service reference](service-reference.md).
- If housemates use it, add a page under `docs/guides/services/` and list it in `docs/mkdocs.guides.yml`. See [This docs site](docs-site.md).
