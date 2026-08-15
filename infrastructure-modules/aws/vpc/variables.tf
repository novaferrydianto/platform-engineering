variable "name" {
  description = "Name prefix for all VPC resources"
  type        = string
}

variable "cidr_block" {
  description = "IPv4 CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.cidr_block))
    error_message = "cidr_block must be a valid IPv4 CIDR."
  }
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones are required for high availability."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per availability zone"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per availability zone. Empty disables public networking entirely."
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Provision NAT gateways so private subnets reach the internet outbound"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway for all AZs. Cheaper, but a single AZ failure removes egress. Non-prod only."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Send VPC flow logs to CloudWatch for network forensics"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Retention for the flow log group"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default     = {}
}
