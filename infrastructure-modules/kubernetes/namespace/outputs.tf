output "name" {
  description = "Namespace name"
  value       = kubernetes_namespace_v1.this.metadata[0].name
}

output "pod_security_standard" {
  description = "Pod Security Standard enforced on the namespace"
  value       = var.pod_security_standard
}
