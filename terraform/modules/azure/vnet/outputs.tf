output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "aks_system_subnet_id" {
  description = "Subnet ID for the AKS system node pool"
  value       = azurerm_subnet.aks_system.id
}

output "aks_user_subnet_id" {
  description = "Subnet ID for the AKS user node pool"
  value       = azurerm_subnet.aks_user.id
}

output "storage_subnet_id" {
  description = "Subnet ID for Azure Files storage"
  value       = azurerm_subnet.storage.id
}
