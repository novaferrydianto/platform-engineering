output "instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.this.name
}

output "connection_name" {
  description = "Connection name for the Cloud SQL Auth Proxy"
  value       = google_sql_database_instance.this.connection_name
}

output "private_ip_address" {
  description = "Private IP of the instance"
  value       = google_sql_database_instance.this.private_ip_address
}

output "database_name" {
  description = "Initial database name"
  value       = google_sql_database.this.name
}

output "admin_password_secret_id" {
  description = "Secret Manager secret holding the admin password"
  value       = google_secret_manager_secret.admin.secret_id
}
