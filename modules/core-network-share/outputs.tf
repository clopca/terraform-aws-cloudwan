output "resource_share_arn" {
  description = "Created or referenced RAM resource share ARN."
  value       = local.resource_share_arn
}

output "resource_association_ids" {
  description = "RAM resource association IDs keyed by the caller-owned resources keys."
  value       = { for key, association in aws_ram_resource_association.this : key => association.id }
}

output "principal_association_ids" {
  description = "RAM principal association IDs keyed by the caller-owned principals keys."
  value       = { for key, association in aws_ram_principal_association.this : key => association.id }
}
