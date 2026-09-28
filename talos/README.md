# Talos

Declarative [Talos Linux](https://www.talos.dev) machine configuration for the cluster, built from
composable multi-document patches. Nothing in this directory is applied automatically; configs are
rendered on demand and pushed to nodes with `talosctl`.

## Layout

| Path                                    | Purpose                                                                   |
| --------------------------------------- | ------------------------------------------------------------------------- |
| `cluster.yaml.j2`                       | Documents applied to every node                                           |
| `controlplane.yaml.j2`                  | Control-plane-only documents, including `machine.type`                    |
| `workers.yaml.j2`                       | Worker-only documents (does not exist yet; created with the first worker) |
| `nodes/<role>/<node>.yaml.j2`           | Per-node documents (hostname, zone)                                       |
| `nodes/<role>/<node>.schematic.yaml.j2` | Optional per-node schematic override                                      |
| `schematic.yaml.j2`                     | Shared [Image Factory](https://factory.talos.dev) schematic               |
| `patches/`                              | Ad-hoc patches for `talosctl patch`, not part of `render-config`          |
| `mod.just`                              | Recipes (`just talos ...`)                                                |

## Rendering

`just talos render-config <node>` builds the final machine config in three layers:

```
talosctl machineconfig patch <(cluster.yaml.j2) \
    -p @<(controlplane.yaml.j2 | workers.yaml.j2) \
    -p @<(nodes/<role>/<node>.yaml.j2)
```

Each layer passes through `minijinja-cli` (strict Jinja templating; the schematic ID arrives as a
`-D` define) and `op inject` (1Password secret resolution) before `talosctl` merges them. Later
patches strategically merge into earlier ones: documents with the same kind/name are deep-merged,
new documents are appended.

- **Directory placement is the single source of truth for a node's role.** The role patch is chosen
  by which `nodes/<role>/` directory contains the node file, and `machine.type` is set by the role
  patch, not the node file.
- **Secrets never live in this repo.** All sensitive values are `op://kubernetes/talos/...`
  references resolved at render time.

## Gotchas

- `machine.ca` and `cluster.ca` merge as a cert+key **unit**: a patch supplying only `key` blanks
  `crt`. This is why `controlplane.yaml.j2` repeats the `crt` references alongside the keys.
- The kubelet is configured in the legacy `machine.kubelet` block (in `cluster.yaml.j2`) because
  `extraMounts` (openebs) and `disableManifestsDirectory` have no `KubeletConfig` equivalent, and
  Talos rejects configs that use both. Everything else uses the new multi-document kinds.
- Talos validates that a setting is not defined in both the legacy `v1alpha1` document and a new
  document (e.g. `allowSchedulingOnControlPlanes`, `cluster.network`). Check with
  `talosctl validate --mode metal -c <rendered.yaml>`.

## Common tasks

```sh
just talos render-config <node>        # render a node's full machine config to stdout
just talos apply-node <node>           # render and apply (talosctl apply-config)
just talos upgrade-node <node>         # upgrade Talos using the node's schematic image
just talos upgrade-k8s <version>       # upgrade Kubernetes across the cluster
just talos download-image <version>    # fetch a metal ISO from the Image Factory
```

Before applying a refactor, confirm
`just talos render-config <node> | talosctl -n <node> apply-config -f /dev/stdin --dry-run`
reports the changes you expect on every node.
