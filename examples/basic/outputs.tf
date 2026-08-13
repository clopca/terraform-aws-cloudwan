output "global_network_id" {
  value = module.cloudwan.global_network_id
}

output "core_network_id" {
  value = module.cloudwan.core_network_id
}

output "policy_document_sha256" {
  value = module.policy.policy_document_sha256
}
