# F9 Homelab: technical documentation

These pages are for the person who runs the house servers. Housemate how-tos are in the [guides](https://help.f9.casa/).

The source of truth is the Git repository, [`fma965/f9-homelab`](https://github.com/fma965/f9-homelab). These pages explain how it fits together and how to operate it. The repository `README.md` has the high-level overview, and this site goes into operations.

## At a glance

| Layer              | What runs it                                                   | Where it's defined                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------- |
| Kubernetes cluster | Talos Linux, 3 control-plane nodes that also run workloads     | `talos/`, `bootstrap/`                      |
| Cluster apps       | Flux (GitOps), Helm via the `app-template` chart               | `kubernetes/apps/<namespace>/<app>/`        |
| Docker host        | TrueNAS server, Compose stacks deployed by Doco-CD             | `docker/`, `.doco-cd.yaml`                  |
| Secrets            | 1Password, via External Secrets (cluster) and Doco-CD (Docker) | `externalsecret.yaml`, `external_secrets:`  |
| Sign-in            | Authelia with LLDAP users and groups                           | `kubernetes/apps/default/authelia`, `lldap` |
| Updates            | Renovate opens PRs, you merge                                  | `.renovaterc.json5`                         |

## Ground rules

- **Everything goes through Git.** Merge a PR and Flux or Doco-CD applies it. Avoid editing live objects, because Flux will revert them (`prune: true`).
- **No secrets in Git.** Use 1Password items and `op://` references.
- **Match the neighbours.** New apps copy the structure of an existing app. See [Adding an app](adding-an-app.md).

## Where to start

- [Architecture](architecture.md) for the big picture
- [Runbook](runbook.md) for commands and fixes
- [Service reference](service-reference.md) for what each app uses
