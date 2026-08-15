variable "name" {
  description = "Network name prefix"
  type        = string
}

variable "project_id" {
  description = "GCP project"
  type        = string
}

variable "region" {
  description = "Region for the subnet and Cloud NAT"
  type        = string
}

variable "subnet_cidr" {
  description = "Primary CIDR for the subnet"
  type        = string
}

variable "pods_cidr" {
  description = "Secondary range for GKE pods"
  type        = string
  default     = ""
}

variable "services_cidr" {
  description = "Secondary range for GKE services"
  type        = string
  default     = ""
}

variable "enable_cloud_nat" {
  description = "Provide outbound internet access for instances without external IPs"
  type        = bool
  default     = true
}

variable "flow_logs_sampling" {
  description = "Fraction of flows logged (0.0-1.0)"
  type        = number
  default     = 0.5
}
