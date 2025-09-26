<div align="center">

## Outdated readme, don't believe it!

<img src="https://i.imgur.com/29sG16L.png" align="center" width="175px" height="175px"/>

### <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f680/512.gif" alt="🚀" width="16" height="16"> F9's Homelab <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f6a7/512.gif" alt="🚧" width="16" height="16">

_... managed with Flux, Doco-CD, Renovate and GitHub Actions_ <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f916/512.gif" alt="🤖" width="16" height="16">

</div>

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4a1/512.gif" alt="💡" width="20" height="20"> Overview

This is a mono repository for my entire _homelab_ configuration, including my Kubernetes cluster and Docker instance. It uses Infrastructure as Code (IaC) and GitOps practices as much as possible using tools like [Kubernetes](https://kubernetes.io/), [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate), [Doco-CD](https://github.com/kimdre/doco-cd), and [GitHub Actions](https://github.com/features/actions). All secrets are using 1Password Connect with the exception of 1 or 2 which are SOPS encrypted.

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f331/512.gif" alt="🌱" width="20" height="20"> Kubernetes

My Kubernetes cluster is deployed with [Talos](https://www.talos.dev). This is a semi-hyper-converged cluster, workloads and block storage are sharing the same available resources on my nodes while I have a separate [TrueNAS](https://truenas.com) server for NFS/SMB shares, AI, bulk file storage and backups.

### Core Components

- [cert-manager](https://github.com/cert-manager/cert-manager): Creates SSL certificates for services in my cluster.
- [cilium](https://github.com/cilium/cilium): eBPF-based networking for my workloads.
- [envoy](https://github.com/envoyproxy/envoy): Modern Kubernetes Gateway provider
- [rook](https://github.com/rook/rook): Distributed storage provider for peristent storage using CEPH
- [volsync](https://github.com/backube/volsync): Asynchronous data replication for Kubernetes volumes to S3 (GarageHQ)
- [external-secrets](https://github.com/external-secrets/external-secrets): Managed Kubernetes secrets using [1Password Connect](https://github.com/1Password/connect).
- [sops](https://github.com/getsops/sops): Managed secrets for Kubernetes and Terraform/OpenTofu which are commited to Git.

### GitOps

[Flux](https://github.com/fluxcd/flux2) watches the clusters in my [kubernetes](./kubernetes/) folder (see Directories below) and makes the changes to my clusters based on the state of my Git repository.

Flux will apply all in `kubernetes/apps`

Flux will recursively search sub folders until it finds the most top level `kustomization.yaml` per directory and then apply all the resources listed in it. That aforementioned `kustomization.yaml` will generally only have a namespace resource and one or many Flux kustomizations (`ks.yaml`). Under the control of those Flux kustomizations there will be a `HelmRelease` or other resources related to the application which will be applied.

[Renovate](https://github.com/renovatebot/renovate) watches my **entire** repository looking for dependency updates, when they are found a PR is automatically created. When PRs are merged Flux applies the changes to my cluster.

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f42c/512.gif" alt="🐬" width="20" height="20"> Docker

My Docker instance is running on my [TrueNAS](https://truenas.com/) server and managed by [Doco-CD](https://github.com/kimdre/doco-cd) with GitOps practices, it runs AI workloads that require a dedicated NVidia GPU, Ser2Net for my Zigbee adapter and more, I've tried to limit as much as possible what the NAS does and where possible offloaded it to the Kubernetes cluster.

### GitOps

[Doco-CD](https://github.com/kimdre/doco-cd) watches my [docker](./docker/) folder (see Directories below) and makes the changes based on the state of my Git repository.

Doco-CD is controlled mostly from a single file, the [.doco-cd.yaml](./.doco-cd.yaml) file. This is the file that tells Doco-CD what folders to search for compose files to deploy.

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f680/512.gif" alt="🚀" width="20" height="20"> Let's Go!

### Pre-requisites
#### Hardware
- 3x Computers (I'm using Dell Optiplex 3060's with 2.5Gbe Ethernet)
#### Software
- Linux or WSL on Windows is preferred
- Brew - `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

### Stage 1: Repository Preparation (Infrastructure)

1. Create a new repository by clicking the green `Use this template` button at the top of this page, then clone the new repo you just created and `cd` into it.
> [!WARNING]
> As this repository assumes it's for myself, there are many hardcoded domain name references currently set, I would recommend find and replacing all references of `${SECRET_EXTERNAL_DOMAIN}` with your own tld and `f9-casa` with your own tld replacing dots with dashes, you will ofcourse also need to update any secret files with your own values.
>
> Critical Files that will need updating are
> - [cert-manager/clusterissuer.yaml](./kubernetes/apps/cert-manager/cert-manager/app/clusterissuer.yaml)
> - [traefik/certificate.yaml](./kubernetes/apps/traefik/certifcates/export/certificate.yaml)
> - [flux-instance/values.yaml](./kubernetes/apps/flux-system/flux-instance/app/helm/values.yaml)
>
> Other files should be updated, but these ones will stop deployment working

### Stage 2: Bootstrap Talos Infrastructure
Proxmox Talos VM's, Basic Kubernetes cluster with Cilium
1. Ensure the following enviroment variables are set to the correct values/paths `PROXMOX_VE_USERNAME`, `PROXMOX_VE_PASSWORD`
```bash
export PROXMOX_VE_USERNAME="root@pam"
export PROXMOX_VE_PASSWORD="password"
```
2. Edit the `infrastructure/talos/prod.auto.tfvars` file to reflect your desired configuration, refer to comments for explanations of eaach variable

3. Execute the [Infrastructure Bootstrap script](infrastructure/talos/bootstrap.sh)
```bash
rm infrastructure/talos/output/* # WARNING! This will delete your old kube-config and talos-confg
rm infrastructure/talos/terraform.tfstate # WARNING! This will delete state
rm infrastructure/talos/terraform.tfstate.backup # WARNING! This will delete state
chmod +x ./infrastructure//talos/bootstrap.sh
./infrastructure/talos/bootstrap.sh
```
> [!TIP]
> Optionally add `--dry-run/-d` to test it, or if you are feeling brave `--auto-approve/-y` to skip confirmation prompts

> [!NOTE]
> Approximate time to deploy: *5 Minutes* (assuming NVME storage)

### Stage 3: Bootstrap FluxCD Deployment
1. Ensure you have updated all your `*sops*` files in `kubernetes/**` to match your own values
> [!NOTE]
> Not many of them have sample files currently but eventually i will ensure every `*sops*` file has a matching `*.sample` file
> [!TIP]
> If you are using VSCode you should be able to automatically encrypt your *sops* files.

2. Ensure the following enviroment variables are set to the correct values/paths `SOPS_AGE_KEY_FILE`, `KUBECONFIG`, `GITHUB_OWNER`, `GITHUB_REPO`
```bash
export SOPS_AGE_KEY_FILE=$PWD/.age.key
export KUBECONFIG=$PWD/infrastructure/talos/output/kube-config.yaml
export GITHUB_REPO="https://github.com/fma965/f9-homelab" # replace with your github repo url
```
3. Execute the [Kubernetes Bootstrap script](kubernetes/bootstrap.sh)
```bash
chmod +x ./kubernetes/bootstrap.sh
./kubernetes/bootstrap.sh
```
> [!TIP]
> Optionally if you are feeling brave `--auto-approve/-y` to skip confirmation prompts

> [!NOTE]
> Approximate time to deploy: *10 Minutes* (assuming NVME storage, excluding PV restore if applicable)

### Stage 4: Bootstrap Docker Deployment (Semi-Manual)
> [!WARNING]
> If you do not intend to use Docker skip this stage

> [!NOTE]
> Currently Komodo does not support adding of a Git Repo via the km CLI, once this is added we can automate this a bit more

1. Install Komodo from the AppStore (TrueNAS) or Docker Compose files (UnRaid / Other)
2. Access the [Komodo WebUI](http://f9-nas.internal:9120)
4. Navigate to "Settings" > "Profile" and create a "New Api Key", copy the Key and Secret in to the Komodo 1Password entry
5. Navigate to "Settings" > "Providers" and add a Github.com Account using your token (regenerate it in Github if needed)
6. Navigate to "Syncs" and Create a New Resource Sync called "f9-homelab"
7. Set the Mode to "Git Repo", Repo to "fma965/f9-homelab"
8. Set the Account to "fma965"
9. Add the following resource path `docker/komodo.toml`
10. Enable "Delete Unmatched Resources" and "Managed"
11. Make sure only "Sync Resources" is checked under the Include section
12. Click "Save", Click "Refresh" and the "Execute"

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f52e/512.gif" alt="🔮" width="20" height="20"> Git Repo Structure

<details>
  <summary>Click here to the directories of this Git Repo with descriptions</summary>

```sh
.
├── 📂 docker
│
├── 📂 infrastructure
│   └── 📂 talos
│       ├── 📂 output              # Terraform output artifacts
│       └── 📂 talos               🤖 # Talos Linux Kubernetes configurations
│
└── 📂 kubernetes
    ├── 📂 apps
    │   ├── 📂 backup              💾 # Backup solutions
    │   ├── 📂 ceph-csi            💾 # Ceph CSI storage driver
    │   ├── 📂 cert-manager        📜 # SSL certificate management
    │   ├── 📂 default             🏠 # Dashboard and landing page
    │   ├── 📂 external-secrets    🤫 # External secret management
    │   ├── 📂 flux-system         ⚡ # GitOps management (FluxCD)
    │   ├── 📂 game                🦖 # Game servers
    │   ├── 📂 git                 ⎙ # Git services
    │   ├── 📂 kube-system         ⚙️ # Core Kubernetes system components
    │   ├── 📂 observability       👁️ # Monitoring and logging stack
    │   ├── 📂 openebs-system      💾 # Container Attached Storage (OpenEBS)
    │   ├── 📂 postgresql          🐘 # PostgreSQL databases
    │   ├── 📂 redis               🧠 # Redis key-value stores
    │   ├── 📂 security            🛡️ # Security tools
    │   ├── 📂 system-upgrade      ⬆️ # Kubernetes node upgrade controller
    │   ├── 📂 traefik             🚦 # Ingress controller and reverse proxy
    │   ├── 📂 volsync             🔄 # Volume snapshot and replication
    │   └── 📂 webdev              🌐 # Web development projects
    ├── 📂 components
    │   ├── 📂 common             ⚙️ # Shared Kubernetes components
    │   ├── 📂 gatus
    │   ├── 📂 volsync
    │   └── 📂 volsync-backuponly
    └── 📂 flux
        └── 📂 cluster             ⚡ # GitOps cluster definitions
```
</details>

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f636_200d_1f32b_fe0f/512.gif" alt="😶" width="20" height="20"> Cloud Dependencies

Most of my infrastructure and workloads are self-hosted and do not rely upon cloud services, some however do, here is a list of them. Note that some of these may not be part of this repo but rather just things that i also use in relation to it.

| Service                                         | Use                                                               | Cost           |
|-------------------------------------------------|-------------------------------------------------------------------|----------------|
| [1Password](https://1password.com/)             | Secrets with [External Secrets](https://external-secrets.io/)     | ~$40/yr        |
| [Cloudflare](https://www.cloudflare.com/)       | Domain                                                            | ~£6/yr         |
| [GCP](https://cloud.google.com/)                | Voice interactions with Home Assistant over Google Assistant      | Free           |
| [GitHub](https://github.com/)                   | Hosting this repository and continuous integration/deployments    | Free           |
| [Discord](https://discord.com/)                 | Alerts and notifications                                          | Free           |
| [Pushover](https://pushover.net/)               | Kubernetes Alerts and application notifications                   | $5 OTP         |

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f393/512.gif" alt="🎓" width="20" height="20"> Wiki
Check out my [Wiki](https://wiki.${SECRET_EXTERNAL_DOMAIN}/hardware/) to see more about my hardware and much more

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f64f/512.gif" alt="🙏" width="20" height="20"> Gratitude and Thanks

Thanks to the [Home Operations](https://discord.gg/home-operations) / [OneDr0p](https://github.com/onedr0p/home-ops) Discord and community.
