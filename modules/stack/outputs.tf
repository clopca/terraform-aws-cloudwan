output "global_network_id" {
  value = module.fabric.global_network_id
}

output "global_network_arn" {
  value = module.fabric.global_network_arn
}

output "core_network_id" {
  value = module.fabric.core_network_id
}

output "core_network_arn" {
  value = module.fabric.core_network_arn
}

output "core_network_state" {
  description = "Core Network state from the policy resource's last provider refresh; not proof that the policy is LIVE."
  value       = module.policy.core_network_state
}

output "core_network_edges_by_region" {
  value = module.fabric.core_network_edges_by_region
}

output "core_network_segments_by_name" {
  value = module.fabric.core_network_segments_by_name
}

output "policy_document_sha256" {
  value = module.policy.policy_document_sha256
}

output "policy_schema_version" {
  value = module.policy.policy_schema_version
}

output "resource_share_arn" {
  description = "RAM share ARN, or null when sharing is disabled."
  value       = var.sharing == null ? null : module.share[0].resource_share_arn
}

output "resource_association_ids" {
  description = "RAM resource association IDs, or an empty map when sharing is disabled."
  value       = var.sharing == null ? {} : module.share[0].resource_association_ids
}

output "principal_association_ids" {
  description = "RAM principal association IDs, or an empty map when sharing is disabled."
  value       = var.sharing == null ? {} : module.share[0].principal_association_ids
}
