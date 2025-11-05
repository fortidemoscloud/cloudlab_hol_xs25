
#--------------------------------------------------------------------------------------------------------------
# FGT Cluster module example
# - 1 FortiGate spoke
#--------------------------------------------------------------------------------------------------------------
module "fgt" {
  source  = "jmvigueras/ftnt-aws-modules/aws//examples/basic_fgt-cluster"
  version = "1.0.4"

  prefix = var.prefix

  region = local.custom_vars_merged["region"]
  azs    = local.azs

  fgt_build        = local.custom_vars_merged["fgt_build"]
  license_type     = local.custom_vars_merged["license_type"]
  fortiflex_tokens = local.custom_vars_merged["fortiflex_tokens"]

  instance_type = local.custom_vars_merged["fgt_size"]

  fgt_number_peer_az = local.custom_vars_merged["fgt_number_peer_az"]
  fgt_cluster_type   = local.custom_vars_merged["fgt_cluster_type"]

  fgt_vpc_cidr               = local.custom_vars_merged["fgt_vpc_cidr"]
  public_subnet_names_extra  = local.custom_vars_merged["public_subnet_names_extra"]
  private_subnet_names_extra = local.custom_vars_merged["private_subnet_names_extra"]

  config_extra = local.extra_config_sdwan

  tags = local.custom_vars_merged["tags"]
}
#--------------------------------------------------------------------------------------------------------------
# K8S server
# - Two applications deployed
#--------------------------------------------------------------------------------------------------------------
module "k8s" {
  source  = "jmvigueras/ftnt-aws-modules/aws//modules/vm"
  version = "1.0.4"

  prefix        = var.prefix
  keypair       = module.fgt.keypair_name
  instance_type = local.custom_vars_merged["k8s_size"]

  user_data = local.k8s_user_data

  subnet_id       = module.fgt.subnet_ids["az1"]["bastion"]
  subnet_cidr     = module.fgt.subnet_cidrs["az1"]["bastion"]
  security_groups = [module.fgt.sg_ids["default"]]
}

locals {
  # K8S configuration and APP deployment
  k8s_deployment = templatefile("./templates/voteapp.yaml.tp", {
    nodeport      = local.app_node_port
    vote_question = "Do you enjoy automation with Fortinet?"
    }
  )
  k8s_user_data = templatefile("./templates/k8s.sh.tp", {
    k8s_version         = local.custom_vars_merged["k8s_version"]
    linux_user          = "ubuntu"
    k8s_deployment      = local.k8s_deployment
    api_cert_extra_sans = module.fgt.fgt["az1.fgt1"]["fgt_public"]
    }
  )
}

#------------------------------------------------------------------------------------------------------------
# Secrets
#------------------------------------------------------------------------------------------------------------
# Create fgt secret
resource "google_secret_manager_secret" "fgt" {
  secret_id = "${var.prefix}-fgt"

  replication {
    automatic = true
  }
}
# Add the secret version with your value
resource "google_secret_manager_secret_version" "fgt" {
  secret      = google_secret_manager_secret.fgt.id
  secret_data = jsonencode(local.o_fgt_secret)
}

# Create VM secret
resource "google_secret_manager_secret" "ssh-key-pem" {
  secret_id = local.ssh_key_pem_secret_id

  replication {
    automatic = true
  }
}
# Create VM secret SSH public key
resource "google_secret_manager_secret_version" "ssh-key-pem" {
  secret      = google_secret_manager_secret.ssh-key-pem.id
  secret_data = module.fgt.ssh_private_key_pem
}