# Argo CD, installed as a day-1 platform component. Everything it then manages
# — Kyverno policies, platform addons, optionally application workloads — comes
# from git via the root Application in provisioning/gitops/, so this module is
# the only part of the GitOps story that is applied imperatively.
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  atomic           = true
  wait             = true
  timeout          = 900

  values = [yamlencode({
    global = {
      domain = var.domain
    }

    configs = {
      params = {
        # TLS terminates at the ingress; running the server itself in insecure
        # mode behind it avoids double encryption, but only makes sense when an
        # ingress actually fronts it.
        "server.insecure" = var.server_behind_tls_ingress
      }

      cm = {
        # The local admin account is a shared credential with no audit trail.
        # Disable it and drive access through SSO once configured.
        "admin.enabled"          = var.admin_enabled
        "exec.enabled"           = false # no kubectl exec from the Argo CD UI
        "application.namespaces" = join(",", var.application_namespaces)
        url                      = "https://${var.domain}"
      }

      rbac = {
        # Read-only by default. Anything beyond that is granted explicitly to a
        # named group, never to the default policy.
        "policy.default" = "role:readonly"
        "policy.csv"     = var.rbac_policy_csv
        scopes           = "[groups]"
      }
    }

    controller = {
      replicas  = var.controller_replicas
      resources = var.controller_resources
    }

    repoServer = {
      # The repo server renders manifests, which means it executes chart
      # templating logic — keep it non-root and unprivileged.
      replicas = var.replicas

      containerSecurityContext = {
        runAsNonRoot             = true
        readOnlyRootFilesystem   = true
        allowPrivilegeEscalation = false
        capabilities             = { drop = ["ALL"] }
        seccompProfile           = { type = "RuntimeDefault" }
      }
    }

    server = {
      replicas = var.replicas

      containerSecurityContext = {
        runAsNonRoot             = true
        readOnlyRootFilesystem   = true
        allowPrivilegeEscalation = false
        capabilities             = { drop = ["ALL"] }
        seccompProfile           = { type = "RuntimeDefault" }
      }
    }

    applicationSet = {
      replicas = var.replicas
    }

    # Notifications and the CLI-facing dex server are off unless configured;
    # every additional component is another thing holding cluster credentials.
    dex = {
      enabled = var.dex_enabled
    }

    notifications = {
      enabled = var.notifications_enabled
    }
  })]
}
