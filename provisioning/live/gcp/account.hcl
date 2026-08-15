locals {
  cloud      = "gcp"
  region     = "asia-southeast1"
  project_id = "REPLACE_WITH_GCP_PROJECT"

  # GCS bucket holding OpenTofu state, created by provisioning/bootstrap/gcp.
  # Loud placeholders on purpose — scripts/check-placeholders.sh fails while
  # either of these is unset, rather than letting a plausible name reach a
  # `terragrunt apply`.
  state_bucket = "REPLACE_WITH_STATE_BUCKET"

  labels = {
    owner   = "platform-team"
    project = "internal-developer-platform"
  }
}
