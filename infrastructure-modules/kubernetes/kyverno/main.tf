# Kyverno admission controller. This module installs the engine only — the
# ClusterPolicies it enforces live in provisioning/policies/kyverno/ and are
# delivered by Argo CD, so a policy change is a reviewed git commit rather than
# a `tofu apply` against the cluster.
#
# Splitting them also avoids the CRD ordering problem: OpenTofu cannot plan a
# ClusterPolicy resource before Kyverno's CRDs exist.
resource "helm_release" "kyverno" {
  name             = "kyverno"
  repository       = "https://kyverno.github.io/kyverno"
  chart            = "kyverno"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  atomic           = true
  wait             = true
  timeout          = 600

  values = [yamlencode({
    # Multiple replicas per controller: a single-replica admission controller is
    # a single point of failure that fails *open* under `failurePolicy: Ignore`
    # or blocks all deployments under `Fail`.
    admissionController = {
      replicas = var.replicas

      container = {
        resources = var.resources
      }

      # The webhook must not intercept its own namespace, or a broken policy
      # cannot be rolled back without deleting the webhook by hand.
      initContainer = {
        resources = var.init_resources
      }
    }

    backgroundController = {
      replicas = var.replicas
    }

    cleanupController = {
      replicas = var.replicas
    }

    reportsController = {
      replicas = var.replicas
    }

    config = {
      # Namespaces excluded from admission control. Kyverno's own namespace and
      # kube-system must be here: a policy that blocks kube-system can brick the
      # cluster with no way in.
      webhooks = [{
        namespaceSelector = {
          matchExpressions = [{
            key      = "kubernetes.io/metadata.name"
            operator = "NotIn"
            values   = concat([var.namespace, "kube-system"], var.excluded_namespaces)
          }]
        }
      }]
    }
  })]
}
