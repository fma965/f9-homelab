# talos/main.tf
module "talos" {
  source = "./talos"
  image = var.image
  cluster = var.cluster
  nodes = var.nodes
  proxmox = var.proxmox
}