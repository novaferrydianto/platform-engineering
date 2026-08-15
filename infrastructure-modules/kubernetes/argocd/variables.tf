variable "chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "10.3.3"
}

variable "namespace" {
  description = "Namespace Argo CD runs in"
  type        = string
  default     = "argocd"
}

variable "domain" {
  description = "Hostname Argo CD is served on"
  type        = string
}

variable "admin_enabled" {
  description = "Enable the built-in local admin account. Off by default — it is a shared credential with no audit trail; use SSO instead."
  type        = bool
  default     = false
}

variable "dex_enabled" {
  description = "Enable the bundled Dex OIDC connector. Required if SSO federates through Dex rather than a direct OIDC provider."
  type        = bool
  default     = false
}

variable "notifications_enabled" {
  description = "Enable the notifications controller"
  type        = bool
  default     = false
}

variable "server_behind_tls_ingress" {
  description = "Run the API server without its own TLS because an ingress terminates it. Only set true when an ingress actually fronts Argo CD."
  type        = bool
  default     = false
}

variable "application_namespaces" {
  description = "Namespaces permitted to hold Application resources, beyond Argo CD's own."
  type        = list(string)
  default     = []
}

variable "rbac_policy_csv" {
  description = "Additional RBAC rules in Argo CD's CSV format. The default policy is readonly; grant more only to named groups."
  type        = string
  default     = ""
}

variable "replicas" {
  description = "Replicas for the server, repo server, and applicationset controller"
  type        = number
  default     = 2
}

variable "controller_replicas" {
  description = "Application controller replicas. Sharding requires matching replica count."
  type        = number
  default     = 1
}

variable "controller_resources" {
  description = "Application controller resources"
  type = object({
    requests = optional(map(string), { cpu = "250m", memory = "512Mi" })
    limits   = optional(map(string), { memory = "2Gi" })
  })
  default = {}
}
