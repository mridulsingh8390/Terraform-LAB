variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = null
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "prefix" {
  description = "Short prefix used across all resource names (e.g. 'aks-dev')"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

# ── VNet ──────────────────────────────────────────────────────────────────────

variable "vnet_name" {
  type = string
}

variable "vnet_cidr" {
  type    = string
  default = "10.0.0.0/8"
}

variable "aks_system_subnet_cidr" {
  type    = string
  default = "10.0.0.0/20"
}

variable "aks_user_subnet_cidr" {
  type    = string
  default = "10.0.16.0/20"
}

variable "storage_subnet_cidr" {
  type    = string
  default = "10.0.32.0/24"
}

# ── Key Vault ─────────────────────────────────────────────────────────────────

variable "key_vault_name" {
  description = "Key Vault name — globally unique, 3-24 chars"
  type        = string
}

variable "kv_sku_name" {
  type    = string
  default = "premium"
}

variable "kv_soft_delete_retention_days" {
  type    = number
  default = 90
}

variable "kv_purge_protection_enabled" {
  type    = bool
  default = true
}

variable "kv_public_network_access_enabled" {
  type    = bool
  default = true
}

variable "kv_network_default_action" {
  type    = string
  default = "Allow"
}

# ── Storage ───────────────────────────────────────────────────────────────────

variable "storage_account_name" {
  description = "Storage account name — globally unique, 3-24 lowercase alphanumeric"
  type        = string
}

variable "storage_replication_type" {
  type    = string
  default = "LRS"
}

variable "postgres_share_name" {
  type    = string
  default = "postgres-data"
}

variable "postgres_share_quota_gb" {
  type    = number
  default = 100
}

variable "k8s_manifest_output_path" {
  description = "Local directory where StorageClass YAML is written"
  type        = string
  default     = "./k8s-manifests"
}

# ── AKS ───────────────────────────────────────────────────────────────────────

variable "cluster_name" {
  type = string
}

variable "dns_prefix" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = null
}

variable "node_os_disk_size_gb" {
  type    = number
  default = 128
}

variable "service_cidr" {
  type    = string
  default = "172.16.0.0/16"
}

variable "dns_service_ip" {
  type    = string
  default = "172.16.0.10"
}

variable "system_node_vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}

variable "system_node_autoscale" {
  type    = bool
  default = true
}

variable "system_node_min" {
  type    = number
  default = 1
}

variable "system_node_max" {
  type    = number
  default = 3
}

variable "user_node_vm_size" {
  description = "Memory-optimised VM for PostgreSQL pods"
  type        = string
  default     = "Standard_E4s_v5"
}

variable "user_node_autoscale" {
  type    = bool
  default = true
}

variable "user_node_min" {
  type    = number
  default = 1
}

variable "user_node_max" {
  type    = number
  default = 5
}
