terraform {
  required_version = ">= 1.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.60"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.3"
    }
  }
}
