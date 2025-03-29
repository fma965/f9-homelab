# tofu/main.tf
module "talos" {
  source = "./talos"

  providers = {
    proxmox = proxmox
  }

  image = {
    version = "v1.9.4"
    schematic = file("${path.module}/talos/image/schematic.yaml")
  }

  cilium = {
    install = file("${path.module}/talos/inline-manifests/cilium-install.yaml")
    values = file("${path.module}/cilium/values.yaml")
  }

  cluster = {
    name            = "talos"
    endpoint        = "10.0.10.101"
    gateway         = "10.0.10.254"
    talos_version   = "v1.9.4"
    proxmox_cluster = "F9"
  }

  nodes = {
    "k8s-cp-01" = {
      host_node     = "F9-HV1"
      machine_type  = "controlplane"
      ip            = "10.0.10.101"
      mac_address   = "BC:24:11:2E:C8:01"
      vm_id         = 801
      cpu           = 4
      ram_dedicated = 4096
    }
    "k8s-cp-02" = {
      host_node     = "F9-HV2"
      machine_type  = "controlplane"
      ip            = "10.0.10.102"
      mac_address   = "BC:24:11:2E:C8:02"
      vm_id         = 802
      cpu           = 4
      ram_dedicated = 4096
    }
    "k8s-cp-03" = {
      host_node     = "F9-HV3"
      machine_type  = "controlplane"
      ip            = "10.0.10.103"
      mac_address   = "BC:24:11:2E:C8:03"
      vm_id         = 803
      cpu           = 4
      ram_dedicated = 4096
    }
    "k8s-worker-01" = {
      host_node     = "F9-HV1"
      machine_type  = "worker"
      ip            = "10.0.10.111"
      mac_address   = "BC:24:11:2E:08:01"
      vm_id         = 811
      cpu           = 4
      ram_dedicated = 4096
      igpu          = true
    }
    "k8s-worker-02" = {
      host_node     = "F9-HV2"
      machine_type  = "worker"
      ip            = "10.0.10.112"
      mac_address   = "BC:24:11:2E:08:02"
      vm_id         = 812
      cpu           = 4
      ram_dedicated = 4096
      igpu          = true
    }
    "k8s-worker-03" = {
      host_node     = "F9-HV3"
      machine_type  = "worker"
      ip            = "10.0.10.113"
      mac_address   = "BC:24:11:2E:08:03"
      vm_id         = 813
      cpu           = 4
      ram_dedicated = 4096
      igpu          = true
    }
  }
}