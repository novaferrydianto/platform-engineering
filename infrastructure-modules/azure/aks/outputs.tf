output "cluster_name" {
  description = "Cluster name"
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_id" {
  description = "Cluster resource identifier"
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_fqdn" {
  description = "API server FQDN — private when private_cluster_enabled is true"
  value       = var.private_cluster_enabled ? azurerm_kubernetes_cluster.this.private_fqdn : azurerm_kubernetes_cluster.this.fqdn
}

output "oidc_issuer_url" {
  description = "OIDC issuer for federated workload identity credentials"
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Managed identity used by kubelet — grant it AcrPull on your registry"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "node_resource_group" {
  description = "Resource group holding the cluster's node infrastructure"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}
