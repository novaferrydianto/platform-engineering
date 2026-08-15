locals {
  environment = "dev"

  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["ap-southeast-1a", "ap-southeast-1b"]
  private_subnet_cidrs = ["10.0.0.0/20", "10.0.16.0/20"]
  public_subnet_cidrs  = ["10.0.128.0/24", "10.0.129.0/24"]

  # One NAT gateway is acceptable here: losing egress in dev during an AZ outage
  # is a cost/availability trade the team accepts. Never set this in prod.
  single_nat_gateway = true

  kubernetes_version = "1.31"
}
