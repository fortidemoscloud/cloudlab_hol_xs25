# ------------------------------------------------------------------------------------------
# Terraform state
# ------------------------------------------------------------------------------------------
terraform {
  required_providers {
    fortios = {
      source = "fortinetdev/fortios"
    }
    google = {
      source  = "hashicorp/google"
      version = "4.48.0"
    }
  }
  backend "s3" {}
}

#variable "project" {}

provider "google" {
  #project = var.project
  region = var.region
}

# ------------------------------------------------------------------------------------------
# FortiOS provider
# ------------------------------------------------------------------------------------------
provider "fortios" {
  hostname = local.fgt_merged.api_host
  token    = local.fgt_merged.api_key
  insecure = "true"
}