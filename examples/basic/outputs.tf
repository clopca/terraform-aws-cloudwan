output "global_network_id" {
  description = "Global Network ID created by the basic example."
  value       = module.cloudwan.global_network_id
}

output "core_network_id" {
  description = "Core Network ID created by the basic example."
  value       = module.cloudwan.core_network_id
}

output "policy_document_sha256" {
  description = "SHA-256 of the exact policy document deployed by the basic example."
  value       = module.policy.policy_document_sha256
}
