output "key_vault_id" {
  value = azurerm_key_vault.kv.id
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}

output "cmk_key_id" {
  description = "Versioned CMK key ID — used by storage account encryption"
  value       = azurerm_key_vault_key.cmk.id
}

output "cmk_key_versionless_id" {
  description = "Versionless CMK key ID — used by Disk Encryption Set (auto-rotates)"
  value       = azurerm_key_vault_key.cmk.versionless_id
}

output "disk_encryption_set_id" {
  description = "Disk Encryption Set ID — passed to AKS for OS disk CMK encryption"
  value       = azurerm_disk_encryption_set.des.id
}
