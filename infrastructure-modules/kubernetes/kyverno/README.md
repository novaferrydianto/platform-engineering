# kubernetes/kyverno

Installs the Kyverno admission controller. **Policies are not installed here** —
they live in [`provisioning/policies/kyverno/`](../../../provisioning/policies/kyverno/)
and are delivered by Argo CD.

## Why the split

- **CRD ordering**: OpenTofu cannot plan a `ClusterPolicy` before Kyverno's CRDs
  exist, so engine and policies cannot live in one apply.
- **Change velocity**: a policy change should be a reviewed git commit that Argo
  CD reconciles in seconds, not a `tofu apply` with cloud credentials.

## What this covers that Pod Security Standards do not

`infrastructure-modules/kubernetes/namespace` already enforces the `restricted`
Pod Security Standard, which handles non-root, capabilities, and privilege
escalation. Kyverno exists here for the rules PSS has no concept of:

| Policy | Why PSS can't do it |
|---|---|
| `verify-image-signatures` | Validates cosign signatures from `reusable-docker-build-push.yml`. Without it the platform signs images that nothing ever verifies. |
| `restrict-image-registries` | PSS does not inspect image provenance at all. |
| `disallow-unpinned-images` | `latest`/mutable tags are a supply-chain gap, not a pod-security one. |
| `require-resource-limits` | PSS ignores resources; a `LimitRange` supplies defaults but never *requires* explicit values. |

## Usage

```hcl
module "kyverno" {
  source = "../../infrastructure-modules/kubernetes/kyverno"

  replicas = 3   # keep >= 2 outside dev
}
```

## Operational notes

- Kyverno's own namespace and `kube-system` are always exempt from admission
  control. A policy that blocks `kube-system` can leave the cluster unrecoverable.
- Roll out new policies in `Audit` mode first (see the policies directory), then
  promote to `Enforce` once the reports are clean.
