# tofu/talos/providers.tf
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.75.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = ">=0.7.0"
    }
  }
}
