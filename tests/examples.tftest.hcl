mock_provider "aws" {
  override_during = plan
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_region" {
    defaults = { region = "us-west-2" }
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
    defaults = { arn = "arn:aws:ram:us-west-2:123456789012:resource-share/22222222-2222-2222-2222-222222222222" }
  }
}

mock_provider "aws" {
  alias           = "ram"
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
  mock_resource "aws_ram_resource_association" {
    defaults = { id = "resource-association-mock" }
  }
  mock_resource "aws_ram_principal_association" {
    defaults = { id = "principal-association-mock" }
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

run "stack_without_sharing" {
  command = plan
  module { source = "./examples/stack_compact" }
  variables {
    sharing = null
  }
  assert {
    condition = (
      output.resource_share_arn == null &&
      output.resource_association_ids == {} &&
      output.principal_association_ids == {}
    )
    error_message = "The compact example must leave no RAM outputs or associations when sharing is disabled."
  }
}

run "stack_with_sharing" {
  command = plan
  module { source = "./examples/stack_compact" }
  variables {
    sharing = {
      name = "tested-compact-share"
      principals = {
        application = "123456789012"
      }
    }
  }
  assert {
    condition = (
      output.resource_share_arn == "arn:aws:ram:us-east-1:123456789012:resource-share/11111111-1111-1111-1111-111111111111" &&
      toset(keys(output.resource_association_ids)) == toset(["core"]) &&
      toset(keys(output.principal_association_ids)) == toset(["application"])
    )
    error_message = "The compact example must propagate the fabric ARN and preserve resource/principal association keys."
  }
}
