terraform {
  required_version = ">= 1.12"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.2"
    }
  }
}
