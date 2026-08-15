include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infrastructure-modules/aws//rds"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id             = "vpc-mock"
    private_subnet_ids = ["subnet-mock-a", "subnet-mock-b", "subnet-mock-c"]
  }
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    node_security_group_id = "sg-mock"
  }
}

locals {
  env     = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  account = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals
}

inputs = {
  name               = "platform-${local.env.environment}"
  database_name      = "platform"
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids

  # The only thing allowed to reach the database is the cluster's node group.
  allowed_security_group_ids = [dependency.eks.outputs.node_security_group_id]

  multi_az            = true
  deletion_protection = true

  tags = merge(local.account.tags, { Environment = local.env.environment })
}
