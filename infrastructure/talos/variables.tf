# talos/variables.tf
variable "proxmox" {
  type = object({
    name         = string
    cluster_name = string
    endpoint     = string
    insecure     = bool
  })
  sensitive = true
}

variable "cluster" {
  description = "Configuration for cluster information"
  type = object({
    name            = string
    endpoint        = string
    gateway         = string
    vip             = string
  })
}

variable "nodes" {
  description = "Configuration for cluster nodes"
  type = map(object({
    host_node     = string
    machine_type  = string
    datastore_id = optional(string, "local-zfs")
    ip            = string
    mac_address   = string
    vm_id         = number
    cpu           = number
    ram_dedicated = number
    disk_size     = optional(number, 20)
    update = optional(bool, false)
    igpu = optional(bool, false)
    vlan_id = optional(number, null)
  }))
}

variable "image" {
  type = object({
    version           = optional(string, "v1.9.5")
    extensions        = list(string)
    platform          = optional(string, "nocloud")
    arch              = optional(string, "amd64")
    factory_url       = optional(string, "https://factory.talos.dev")
    proxmox_datastore = optional(string, "local")
  })
  description = "The Talos image factory configuration"
  validation {
    condition     = can(regex("^v(?P<major>0|[1-9]\\d*)\\.(?P<minor>0|[1-9]\\d*)\\.(?P<patch>0|[1-9]\\d*)(?:-(?P<prerelease>(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$", var.image.version))
    error_message = "Talos image version must follow semantic versioning format"
  }
}