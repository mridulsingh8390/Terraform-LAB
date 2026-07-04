output "cluster_id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "kube_config_raw" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "host" {
  value     = azurerm_kubernetes_cluster.aks.kube_config[0].host
  sensitive = true
}

output "kubelet_identity_object_id" {
  description = "Object ID of the AKS kubelet identity — grant access to Azure resources"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "cluster_identity_principal_id" {
  description = "Principal ID of the AKS cluster's system-assigned identity (control plane)"
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "node_resource_group" {
  value = azurerm_kubernetes_cluster.aks.node_resource_group
}
