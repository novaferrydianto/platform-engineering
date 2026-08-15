output "cluster_name" {
  description = "Cluster name"
  value       = google_container_cluster.this.name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = google_container_cluster.this.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64 CA bundle for the API server"
  value       = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "workload_identity_pool" {
  description = "Workload Identity pool — bind Kubernetes service accounts against it"
  value       = "${var.project_id}.svc.id.goog"
}

output "node_service_account_email" {
  description = "Least-privilege service account attached to nodes"
  value       = google_service_account.nodes.email
}
