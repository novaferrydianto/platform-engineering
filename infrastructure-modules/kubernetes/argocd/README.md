# kubernetes/argocd

Installs Argo CD. What it manages lives in
[`provisioning/gitops/`](../../../provisioning/gitops/) — this module is the
only imperative step in the GitOps chain.

## Security defaults

- **Local admin disabled** (`admin.enabled = false`). The built-in account is a
  shared credential with no audit trail. Configure SSO and grant access to
  groups instead.
- **`exec.enabled = false`** — no `kubectl exec` into workloads from the Argo CD
  UI, which would otherwise be an unaudited shell into any managed namespace.
- **Default RBAC is `role:readonly`**. Write access is granted per-group through
  `rbac_policy_csv`, never by widening the default.
- **Non-root, read-only rootfs, all capabilities dropped** on the server and
  repo server, matching the `restricted` Pod Security Standard the platform
  enforces everywhere else.
- **Dex and notifications off** unless explicitly enabled — each is another
  component holding cluster credentials.

## Usage

```hcl
module "argocd" {
  source = "../../infrastructure-modules/kubernetes/argocd"

  domain = "argocd.example.internal"

  # Grant write access to a named group rather than loosening the default.
  rbac_policy_csv = <<-CSV
    g, platform-team, role:admin
  CSV
}
```

## How this relates to `reusable-helm-deploy.yml`

Both can deploy an application; they are not redundant, and picking one per
workload is a deliberate choice:

| | `reusable-helm-deploy.yml` (CI push) | Argo CD (GitOps pull) |
|---|---|---|
| Trigger | Pipeline runs `helm upgrade` | Controller reconciles git state |
| Drift | Undetected until the next deploy | Detected and corrected continuously |
| Cluster credentials | Held by CI via OIDC | Held only by the in-cluster controller |
| Approval gate | GitHub Environment reviewers | PR review on the manifest repo |

The CI path stays the default for the golden paths because it keeps the whole
deploy visible in one pipeline run. Argo CD is the better fit for platform
components and anything where drift correction matters more than deploy-time
visibility — which is why the Kyverno policies are delivered through it.
