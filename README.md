<div align="center">

<img src="https://i.imgur.com/29sG16L.png" align="center" width="175px" height="175px"/>

### <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f680/512.gif" alt="🚀" width="16" height="16"> F9's Homelab <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f6a7/512.gif" alt="🚧" width="16" height="16">

_... managed with Flux, Renovate, Komodo and GitHub Actions_ <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f916/512.gif" alt="🤖" width="16" height="16">

</div>

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4a1/512.gif" alt="💡" width="20" height="20"> Overview

This is a mono repository for my entire _homelab_ configuration, including my Kubernetes cluster and Docker instance. It uses Infrastructure as Code (IaC) and GitOps practices as much as possible using tools like [Terraform](https://www.terraform.io/), [Kubernetes](https://kubernetes.io/), [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate), [Komodo](https://github.com/moghtech/komodo), and [GitHub Actions](https://github.com/features/actions). All secrets are using 1Password Connect or if that isn't possible _SOPS_ encryption.

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/2699_fe0f/512.gif" alt="⚙️" width="20" height="20"> Infrastructure

Using [OpenTofu](https://github.com/opentofu/opentofu) ([Terraform fork](https://github.com/hashicorp/terraform)) we can spin up any amount of Proxmox VM's with Kubernetes fully configured running on [Talos](https://github.com/siderolabs/talos).

### OpenTofu Providers
- [siderolabs/talos](https://search.opentofu.org/provider/siderolabs/talos/latest): Manage Talos OS
- [bpg/proxmox](https://search.opentofu.org/provider/bpg/proxmox/latest): Manage Proxmox nodes
- [hashicorp/kubernetes](https://search.opentofu.org/provider/hashicorp/kubernetes/latest): Manage Kubernetes

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f331/512.gif" alt="🌱" width="20" height="20"> Kubernetes

My Kubernetes cluster is deployed with [Talos](https://www.talos.dev). This is a semi-hyper-converged cluster, workloads and block storage are sharing the same available resources on my nodes while I have a separate [Unraid](https://unraid.net/) server for NFS/SMB shares, bulk file storage and backups.

### Core Components

- [cert-manager](https://github.com/cert-manager/cert-manager): Creates SSL certificates for services in my cluster.
- [cilium](https://github.com/cilium/cilium): eBPF-based networking for my workloads.
- [traefik](https://github.com/traefik/traefik): Ingress provider
- [longhorn](https://github.com/longhorn/longhorn): Distributed storage for peristent storage. to be replaced with ceph-csi
- [external-secrets](https://github.com/external-secrets/external-secrets): Managed Kubernetes secrets using [1Password Connect](https://github.com/1Password/connect).
- [sops](https://github.com/getsops/sops): Managed secrets for Kubernetes and Terraform/OpenTofu which are commited to Git.

WIP
- [ceph-csi](https://github.com/ceph/ceph-csi): Distributed block storage for peristent storage using external ceph provider (proxmox)

### GitOps

[Flux](https://github.com/fluxcd/flux2) watches the clusters in my [kubernetes](./kubernetes/) folder (see Directories below) and makes the changes to my clusters based on the state of my Git repository.

Unlike some other repos's i have set a up a few extra folders instead of just apps, components, flux, this is mostly to allow for easy restore of Longhorn volumes from S3 (local for now)

Flux will first apply all resources in `kubernetes/core` then `kubernetes/databases` and then `kubernetes/apps`, if using the restore script, the process will be paused after `kubernetes/core` to allow restoring manually of Longhorn volumes

For each of these folders Flux will recursively search it until it finds the most top level `kustomization.yaml` per directory and then apply all the resources listed in it. That aforementioned `kustomization.yaml` will generally only have a namespace resource and one or many Flux kustomizations (`ks.yaml`). Under the control of those Flux kustomizations there will be a `HelmRelease` or other resources related to the application which will be applied.

[Renovate](https://github.com/renovatebot/renovate) watches my **entire** repository looking for dependency updates, when they are found a PR is automatically created. When some PRs are merged Flux applies the changes to my cluster.

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f42c/512.gif" alt="🐬" width="20" height="20"> Docker

My Docker instance is running on my [Unraid](https://unraid.net/) server and managed by [Komodo](https://github.com/moghtech/komodo) with GitOps practices, it runs most things that require bulk storage such as [Jellyfin](https://github.com/jellyfin/jellyfin), [Frigate](https://github.com/blakeblackshear/frigate), [Immich](https://github.com/immich-app/immich), [*Arrs](https://wiki.servarr.com/) and AI workloads.

These could run on my Kubernetes cluster but as they require bulk storage it seems a bit pointless when Unraid is able to do these things for me.

### GitOps

[Komodo](https://github.com/moghtech/komodo) watches my [docker](./docker/) folder (see Directories below) and makes the changes based on the state of my Git repository.

Komodo is controlled mostly from a single file, the [komodo.toml](./docker/komodo.toml) file. This is the file that sets up al the stacks, from there it's just docker compose.yaml files

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f680/512.gif" alt="🚀" width="20" height="20"> Let's Go!

### Pre-requisites
#### Hardware
- Proxmox Cluster
#### Tools
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [SOPS](https://github.com/getsops/sops/releases/latest) (Windows user's ensure it's in your `PATH`)
- Optional: [talosctl](https://www.talos.dev/v1.9/talos-guides/install/talosctl/)
- Optional: [fluxcli](https://fluxcd.io/flux/cmd/) (required if using `--restore`)
#### Credentials/Keys
- Proxmox SSH Credentials (e.g `root` / `password`)
- SOPS Age Key (saved to `.age.key` - @fma965 check your password manager 😉)

### Stage 1: Repository Preparation (Infrastructure)

1. Create a new repository by clicking the green `Use this template` button at the top of this page, then clone the new repo you just created and `cd` into it.
> [!WARNING]
> As this repository assumes it's for myself, there are many hardcoded domain name references currently set, I would recommend find and replacing all references of `f9.casa` with your own tld, you will ofcourse also need to update any secret files with your own values.
>
> Critical Files that will need updating are
> - [cert-manager/clusterissuer.yaml](./kubernetes/core/cert-manager/cert-manager/app/clusterissuer.yaml)
> - [cert-manager/cloudflare-secret.sops.yaml](./kubernetes/core/cert-manager/cert-manager/app/cloudflare-secret.sops.yaml)
> - [traefik/certificate.yaml](./kubernetes/core/traefik/traefik/app/certificate.yaml)
> - [flux-instance/values.yaml](./kubernetes/core/flux-system/flux-instance/app/helm/values.yaml)
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
> Optionally add `--restore/-r` to pause the script after longhorn is installed to manually restore volumes or if you are feeling brave `--auto-approve/-y` to skip confirmation prompts

> [!NOTE]
> Approximate time to deploy: *10 Minutes* (assuming NVME storage, excluding Longhorn restore if applicable)

### Stage 4: Bootstrap Docker Deployment
> [!WARNING]
> If you do not intend to use Docker skip this stage, this has only been tested on Unraid but it should be quite easily adaptable to other operating systems

1. Ensure you have the [Docker Compose](https://forums.unraid.net/topic/114415-plugin-docker-compose-manager/) plugin installed on Unraid

2. Ensure the `SOPS_AGE_KEY_FILE` enviroment variable is set to the correct paths
```bash
export SOPS_AGE_KEY_FILE=$PWD/.age.key
```

3. Execute the [Docker Bootstrap script](docker/bootstrap.sh)
> [!IMPORTANT]
> replace `root@unraidIP` with your unraidIP
```bash
chmod +x ./docker/bootstrap.sh
./docker/bootstrap.sh root@unraidIP
```

### Stage 5: Configuring Komodo (New Installs only)
> [!NOTE]
> If you have lost the Komodo database also follow the below steps to reconfigure the GitOps sync, adjust values to reflect your own configuration
1. Access the [Komodo WebUI](https://komodo.f9.casa)
2. Navigate to "Servers" and Delete the existing Server.
3. Navigate to "Settings" > "Providers" and add a Github.com Account using your token
4. Navigate to "Syncs" and Create a New Resource Sync called "f9-homelab"
5. Set the Mode to "Git Repo", Repo to "fma965/f9-homelab"
6. Set the Account to "fma965"
7. Add the following resource path `docker/komodo.toml`
8. Enable "Delete Unmatched Resources" and "Managed"
9. Make sure only "Sync Resources" is checked under the Include section
10. Click "Save", Click "Refresh" and the "Execute"

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f52e/512.gif" alt="🔮" width="20" height="20"> Git Repo Structure

<details>
  <summary>Click here to the directories of this Git Repo with descriptions</summary>

```sh
.
├── 📂 docker
│   ├── 📂 komodo          # Docker development environment configurations
│   └── 📂 stacks
│       ├── 📂 ai          🤖 # AI/ML services (LLMs, vector DBs, etc.)
│       ├── 📂 arr         🎬 # *ARR media stack (Sonarr/Radarr/Prowlarr)
│       ├── 📂 backup      💾 # Backup solutions (Duplicati, Borg, etc.)
│       ├── 📂 downloaders ⏬ # Download managers (qBittorrent, NZBGet)
│       ├── 📂 git         ⎙  # Git services (Gitea, GitLab)
│       ├── 📂 media       🎵 # Media processors (Handbrake, Tdarr)
│       ├── 📂 misc        🎪 # Miscellaneous utilities
│       └── 📂 monitoring  👁️ # Monitoring tools (Grafana, Prometheus)
│
├── 📂 infrastructure
│   └── 📂 talos
│       ├── 📂 output      # Terraform output artifacts
│       └── 📂 talos       🤖 # Talos Linux Kubernetes configurations
│
└── 📂 kubernetes
    ├── 📂 apps
    │   ├── 📂 authentik     🔐 # SSO and identity management
    │   ├── 📂 backup        💾 # Kubernetes backup solutions (Velero, Kasten)
    │   ├── 📂 crowdsec      🛡️ # Security and intrusion detection
    │   ├── 📂 gatus         ❤️ # Service health monitoring
    │   ├── 📂 git           ⎙  # Git management tools
    │   ├── 📂 homepage      🏠 # Dashboard and landing page
    │   ├── 📂 outline       📝 # Documentation/wiki system
    │   ├── 📂 pgadmin       🐘 # PostgreSQL administration interface
    │   ├── 📂 phpmyadmin    🐬 # MySQL/MariaDB administration interface
    │   ├── 📂 pterodactyl   🦖 # Game server management panel
    │   └── 📂 webdev        🌐 # Web development tools
    │
    ├── 📂 components
    │   └── 📂 common       ⚙️ # Shared Kubernetes components
    │
    ├── 📂 core
    │   ├── 📂 cert-manager 📜 # SSL certificate management
    │   ├── 📂 kube-system  ⚙️ # Core Kubernetes system components
    │   ├── 📂 longhorn-system 🦏 # Distributed block storage
    │   └── 📂 traefik      🚦 # Ingress controller and reverse proxy
    │
    ├── 📂 databases
    │   ├── 📂 mariadb      🐬 # MySQL-compatible databases
    │   ├── 📂 postgres     🐘 # PostgreSQL databases
    │   └── 📂 redis        🧠 # Redis key-value stores
    │
    └── 📂 flux
        └── 📂 cluster      ⚡ # GitOps deployment configurations
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

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f393/512.gif" alt="🎓" width="20" height="20"> Wiki
Check out my [Wiki](https://wiki.f9.casa/hardware/) to see more about my hardware and much more

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f64f/512.gif" alt="🙏" width="20" height="20"> Gratitude and Thanks

Thanks to the [Home Operations](https://discord.gg/home-operations) Discord community and [StoneGarden](https://blog.stonegarden.dev/articles/2024/08/talos-proxmox-tofu/) for the initial Proxmox Tofu code.
