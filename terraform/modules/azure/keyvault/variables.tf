variable "key_vault_name" {
  description = "Name of the Key Vault (globally unique, 3-24 alphanumeric + hyphens)"
  type        = string
}

variable "prefix" {
  description = "Short prefix used to name CMK key and Disk Encryption Set"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "sku_name" {
  description = "Key Vault SKU: standard or premium (premium required for HSM-backed keys)"
  type        = string
  default     = "premium"
}

variable "soft_delete_retention_days" {
  description = "Soft-delete retention in days (7-90)"
  type        = number
  default     = 90
}

variable "purge_protection_enabled" {
  description = "Enable purge protection. Required true in prod to prevent CMK deletion."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Allow public network access to the Key Vault"
  type        = bool
  default     = true
}

variable "network_default_action" {
  description = "Default network ACL action: Allow or Deny"
  type        = string
  default     = "Allow"
}

variable "allowed_ip_rules" {
  description = "IP rules allowed when network_default_action = Deny"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
