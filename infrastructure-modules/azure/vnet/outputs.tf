output "vnet_id" {
  description = "Virtual network identifier"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Virtual network name"
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Subnet identifiers keyed by subnet name"
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "nsg_ids" {
  description = "Network security group identifiers keyed by subnet name"
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}

output "nat_gateway_public_ip" {
  description = "Outbound public IP — use it when allowlisting egress at a third party"
  value       = var.enable_nat_gateway ? azurerm_public_ip.nat[0].ip_address : null
}
