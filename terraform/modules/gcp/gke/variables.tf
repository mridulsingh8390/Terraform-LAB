variable "cluster_name" {
  type = string
}

variable "prefix" {
  type = string
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "pods_range_name" {
  type    = string
  default = "pods"
}

variable "services_range_name" {
  type    = string
  default = "services"
}

variable "cmk_id" {
  description = "KMS CryptoKey ID for etcd encryption and node boot disk encryption"
  type        = string
}

variable "master_ipv4_cidr" {
  description = "CIDR for the GKE control plane (must be /28, unique per cluster)"
  type        = string
  default     = "172.16.0.0/28"
}

variable "release_channel" {
  description = "GKE release channel: RAPID, REGULAR, or STABLE"
  type        = string
  default     = "REGULAR"
}

variable "deletion_protection" {
  description = "Prevent accidental cluster deletion"
  type        = bool
  default     = false
}

variable "node_disk_size_gb" {
  description = "Boot disk size in GB for all nodes"
  type        = number
  default     = 100
}

variable "node_service_account" {
  description = "Service account email for GKE nodes. Leave null to create one automatically."
  type        = string
  default     = null
}

# ── System node pool ──────────────────────────────────────────────────────────

variable "system_node_machine_type" {
  type    = string
  default = "n2-standard-2"
}

variable "system_node_min" {
  type    = number
  default = 1
}

variable "system_node_max" {
  type    = number
  default = 3
}

# ── User node pool ────────────────────────────────────────────────────────────

variable "user_node_machine_type" {
  description = "Machine type for user nodes (memory-optimised for PostgreSQL)"
  type        = string
  default     = "n2-highmem-4"
}

variable "user_node_min" {
  type    = number
  default = 1
}

variable "user_node_max" {
  type    = number
  default = 5
}

variable "labels" {
  type    = map(string)
  default = {}
}
