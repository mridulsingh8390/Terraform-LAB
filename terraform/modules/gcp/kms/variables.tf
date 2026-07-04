variable "prefix" {
  type = string
}

variable "project_id" {
  type = string
}

variable "location" {
  description = "KMS keyring location — must match the region of resources using it"
  type        = string
}
