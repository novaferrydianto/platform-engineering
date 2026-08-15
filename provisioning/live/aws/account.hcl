locals {
  cloud  = "aws"
  region = "ap-southeast-1"

  # Bucket holding OpenTofu state, created by provisioning/bootstrap/aws.
  # Deliberately a loud placeholder rather than a plausible-looking name: a name
  # that looks real fails later, with a confusing "bucket does not exist".
  # scripts/check-placeholders.sh fails while this is unset.
  state_bucket = "REPLACE_WITH_STATE_BUCKET"

  tags = {
    Owner   = "platform-team"
    Project = "internal-developer-platform"
  }
}
