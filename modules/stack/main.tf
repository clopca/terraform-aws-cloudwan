module "fabric" {
  source = "../.."

  providers = { aws = aws }

  global_network = var.global_network
  core_network   = var.core_network
  tags           = var.tags
}

module "policy" {
  source = "../policy"

  providers = { aws = aws }

  core_network_id = module.fabric.core_network_id
  policy_document = var.policy_document
  approval        = var.approval
  timeouts        = var.policy_timeouts
}

module "share" {
  count  = var.sharing == null ? 0 : 1
  source = "../core-network-share"

  providers = { aws = aws.us_east_1 }

  resource_share = var.sharing.resource_share
  resources = {
    core = module.fabric.core_network_arn
  }
  principals = var.sharing.principals
}
