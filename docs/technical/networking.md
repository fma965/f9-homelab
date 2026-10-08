# Networking & DNS

## Gateways

Envoy Gateway provides two gateways in the `network` namespace:

| Gateway          | DNS                                  | Used for                                                       |
| ---------------- | ------------------------------------ | -------------------------------------------------------------- |
| `envoy-external` | Public records in Cloudflare         | Anything reachable from outside, through the Cloudflare Tunnel |
| `envoy-internal` | Private records on the UniFi gateway | Home-network-only services                                     |

A route chooses its gateway in `parentRefs`. ExternalDNS watches the routes and creates the records automatically (one instance for Cloudflare, one for UniFi). You normally never edit DNS by hand.

!!! warning "Public does not mean unauthenticated"
Most apps on `envoy-external` are protected by Authelia (`ext-auth` component) or by their own OIDC login. A route with neither is open to the internet. Check before adding one.

## Cilium

Cilium provides the CNI and announces LoadBalancer IPs to the UniFi gateway over BGP. See `kubernetes/apps/kube-system/cilium/README.md` in the repo. Multus attaches pods to additional VLANs when an app needs it.

## TLS

cert-manager issues certificates (`network/certificates`). The Cloudflare Tunnel (`network/cloudflare-tunnel`) carries external traffic into the cluster.

## Addresses to remember

| Name                | Purpose                                                |
| ------------------- | ------------------------------------------------------ |
| `nas.main.internal` | TrueNAS (NFS, Docker host, llama.cpp :8080, CUPS :631) |
| `auth.f9.casa`      | Authelia                                               |
| `f9.casa`           | Homepage                                               |
