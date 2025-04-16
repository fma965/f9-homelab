data "talos_image_factory_extensions_versions" "this" {
  talos_version = var.image.version
  filters = {
    names = var.image.extensions
  }
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info[*].name
        }
      }
    }
  )
}

resource "proxmox_virtual_environment_download_file" "this" {
  for_each                = toset(distinct([for v in values(var.nodes) : v.host_node]))
  node_name               = each.value
  content_type            = "iso"
  datastore_id            = var.image.proxmox_datastore
  file_name               = "talos-${var.image.version}_${var.image.platform}-${var.image.arch}.img"
  url                     = "${var.image.factory_url}/image/${talos_image_factory_schematic.this.id}/${var.image.version}/${var.image.platform}-${var.image.arch}.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = true
  overwrite_unmanaged     = true #overwriting image when image is already existing but not managed by terraform (for example when ressources moved from state)
}