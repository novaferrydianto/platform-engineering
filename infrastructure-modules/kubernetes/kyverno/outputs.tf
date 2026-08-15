output "namespace" {
  description = "Namespace Kyverno is installed in"
  value       = helm_release.kyverno.namespace
}

output "chart_version" {
  description = "Installed chart version"
  value       = helm_release.kyverno.version
}
