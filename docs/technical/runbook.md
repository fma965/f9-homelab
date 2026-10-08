# Runbook

## Access

```sh
export KUBECONFIG=~/Projects/f9-homelab/kubeconfig
export TALOSCONFIG=~/Projects/f9-homelab/talosconfig
ssh scott@nas.main.internal          # then: sudo -n docker ...
```

## Is the cluster healthy?

```sh
flux get ks -A | grep -v True        # anything not Ready
flux get hr -A | grep -v True
kubectl get pods -A | grep -vE 'Running|Completed'
talosctl health
```

Gatus (`status.f9.casa`) and Alertmanager give the same view from outside.

## An app is stuck or broken

1. `kubectl -n <ns> describe pod <pod>` and `kubectl -n <ns> logs <pod>`.
2. `flux reconcile hr <app> -n <ns> --force` to retry the Helm release.
3. `kubectl -n <ns> rollout restart deploy/<app>` to restart it.
4. Edits made directly with `kubectl` are reverted by Flux. Fix the manifest in Git.

## Restore an app's config from backup

For apps using the `kopiur/backup` component:

1. Suspend the Kustomization: `flux suspend ks <app>`.
2. Scale the app to zero and delete its PVC.
3. `flux resume ks <app>`. The PVC is recreated and populated from the latest Kopia snapshot.

## A Docker stack didn't deploy

```sh
sudo -n docker logs --since 15m doco-cd
```

Frequent causes: a shared `image:` name on a locally built image (pull fails), a container-name conflict after renaming a stack (remove the old container), or an unresolved `op://` secret.

## Deleting a PR-merged app

Remove its `ks.yaml` entry from the namespace `kustomization.yaml` and delete the folder. Flux prunes the resources (`prune: true`). PVCs managed by kopiur follow the component's retention rules, so check them before assuming data is gone.

## Upgrades

- Renovate PRs cover images, charts and workflows. Review and merge.
- Talos and Kubernetes upgrades are automated by `tuppr`.
