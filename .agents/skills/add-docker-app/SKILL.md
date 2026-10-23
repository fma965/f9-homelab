---
name: add-docker-app
description: Use when deploying or changing a stack on the NAS Docker host — Compose stacks under docker/, Doco-CD deployments, "deploy X to the NAS", secrets or reverse-proxy wiring for a Compose app
---

# Add an App to the NAS Docker Host

Stacks live in `docker/<group>/<app>/compose.yaml` and are deployed GitOps-style by [Doco-CD](https://github.com/kimdre/doco-cd) from the entries in `.doco-cd.yaml` at the repository root. Doco-CD runs on the NAS (TrueNAS, `nas.main.internal`), follows `main`, polls on a short interval and is also triggered by webhook. **Removing or renaming a stack directory removes the running stack.** Mirror an existing stack rather than inventing structure:

| Group           | Reference stacks                                                      |
| --------------- | --------------------------------------------------------------------- |
| `ai`            | `whisper` (published ports, bind-mounted data), `llamacpp` (a secret) |
| `management`    | `webtop` (web UI, GPU device, config bind mount)                      |
| `media`         | `tdarr`                                                               |
| `observability` | `node-exporter`, `smartctl-exporter`, `liquidctl-exporter`            |
| `security`      | `frigate` (config directory, README)                                  |
| `system`        | `cups`, `scanner` (locally built images)                              |
| `backup`        | `garage`                                                              |

## Steps

1. **Directory**: `docker/<group>/<app>/compose.yaml`, in an existing group where it fits (`ls docker/`). A new group is fine if nothing matches.

2. **Compose file**, following the existing stacks:
    - `services.<name>` with `container_name` and `restart: unless-stopped`.
    - A registry-qualified image **pinned by digest** (`image: repo/name:tag@sha256:...`); Renovate keeps both current. **Never write a tag or digest from memory**: look up the upstream project's current release and the image digest first.
    - A `TZ=Europe/London` and `PUID`/`PGID` environment where the image supports them, or `user:`.
    - Persistent data: bind mounts under `/mnt/<pool>/appdata/<app>/...` (see `webtop`, `whisper`). Config files shipped in the repository go in `config/` or `resources/` next to the Compose file and are mounted read-only.
    - A locally built image must use `build:` per service, not a shared `image:` name: Doco-CD pulls images before deploying, so a shared name makes the deploy fail (see `cups`, `scanner`).

3. **Register the stack** in `.doco-cd.yaml` with the same block every stack has:

    ```yaml
    ---
    name: <app>
    working_dir: docker/<group>/<app>
    reference: refs/heads/main
    webhook_filter: "^refs/heads/main$"
    ```

4. **Secrets**: add `VAR_NAME: op://kubernetes/<item>/<field>` under an `external_secrets:` key in that stack's `.doco-cd.yaml` block, and reference it as `${VAR_NAME}` in the Compose file. Use the item's **real field names** (ask the user; never guess). A `${VAR}` that is not registered silently resolves empty.

5. **Expose it** (only if it serves HTTP). Stacks on the NAS are reached through the cluster's Envoy gateway, not directly:
    - Add a folder for the site under `kubernetes/apps/network/envoy-gateway/config/<site>/` (list it in that folder's `kustomization.yaml`), copying an existing one (for example `tdarr`): `backend.yaml` with a `Service` and an `EndpointSlice` with `addressType: FQDN` and the address `nas.main.internal`, `route.yaml` with an `HTTPRoute` with hostname `<app>.f9.casa`, and `oidc.yaml` with a Pocket ID `PocketIDOIDCClient` and `SecurityPolicy`. See the README there. Admin tools use `envoy-internal`; only use `envoy-external` when it must be public.
    - A port the cluster must reach has to be allowed by the UniFi firewall for cluster-to-NAS traffic, and web UIs published on the NAS may be limited to the cluster nodes on the host. Those rules are documented in the private repository; ask the owner or check there before publishing a new port.
    - Only publish `ports:` for what must be reachable. Do not publish web UIs to the whole LAN by accident.
    - Add a Gatus endpoint and Homepage tile the way the neighbouring entries do.

6. **Verify**: `docker compose -f docker/<group>/<app>/compose.yaml config --quiet` (unset `${VAR}` warnings are expected). Show the user the files before committing. Commit style: `feat(<app>): deploy to the NAS`. After merge Doco-CD deploys within a few minutes; check its container logs on the NAS (`docker logs doco-cd`) and the stack's health. Do not run anything on the NAS unless the user asks. A new or changed stack is a major change: also update the private technical docs (docker host page and inventory, the firewall or exposure notes if a port changed) and the risk-register change log, as `AGENTS.md` requires.

## Common mistakes

- **Inventing an image tag or digest**: a made-up reference deploys nothing or the wrong thing.
- **A secret in Compose but not in `.doco-cd.yaml`**: the variable silently resolves empty.
- **Forgetting the `.doco-cd.yaml` block**: the stack is never deployed.
- **A shared `image:` name on a locally built image**: Doco-CD pulls it and fails. Use `build:`.
- **Renaming or renumbering a stack directory casually**: Doco-CD tears the old stack down, losing anonymous volumes. Move data deliberately.
- **Publishing a port without the firewall and gateway wiring**: the port is open on the host but the cluster cannot reach it, or the whole LAN can.
- **Putting secrets, internal IPs or firewall details in the repository**: it is public.
