include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infrastructure-modules/aws//vpc"
}

locals {
  env     = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  account = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals
}

inputs = {
  name                 = "platform-${local.env.environment}"
  cidr_block           = local.env.vpc_cidr
  availability_zones   = local.env.availability_zones
  private_subnet_cidrs = local.env.private_subnet_cidrs
  public_subnet_cidrs  = local.env.public_subnet_cidrs
  single_nat_gateway   = local.env.single_nat_gateway

  tags = merge(local.account.tags, { Environment = local.env.environment })
}
