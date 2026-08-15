output "bucket_id" {
  description = "Bucket name"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "Bucket ARN"
  value       = aws_s3_bucket.this.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name — use this as the CDN origin"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "kms_key_arn" {
  description = "KMS key encrypting objects; grant it to any principal reading the bucket"
  value       = aws_kms_key.this.arn
}
