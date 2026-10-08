# Service reference

Where each service runs, how it's protected and what it stores. "Own" means the app has its own accounts.

## Household services (Kubernetes, `default` namespace)

| Service                             | Address                        | Protection                    | Notes                                                             |
| ----------------------------------- | ------------------------------ | ----------------------------- | ----------------------------------------------------------------- |
| Homepage                            | `f9.casa`                      | Authelia (`home`)             | Dashboard, built from route annotations                           |
| Authelia / LLDAP                    | `auth.f9.casa`                 | n/a                           | SSO and users                                                     |
| Home Assistant                      | `home.f9.casa`                 | Authelia                      | ESPHome, Zigbee, Matter, Mosquitto and Govee bridge sit alongside |
| Paperless-ngx                       | `docs.f9.casa`                 | Authelia                      | AI via llama.cpp, see [Paperless AI](paperless-ai.md)             |
| Immich                              | `photos.f9.casa`               | Own                           | ML on the Docker host                                             |
| Jellyfin                            | `jellyfin.f9.casa`             | Own                           | Config PVC on Ceph with no automated backup                       |
| Seerr                               | `requests.f9.casa`             | Own                           | Requests flow to Sonarr/Radarr                                    |
| Sonarr, Radarr, Prowlarr, Recyclarr | `<name>.f9.casa`               | Authelia (`media_management`) | Download automation                                               |
| qBittorrent, SABnzbd                | `torrents.`, `sabnzbd.f9.casa` | Authelia (`downloads`)        | Downloaders                                                       |
| Music Assistant                     | `music.f9.casa`                | Own                           |                                                                   |
| Homebox                             | `inventory.f9.casa`            | OIDC                          | Postgres                                                          |
| Open WebUI                          | `ai.f9.casa`                   | OIDC                          | Uses llama.cpp                                                    |
| SearXNG                             | `search.f9.casa`               | None                          |                                                                   |
| Zipline                             | `i.f9.casa`                    | OIDC                          |                                                                   |
| Bambuddy                            | `bambuddy.f9.casa`             | OIDC                          | 3D printer management                                             |
| IT-Tools                            | `it.f9.casa`                   | None                          |                                                                   |

## Admin and platform

| Service                                           | Address                                                  | Notes                                         |
| ------------------------------------------------- | -------------------------------------------------------- | --------------------------------------------- |
| Gatus                                             | `status.f9.casa`                                         | Status checks, feeds from route annotations   |
| Grafana / Prometheus / Alertmanager               | `grafana.`, `prometheus.`, `alertmanager.f9.casa`        | Admin only                                    |
| VictoriaLogs                                      | `victoria-logs.f9.casa`                                  | Logs                                          |
| Flux Operator                                     | `flux-operator.f9.casa`                                  | Deployment status                             |
| Kopia                                             | `kopiur-system/kopia`                                    | Browse backups                                |
| pgAdmin                                           | database namespace                                       | Postgres admin                                |
| TrueNAS, KVM, Doco-CD, Frigate, Garage, S3, Tdarr | via `network/envoy-gateway/config/externalservices.yaml` | External services proxied through the gateway |

## Docker host

See [Docker host](docker-host.md).

## Web projects (`webdev`)

Debt manager, games manager (and games DB), overlays and ws-broadcast are your own apps.
