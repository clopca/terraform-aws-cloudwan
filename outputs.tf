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

# Stable composition record. Increment schema_version only for a documented shape change.
output "fabric_handle" {
  description = "Versioned Global Network and Core Network handle for cross-module and cross-state composition."
  value = {
    schema_version = "cloudwan-fabric-handle/v1"
    global_network = {
      id  = local.global_network_id
      arn = local.global_network_arn
    }
    core_network = {
      id  = local.core_network_id
      arn = local.core_network_arn
    }
  }
}
