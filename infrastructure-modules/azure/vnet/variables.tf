variable "name" {
  description = "Virtual network name prefix"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create resources in"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "subnets" {
  description = "Subnets keyed by name"
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = list(string)
    }))
  }))
}

variable "enable_nat_gateway" {
  description = "Provide deterministic outbound egress via a NAT gateway"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Workspace for NSG flow logs and diagnostics. Empty disables diagnostic settings."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default     = {}
}
