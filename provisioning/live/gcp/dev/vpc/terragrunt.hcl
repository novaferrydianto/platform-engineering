include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infrastructure-modules/gcp//vpc"
}

locals {
  env     = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  account = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals
}

inputs = {
  name          = "platform-${local.env.environment}"
  project_id    = local.account.project_id
  region        = local.account.region
  subnet_cidr   = local.env.subnet_cidr
  pods_cidr     = local.env.pods_cidr
  services_cidr = local.env.services_cidr
}
