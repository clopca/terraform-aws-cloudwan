mock_provider "aws" {
  override_during = plan

  mock_resource "aws_networkmanager_global_network" {
    defaults = {
      id  = "global-network-11111111111111111"
      arn = "arn:aws:networkmanager::123456789012:global-network/global-network-11111111111111111"
    }
  }

  mock_resource "aws_networkmanager_core_network" {
    defaults = {
      id                = "core-network-11111111111111111"
      arn               = "arn:aws:networkmanager::123456789012:core-network/core-network-11111111111111111"
      global_network_id = "global-network-11111111111111111"
      state             = "AVAILABLE"
      edges = [{
        edge_location      = "us-west-2"
        asn                = 64512
        inside_cidr_blocks = ["169.254.0.0/24"]
      }]
      segments = [{
        name            = "shared"
        edge_locations  = ["us-west-2"]
        shared_segments = []
      }]
    }
  }

  mock_data "aws_networkmanager_global_network" {
    defaults = {
      id  = "global-network-11111111111111111"
      arn = "arn:aws:networkmanager::123456789012:global-network/global-network-11111111111111111"
    }
  }

  mock_data "aws_networkmanager_core_network" {
    defaults = {
      core_network_id   = "core-network-11111111111111111"
      arn               = "arn:aws:networkmanager::123456789012:core-network/core-network-11111111111111111"
      global_network_id = "global-network-11111111111111111"
      state             = "AVAILABLE"
      edges = [{
        edge_location      = "us-west-2"
        asn                = 64512
        inside_cidr_blocks = ["169.254.0.0/24"]
      }]
      segments = [{
        name            = "shared"
        edge_locations  = ["us-west-2"]
        shared_segments = []
      }]
    }
  }
}

run "create_global_and_core" {
  command = plan
  variables {
    global_network = { description = "created-global" }
    core_network   = { description = "created-core" }
  }
  assert {
    condition     = length(aws_networkmanager_global_network.global_network) == 1 && length(aws_networkmanager_core_network.core_network) == 1
    error_message = "Create mode must own exactly one Global Network and one Core Network."
  }
}

run "reference_global_and_core" {
  command = plan
  variables {
    global_network = { create = false, id = "global-network-11111111111111111" }
    core_network   = { create = false, id = "core-network-11111111111111111" }
  }
  assert {
    condition = (
      length(aws_networkmanager_global_network.global_network) == 0 &&
      length(aws_networkmanager_core_network.core_network) == 0 &&
      output.core_network_id == "core-network-11111111111111111" &&
      output.core_network_edges_by_region["us-west-2"].asn == 64512
    )
    error_message = "Reference mode must own no fabric resources and retain resolved Tier 1 topology."
  }
}

run "reference_global_create_core" {
  command = plan
  variables {
    global_network = { create = false, id = "global-network-11111111111111111" }
    core_network   = { description = "created-core" }
  }
  assert {
    condition     = length(aws_networkmanager_global_network.global_network) == 0 && length(aws_networkmanager_core_network.core_network) == 1
    error_message = "Each fabric boundary must select ownership independently."
  }
}

run "reject_create_global_reference_core" {
  command = plan
  variables {
    global_network = { description = "created-global" }
    core_network   = { create = false, id = "core-network-11111111111111111" }
  }
  expect_failures = [terraform_data.fabric_contract]
}

run "reject_global_create_with_id" {
  command = plan
  variables {
    global_network = { id = "global-network-11111111111111111" }
    core_network   = { description = "core" }
  }
  expect_failures = [var.global_network]
}

run "reject_global_reference_create_fields" {
  command = plan
  variables {
    global_network = { create = false, id = "global-network-11111111111111111", description = "not-owned" }
    core_network   = { description = "core" }
  }
  expect_failures = [var.global_network]
}

run "reject_core_create_with_id" {
  command = plan
  variables {
    global_network = { description = "global" }
    core_network   = { id = "core-network-11111111111111111" }
  }
  expect_failures = [var.core_network]
}

run "reject_core_reference_create_fields" {
  command = plan
  variables {
    global_network = { create = false, id = "global-network-11111111111111111" }
    core_network = {
      create      = false
      id          = "core-network-11111111111111111"
      base_policy = { regions = ["us-west-2"] }
    }
  }
  expect_failures = [var.core_network]
}

run "base_policy_document" {
  command = plan
  variables {
    global_network = { description = "global" }
    core_network = {
      description = "core"
      base_policy = { policy_document = jsonencode({ version = "2021.12" }) }
    }
  }
  assert {
    condition     = aws_networkmanager_core_network.core_network[0].create_base_policy
    error_message = "A document base policy must enable create_base_policy."
  }
}

run "base_policy_regions" {
  command = plan
  variables {
    global_network = { description = "global" }
    core_network = {
      description = "core"
      base_policy = { regions = ["us-west-2", "eu-west-1"] }
    }
  }
  assert {
    condition     = toset(aws_networkmanager_core_network.core_network[0].base_policy_regions) == toset(["us-west-2", "eu-west-1"])
    error_message = "Region base policy must pass all caller regions to initial Core Network creation."
  }
}

run "reject_base_policy_both_branches" {
  command = plan
  variables {
    global_network = { description = "global" }
    core_network = {
      description = "core"
      base_policy = {
        policy_document = "{}"
        regions         = ["us-west-2"]
      }
    }
  }
  expect_failures = [var.core_network]
}

run "reject_base_policy_invalid_json" {
  command = plan
  variables {
    global_network = { description = "global" }
    core_network = {
      description = "core"
      base_policy = { policy_document = "not-json" }
    }
  }
  expect_failures = [var.core_network]
}

run "base_policy_approval_matches" {
  command = plan
  variables {
    global_network = { description = "global" }
    core_network = {
      description = "core"
      base_policy = {
        policy_document = "{}"
        approved_sha256 = sha256("{}")
      }
    }
  }
}

run "reject_base_policy_approval_mismatch" {
  command = plan
  variables {
    global_network = { description = "global" }
    core_network = {
      description = "core"
      base_policy = {
        policy_document = "{}"
        approved_sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      }
    }
  }
  expect_failures = [terraform_data.base_policy_approval]
}

run "reject_core_global_mismatch" {
  command = plan
  variables {
    global_network = { create = false, id = "global-network-11111111111111111" }
    core_network   = { create = false, id = "core-network-11111111111111111" }
  }
  override_data {
    target = data.aws_networkmanager_core_network.existing[0]
    values = { global_network_id = "global-network-22222222222222222" }
  }
  expect_failures = [terraform_data.core_global_relationship]
}
