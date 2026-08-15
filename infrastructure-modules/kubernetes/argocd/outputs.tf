output "namespace" {
  description = "Namespace Argo CD is installed in"
  value       = helm_release.argocd.namespace
}

output "chart_version" {
  description = "Installed chart version"
  value       = helm_release.argocd.version
}

output "server_url" {
  description = "URL Argo CD is served on"
  value       = "https://${var.domain}"
}
