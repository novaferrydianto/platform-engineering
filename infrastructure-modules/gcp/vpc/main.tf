locals {
  has_secondary_ranges = var.pods_cidr != "" && var.services_cidr != ""
}

resource "google_compute_network" "this" {
  name                            = var.name
  project                         = var.project_id
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = false
}

resource "google_compute_subnetwork" "this" {
  name          = "${var.name}-${var.region}"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = var.subnet_cidr

  # Lets instances reach Google APIs over internal addresses instead of the
  # public internet.
  private_ip_google_access = true

  dynamic "secondary_ip_range" {
    for_each = local.has_secondary_ranges ? [1] : []

    content {
      range_name    = "pods"
      ip_cidr_range = var.pods_cidr
    }
  }

  dynamic "secondary_ip_range" {
    for_each = local.has_secondary_ranges ? [1] : []

    content {
      range_name    = "services"
      ip_cidr_range = var.services_cidr
    }
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = var.flow_logs_sampling
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# GCP's implied allow-egress rule is left in place, but ingress is denied
# explicitly at the lowest priority so nothing is reachable by default.
resource "google_compute_firewall" "deny_all_ingress" {
  name      = "${var.name}-deny-all-ingress"
  project   = var.project_id
  network   = google_compute_network.this.name
  direction = "INGRESS"
  priority  = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_internal" {
  name      = "${var.name}-allow-internal"
  project   = var.project_id
  network   = google_compute_network.this.name
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "all"
  }

  source_ranges = compact([var.subnet_cidr, var.pods_cidr, var.services_cidr])

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_router" "this" {
  count = var.enable_cloud_nat ? 1 : 0

  name    = "${var.name}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.this.id
}

resource "google_compute_router_nat" "this" {
  count = var.enable_cloud_nat ? 1 : 0

  name                               = "${var.name}-nat"
  project                            = var.project_id
  region                             = var.region
  router                             = google_compute_router.this[0].name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
