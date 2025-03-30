# F9's Homelab Deployment

## Summary
This repo uses **IaC** and **GitOps** techniques to easily and securely (using **SOPS AGE**) deploy **Talos Linux**, **Kubernetes (K8S)** and **Docker** services with code.

### Talos Linux IaC using Terraform/OpenTofu
Located in the [infrastructure](infrastructure) folder
- 3x Talos Control Plane VM Creation (Proxmox)
- 3x Talos Worker VM Creation (Proxmox)
- Talos Cluster configuration

Based on [Stonegarden](https://blog.stonegarden.dev/articles/2024/08/talos-proxmox-tofu/) modified for my use.

###  Kubernetes GitOps using FluxCD
Located in the [kubernetes](kubernetes) folder
- FluxCD powered GitOps deployment
- Cert-Manager using LetsEncrypt with Cloudflare API authentication
- Cilium load balancer
- Traefik ingress
- Longhorn
- MariaDB (MySQl), Postgres and Redis databases

The [kubernetes](kubernetes) folder of this repo mostly follows the FluxCD Mono Repo structure.

### Docker GitOps using Komodo
Located in the [docker](docker) folder
- [Komodo](https://komo.do/) powered GitOps deployment

As this runs on my UnRaid instance this is configured manually once the [Komodo Compose](docker/komodo/) file is up and running

### AGE encrypted Secrets with SOPS
All `*secret.enc.env` (docker) and `*secret.enc.yaml` (kubernetes) files are encrypted with SOPS using AGE.

I have included `*secret.sample.yaml` and `*secret.enc.env` files which contain placeholder values to enhance the usability.

## Pre-requisites
### Clone the Repo
`git clone https://github.com/fma965/f9-homelab`

### Download CLI Tools
Ensure you have installed in a WSL or Linux installation the following packages
- [fluxcli](https://fluxcd.io/flux/cmd/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [talosctl](https://www.talos.dev/v1.9/talos-guides/install/talosctl/) 
- [SOPS](https://github.com/getsops/sops/releases/latest)

Windows users make sure SOPS is in your `PATH` (e.g. C:\Windows)
### SOPS Age Public/Private Keys
[AGE](https://github.com/FiloSottile/age) keys for SOPS to use need to be saved in the following structure from the root of this repo.
`.sops/age/private.key` 
`.sops/age/public.key` 
(these are ignored by the .gitignore file)

If you have lost these, perhaps they are stored in your password manager ;)

### Configure your GitHooks
Set your GitHooks to use `.githooks` with this command
```
git config --local core.hooksPath .githooks/
chmod +x .githooks/*
```
This makes sure any filename with `secret.yaml` or `secret.env` in their name are encrypted with SOPS when commiting

## Instructions
### Restoring Infrastructure
Run the following script to initiate Tofu and create the Talos Linux powered kubernetes cluster

```bash
rm infrastructure/tofu/output/* # WARNING! This will delete your old kube-config and talos-confg
rm infrastructure/tofu/terraform.tfstate # WARNING! This will delete state
rm infrastructure/tofu/terraform.tfstate.backup # WARNING! This will delete state
chmod +x ./infrastructure/restore-infrastructure.sh
./infrastructure/restore-infrastructure.sh
```
Optionally add `--dry-run`/`-d` to test it, or if you are feeling brave `--auto-approve`/`-y` to skip confirmation prompts

Approximate restore time: **4 Minutes**

### Restoring Kubernetes
Export your SOPS_AGE_KEY_FILE and if you do not wish to enter your GitHub Token later export that aswell
```bash
export SOPS_AGE_KEY_FILE=$PWD/.sops/age/private.key
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxx`
```
Run the following script to initiate the FluxCD kubernetes GitOps process
```bash
chmod +x ./kubernetes/restore-kubernetes.sh
./kubernetes/restore-kubernetes.sh
```
At a certain point during the script, it will ask you to "Access Longhorn at: http://localhost:8080" follow the steps

If you are unable to access the S3 backup target, we may just need to force a upgrade of the cilium helmrelease for some reason, to do this i simply make a edit of the helmrelease in k9s/lens and then that causes it to be upgraded.
`helm upgrade cilium cilium/cilium --force --reuse-values -n kube-system`

If that doesn't work using k9s edit the helmrelease of cilium and toggle the gatewayAPI value, save, then toggle it back to true again.

Approximate restore time: **Less than 30 Minutes** 

(**5 Minutes** for initial deployment, **8 Minutes** to restore volumes, and another **5 Minutes** to restore apps)

### Restoring Docker
Run the following script to decrypt and copy the Compose files to UnRaid
(Make sure you have the [docker compose plugin](https://forums.unraid.net/topic/114415-plugin-docker-compose-manager/) installed)
```bash
chmod +x ./docker/restore-docker.sh
./docker/restore-docker.sh root@unraidIP
```
If you have lost the Komodo database also follow the below steps to reconfigure the GitOps sync
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

## Git Repo Structure
Infrastructure is in [infrastructure](infrastructure)
Docker is in [docker](docker)
Kubernetes is in [kubernetes](kubernetes)
```
📁 Repository Root
│
├───🔧 .githooks/                    # Git hook scripts
│   ├───🐙 commit-msg                # Enforces semantic commit messages
│   ├───🔓 post-checkout             # Auto-decrypts files after checkout
│   └───🔐 pre-commit               # Ensures secrets are encrypted before commit
│
├───🤖 .github/                      # GitHub configurations
│
├───🔄 renovate.json5               # Base RenovateBot configuration
├───🔄 .renovate/                   # Additional RenovateBot configuration
│
│
├───🔑 .sops/age/                    # SOPS encryption keys
│   ├───🗝️ private.key              # Age private key (gitignored)
│   └───🔓 public.key               # Age public key
│
├───🐳 docker/                       # Docker/Compose configurations
│   ├───🦎 komodo/                   # Komodo-specific files
│   │   ├───📝 compose.yaml         # Main compose file
│   │   └───🔒 secret.enc.env       # Encrypted environment variables
│   │
│   ├───⚙️ komodo.toml              # Komodo stack configuration
│   └───📦 stacks/                  # All Docker stacks
│       ├───📁 stack1/
│       └───📁 stack2/
│
├───🖥️ infrastructure/              # Talos Linux IaC
│   └───🚀 tofu/
│       ├───🔗 cilium/               # Cilium CNI configs
│       ├───📤 output/               # Tofu state/outputs
│       ├───🔄 simplified/           # Simplified manifests
│       └───🤖 talos/
│           ├───🖼️ image/           # OS image configs
│           ├───📜 inline-manifests/ # Embedded Kubernetes manifests
│           └───⚙️ machine-config/   # Talos machine configs
│
└───☸️ kubernetes/                   # FluxCD GitOps
    ├───📱 apps/                     # Application manifests
    │   └───📌 base/                 # Base Kustomizations
    │
    ├───🏠 clusters/
    │   └───home/
    │       └───🌀 flux-system/       # Flux bootstrap configs
    │           ├───📜 gotk-components.yaml
    │           └───📜 gotk-sync.yaml
    │
    └───🛠️ infrastructure/
        ├───⚙️ configs/              # Cluster configs
        ├───🎮 controllers/          # Custom controllers
        └───🗃️ databases/           # Database operators
```

## Footnotes
Check my [Wiki](https://wiki.f9.casa) for more details!