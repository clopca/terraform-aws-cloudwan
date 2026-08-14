module "cloudwan" {
  source = "../.."

  global_network = { description = "cross-account-global-network" }
  core_network = {
    description = "cross-account-core-network"
    base_policy = { regions = ["us-west-2", "us-east-1"] }
  }
}

module "share" {
  source = "../../modules/core-network-share"

  providers = { aws = aws.ram }

  resource_share = {
    name                      = "organization-cloudwan"
    allow_external_principals = false
  }

  resources = {
    core = module.cloudwan.core_network_arn
  }

  principals = {
    organization   = var.organization_arn
    application-ou = var.application_ou_arn
  }
}
