resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.name

    labels = merge(var.labels, {
      "app.kubernetes.io/managed-by" = "opentofu"

      # Pod Security admission is enforced at the namespace, so a workload that
      # violates the standard is rejected rather than merely flagged.
      "pod-security.kubernetes.io/enforce" = var.pod_security_standard
      "pod-security.kubernetes.io/audit"   = var.pod_security_standard
      "pod-security.kubernetes.io/warn"    = var.pod_security_standard
    })
  }
}

# Deny-all baseline. Workload charts add their own NetworkPolicies on top to
# open the specific paths they need.
resource "kubernetes_network_policy_v1" "default_deny" {
  metadata {
    name      = "default-deny-all"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]

    # DNS resolution must survive the deny-all, or nothing in the namespace can
    # resolve anything at all.
    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }

      ports {
        port     = "53"
        protocol = "UDP"
      }

      ports {
        port     = "53"
        protocol = "TCP"
      }
    }

    ingress {
      from {
        pod_selector {}
      }
    }

    dynamic "ingress" {
      for_each = var.allowed_ingress_namespaces

      content {
        from {
          namespace_selector {
            match_labels = {
              "kubernetes.io/metadata.name" = ingress.value
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_resource_quota_v1" "this" {
  count = var.resource_quota != null ? 1 : 0

  metadata {
    name      = "namespace-quota"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = var.resource_quota.requests_cpu
      "requests.memory" = var.resource_quota.requests_memory
      "limits.cpu"      = var.resource_quota.limits_cpu
      "limits.memory"   = var.resource_quota.limits_memory
      "pods"            = var.resource_quota.pods
    }
  }
}

resource "kubernetes_limit_range_v1" "this" {
  metadata {
    name      = "container-defaults"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }

  spec {
    limit {
      type = "Container"

      default = {
        cpu    = var.default_container_limits.default_cpu
        memory = var.default_container_limits.default_memory
      }

      default_request = {
        cpu    = var.default_container_limits.default_request_cpu
        memory = var.default_container_limits.default_request_memory
      }

      max = {
        cpu    = var.default_container_limits.max_cpu
        memory = var.default_container_limits.max_memory
      }
    }
  }
}

# The default ServiceAccount is left without automounted tokens so a pod that
# does not declare one cannot reach the API server.
resource "kubernetes_service_account_v1" "default" {
  metadata {
    name      = "default"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }

  automount_service_account_token = false
}
