
image = {
  version      = "v1.10.6"  # Must follow semantic versioning
  extensions   = ["i915-ucode", "intel-ucode", "qemu-guest-agent", "iscsi-tools", "util-linux-tools"] # Array of Talos extensions
}

cluster = {
  name            = "F9"                    # Kubernetes cluster name
  endpoint        = "10.0.10.101"           # Kubernetes controlplane IP
  gateway         = "10.0.10.254"           # Gateway IP
  vip             = "10.0.10.100"           # Control Plane VIP
}

proxmox = {
  cluster_name = "F9"                       # Name of your Proxmox cluster
  name         = "F9-HV1"                   # Name of one of your nodes
  endpoint     = "https://10.0.40.1:8006"   # IP:Port of your chosen node
  insecure     = true                       # Ignore certificate error (self-signed cert)
}

nodes = {
  "k8s-cp-01" = {                           # VM name
    host_node     = "F9-HV1"                # Cluster node
    machine_type  = "controlplane"          # Kubernetes controlplane/worker
    ip            = "10.0.10.101"           # IP address
    mac_address   = "BC:24:11:2E:C8:01"     # MAC Address
    vm_id         = 801                     # VM ID
    cpu           = 4                       # CPU Cores
    ram_dedicated = 8192                    # RAM
    datastore_id = "local-zfs"              # Primary Disk Data Store
    disk_size     = 20                      # Primary Disk Size
    vlan_id       = 10                      # Optional: VLAN ID
  }
  "k8s-cp-02" = {                           # VM name
    host_node     = "F9-HV2"                # Cluster node
    machine_type  = "controlplane"          # Kubernetes controlplane/worker
    ip            = "10.0.10.102"           # IP address
    mac_address   = "BC:24:11:2E:C8:02"     # MAC Address
    vm_id         = 802                     # VM ID
    cpu           = 4                       # CPU Cores
    ram_dedicated = 8192                    # RAM
    datastore_id = "local-zfs"              # Primary Disk Data Store
    disk_size     = 20                      # Primary Disk Size
    vlan_id       = 10                      # Optional: VLAN ID
  }
  "k8s-cp-03" = {                           # VM name
    host_node     = "F9-HV3"                # Cluster node
    machine_type  = "controlplane"          # Kubernetes controlplane/worker
    ip            = "10.0.10.103"           # IP address
    mac_address   = "BC:24:11:2E:C8:03"     # MAC Address
    vm_id         = 803                     # VM ID
    cpu           = 4                       # CPU Cores
    ram_dedicated = 8192                    # RAM
    datastore_id = "local-zfs"              # Primary Disk Data Store
    disk_size     = 20                      # Primary Disk Size
    vlan_id       = 10                      # Optional: VLAN ID
  }
  "k8s-worker-01" = {                       # VM name
    host_node     = "F9-HV1"                # Cluster node
    machine_type  = "worker"                # Kubernetes controlplane/worker
    ip            = "10.0.10.111"           # IP address
    mac_address   = "BC:24:11:2E:08:01"     # MAC Address
    vm_id         = 811                     # VM ID
    cpu           = 6                       # CPU Cores
    ram_dedicated = 16384                    # RAM
    datastore_id = "local-zfs"              # Primary Disk Data Store
    igpu          = true                   # GPU passthrough
    disk_size     = 30                      # Primary Disk Size
    cache_size    = 30                         # Optional: Cache (local-path) Storage Size, 30GB if not specified
    cache_datastore_id = "nvme"             # Optional: Cache Datastore
    vlan_id       = 10                      # Optional: VLAN ID
  }
  "k8s-worker-02" = {                       # VM name
    host_node     = "F9-HV2"                # Cluster node
    machine_type  = "worker"                # Kubernetes controlplane/worker
    ip            = "10.0.10.112"           # IP address
    mac_address   = "BC:24:11:2E:08:02"     # MAC Address
    vm_id         = 812                     # VM ID
    cpu           = 6                       # CPU Cores
    ram_dedicated = 16384                    # RAM
    datastore_id = "local-zfs"              # Primary Disk Data Store
    igpu          = true                   # GPU passthrough
    disk_size     = 30                      # Primary Disk Size
    cache_size    = 30                      # Optional: Cache (local-path) Storage Size, 30GB if not specified
    cache_datastore_id = "nvme"             # Optional: Cache Datastore
    vlan_id       = 10                      # Optional: VLAN ID
  }
  "k8s-worker-03" = {                       # VM name
    host_node     = "F9-HV3"                # Cluster node
    machine_type  = "worker"                # Kubernetes controlplane/worker
    ip            = "10.0.10.113"           # IP address
    mac_address   = "BC:24:11:2E:08:03"     # MAC Address
    vm_id         = 813                     # VM ID
    cpu           = 6                       # CPU Cores
    ram_dedicated = 16384                    # RAM
    datastore_id = "local-zfs"              # Primary Disk Data Store
    igpu          = true                   # GPU passthrough
    disk_size     = 30                      # Primary Disk Size
    cache_size    = 30                      # Optional: Cache (local-path) Storage Size, 30GB if not specified
    cache_datastore_id = "nvme"             # Optional: Cache Datastore
    vlan_id       = 10                      # Optional: VLAN ID
  }
}