variable "name" {
  description = "Cluster name"
  type        = string
}

variable "project_id" {
  description = "GCP project"
  type        = string
}

variable "region" {
  description = "Region for a regional cluster"
  type        = string
}

variable "network_name" {
  description = "VPC network hosting the cluster"
  type        = string
}

variable "subnet_name" {
  description = "Subnetwork hosting the nodes"
  type        = string
}

variable "pods_range_name" {
  description = "Secondary range name for pods"
  type        = string
}

variable "services_range_name" {
  description = "Secondary range name for services"
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "RFC1918 /28 for the private control plane"
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_networks" {
  description = "CIDRs allowed to reach the control plane. Empty means VPC-internal access only."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []

  validation {
    condition     = alltrue([for n in var.master_authorized_networks : n.cidr_block != "0.0.0.0/0"])
    error_message = "0.0.0.0/0 is not an acceptable control plane allowlist."
  }
}

variable "release_channel" {
  description = "GKE release channel driving automatic upgrades"
  type        = string
  default     = "REGULAR"
}

variable "node_pools" {
  description = "Node pools keyed by name"
  type = map(object({
    machine_type = string
    min_count    = number
    max_count    = number
    disk_size_gb = optional(number, 50)
    spot         = optional(bool, false)
    labels       = optional(map(string), {})
  }))
  default = {}
}

variable "labels" {
  description = "Labels applied to the cluster"
  type        = map(string)
  default     = {}
}
