# gcp/vpc

Custom-mode VPC with a regional subnet, secondary ranges for GKE, and Cloud NAT.

## Security defaults

- **Custom subnet mode** — no auto-created subnets in every region.
- **Explicit deny-all ingress** at priority 65534, with an internal-only allow
  rule above it. Nothing is reachable from outside until a rule says so.
- **Private Google Access** so instances reach Google APIs without external IPs.
- **VPC flow logs** at 50% sampling with full metadata.
- **Cloud NAT** for outbound access, so no instance needs an external IP.

## Usage

```hcl
module "vpc" {
  source = "../../infrastructure-modules/gcp/vpc"

  name          = "platform-prod"
  project_id    = "acme-platform-prod"
  region        = "asia-southeast1"
  subnet_cidr   = "10.10.0.0/20"
  pods_cidr     = "10.20.0.0/16"
  services_cidr = "10.30.0.0/20"
}
```

Set `pods_cidr` and `services_cidr` when the network will host a GKE cluster —
the module exposes the range names the `gcp/gke` module expects.
