include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infrastructure-modules/gcp//gke"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    network_name        = "mock-network"
    subnet_name         = "mock-subnet"
    pods_range_name     = "pods"
    services_range_name = "services"
  }
}

locals {
  env     = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  account = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals
}

inputs = {
  name                = "platform-${local.env.environment}"
  project_id          = local.account.project_id
  region              = local.account.region
  network_name        = dependency.vpc.outputs.network_name
  subnet_name         = dependency.vpc.outputs.subnet_name
  pods_range_name     = dependency.vpc.outputs.pods_range_name
  services_range_name = dependency.vpc.outputs.services_range_name

  # Control plane reachable only from inside the VPC.
  master_authorized_networks = [
    {
      cidr_block   = local.env.subnet_cidr
      display_name = "vpc-internal"
    },
  ]

  node_pools = {
    general = {
      machine_type = "e2-standard-2"
      min_count    = 1
      max_count    = 3
    }
  }

  labels = merge(local.account.labels, { environment = local.env.environment })
}
