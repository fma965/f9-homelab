# tofu/talos/output.tf
output "client_configuration" {
  value     = data.talos_client_configuration.this
  sensitive = true
}

output "kube_config" {
  value = {
    kubeconfig_raw = talos_cluster_kubeconfig.this.kubeconfig_raw
  }
  sensitive = true
}

output "machine_config" {
  value = data.talos_machine_configuration.this
}
