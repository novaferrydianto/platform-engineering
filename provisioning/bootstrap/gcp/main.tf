# Bootstrap root for the GCP remote state backend. See ../aws/main.tf for why
# this starts with local state, and ../README.md for the migration procedure.

terraform {
  required_version = ">= 1.12"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.44"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  description = "Project the state bucket lives in"
  type        = string
}

variable "region" {
  description = "Default provider region"
  type        = string
  default     = "asia-southeast1"
}

variable "location" {
  description = "Bucket location. A multi-region survives a single region outage, which is the point for state."
  type        = string
  default     = "ASIA"
}

variable "bucket_name" {
  description = "Globally unique state bucket name. Must match state_bucket in provisioning/live/gcp/account.hcl."
  type        = string
}

module "tofu_backend" {
  source = "../../../infrastructure-modules/gcp/tofu-backend"

  bucket_name = var.bucket_name
  project_id  = var.project_id
  location    = var.location
}

output "bucket_name" {
  description = "Set this as state_bucket in provisioning/live/gcp/account.hcl"
  value       = module.tofu_backend.bucket_name
}

output "backend_block" {
  description = "Paste into backend.tf to migrate this root's own state into the bucket"
  value       = module.tofu_backend.backend_block
}
