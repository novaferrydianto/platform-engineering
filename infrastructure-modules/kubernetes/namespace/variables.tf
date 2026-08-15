variable "name" {
  description = "Namespace name"
  type        = string
}

variable "labels" {
  description = "Additional labels"
  type        = map(string)
  default     = {}
}

variable "pod_security_standard" {
  description = "Pod Security Standard enforced on the namespace"
  type        = string
  default     = "restricted"

  validation {
    condition     = contains(["restricted", "baseline"], var.pod_security_standard)
    error_message = "Use restricted, or baseline where a workload genuinely cannot comply. privileged is not permitted."
  }
}

variable "resource_quota" {
  description = "Aggregate resource ceiling for the namespace. Null disables the quota."
  type = object({
    requests_cpu    = string
    requests_memory = string
    limits_cpu      = string
    limits_memory   = string
    pods            = optional(string, "100")
  })
  default = null
}

variable "default_container_limits" {
  description = "LimitRange defaults applied to containers that declare none"
  type = object({
    default_cpu            = optional(string, "500m")
    default_memory         = optional(string, "512Mi")
    default_request_cpu    = optional(string, "50m")
    default_request_memory = optional(string, "128Mi")
    max_cpu                = optional(string, "4")
    max_memory             = optional(string, "8Gi")
  })
  default = {}
}

variable "allowed_ingress_namespaces" {
  description = "Namespaces allowed to reach pods here. Empty means only same-namespace traffic."
  type        = list(string)
  default     = []
}
