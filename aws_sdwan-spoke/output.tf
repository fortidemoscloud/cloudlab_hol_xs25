output "fgt" {
  value = module.fgt.fgt
}

output "fgt_secret_id" {
  value = "${var.prefix}-fgt"
}

output "ssh_key_pem_secret_id" {
  sensitive = true
  value     = local.ssh_key_pem_secret_id
}

output "fgt_api_key" {
  value = module.fgt.api_key
}

output "k8s" {
  value = local.o_k8s
}

/*
output "fgt_secret" {
  value = local.o_fgt_secret
}

output "ssh_private_key_pem" {
  sensitive = true
  value     = module.fgt.ssh_private_key_pem
}
*/