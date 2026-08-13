mock_provider "aws" {
  override_during = plan
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
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
      edges             = []
      segments          = []
    }
  }
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
  mock_resource "aws_networkmanager_core_network_policy_attachment" {
    defaults = { state = "AVAILABLE" }
  }
  mock_resource "aws_ram_resource_share" {
    defaults = { arn = "arn:aws:ram:us-east-1:123456789012:resource-share/11111111-1111-1111-1111-111111111111" }
  }
}

mock_provider "aws" {
  alias           = "us_east_1"
  override_during = plan
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
  }
  mock_resource "aws_ram_resource_share" {
    defaults = { arn = "arn:aws:ram:us-east-1:123456789012:resource-share/11111111-1111-1111-1111-111111111111" }
  }
}

run "example_basic" {
  command = plan
  module { source = "./examples/basic" }
}

run "example_reference_core_network" {
  command = plan
  module { source = "./examples/reference_core_network" }
}

run "example_core_network_share" {
  command = plan
  module { source = "./examples/core_network_share" }
}

run "example_stack_compact" {
  command = plan
  module { source = "./examples/stack_compact" }
}
