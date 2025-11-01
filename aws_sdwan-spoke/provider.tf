#-------------------------------------------------------------------------------------------------------------
# Terraform Backend config
#-------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = local.custom_vars_merged["region"]
}

#variable "project" {}

provider "google" {
  #project = var.project
  region = local.custom_vars_merged["gcp_secrets_region"]
}

# Prepare to add backend config from CLI
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.94.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "4.48.0"
    }
  }
  backend "s3" {}
}