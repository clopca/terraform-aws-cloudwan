mock_provider "aws" {
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
      edges             = []
      segments          = []
    }
  }
}

run "base_policy_initial_apply" {
  command = apply

  variables {
    global_network = { description = "stateful-global" }
    core_network = {
      description = "stateful-core"
      base_policy = {
        policy_document = jsonencode({ version = "2021.12", marker = "initial" })
      }
    }
  }

  assert {
    condition = (
      aws_networkmanager_core_network.core_network[0].create_base_policy &&
      aws_networkmanager_core_network.core_network[0].base_policy_document == jsonencode({ version = "2021.12", marker = "initial" })
    )
    error_message = "The initial mocked apply must persist the exact create-only base policy document."
  }
}

run "base_policy_is_create_only_after_initial_apply" {
  command = plan

  variables {
    global_network = { description = "stateful-global" }
    core_network = {
      description = "stateful-core"
      base_policy = {
        regions = ["eu-west-1", "us-west-2"]
      }
    }
  }

  assert {
    condition = (
      aws_networkmanager_core_network.core_network[0].create_base_policy &&
      aws_networkmanager_core_network.core_network[0].base_policy_document == jsonencode({ version = "2021.12", marker = "initial" }) &&
      try(length(aws_networkmanager_core_network.core_network[0].base_policy_regions), 0) == 0
    )
    error_message = "A second plan must ignore changes to create_base_policy, base_policy_document, and base_policy_regions."
  }
}
