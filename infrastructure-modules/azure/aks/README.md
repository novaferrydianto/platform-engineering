# azure/aks

Private AKS cluster with Entra ID RBAC, workload identity, and Cilium network policy.

## Security defaults

- **Private API server** (`private_cluster_enabled = true`). If you expose it,
  `authorized_ip_ranges` rejects `0.0.0.0/0` by variable validation.
- **`run_command_enabled = false`** — `az aks command invoke` runs commands
  through the control plane and bypasses network restrictions, so leaving it on
  makes a "private" cluster reachable anyway.
- **Local accounts disabled**; cluster admin comes only from the Entra ID groups
  in `admin_group_object_ids`, which must be non-empty.
- **Azure RBAC for Kubernetes authorization** plus Azure Policy admission.
- **Workload identity + OIDC issuer**, so pods federate to Entra ID identities
  instead of holding secrets.
- **Cilium network policy** enforced on an overlay data plane.
- **Microsoft Defender for Containers** and audit log diagnostics wired to Log
  Analytics.
- **Image cleaner** removes unused, potentially vulnerable images every 48h.
- **Patch auto-upgrade** with a weekend maintenance window; system pool tainted
  `only_critical_addons_enabled` so workloads land on user pools.

## Usage

```hcl
module "aks" {
  source = "../../infrastructure-modules/azure/aks"

  name                       = "platform-prod"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = "southeastasia"
  subnet_id                  = module.vnet.subnet_ids["aks"]
  admin_group_object_ids     = ["00000000-0000-0000-0000-000000000000"]
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  user_node_pools = {
    apps = {
      vm_size   = "Standard_D4s_v5"
      min_count = 3
      max_count = 10
    }
  }

  tags = { environment = "prod" }
}
```

`outbound_type = "userAssignedNATGateway"` expects the subnet to already have a
NAT gateway attached — the `azure/vnet` module provides one by default.
