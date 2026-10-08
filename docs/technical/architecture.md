# Architecture

```text
                         Internet
                            |
                    Cloudflare (DNS + Tunnel)
                            |
        +-------------------+-------------------+
        |   Talos Kubernetes cluster (3 nodes)  |
        |   Cilium (BGP to UniFi) + Envoy GW    |
        |   Flux -> apps in namespaces          |
        |   Rook Ceph (block storage)           |
        +-------------------+-------------------+
                            | NFS / HTTP
        +-------------------+-------------------+
        |   TrueNAS (nas.main.internal)         |
        |   NFS/SMB shares, backups             |
        |   Docker: llama.cpp, Frigate, CUPS,   |
        |   scanner button, Garage, PBS ...     |
        +---------------------------------------+
```

## Why two places?

- **Kubernetes** hosts almost everything: stateless apps, apps with databases, auth, monitoring.
- **The Docker host** runs things that need dedicated hardware or must keep working when the cluster is down: GPU workloads (llama.cpp, Whisper, Immich ML), USB devices (printer, scanner), Frigate, and backup targets.

## How a change reaches production

```text
PR merged to main
   |-- kubernetes/**  -> Flux notices (GitRepository) -> HelmRelease/Kustomization applied
   `-- docker/**      -> Doco-CD polls (~3 min) -> docker compose up for the stack
```

Renovate keeps container images, Helm charts and GitHub Actions current by opening PRs. Digest-only bumps for trusted images auto-merge.

## Namespaces

| Namespace       | Purpose                                                                            |
| --------------- | ---------------------------------------------------------------------------------- |
| `default`       | Household apps (Home Assistant, Immich, Jellyfin, Paperless, Authelia, LLDAP, ...) |
| `network`       | Envoy Gateway, Cloudflare tunnel/DNS, UniFi DNS, certificates, SMTP relay          |
| `database`      | CloudNativePG (Postgres), Dragonfly (Redis-compatible), pgAdmin                    |
| `o11y`          | Prometheus stack, Grafana, Gatus, VictoriaLogs, exporters                          |
| `rook-ceph`     | Ceph storage                                                                       |
| `kube-system`   | Cilium, CoreDNS, Multus, Spegel, reloader, NFS CSI driver, descheduler             |
| `kopiur-system` | Backup controller (kopiur) and Kopia S3                                            |
| `flux-system`   | Flux and the Flux Operator                                                         |
| `webdev`        | Your own web projects (debt manager, games manager, overlays)                      |
| `mcp`           | MCP servers (Home Assistant, Grafana, TrueNAS, UniFi)                              |

See the repo README for the full component list.
