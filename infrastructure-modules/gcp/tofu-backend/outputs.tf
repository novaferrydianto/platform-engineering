output "bucket_name" {
  description = "State bucket name — this is the value account.hcl's state_bucket must hold"
  value       = google_storage_bucket.state.name
}

output "bucket_url" {
  description = "State bucket URL"
  value       = google_storage_bucket.state.url
}

output "backend_block" {
  description = "Ready-to-paste backend configuration for this bucket"
  value       = <<-HCL
    terraform {
      backend "gcs" {
        bucket = "${google_storage_bucket.state.name}"
        prefix = "bootstrap"
      }
    }
  HCL
}
