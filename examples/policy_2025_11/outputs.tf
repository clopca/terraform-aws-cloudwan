output "policy_version" {
  description = "Cloud WAN policy document version rendered by the AWS provider data source."
  value       = jsondecode(data.aws_networkmanager_core_network_policy_document.routing_and_inspection.json).version
}

output "policy_document_sha256" {
  description = "SHA-256 of the exact rendered 2025.11 policy document."
  value       = module.policy.policy_document_sha256
}

output "core_network_id" {
  description = "Core Network receiving the rendered policy."
  value       = module.cloudwan.core_network_id
}
