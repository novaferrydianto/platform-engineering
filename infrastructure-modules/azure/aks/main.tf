locals {
  tags = merge(var.tags, { ManagedBy = "opentofu" })
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = var.name
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Standard"
  tags                = local.tags

  private_cluster_enabled           = var.private_cluster_enabled
  role_based_access_control_enabled = true
  local_account_disabled            = true
  automatic_upgrade_channel         = "patch"
  node_os_upgrade_channel           = "NodeImage"
  image_cleaner_enabled             = true
  image_cleaner_interval_hours      = 48
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  azure_policy_enabled              = true

  # `az aks command invoke` bypasses network restrictions on a private cluster —
  # a private API server with run_command on is not actually private.
  run_command_enabled              = false
  http_application_routing_enabled = false
  open_service_mesh_enabled        = false

  node_provisioning_profile {
    mode = "Manual"
  }

  default_node_pool {
    name                         = "system"
    vm_size                      = var.default_node_pool.vm_size
    vnet_subnet_id               = var.subnet_id
    os_disk_size_gb              = var.default_node_pool.os_disk_gb
    os_disk_type                 = "Managed"
    auto_scaling_enabled         = true
    min_count                    = var.default_node_pool.min_count
    max_count                    = var.default_node_pool.max_count
    only_critical_addons_enabled = true
    zones                        = ["1", "2", "3"]
    max_pods                     = 50

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # Entra ID groups are the only path to cluster admin; local accounts are off.
  azure_active_directory_role_based_access_control {
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    network_data_plane  = "cilium"
    load_balancer_sku   = "standard"
    outbound_type       = "userAssignedNATGateway"
    service_cidr        = "172.16.0.0/16"
    dns_service_ip      = "172.16.0.10"
  }

  dynamic "api_server_access_profile" {
    for_each = var.private_cluster_enabled ? [] : [1]

    content {
      authorized_ip_ranges = var.authorized_ip_ranges
    }
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  microsoft_defender {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != "" ? [1] : []

    content {
      log_analytics_workspace_id      = var.log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = true
    }
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "18:00"
    utc_offset  = "+00:00"
  }

  lifecycle {
    ignore_changes = [kubernetes_version] # patch upgrades are applied by the upgrade channel
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each = var.user_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  vnet_subnet_id        = var.subnet_id
  os_disk_size_gb       = each.value.os_disk_gb
  auto_scaling_enabled  = true
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  priority              = each.value.spot ? "Spot" : "Regular"
  eviction_policy       = each.value.spot ? "Delete" : null
  spot_max_price        = each.value.spot ? -1 : null
  node_labels           = each.value.labels
  zones                 = ["1", "2", "3"]
  max_pods              = 50
  tags                  = local.tags

  upgrade_settings {
    max_surge = "33%"
  }
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.log_analytics_workspace_id != "" ? 1 : 0

  name                       = "${var.name}-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "guard"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
