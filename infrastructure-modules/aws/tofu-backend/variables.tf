variable "bucket_name" {
  description = "Globally unique S3 bucket name for OpenTofu remote state"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket names must be lowercase, 3-63 characters, and start and end alphanumerically."
  }
}

variable "noncurrent_version_retention_days" {
  description = "Days a superseded state version is kept before expiry"
  type        = number
  default     = 90

  validation {
    condition     = var.noncurrent_version_retention_days >= 30
    error_message = "Keep at least 30 days of state history; shorter windows make real incidents unrecoverable."
  }
}

variable "noncurrent_versions_kept" {
  description = "Minimum superseded versions retained regardless of age"
  type        = number
  default     = 20
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default     = {}
}
