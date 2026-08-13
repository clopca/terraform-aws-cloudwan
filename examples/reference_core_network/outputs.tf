output "global_network_arn" {
  value = module.cloudwan.global_network_arn
}

output "core_network_arn" {
  value = module.cloudwan.core_network_arn
}

output "core_network_edges_by_region" {
  value = module.cloudwan.core_network_edges_by_region
}
