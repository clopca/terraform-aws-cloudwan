data "aws_networkmanager_global_network" "existing" {
  count = var.global_network.create ? 0 : 1

  global_network_id = var.global_network.id
}

data "aws_networkmanager_core_network" "existing" {
  count = var.core_network.create ? 0 : 1

  core_network_id = var.core_network.id
}

resource "aws_networkmanager_global_network" "global_network" {
  count = var.global_network.create ? 1 : 0

  description = var.global_network.description
  tags        = merge(var.tags, var.global_network.tags)
}

locals {
  global_network_id  = var.global_network.create ? aws_networkmanager_global_network.global_network[0].id : data.aws_networkmanager_global_network.existing[0].id
  global_network_arn = var.global_network.create ? aws_networkmanager_global_network.global_network[0].arn : data.aws_networkmanager_global_network.existing[0].arn

  base_policy_document        = try(var.core_network.base_policy.policy_document, null)
  base_policy_regions         = try(var.core_network.base_policy.regions, null)
  base_policy_approved_sha256 = try(lower(trimspace(var.core_network.base_policy.approved_sha256)), null)
  base_policy_actual_sha256   = local.base_policy_document == null ? null : sha256(local.base_policy_document)
}

resource "terraform_data" "fabric_contract" {
  input = {
    global_network_create = var.global_network.create
    core_network_create   = var.core_network.create
    has_base_policy       = var.core_network.base_policy != null
  }

  lifecycle {
    precondition {
      condition     = !(var.global_network.create && !var.core_network.create)
      error_message = "An existing Core Network cannot belong to a newly created Global Network."
    }

    precondition {
      condition     = var.core_network.base_policy == null || var.core_network.create
      error_message = "base_policy is CREATE-ONLY and cannot be applied to a referenced Core Network."
    }
  }
}

resource "terraform_data" "base_policy_approval" {
  input = local.base_policy_actual_sha256

  lifecycle {
    precondition {
      condition = local.base_policy_approved_sha256 == null ? true : (
        local.base_policy_approved_sha256 == local.base_policy_actual_sha256
      )
      error_message = "base_policy.approved_sha256 does not match the exact policy_document bytes."
    }
  }
}

resource "aws_networkmanager_core_network" "core_network" {
  count = var.core_network.create ? 1 : 0

  global_network_id    = local.global_network_id
  description          = var.core_network.description
  create_base_policy   = var.core_network.base_policy != null
  base_policy_document = local.base_policy_document
  base_policy_regions  = local.base_policy_regions
  tags                 = merge(var.tags, var.core_network.tags)

  depends_on = [terraform_data.fabric_contract, terraform_data.base_policy_approval]

  lifecycle {
    ignore_changes = [
      create_base_policy,
      base_policy_document,
      base_policy_regions,
    ]
  }
}

locals {
  core_network_id       = var.core_network.create ? aws_networkmanager_core_network.core_network[0].id : data.aws_networkmanager_core_network.existing[0].core_network_id
  core_network_arn      = var.core_network.create ? aws_networkmanager_core_network.core_network[0].arn : data.aws_networkmanager_core_network.existing[0].arn
  core_network_state    = var.core_network.create ? aws_networkmanager_core_network.core_network[0].state : data.aws_networkmanager_core_network.existing[0].state
  core_network_edges    = var.core_network.create ? aws_networkmanager_core_network.core_network[0].edges : data.aws_networkmanager_core_network.existing[0].edges
  core_network_segments = var.core_network.create ? aws_networkmanager_core_network.core_network[0].segments : data.aws_networkmanager_core_network.existing[0].segments
}

resource "terraform_data" "core_global_relationship" {
  input = {
    core_network_id   = local.core_network_id
    global_network_id = local.global_network_id
  }

  lifecycle {
    precondition {
      condition = var.core_network.create ? true : (
        data.aws_networkmanager_core_network.existing[0].global_network_id == local.global_network_id
      )
      error_message = "The referenced Core Network must belong to the resolved Global Network."
    }
  }
}
