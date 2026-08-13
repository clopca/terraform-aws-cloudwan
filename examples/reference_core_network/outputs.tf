output "global_network_arn" {
  description = "Resolved Global Network ARN."
  value       = module.cloudwan.global_network_arn
}

output "core_network_arn" {
  description = "Resolved Core Network ARN."
  value       = module.cloudwan.core_network_arn
}

output "core_network_edges_by_region" {
  description = "Resolved Core Network edges keyed by AWS Region."
  value       = module.cloudwan.core_network_edges_by_region
}
