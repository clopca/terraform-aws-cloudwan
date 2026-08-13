output "core_network_id" {
  description = "Core Network ID produced by the compact fabric composition."
  value       = module.fabric.core_network_id
}

output "policy_document_sha256" {
  description = "SHA-256 of the exact deployed policy document bytes."
  value       = module.policy_deployment.policy_document_sha256
}

output "resource_share_arn" {
  description = "RAM resource share ARN when sharing is enabled, otherwise null."
  value       = var.sharing == null ? null : module.share[0].resource_share_arn
}

output "resource_association_ids" {
  description = "RAM resource association IDs keyed by compact-composition identity, or an empty map when sharing is disabled."
  value       = var.sharing == null ? {} : module.share[0].resource_association_ids
}

output "principal_association_ids" {
  description = "RAM principal association IDs keyed by compact-composition identity, or an empty map when sharing is disabled."
  value       = var.sharing == null ? {} : module.share[0].principal_association_ids
}
