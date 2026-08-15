# azure/vnet

Virtual network with per-subnet NSGs, NAT gateway egress, and diagnostics.

## Security defaults

- **Deny-all inbound NSG rule** at priority 4096 on every subnet, with an
  intra-VNet allow above it. Anything reachable from outside is an explicit,
  reviewed addition.
- **NAT gateway egress** across three zones, so outbound traffic leaves from a
  known, allowlistable IP and instances need no public addresses.
- **NSG diagnostics** to Log Analytics when a workspace is supplied.
- **Private endpoint network policies enabled**, keeping private endpoints as
  the path to PaaS services.

## Usage

```hcl
module "vnet" {
  source = "../../infrastructure-modules/azure/vnet"

  name                = "platform-prod"
  resource_group_name = azurerm_resource_group.this.name
  location            = "southeastasia"
  address_space       = ["10.40.0.0/16"]

  subnets = {
    aks = {
      address_prefixes  = ["10.40.0.0/20"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    data = {
      address_prefixes = ["10.40.16.0/24"]
    }
  }

  tags = { environment = "prod" }
}
```
