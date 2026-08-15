variable "chart_version" {
  description = "Kyverno Helm chart version"
  type        = string
  default     = "3.8.2"
}

variable "namespace" {
  description = "Namespace Kyverno runs in"
  type        = string
  default     = "kyverno"
}

variable "replicas" {
  description = "Replicas per Kyverno controller. Keep >= 2 outside dev — a single admission controller replica is a cluster-wide single point of failure."
  type        = number
  default     = 3

  validation {
    condition     = var.replicas >= 1
    error_message = "At least one replica is required."
  }
}

variable "excluded_namespaces" {
  description = "Extra namespaces exempt from admission control, beyond Kyverno's own and kube-system."
  type        = list(string)
  default     = []
}

variable "resources" {
  description = "Admission controller container resources"
  type = object({
    requests = optional(map(string), { cpu = "100m", memory = "256Mi" })
    limits   = optional(map(string), { memory = "512Mi" })
  })
  default = {}
}

variable "init_resources" {
  description = "Init container resources"
  type = object({
    requests = optional(map(string), { cpu = "10m", memory = "64Mi" })
    limits   = optional(map(string), { memory = "128Mi" })
  })
  default = {}
}
