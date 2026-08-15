output "bucket_name" {
  description = "State bucket name — this is the value account.hcl's state_bucket must hold"
  value       = aws_s3_bucket.state.id
}

output "bucket_arn" {
  description = "State bucket ARN"
  value       = aws_s3_bucket.state.arn
}

output "kms_key_arn" {
  description = "KMS key encrypting the state"
  value       = aws_kms_key.state.arn
}

output "backend_block" {
  description = "Ready-to-paste backend configuration for this bucket"
  value       = <<-HCL
    terraform {
      backend "s3" {
        bucket       = "${aws_s3_bucket.state.id}"
        key          = "bootstrap/tofu.tfstate"
        region       = "${data.aws_region.current.region}"
        encrypt      = true
        kms_key_id   = "${aws_kms_key.state.arn}"
        use_lockfile = true
      }
    }
  HCL
}

data "aws_region" "current" {}
