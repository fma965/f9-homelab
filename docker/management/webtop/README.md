# webtop

Debian XFCE desktop in the browser (`lscr.io/linuxserver/webtop`), reached through Envoy and Authelia at `https://remote.f9.casa`.

### Access (allow-list gate)

The desktop (`3000`), which has no login of its own, is not published directly. `webtop-gate` (nginx, `gate/nginx.conf`) publishes port `3000` and only accepts connections from the three Kubernetes nodes (`10.10.100.1-3`), where Envoy runs and which is the address every cluster pod appears to have. Everything else on the network (Main LAN, Media, ...) gets `403`. Reach it through `https://remote.f9.casa`, which adds Authelia.

This is an allow-list, not a login: anything running in the cluster can still reach the port directly, so the app should not be given more trust than it has. If a new in-cluster client needs it, it works already (it comes from a node address); if a client outside the cluster needs it, add its address to `gate/nginx.conf` deliberately. The published port is IPv4-only on purpose: Docker's IPv6 proxy hides the client address.

Port `3001` (HTTPS) is not published; nothing uses it.
