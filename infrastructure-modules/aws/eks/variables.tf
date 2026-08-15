variable "name" {
  description = "Cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "EKS control plane version"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC to place the cluster in"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the control plane ENIs and worker nodes"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "EKS requires subnets in at least two availability zones."
  }
}

variable "endpoint_public_access" {
  description = "Expose the Kubernetes API to the internet. Off by default — reach it over the VPC or a bastion."
  type        = bool
  default     = false
}

variable "endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach a public API endpoint. Never 0.0.0.0/0 in production."
  type        = list(string)
  default     = []

  validation {
    condition     = !contains(var.endpoint_public_access_cidrs, "0.0.0.0/0")
    error_message = "0.0.0.0/0 is not an acceptable API endpoint allowlist; scope it to known networks."
  }
}

variable "enabled_log_types" {
  description = "Control plane log types shipped to CloudWatch"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "Retention for control plane logs"
  type        = number
  default     = 90
}

variable "node_groups" {
  description = "Managed node groups keyed by name"
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    capacity_type  = optional(string, "ON_DEMAND")
    disk_size      = optional(number, 50)
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default     = {}
}
