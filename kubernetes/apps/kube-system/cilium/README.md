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

## OpenWRT (FRR) BGP (Old)

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
 /etc/init.d/frr enable && /etc/init.d/frr restart
```

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