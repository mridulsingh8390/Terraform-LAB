variable "cluster_name" {
  description = "Name of the AKS cluster"
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

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version (leave null for latest supported)"
  type        = string
  default     = null
}

variable "system_subnet_id" {
  description = "Subnet ID for the system node pool"
  type        = string
}

variable "user_subnet_id" {
  description = "Subnet ID for the user node pool"
  type        = string
}

variable "disk_encryption_set_id" {
  description = "Disk Encryption Set ID for CMK encryption of node OS disks"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault ID — used to grant AKS identity crypto access for etcd encryption"
  type        = string
}

variable "node_os_disk_size_gb" {
  description = "OS disk size in GB for all node pools"
  type        = number
  default     = 128
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "172.16.0.0/16"
}

variable "dns_service_ip" {
  description = "IP for cluster DNS service (must be within service_cidr)"
  type        = string
  default     = "172.16.0.10"
}

# ── System node pool ──────────────────────────────────────────────────────────

variable "system_node_vm_size" {
  description = "VM size for system nodes"
  type        = string
  default     = "Standard_D2s_v5"
}

variable "system_node_count" {
  description = "Fixed system node count (used when autoscale is false)"
  type        = number
  default     = 2
}

variable "system_node_autoscale" {
  description = "Enable autoscaling for system node pool"
  type        = bool
  default     = true
}

variable "system_node_min" {
  description = "Minimum system node count when autoscaling"
  type        = number
  default     = 1
}

variable "system_node_max" {
  description = "Maximum system node count when autoscaling"
  type        = number
  default     = 3
}

# ── User node pool ────────────────────────────────────────────────────────────

variable "user_node_vm_size" {
  description = "VM size for user nodes (runs PostgreSQL — choose memory-optimised)"
  type        = string
  default     = "Standard_E4s_v5"
}

variable "user_node_count" {
  description = "Fixed user node count (used when autoscale is false)"
  type        = number
  default     = 2
}

variable "user_node_autoscale" {
  description = "Enable autoscaling for user node pool"
  type        = bool
  default     = true
}

variable "user_node_min" {
  description = "Minimum user node count when autoscaling"
  type        = number
  default     = 1
}

variable "user_node_max" {
  description = "Maximum user node count when autoscaling"
  type        = number
  default     = 5
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
