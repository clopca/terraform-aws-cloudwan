output "resource_share_arn" {
  description = "RAM resource share ARN created by the example."
  value       = module.share.resource_share_arn
}

output "principal_association_ids" {
  description = "RAM principal association IDs keyed by example identity."
  value       = module.share.principal_association_ids
}
