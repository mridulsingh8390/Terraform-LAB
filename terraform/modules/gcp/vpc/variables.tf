variable "vpc_name" {
  type = string
}

variable "prefix" {
  type = string
}

variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "gke_subnet_cidr" {
  description = "Primary CIDR for the GKE subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary CIDR for pod IPs"
  type        = string
  default     = "10.16.0.0/14"
}

variable "services_cidr" {
  description = "Secondary CIDR for service IPs"
  type        = string
  default     = "10.20.0.0/20"
}

variable "master_ipv4_cidr" {
  description = "CIDR for the GKE master (control plane) — used in firewall rules"
  type        = string
  default     = "172.16.0.0/28"
}
