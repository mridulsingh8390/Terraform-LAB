variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.31"
}

variable "subnet_ids" {
  description = "Private subnet IDs for EKS nodes"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "Security group ID for EKS nodes"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for etcd envelope encryption and EBS volume encryption"
  type        = string
}

variable "endpoint_public_access" {
  description = "Allow public access to the EKS API endpoint"
  type        = bool
  default     = true
}

variable "node_volume_size_gb" {
  description = "EBS root volume size in GB for all nodes"
  type        = number
  default     = 50
}

variable "enable_system_node_group" {
  description = "Create a dedicated system node group with CriticalAddonsOnly taint. Set false for dev/lab to use a single user node pool for all workloads."
  type        = bool
  default     = false
}

# ── System node group ─────────────────────────────────────────────────────────

variable "system_node_instance_types" {
  description = "EC2 instance types for system nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "system_node_desired" {
  type    = number
  default = 2
}

variable "system_node_min" {
  type    = number
  default = 1
}

variable "system_node_max" {
  type    = number
  default = 3
}

# ── User node group ───────────────────────────────────────────────────────────

variable "user_node_instance_types" {
  description = "EC2 instance types for user nodes (memory-optimised for PostgreSQL)"
  type        = list(string)
  default     = ["r5.large"]
}

variable "user_node_desired" {
  type    = number
  default = 2
}

variable "user_node_min" {
  type    = number
  default = 1
}

variable "user_node_max" {
  type    = number
  default = 5
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
