# Root Terragrunt configuration. Every unit finds this with
# find_in_parent_folders("root.hcl") and inherits remote state, provider
# generation, and common inputs from it.

locals {
  account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  cloud       = local.account_vars.locals.cloud
  environment = local.environment_vars.locals.environment
  region      = local.account_vars.locals.region

  state_bucket = local.account_vars.locals.state_bucket
  state_key    = "${local.environment}/${path_relative_to_include()}/tofu.tfstate"
}

# State is encrypted, versioned, and locked. `generate` writes the backend into
# each unit so no unit can accidentally use local state.
remote_state {
  backend = local.cloud == "aws" ? "s3" : (local.cloud == "gcp" ? "gcs" : "azurerm")

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = local.cloud == "aws" ? {
    bucket       = local.state_bucket
    key          = local.state_key
    region       = local.region
    encrypt      = true
    use_lockfile = true
    } : local.cloud == "gcp" ? {
    bucket = local.state_bucket
    prefix = local.state_key
    } : {
    storage_account_name = local.state_bucket
    container_name       = "tfstate"
    key                  = local.state_key
    use_azuread_auth     = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    %{if local.cloud == "aws"~}
    provider "aws" {
      region = "${local.region}"

      default_tags {
        tags = {
          Environment = "${local.environment}"
          ManagedBy   = "terragrunt"
        }
      }
    }
    %{endif~}
    %{if local.cloud == "gcp"~}
    provider "google" {
      project = "${try(local.account_vars.locals.project_id, "")}"
      region  = "${local.region}"
    }
    %{endif~}
    %{if local.cloud == "azure"~}
    provider "azurerm" {
      subscription_id = "${try(local.account_vars.locals.subscription_id, "")}"

      features {}
    }
    %{endif~}
  EOF
}

# Applied to every unit unless the unit overrides it.
inputs = merge(
  local.account_vars.locals,
  local.environment_vars.locals,
)
