# Cilium

## OpenWRT (FRR) BGP

```sh
apk add frr frr-bgpd frr-watchfrr frr-zebra
nano /etc/frr/frr.conf`
```

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
```

```sh
/etc/init.d/frr restart
/etc/init.d/frr enable
```

10.10.100.254 = Router IP
10.10.100.x = Kubernetes Nodes
k8s = Group Name

## Useful commands
#### Router

```sh
vtysh
show ip route bgp
```

```sh
ip route show
```

#### Cilium CLI
```sh
cilium bgp routes
cilium bgp peers
```