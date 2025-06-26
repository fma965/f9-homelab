# talos/providers.tf
terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.8.1"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.78.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox.endpoint
  insecure = var.proxmox.insecure
}

provider "kubernetes" {
  host = module.talos.kube_config.kubernetes_client_configuration.host
  client_certificate = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_certificate)
  client_key = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(module.talos.kube_config.kubernetes_client_configuration.ca_certificate)
}