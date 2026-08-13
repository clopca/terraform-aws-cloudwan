terraform {
  required_version = ">= 1.15"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.59"
      configuration_aliases = [aws.ram]
    }
  }
}

locals {
  base_policy_document = jsonencode({
    version = "2021.12"
    "core-network-configuration" = {
      "asn-ranges"     = ["64512-64520"]
      "edge-locations" = [{ location = "us-west-2" }]
    }
    segments = [{ name = "legacy" }]
  })

  live_policy_document = jsonencode({
    version = "2021.12"
    "core-network-configuration" = {
      "asn-ranges"     = ["64512-64520"]
      "edge-locations" = [{ location = "us-west-2" }]
    }
    segments = [{ name = "legacy" }]
  })
}

resource "aws_networkmanager_global_network" "global_network" {
  count = 1

  description = "migration-fixture-global"
  tags        = { MigrationFixture = "v3-like" }
}

resource "aws_networkmanager_core_network" "core_network" {
  count = 1

  global_network_id    = aws_networkmanager_global_network.global_network[0].id
  description          = "migration-fixture-core"
  create_base_policy   = true
  base_policy_document = local.base_policy_document
  tags                 = { MigrationFixture = "v3-like" }
}

resource "aws_networkmanager_core_network_policy_attachment" "policy_attachment" {
  count = 1

  core_network_id = aws_networkmanager_core_network.core_network[0].id
  policy_document = local.live_policy_document
}

resource "aws_ram_resource_share" "resource_share" {
  provider = aws.ram
  count    = 1

  name                      = "migration-fixture-share"
  allow_external_principals = false
  tags                      = { MigrationFixture = "v3-like" }
}

resource "aws_ram_resource_association" "resource_association" {
  provider = aws.ram
  count    = 1

  resource_arn       = aws_networkmanager_core_network.core_network[0].arn
  resource_share_arn = aws_ram_resource_share.resource_share[0].arn
}

resource "aws_ram_principal_association" "principal_association" {
  provider = aws.ram
  count    = 1

  principal          = "arn:aws:organizations::123456789012:ou/o-abcdefghij/ou-abcd-12345678"
  resource_share_arn = aws_ram_resource_share.resource_share[0].arn
}
