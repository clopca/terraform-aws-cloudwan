locals {
  policy_document = jsonencode({
    version = "2021.12"
    "core-network-configuration" = {
      "asn-ranges"     = ["64512-64520"]
      "edge-locations" = [{ location = "us-west-2" }]
    }
    segments = [{ name = "shared" }]
  })
}

module "fabric" {
  source = "../.."

  global_network = { description = "compact-global-network" }
  core_network = {
    description = "compact-core-network"
    base_policy = { policy_document = local.policy_document }
  }

  tags = { Example = "stack-compact" }
}

module "policy_deployment" {
  source = "../../modules/policy-deployment"

  core_network_id = module.fabric.core_network_id
  policy_document = local.policy_document
  timeouts        = { update = "1h30m" }
}

module "share" {
  count  = var.sharing == null ? 0 : 1
  source = "../../modules/core-network-share"

  providers = { aws = aws.ram }

  resource_share = { name = var.sharing.name }
  resources      = { core = module.fabric.core_network_arn }
  principals     = var.sharing.principals
}
