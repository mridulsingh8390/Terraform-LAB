output "storage_account_id" {
  value = azurerm_storage_account.sa.id
}

output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "storage_account_primary_endpoint" {
  value = azurerm_storage_account.sa.primary_file_endpoint
}

output "postgres_share_name" {
  description = "Azure Files NFS share name — referenced in PVC manifests"
  value       = azurerm_storage_share.postgres.name
}

output "storageclass_manifest_path" {
  description = "Path to the written Kubernetes StorageClass YAML"
  value       = local_file.storageclass.filename
}
