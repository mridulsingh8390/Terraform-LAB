variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "prefix" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "kms_deletion_window_days" {
  type    = number
  default = 30
}

variable "efs_throughput_mode" {
  type    = string
  default = "elastic"
}

variable "efs_performance_mode" {
  type    = string
  default = "generalPurpose"
}

variable "k8s_manifest_output_path" {
  type    = string
  default = "./k8s-manifests"
}

variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.31"
}

variable "endpoint_public_access" {
  type    = bool
  default = true
}

variable "node_volume_size_gb" {
  type    = number
  default = 50
}

variable "enable_system_node_group" {
  description = "Create a dedicated system node group. Set false for dev to use single user pool."
  type        = bool
  default     = false
}

variable "system_node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
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

variable "user_node_instance_types" {
  type    = list(string)
  default = ["r5.large"]
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
