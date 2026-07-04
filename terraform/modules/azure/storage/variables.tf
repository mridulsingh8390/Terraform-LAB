variable "storage_account_name" {
  description = "Storage account name (globally unique, 3-24 lowercase alphanumeric)"
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

variable "replication_type" {
  description = "Replication: LRS, ZRS, GRS (Premium FileStorage supports LRS and ZRS only)"
  type        = string
  default     = "LRS"
}

variable "key_vault_id" {
  description = "Key Vault resource ID — used to grant the storage account CMK access"
  type        = string
}

variable "cmk_key_id" {
  description = "Versioned CMK key ID from Key Vault — used to encrypt the storage account"
  type        = string
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access the storage account (storage + AKS subnets)"
  type        = list(string)
}

variable "postgres_share_name" {
  description = "Name of the Azure Files NFS share for PostgreSQL data"
  type        = string
  default     = "postgres-data"
}

variable "postgres_share_quota_gb" {
  description = "Size of the PostgreSQL NFS share in GB (minimum 100 GB for Premium)"
  type        = number
  default     = 100
}

variable "k8s_manifest_output_path" {
  description = "Local directory to write the Kubernetes StorageClass YAML into"
  type        = string
  default     = "./k8s-manifests"
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
