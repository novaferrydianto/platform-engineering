locals {
  is_postgres = startswith(var.database_version, "POSTGRES")
}

resource "google_sql_database_instance" "this" {
  name                = var.name
  project             = var.project_id
  region              = var.region
  database_version    = var.database_version
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_size         = var.disk_size_gb
    disk_type         = "PD_SSD"
    disk_autoresize   = true
    user_labels       = var.labels

    ip_configuration {
      # Private IP only — the instance has no public address at all.
      ipv4_enabled                                  = false
      private_network                               = var.network_id
      ssl_mode                                      = "ENCRYPTED_ONLY"
      enable_private_path_for_google_cloud_services = true
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "17:00"
      point_in_time_recovery_enabled = local.is_postgres
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = var.backup_retention_count
        retention_unit   = "COUNT"
      }
    }

    maintenance_window {
      day          = 7
      hour         = 18
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = true
      record_application_tags = false
      record_client_address   = false
    }

    dynamic "database_flags" {
      for_each = local.is_postgres ? [1] : []

      content {
        name  = "log_connections"
        value = "on"
      }
    }

    dynamic "database_flags" {
      for_each = local.is_postgres ? [1] : []

      content {
        name  = "log_disconnections"
        value = "on"
      }
    }
  }
}

resource "google_sql_database" "this" {
  name     = var.database_name
  project  = var.project_id
  instance = google_sql_database_instance.this.name
}

# Applications authenticate with IAM through the Cloud SQL Auth Proxy. This
# built-in user exists for administrative access only; its password is generated
# here and written to Secret Manager rather than surfaced as an output.
resource "random_password" "admin" {
  length      = 32
  special     = true
  min_lower   = 4
  min_upper   = 4
  min_numeric = 4
  min_special = 4
}

resource "google_sql_user" "admin" {
  name     = "dbadmin"
  project  = var.project_id
  instance = google_sql_database_instance.this.name
  password = random_password.admin.result
}

resource "google_secret_manager_secret" "admin" {
  secret_id = "${var.name}-admin-password"
  project   = var.project_id
  labels    = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "admin" {
  secret      = google_secret_manager_secret.admin.id
  secret_data = random_password.admin.result
}
