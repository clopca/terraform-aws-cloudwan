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

module "cloudwan" {
  source = "../../modules/stack"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  global_network = { description = "compact-global-network" }
  core_network = {
    description = "compact-core-network"
    base_policy = { policy_document = local.policy_document }
  }

  policy_document = local.policy_document
  policy_timeouts = { update = "1h30m" }

  sharing = {
    resource_share = { name = "compact-core-network" }
    principals = {
      application = "123456789012"
    }
  }

  tags = { Example = "stack-compact" }
}
