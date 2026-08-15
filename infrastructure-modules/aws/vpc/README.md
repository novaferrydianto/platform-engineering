# aws/vpc

Multi-AZ VPC with private and optional public subnets, NAT egress, and flow logs.

## Security defaults

- The default security group is emptied — anything that lands in it by accident
  has no network access.
- `map_public_ip_on_launch = false`; public IPs are opt-in per workload.
- Flow logs to CloudWatch are on by default (`enable_flow_logs`), with the IAM
  policy scoped to this VPC's log group rather than `*`.
- At least two availability zones are enforced by variable validation.

## Usage

```hcl
module "vpc" {
  source = "../../infrastructure-modules/aws/vpc"

  name                 = "platform-prod"
  cidr_block           = "10.0.0.0/16"
  availability_zones   = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  private_subnet_cidrs = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
  public_subnet_cidrs  = ["10.0.128.0/24", "10.0.129.0/24", "10.0.130.0/24"]

  tags = { Environment = "prod" }
}
```

Set `single_nat_gateway = true` in dev to cut cost; leave it `false` in prod so
an AZ failure does not remove egress for every private subnet.
