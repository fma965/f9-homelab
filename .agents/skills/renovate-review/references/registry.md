# Reading a registry with crane

`crane` is a mise tool in this repository (`.mise/config.toml`). It reads public registries anonymously, so for a
container image or an OCI chart prefer it to hand-written `curl` calls to registry APIs. If it is not installed,
say that evidence was read another way, or is **unverified**; do not describe a registry check you did not run.

Run it through mise so the pinned version is used: `mise exec crane -- crane <command>`.

## Container images

- `crane ls <registry>/<repo>` lists tags. `sha256-…` tags are signatures and attestations, not versions.
- `crane digest <image>:<tag>` resolves a tag to its digest. Compare it with the `@sha256:` in the manifest or in the
  Renovate PR: a different digest for the same tag is a rebuild.
- `crane manifest <image>:<tag>` shows which platforms a multi-platform image has. All nodes are `linux/amd64`
  (Talos on Dell OptiPlex machines), so a new tag without `linux/amd64` is a finding, not a detail.
- `crane config --platform linux/amd64 <image>@<digest>` is the image's own record of how it was built. Read:
    - `created`: when it was built.
    - `config.Labels["org.opencontainers.image.source"]`: the upstream project (the place to read release notes).
    - `config.Labels["org.opencontainers.image.revision"]`: the commit it was built from. For
      `ghcr.io/home-operations/*` images this is a `home-operations/containers` commit, not the application's;
      its diff explains why a digest-only update was rebuilt.
    - `config.Labels["org.opencontainers.image.version"]`: the version, to compare with the release being reviewed.
      Use this on the **pinned digest**, not only the tag: it checks that the digest in the manifest really is the
      release the PR claims.

## OCI charts (an app's `ocirepository.yaml`)

`crane config <registry-path>:<version>` prints the chart's `Chart.yaml` as JSON: `version`, `appVersion` and
`sources`. Run it at the old and the new tag; a changed `appVersion` means the application's release notes need
reading too, not only the chart's. (`appVersion` is not always set; app-template leaves it empty.)

## What to report

State the digest or tag you resolved and the labels you read. A label that is missing is not evidence either way.
