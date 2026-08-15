locals {
  environment = "prod"

  vpc_cidr             = "10.2.0.0/16"
  availability_zones   = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  private_subnet_cidrs = ["10.2.0.0/20", "10.2.16.0/20", "10.2.32.0/20"]
  public_subnet_cidrs  = ["10.2.128.0/24", "10.2.129.0/24", "10.2.130.0/24"]

  # One NAT gateway per AZ: an AZ failure must not remove egress for the others.
  single_nat_gateway = false

  kubernetes_version = "1.31"
}
