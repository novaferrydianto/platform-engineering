variable "bucket_name" {
  description = "Globally unique GCS bucket name for OpenTofu remote state"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket names must be lowercase, 3-63 characters, and start and end alphanumerically."
  }
}

variable "project_id" {
  description = "Project the state bucket lives in"
  type        = string
}

variable "location" {
  description = "Bucket location. A multi-region survives a single region outage, which is the point for state."
  type        = string
  default     = "ASIA"
}

variable "kms_key_name" {
  description = "Customer-managed encryption key. Null uses Google-managed encryption, which is still encrypted at rest."
  type        = string
  default     = null
}

variable "noncurrent_version_retention_days" {
  description = "Days a superseded state version is kept before deletion"
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

variable "labels" {
  description = "Labels applied to the bucket"
  type        = map(string)
  default     = {}
}
