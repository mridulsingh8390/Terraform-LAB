variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "prefix" {
  description = "Short prefix used to name child resources (e.g. 'aks-dev')"
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

variable "vnet_cidr" {
  description = "Address space for the VNet (e.g. '10.0.0.0/8')"
  type        = string
  default     = "10.0.0.0/8"
}

variable "aks_system_subnet_cidr" {
  description = "CIDR for the AKS system node pool subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "aks_user_subnet_cidr" {
  description = "CIDR for the AKS user node pool subnet (runs app + PostgreSQL pods)"
  type        = string
  default     = "10.0.16.0/20"
}

variable "storage_subnet_cidr" {
  description = "CIDR for the storage subnet (Azure Files endpoint)"
  type        = string
  default     = "10.0.32.0/24"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
