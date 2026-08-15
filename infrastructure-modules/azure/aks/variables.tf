variable "name" {
  description = "Cluster name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the cluster in"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "kubernetes_version" {
  description = "AKS control plane version"
  type        = string
  default     = "1.31"
}

variable "subnet_id" {
  description = "Subnet hosting the node pools"
  type        = string
}

variable "private_cluster_enabled" {
  description = "Keep the API server on a private endpoint"
  type        = bool
  default     = true
}

variable "authorized_ip_ranges" {
  description = "CIDRs allowed to reach a public API server. Ignored when the cluster is private."
  type        = list(string)
  default     = []

  validation {
    condition     = !contains(var.authorized_ip_ranges, "0.0.0.0/0")
    error_message = "0.0.0.0/0 is not an acceptable API server allowlist."
  }
}

variable "default_node_pool" {
  description = "System node pool"
  type = object({
    vm_size    = string
    min_count  = number
    max_count  = number
    os_disk_gb = optional(number, 64)
  })
  default = {
    vm_size   = "Standard_D4s_v5"
    min_count = 3
    max_count = 6
  }
}

variable "user_node_pools" {
  description = "Additional workload node pools keyed by name"
  type = map(object({
    vm_size    = string
    min_count  = number
    max_count  = number
    os_disk_gb = optional(number, 64)
    spot       = optional(bool, false)
    labels     = optional(map(string), {})
  }))
  default = {}
}

variable "log_analytics_workspace_id" {
  description = "Workspace for container insights and audit logs. Empty disables monitoring."
  type        = string
  default     = ""
}

variable "admin_group_object_ids" {
  description = "Entra ID group object IDs granted cluster admin. Local accounts are disabled, so this must not be empty."
  type        = list(string)

  validation {
    condition     = length(var.admin_group_object_ids) > 0
    error_message = "At least one Entra ID admin group is required; local accounts are disabled."
  }
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default     = {}
}
