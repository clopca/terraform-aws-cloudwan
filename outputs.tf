# Tier 1: stable handles.
output "global_network_id" {
  description = "Global Network ID in create and reference modes."
  value       = local.global_network_id
}

output "global_network_arn" {
  description = "Global Network ARN in create and reference modes."
  value       = var.global_network.create ? aws_networkmanager_global_network.global_network[0].arn : data.aws_networkmanager_global_network.existing[0].arn
}

output "core_network_id" {
  description = "Core Network ID in create and reference modes."
  value       = local.core_network_id
}

output "core_network_arn" {
  description = "Core Network ARN in create and reference modes."
  value       = local.core_network_arn
}

output "core_network_state" {
  description = "Core Network state from the last refresh; not continuous health and not proof that a policy is LIVE."
  value       = local.core_network_state
}

output "core_network_edges_by_region" {
  description = "Resolved Core Network edges keyed by AWS Region in create and reference modes."
  value = {
    for edge in local.core_network_edges : edge.edge_location => {
      asn                = edge.asn
      inside_cidr_blocks = sort(tolist(edge.inside_cidr_blocks))
    }
  }
}

output "core_network_segments_by_name" {
  description = "Resolved Core Network segments keyed by segment name in create and reference modes."
  value = {
    for segment in local.core_network_segments : segment.name => {
      edge_locations  = sort(tolist(segment.edge_locations))
      shared_segments = sort(tolist(segment.shared_segments))
    }
  }
}

# Tier 3: provider-shaped escape hatch. Do not pass this output across states.
output "resources" {
  description = "UNSTABLE Tier 3 provider-shaped escape hatch. Shape may change in any release; prefer Tier 1 outputs."
  value = {
    global_network = var.global_network.create ? aws_networkmanager_global_network.global_network[0] : null
    core_network   = var.core_network.create ? aws_networkmanager_core_network.core_network[0] : null
  }
}
