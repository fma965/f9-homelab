# External services behind the gateway

Things that are not pods but are published through the Envoy gateways: the NAS and the services that run on it. There is one folder per site, and each folder lists its files in its own `kustomization.yaml`:

| File           | What it holds                                                                                                                                                                                                                                           |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `backend.yaml` | Where the site really is: a `Service` plus an `EndpointSlice` (address `nas.main.internal`, an FQDN), or an Envoy `Backend` (TrueNAS, which needs TLS settings)                                                                                         |
| `route.yaml`   | The `HTTPRoute`: hostname, gateway (`envoy-internal` for admin tools) and the Homepage and Gatus annotations                                                                                                                                            |
| `oidc.yaml`    | The Pocket ID login for the route: a `SecurityPolicy` and a `PocketIDOIDCClient` (written out here because there is no Flux Kustomization per site, so the `oidc` component does not apply). Sites with their own authentication or a webhook have none |

| Folder    | Hostnames                                   | Notes                                                                                                                   |
| --------- | ------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `truenas` | `truenas.f9.casa`                           | The NAS web UI over TLS (self-signed certificate, HTTP/1.1 for its websocket)                                           |
| `webtop`  | `remote.f9.casa`                            | Browser desktop on the NAS. Public on purpose; the Pocket ID login is its only gate                                     |
| `nanokvm` | `kvm.f9.casa`                               | Out-of-band console for the server (admin)                                                                              |
| `doco-cd` | `doco-cd.f9.casa`                           | Webhook for Doco-CD; no login (a webhook secret protects it)                                                            |
| `garage`  | `garage.f9.casa`, `s3.f9.casa` and wildcard | The web UI (login) and the S3 API (signed requests, no login)                                                           |
| `tdarr`   | `tdarr.f9.casa`                             | Media transcoding                                                                                                       |
| `frigate` | `frigate.f9.casa`, `cctv.f9.casa`           | One route and login each: `frigate` is the admin role, `cctv` the viewer role; the route sets Frigate's `Remote-Groups` |

The Flux Kustomization is `envoy-gateway-config` and depends on `pocket-id`. To add a site, copy a folder with the same shape (for example `tdarr`), change the names, hostname and address, and list the folder in `kustomization.yaml`. The login rules for a gated route are in [the `oidc` component](../../../../components/oidc/README.md).
