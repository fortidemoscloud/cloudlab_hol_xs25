#------------------------------------------------------------------------------------------------------------
# Provider
#------------------------------------------------------------------------------------------------------------
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.48.0"
    }
  }
  #backend "s3" {}
}

variable "project" {}

provider "google" {
  project = var.project
  region  = local.custom_vars_merged["region"]
}
provider "google-beta" {
  project = var.project
  region  = local.custom_vars_merged["region"]
}

