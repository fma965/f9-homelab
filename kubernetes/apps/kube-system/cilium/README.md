# Cilium

## OpenWRT (FRR) BGP

```sh
apk add frr frr-bgpd frr-watchfrr frr-zebra
nano /etc/frr/frr.conf`
```

```sh
router bgp 64521
  bgp router-id 10.0.10.254
  no bgp ebgp-requires-policy

  neighbor k8s peer-group
  neighbor k8s remote-as 64520

  neighbor 10.0.10.101 peer-group k8s ! Control plane node
  neighbor 10.0.10.102 peer-group k8s ! Control plane node
  neighbor 10.0.10.103 peer-group k8s ! Control plane node
  neighbor 10.0.10.111 peer-group k8s ! Worker node
  neighbor 10.0.10.112 peer-group k8s ! Worker node
  neighbor 10.0.10.113 peer-group k8s ! Worker node
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

10.0.10.254 = Router IP
10.0.10.1xx = Kubernetes Nodes
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