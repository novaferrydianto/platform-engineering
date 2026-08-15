# Bootstrap root for the AWS remote state backend.
#
# This is the only configuration in the repo that starts with LOCAL state, for
# an unavoidable reason: it creates the bucket that every other unit stores its
# state in, so that bucket cannot itself be stored there yet. After the first
# apply, state is migrated into the bucket it just made (see README).
#
# The provider block is inline because .gitignore excludes provider.tf —
# Terragrunt generates that file for units under provisioning/live/, and this
# root deliberately does not use Terragrunt.

terraform {
  required_version = ">= 1.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.60"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      ManagedBy = "opentofu"
      Purpose   = "tofu-remote-state"
    }
  }
}

variable "region" {
  description = "Region the state bucket is created in"
  type        = string
  default     = "ap-southeast-1"
}

variable "bucket_name" {
  description = "Globally unique state bucket name. Must match state_bucket in provisioning/live/aws/account.hcl."
  type        = string
}

module "tofu_backend" {
  source = "../../../infrastructure-modules/aws/tofu-backend"

  bucket_name = var.bucket_name
}

output "bucket_name" {
  description = "Set this as state_bucket in provisioning/live/aws/account.hcl"
  value       = module.tofu_backend.bucket_name
}

output "backend_block" {
  description = "Paste into backend.tf to migrate this root's own state into the bucket"
  value       = module.tofu_backend.backend_block
}
