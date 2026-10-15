# egress

Opt an app in to a shared Cilium egress profile by labelling its pods, instead of repeating the rule in its own `networkpolicy.yaml`. After deedee-ops/home-ops (`kubernetes/apps/kube-system/cilium/globalpolicy.yaml`).

The profiles are `CiliumClusterwideNetworkPolicy` objects selecting `egress.cilium.io/<profile>: "true"`, each with `enableDefaultDeny` off, so a profile only **adds** an allow. A pod is limited by its own policy (or a per-namespace deny-all); the profiles it carries are added on top. Where the reply to the pod's own Service call would be dropped by its ingress policy, the profile also allows the reply in.

| Profile            | Allows                                                                       | Defined in                                           |
| ------------------ | ---------------------------------------------------------------------------- | ---------------------------------------------------- |
| `kube-apiserver`   | the API server, 6443 (`host`, `kube-apiserver`, `remote-node`) and its reply | `kube-system/cilium/app/egress-profiles.yaml`        |
| `nas`              | the NAS `10.10.10.3`, any port                                               | same                                                 |
| `unifi`            | the UniFi controller `10.10.100.254:443`                                     | same                                                 |
| `internet`         | the public web, 80 and 443 (private ranges excluded)                         | same                                                 |
| `internet-all`     | the public internet on any port (private ranges excluded)                    | same                                                 |
| `gateway-external` | the external gateway, 10443, and its reply                                   | same                                                 |
| `smtp-relay`       | the SMTP relay, 25, and its reply                                            | `network/smtp-relay/app/networkpolicy.yaml`          |
| `postgres`         | the shared Postgres, 5432, and its reply                                     | `database/cloudnative-pg/cluster/networkpolicy.yaml` |
| `dragonfly`        | the shared Dragonfly, 6379, and its reply                                    | `database/dragonfly/cluster/networkpolicy.yaml`      |

DNS is cluster-wide, not a label (`allow-dns` in `kube-system/cilium`).

## Using it

**bjw-s app-template apps:** add the components to the app's Flux Kustomization (`ks.yaml`), listed alphabetically with the other components:

```yaml
components:
    - ../../../../components/egress/kube-apiserver
    - ../../../../components/egress/smtp-relay
```

Each one adds the label under `spec.values.defaultPodOptions.labels` of the app's HelmRelease, which rolls the pods once.

**Other charts** do not read `defaultPodOptions`: set the chart's own pod-label value in the HelmRelease (`podLabels` for cert-manager and External Secrets, `labels` on a custom resource, and so on). Check the chart.

**After labelling**, remove the matching stanza from the app's own policy (and its reply rule from the ingress side), and check Hubble for `Policy denied`. A pod whose own policy has no egress left would stop being limited, so keep `egress: - {}` (deny all) in it or rely on a per-namespace deny-all.
