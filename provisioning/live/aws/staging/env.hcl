locals {
  environment = "staging"

  vpc_cidr             = "10.1.0.0/16"
  availability_zones   = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  private_subnet_cidrs = ["10.1.0.0/20", "10.1.16.0/20", "10.1.32.0/20"]
  public_subnet_cidrs  = ["10.1.128.0/24", "10.1.129.0/24", "10.1.130.0/24"]

  # Staging mirrors prod's topology so a change that works here behaves the same
  # way there.
  single_nat_gateway = false

  kubernetes_version = "1.31"
}
