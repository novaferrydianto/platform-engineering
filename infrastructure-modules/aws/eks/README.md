# aws/eks

Private EKS cluster with managed node groups, IRSA, and envelope-encrypted secrets.

## Security defaults

- **Private API endpoint** — `endpoint_public_access = false`. Enabling it
  requires an explicit CIDR allowlist, and `0.0.0.0/0` is rejected by variable
  validation.
- **etcd secret encryption** via a dedicated, auto-rotating KMS key.
- **IMDSv2 required** with `http_put_response_hop_limit = 1`, closing the
  SSRF-to-node-credentials path.
- **Encrypted gp3 root volumes** on every node, using the same KMS key.
- **Control plane audit logging** on by default, retained 90 days.
- **`bootstrap_cluster_creator_admin_permissions = false`** — the principal that
  runs `apply` does not silently become cluster admin; grant access explicitly
  via EKS access entries.
- **IRSA OIDC provider** so workloads assume scoped roles instead of inheriting
  the node role.
- **NetworkPolicy enforcement** via the VPC CNI's native eBPF policy agent
  (`enableNetworkPolicy`) — the AWS-managed equivalent of GKE's Calico and
  AKS's Cilium. Without it, `NetworkPolicy` objects apply but do nothing.

## Usage

```hcl
module "eks" {
  source = "../../infrastructure-modules/aws/eks"

  name               = "platform-prod"
  kubernetes_version = "1.31"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  node_groups = {
    general = {
      instance_types = ["m6i.large"]
      desired_size   = 3
      min_size       = 3
      max_size       = 10
    }
  }

  tags = { Environment = "prod" }
}
```

## Granting cluster access

`authentication_mode = "API"` means access is managed through EKS access
entries, not the legacy `aws-auth` ConfigMap. Create entries for the roles that
need cluster access in the consuming stack.
