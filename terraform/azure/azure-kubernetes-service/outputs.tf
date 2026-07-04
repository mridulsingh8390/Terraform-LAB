output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "vnet_id" {
  value = module.vnet.vnet_id
}

output "key_vault_id" {
  value = module.keyvault.key_vault_id
}

output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}

output "disk_encryption_set_id" {
  value = module.keyvault.disk_encryption_set_id
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "postgres_share_name" {
  value = module.storage.postgres_share_name
}

output "storageclass_manifest_path" {
  description = "Path to the written Azure Files StorageClass YAML"
  value       = module.storage.storageclass_manifest_path
}

output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "aks_kube_config" {
  value     = module.aks.kube_config_raw
  sensitive = true
}

output "aks_oidc_issuer_url" {
  value = module.aks.oidc_issuer_url
}
