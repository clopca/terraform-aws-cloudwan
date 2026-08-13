module "cloudwan" {
  source = "../.."

  global_network = { description = "shared-global-network" }
  core_network = {
    description = "shared-core-network"
    base_policy = { regions = ["us-west-2"] }
  }
}

module "share" {
  source = "../../modules/core-network-share"

  providers = { aws = aws.ram }

  resource_share = {
    name = "shared-core-network"
  }

  resources = {
    core = module.cloudwan.core_network_arn
  }

  principals = {
    network-tools = "123456789012"
  }
}
