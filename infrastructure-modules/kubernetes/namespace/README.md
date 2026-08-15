# kubernetes/namespace

Cloud-agnostic namespace with security and resource guardrails preconfigured.
Works on EKS, GKE, AKS, or any conformant cluster.

## What it enforces

- **Pod Security admission** at `restricted` — non-conforming pods are rejected,
  not just warned. `privileged` is not an accepted value.
- **Default-deny NetworkPolicy** for both ingress and egress, with a DNS egress
  carve-out (without it nothing in the namespace can resolve anything) and
  same-namespace ingress allowed.
- **ResourceQuota** ceiling when supplied, so one namespace cannot starve the
  cluster.
- **LimitRange** defaults, so a container that declares no limits still gets
  them.
- **`default` ServiceAccount with token automounting off** — a pod that does not
  explicitly request a ServiceAccount cannot reach the API server.

## Usage

```hcl
module "namespace" {
  source = "../../infrastructure-modules/kubernetes/namespace"

  name = "orders-prod"

  resource_quota = {
    requests_cpu    = "10"
    requests_memory = "20Gi"
    limits_cpu      = "20"
    limits_memory   = "40Gi"
  }

  allowed_ingress_namespaces = ["ingress-nginx"]
}
```

Workload charts add their own NetworkPolicies on top of the default-deny to
open the specific paths they need.
