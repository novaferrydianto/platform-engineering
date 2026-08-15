# gcp/gke

Private, regional GKE cluster with Workload Identity and network policy.

## Security defaults

- **Private nodes** with no external IPs; egress via the VPC module's Cloud NAT.
- **Master authorized networks** — `0.0.0.0/0` is rejected by variable
  validation.
- **Workload Identity** (`GKE_METADATA`) so pods impersonate Google service
  accounts instead of using node credentials or exported keys.
- **Dedicated least-privilege node service account** — not the default Compute
  Engine SA, which carries project editor.
- **Calico network policy** enabled, so `NetworkPolicy` objects are enforced.
- **Binary Authorization** in enforcement mode — only admitted images run.
- **Shielded nodes** with secure boot and integrity monitoring; legacy metadata
  endpoints disabled.
- **Deletion protection** on, and auto-repair/auto-upgrade for every pool.

## Usage

```hcl
module "gke" {
  source = "../../infrastructure-modules/gcp/gke"

  name                = "platform-prod"
  project_id          = "acme-platform-prod"
  region              = "asia-southeast1"
  network_name        = module.vpc.network_name
  subnet_name         = module.vpc.subnet_name
  pods_range_name     = module.vpc.pods_range_name
  services_range_name = module.vpc.services_range_name

  master_authorized_networks = [
    { cidr_block = "10.10.0.0/20", display_name = "vpc-internal" },
  ]

  node_pools = {
    general = {
      machine_type = "e2-standard-4"
      min_count    = 3
      max_count    = 10
    }
  }
}
```

Binary Authorization runs in enforcement mode — configure a policy that admits
your signed images before deploying, or admission will reject them.
