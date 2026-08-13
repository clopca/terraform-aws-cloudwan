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


provider "aws" {
  region = "us-west-2"
}

provider "aws" {
  alias  = "ram"
  region = "us-east-1"
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

  desired_policy_document = jsonencode({
    version = "2021.12"
    "core-network-configuration" = {
      "asn-ranges"     = ["64512-64520"]
      "edge-locations" = [{ location = "us-west-2" }]
    }
    segments = [{ name = "migrated" }]
  })
}

module "cloudwan" {
  source = "../../../.."

  global_network = {
    description = "migration-fixture-global"
  }
  core_network = {
    description = "migration-fixture-core"
    base_policy = {
      policy_document = local.base_policy_document
      approved_sha256 = sha256(local.base_policy_document)
    }
  }
  tags = { MigrationFixture = "v3-like" }
}

module "cloudwan_policy" {
  source = "../../../../modules/policy-deployment"

  core_network_id = module.cloudwan.core_network_id
  policy_document = local.desired_policy_document
  timeouts        = { update = "60m" }
}

module "cloudwan_share" {
  source = "../../../../modules/core-network-share"

  providers = { aws = aws.ram }

  resource_share = {
    name = "migration-fixture-share"
    tags = { MigrationFixture = "v3-like" }
  }
  resources = {
    core = module.cloudwan.core_network_arn
  }
  principals = {
    production-ou = "arn:aws:organizations::123456789012:ou/o-abcdefghij/ou-abcd-12345678"
  }
}

moved {
  from = module.cloudwan.aws_networkmanager_core_network_policy_attachment.policy_attachment[0]
  to   = module.cloudwan_policy.aws_networkmanager_core_network_policy_attachment.this
}

moved {
  from = module.cloudwan.aws_ram_resource_share.resource_share[0]
  to   = module.cloudwan_share.aws_ram_resource_share.this[0]
}

moved {
  from = module.cloudwan.aws_ram_resource_association.resource_association[0]
  to   = module.cloudwan_share.aws_ram_resource_association.this["core"]
}

moved {
  from = module.cloudwan.aws_ram_principal_association.principal_association[0]
  to   = module.cloudwan_share.aws_ram_principal_association.this["production-ou"]
}

output "resource_share_arn" {
  value = module.cloudwan_share.resource_share_arn
}
