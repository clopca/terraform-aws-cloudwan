mock_provider "aws" {
  override_during = plan

  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_region" {
    defaults = { region = "us-west-2" }
  }
  mock_resource "aws_networkmanager_global_network" {
    defaults = {
      id       = "global-network-11111111111111111"
      arn      = "arn:aws:networkmanager::123456789012:global-network/global-network-11111111111111111"
      tags_all = { MigrationFixture = "v3-like" }
    }
  }
  mock_resource "aws_networkmanager_core_network" {
    defaults = {
      id                = "core-network-11111111111111111"
      arn               = "arn:aws:networkmanager::123456789012:core-network/core-network-11111111111111111"
      created_at        = "2026-08-14T00:00:00Z"
      global_network_id = "global-network-11111111111111111"
      state             = "AVAILABLE"
      edges             = []
      segments          = []
      tags_all          = { MigrationFixture = "v3-like" }
    }
  }
  mock_resource "aws_networkmanager_core_network_policy_attachment" {
    defaults = {
      id    = "core-network-11111111111111111"
      state = "AVAILABLE"
    }
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
    defaults = {
      id              = "11111111-1111-1111-1111-111111111111"
      arn             = "arn:aws:ram:us-east-1:123456789012:resource-share/11111111-1111-1111-1111-111111111111"
      permission_arns = []
      region          = "us-east-1"
      tags_all        = { MigrationFixture = "v3-like" }
    }
  }
  mock_resource "aws_ram_resource_association" {
    defaults = {
      id     = "resource-association-mock"
      region = "us-east-1"
    }
  }
  mock_resource "aws_ram_principal_association" {
    defaults = {
      id     = "principal-association-mock"
      region = "us-east-1"
    }
  }
}

run "apply_v3_like_state" {
  command   = apply
  state_key = "v3-to-v4-first-hop"

  module {
    source = "./tests/fixtures/v3-to-v4-first-hop/v3-like"
  }

  providers = {
    aws     = aws
    aws.ram = aws.ram
  }
}

run "plan_v4_first_hop" {
  command   = plan
  state_key = "v3-to-v4-first-hop"

  module {
    source = "./tests/fixtures/v3-to-v4-first-hop/v4-first-hop"
  }

  providers = {
    aws     = aws
    aws.ram = aws.ram
  }

  assert {
    condition     = output.resource_share_arn == "arn:aws:ram:us-east-1:123456789012:resource-share/11111111-1111-1111-1111-111111111111"
    error_message = "The first-hop plan must retain the v3 RAM share through the role provider."
  }
}
