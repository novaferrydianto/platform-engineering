variable "name" {
  description = "Instance name"
  type        = string
}

variable "project_id" {
  description = "GCP project"
  type        = string
}

variable "region" {
  description = "Instance region"
  type        = string
}

variable "database_version" {
  description = "Cloud SQL engine version"
  type        = string
  default     = "POSTGRES_16"
}

variable "tier" {
  description = "Machine tier"
  type        = string
  default     = "db-custom-2-7680"
}

variable "disk_size_gb" {
  description = "Initial disk size"
  type        = number
  default     = 50
}

variable "database_name" {
  description = "Initial database created on the instance"
  type        = string
}

variable "network_id" {
  description = "VPC network for the private IP connection"
  type        = string
}

variable "availability_type" {
  description = "REGIONAL for a cross-zone standby, ZONAL for single zone"
  type        = string
  default     = "REGIONAL"
}

variable "backup_retention_count" {
  description = "Number of automated backups retained"
  type        = number
  default     = 30

  validation {
    condition     = var.backup_retention_count >= 7
    error_message = "Retain at least 7 backups."
  }
}

variable "deletion_protection" {
  description = "Block accidental deletion"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels applied to the instance"
  type        = map(string)
  default     = {}
}
