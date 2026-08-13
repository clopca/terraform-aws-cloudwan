output "global_network_id" {
  description = "Computed Global Network ID passed through the root module."
  value       = module.cloudwan.global_network_id
}

output "core_network_id" {
  description = "Computed Core Network ID passed through the root module."
  value       = module.cloudwan.core_network_id
}

output "fabric_handle" {
  description = "Versioned fabric handle returned for computed reference IDs."
  value       = module.cloudwan.fabric_handle
}
