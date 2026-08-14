output "resource_share_arn" {
  description = "RAM resource share ARN used for Organization-wide access."
  value       = module.share.resource_share_arn
}

output "principal_association_ids" {
  description = "RAM principal association IDs keyed by Organization and OU identity."
  value       = module.share.principal_association_ids
}
