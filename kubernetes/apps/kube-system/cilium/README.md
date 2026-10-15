# Cilium

## Unifi (FRR) BGP

Enable SSH, SSH in to Unifi Gateway

```sh
sed -i 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
vi /etc/frr/frr.conf
```

Replace frr.conf with below

```sh
router bgp 64521
  bgp router-id 10.10.100.254
  no bgp ebgp-requires-policy

  neighbor k8s peer-group
  neighbor k8s remote-as 64520

  neighbor 10.10.100.1 peer-group k8s
  neighbor 10.10.100.2 peer-group k8s
  neighbor 10.10.100.3 peer-group k8s
  address-family ipv4 unicast
    redistribute connected
    neighbor k8s next-hop-self
    neighbor k8s soft-reconfiguration inbound
  exit-address-family
exit
```

```sh
systemctl enable frr.service && service frr start
```

10.10.100.254 = Gateway IP

10.10.100.x = Kubernetes Nodes

k8s = Group Name

## Useful commands

```sh
vtysh -c 'show ip bgp'
vtysh -c 'show ip route bgp'
ip route show
```

#### Cilium CLI

```sh
cilium bgp routes
cilium bgp peers
```

## Egress profiles

Shared egress rules are `CiliumClusterwideNetworkPolicy` objects selected by a pod label (after deedee-ops/home-ops). A pod opts in with `egress.cilium.io/<profile>: "true"` instead of repeating the rule in its own `networkpolicy.yaml`. Every profile has `enableDefaultDeny` off, so it only **adds** an allow: a pod is limited by its own policy (or a per-namespace deny-all) and the profiles it carries are added on top. Where the reply to the pod's own Service call would be dropped by its ingress policy, the profile also allows the reply in. DNS is cluster-wide (`allow-dns`), not a label.

| Profile            | Allows                                                                        | Defined in                                           |
| ------------------ | ----------------------------------------------------------------------------- | ---------------------------------------------------- |
| `kube-apiserver`   | the API server, 6443 (`host`, `kube-apiserver`, `remote-node`), and its reply | `app/egress-profiles.yaml`                           |
| `nas`              | the NAS `10.10.10.3`, any port                                                | same                                                 |
| `unifi`            | the UniFi controller `10.10.100.254:443`                                      | same                                                 |
| `internet`         | the public web, 80 and 443 (private ranges excluded)                          | same                                                 |
| `internet-all`     | the public internet on any port (private ranges excluded)                     | same                                                 |
| `gateway-external` | the external gateway, 10443, and its reply                                    | same                                                 |
| `smtp-relay`       | the SMTP relay, 25, and its reply                                             | `network/smtp-relay/app/networkpolicy.yaml`          |
| `postgres`         | the shared Postgres, 5432, and its reply                                      | `database/cloudnative-pg/cluster/networkpolicy.yaml` |
| `dragonfly`        | the shared Dragonfly, 6379, and its reply                                     | `database/dragonfly/cluster/networkpolicy.yaml`      |

Set the label in the app's HelmRelease: `defaultPodOptions.labels` for bjw-s app-template apps, the chart's own pod-label value (`podLabels` and the like) for others. After labelling, remove the matching stanza from the app's own policy (and its reply rule on the ingress side) and check Hubble for `Policy denied`. A pod whose own policy loses its last egress stanza would stop being limited, so keep `egress: - {}` (deny all) in it or rely on a per-namespace deny-all.
