#-------------------------------------------------------------------------------------------------------------
# Data and Locals
#-------------------------------------------------------------------------------------------------------------
data "aws_availability_zones" "available" {}

data "google_secret_manager_secret_version" "hubs_secret" {
  secret = var.hubs_secret_id
}

locals {
  #  Availability Zones list of AZs to be used
  azs = slice(data.aws_availability_zones.available.names, 0, lookup(local.custom_vars_parsed, "number_azs", 1))

  # Parse the custom_vars variable from JSON string to an object
  custom_vars_parsed = jsondecode(var.custom_vars)

  # Create a merged custom_vars with defaults for any missing values
  custom_vars_merged = {
    region                     = try(local.custom_vars_parsed.region, "eu-west-1")
    number_azs                 = try(local.custom_vars_parsed.number_azs, 1)
    fgt_build                  = try(local.custom_vars_parsed.fgt_build, "build2829")
    license_type               = try(local.custom_vars_parsed.license_type, "payg")
    fortiflex_tokens           = try(jsondecode(local.custom_vars_parsed.fortiflex_tokens), [])
    fgt_size                   = try(local.custom_vars_parsed.fgt_size, "c6i.large")
    fgt_number_peer_az         = try(local.custom_vars_parsed.fgt_number_peer_az, 1)
    fgt_cluster_type           = try(local.custom_vars_parsed.fgt_cluster_type, "fgsp")
    fgt_vpc_cidr               = try(local.spoke_parsed.cidr, local.custom_vars_parsed.fgt_vpc_cidr, "192.168.1.0/24")
    public_subnet_names_extra  = try(jsondecode(local.custom_vars_parsed.public_subnet_names_extra), ["bastion"])
    private_subnet_names_extra = try(jsondecode(local.custom_vars_parsed.private_subnet_names_extra), ["protected"])
    k8s_size                   = try(local.custom_vars_parsed.k8s_size, "t3.2xlarge")
    k8s_version                = try(local.custom_vars_parsed.k8s_version, "1.31")
    gcp_secrets_region         = try(local.custom_vars_parsed.gcp_secrets_region, "europe-west2")
    tags                       = try(jsondecode(local.custom_vars_parsed.tags), { "Deploy" = "CloudLab AWS", "Project" = "CloudLab" })
  }

  # Parse the hubs variable from JSON string to a list of maps
  hubs_string = try(data.google_secret_manager_secret_version.hubs_secret.secret_data, var.hubs, "[{}]")
  hubs        = try(jsondecode(local.hubs_string), [{}])

  # Parse the spoke variable from JSON string to a map
  spoke_parsed = jsondecode(var.spoke)
  spoke_merged = {
    id      = try(local.spoke_parsed.id, "spoke1")
    bgp_asn = try(local.spoke_parsed.bgp_asn, lookup(local.hubs[0], "bgp_asn", "65000"))
    cidr    = try(local.spoke_parsed.cidr, "192.168.1.0/24")
  }

  extra_config_sdwan = join("\n", [for hub in range(length(local.hubs)) : templatefile("./templates/fgt_sdwan.conf", {
    hub_id             = local.hubs[hub]["id"]
    hub_ipsec_id       = "${local.hubs[hub]["id"]}_ipsec_${hub + 1}"
    hub_vpn_psk        = local.hubs[hub]["vpn_psk"]
    hub_external_ip    = lookup(local.hubs[hub], "external_ip", "")
    hub_external_fqdn  = lookup(local.hubs[hub], "external_fqdn", "")
    hub_private_ip     = local.hubs[hub]["hub_ip"]
    site_private_ip    = lookup(local.hubs[hub], "site_ip", "")
    hub_bgp_asn        = local.hubs[hub]["bgp_asn"]
    hck_ip             = local.hubs[hub]["hck_ip"]
    hub_cidr           = local.hubs[hub]["cidr"]
    network_id         = lookup(local.hubs[hub], "network_id", "1")
    ike_version        = lookup(local.hubs[hub], "ike_version", "2")
    dpd_retryinterval  = lookup(local.hubs[hub], "dpd_retryinterval", "5")
    local_id           = local.spoke_merged["id"]
    local_bgp_asn      = local.spoke_merged["bgp_asn"]
    local_network      = local.spoke_merged["cidr"]
    sdwan_port         = "port1"
    route_map_out      = lookup(local.hubs[hub], "route_map_out", "rm_out_branch_sla_nok")
    route_map_out_pref = lookup(local.hubs[hub], "route_map_out_pref", "rm_out_branch_sla_ok")
    route_map_in       = lookup(local.hubs[hub], "route_map_in", "")
    count              = hub + 1
    })
  ])

  #-------------------------------------------------------------------------------------------------------------
  # Outputs
  #-------------------------------------------------------------------------------------------------------------
  o_fgt_secret = {
    api_host = "${module.fgt.fgt["az1.fgt1"]["fgt_public"]}:8443"
    api_key  = module.fgt.api_key
  }
  
  app_node_port = "31000"

  o_k8s = {
    public_ip   = module.k8s.vm["public_ip"]
    adminuser   = module.k8s.vm["adminuser"]
    app_url     = "http://${module.k8s.vm["public_ip"]}:${local.app_node_port}"
  }
  
  ssh_key_pem_secret_id = "${var.prefix}-ssh-key-pem"
}