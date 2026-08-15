include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infrastructure-modules/aws//eks"
}

dependency "vpc" {
  config_path = "../vpc"

  # Lets `plan` work before the VPC exists, e.g. on a first-run PR.
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id             = "vpc-mock"
    private_subnet_ids = ["subnet-mock-a", "subnet-mock-b"]
  }
}

locals {
  env     = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  account = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals
}

inputs = {
  name               = "platform-${local.env.environment}"
  kubernetes_version = local.env.kubernetes_version
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids

  node_groups = {
    general = {
      instance_types = ["t3.large"]
      desired_size   = 2
      min_size       = 2
      max_size       = 4
    }
  }

  tags = merge(local.account.tags, { Environment = local.env.environment })
}
