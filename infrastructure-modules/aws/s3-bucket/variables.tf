variable "name" {
  description = "Bucket name (must be globally unique)"
  type        = string
}

variable "versioning_enabled" {
  description = "Keep prior object versions — the recovery path for accidental deletes and ransomware"
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Days before superseded versions are purged"
  type        = number
  default     = 90
}

variable "static_website" {
  description = "Configure the bucket as a CDN origin for a static site"
  type        = bool
  default     = false
}

variable "cors_allowed_origins" {
  description = "Origins permitted by CORS. Never use ['*'] for anything authenticated."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default     = {}
}
