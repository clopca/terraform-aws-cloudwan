output "core_network_id" {
  description = "Core Network targeted by this deployment request."
  value       = var.core_network_id
}

output "core_network_state" {
  description = "Core Network state from the last provider refresh; not proof that the desired policy is LIVE."
  value       = aws_networkmanager_core_network_policy_attachment.this.state
}

output "policy_document_sha256" {
  description = "SHA-256 of the exact policy_document string bytes submitted to Terraform."
  value       = local.policy_document_sha256
}

output "policy_schema_version" {
  description = "Cloud WAN policy schema version declared by policy_document."
  value       = jsondecode(var.policy_document).version
}
