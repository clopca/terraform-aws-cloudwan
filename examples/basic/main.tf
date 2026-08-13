locals {
  policy_document = jsonencode({
    version = "2021.12"
    "core-network-configuration" = {
      "asn-ranges" = ["64512-64520"]
      "edge-locations" = [{
        location = "us-west-2"
      }]
    }
    segments = [{ name = "shared" }]
  })
}

module "cloudwan" {
  source = "../.."

  global_network = {
    description = "basic-global-network"
  }

  core_network = {
    description = "basic-core-network"
    base_policy = {
      policy_document = local.policy_document
    }
  }

  tags = { Example = "basic" }
}

module "policy" {
  source = "../../modules/policy"

  core_network_id = module.cloudwan.core_network_id
  policy_document = local.policy_document
  timeouts        = { update = "60m" }
}
