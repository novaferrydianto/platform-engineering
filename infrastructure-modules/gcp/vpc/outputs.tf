output "network_id" {
  description = "VPC network identifier"
  value       = google_compute_network.this.id
}

output "network_name" {
  description = "VPC network name"
  value       = google_compute_network.this.name
}

output "subnet_id" {
  description = "Subnetwork identifier"
  value       = google_compute_subnetwork.this.id
}

output "subnet_name" {
  description = "Subnetwork name"
  value       = google_compute_subnetwork.this.name
}

output "pods_range_name" {
  description = "Secondary range name for GKE pods, empty when not configured"
  value       = local.has_secondary_ranges ? "pods" : ""
}

output "services_range_name" {
  description = "Secondary range name for GKE services, empty when not configured"
  value       = local.has_secondary_ranges ? "services" : ""
}
