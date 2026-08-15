locals {
  labels = merge(var.labels, { managed_by = "opentofu", purpose = "tofu-remote-state" })
}

resource "google_storage_bucket" "state" {
  name     = var.bucket_name
  project  = var.project_id
  location = var.location

  # Uniform access removes per-object ACLs, so bucket IAM is the single place
  # access is decided rather than one of two.
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  storage_class = "STANDARD"
  labels        = local.labels

  # Versioning is what makes a corrupted or truncated state file recoverable.
  versioning {
    enabled = true
  }

  dynamic "encryption" {
    for_each = var.kms_key_name != null ? [1] : []

    content {
      default_kms_key_name = var.kms_key_name
    }
  }

  # State history accumulates a version per apply; without expiry the bucket
  # grows without bound.
  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      days_since_noncurrent_time = var.noncurrent_version_retention_days
      num_newer_versions         = var.noncurrent_versions_kept
      with_state                 = "ARCHIVED"
    }
  }

  lifecycle {
    # Losing this bucket means losing the record of every resource the platform
    # manages. Removing this guard should be a deliberate, separate commit.
    prevent_destroy = true
  }
}
