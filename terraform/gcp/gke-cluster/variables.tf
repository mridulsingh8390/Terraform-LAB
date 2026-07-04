variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "prefix" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

# ── VPC ───────────────────────────────────────────────────────────────────────

variable "vpc_name" {
  type = string
}

variable "gke_subnet_cidr" {
  type    = string
  default = "10.0.0.0/20"
}

variable "pods_cidr" {
  type    = string
  default = "10.16.0.0/14"
}

variable "services_cidr" {
  type    = string
  default = "10.20.0.0/20"
}

variable "master_ipv4_cidr" {
  description = "Control plane CIDR (/28, must be unique per cluster)"
  type        = string
  default     = "172.16.0.0/28"
}

# ── Filestore ─────────────────────────────────────────────────────────────────

variable "filestore_zone" {
  description = "Zone for the Filestore instance (must be in var.region)"
  type        = string
}

variable "filestore_tier" {
  type    = string
  default = "BASIC_SSD"
}

variable "filestore_capacity_gb" {
  description = "Minimum 2660 GB for BASIC_SSD"
  type        = number
  default     = 2660
}

variable "filestore_reserved_cidr" {
  type    = string
  default = "10.100.0.0/29"
}

variable "k8s_manifest_output_path" {
  type    = string
  default = "./k8s-manifests"
}

# ── GKE ───────────────────────────────────────────────────────────────────────

variable "cluster_name" {
  type = string
}

variable "release_channel" {
  type    = string
  default = "REGULAR"
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "node_disk_size_gb" {
  type    = number
  default = 100
}

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

variable "user_node_machine_type" {
  description = "Memory-optimised machine type for PostgreSQL pods"
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
