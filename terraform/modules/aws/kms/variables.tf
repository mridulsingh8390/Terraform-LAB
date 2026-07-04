variable "prefix" {
  description = "Short prefix used to name the KMS key and alias"
  type        = string
}

variable "deletion_window_in_days" {
  description = "Waiting period (7-30 days) before KMS key is deleted after scheduled deletion"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
