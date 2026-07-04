variable "prefix" {
  type = string
}

variable "project_id" {
  type = string
}

variable "zone" {
  description = "Zone for the Filestore instance (e.g. us-central1-a)"
  type        = string
}

variable "vpc_name" {
  description = "VPC network name for Filestore private access"
  type        = string
}

variable "cmk_id" {
  description = "KMS CryptoKey ID for CMEK encryption of the Filestore instance"
  type        = string
}

variable "tier" {
  description = "Filestore tier: BASIC_HDD, BASIC_SSD, PREMIUM, ENTERPRISE"
  type        = string
  default     = "BASIC_SSD"
}

variable "capacity_gb" {
  description = "Filestore capacity in GB (min 2660 GB for BASIC_SSD)"
  type        = number
  default     = 2660
}

variable "filestore_reserved_cidr" {
  description = "Reserved CIDR for Filestore private IP allocation"
  type        = string
  default     = "10.100.0.0/29"
}

variable "k8s_manifest_output_path" {
  description = "Directory to write the Kubernetes StorageClass YAML into"
  type        = string
  default     = "./k8s-manifests"
}

variable "labels" {
  type    = map(string)
  default = {}
}
