terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

# Regression fixture for issue #25: the firewall policy ARN is computed (known
# only after apply). Instance keys of module.network_firewall must come solely
# from caller-defined map keys so the plan never fails with
# "Invalid for_each argument".
resource "aws_networkfirewall_firewall_policy" "computed" {
  name = "computed-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
  }
}

module "cloudwan" {
  source = "../../.."

  core_network_arn        = "arn:aws:networkmanager::123456789012:core-network/core-network-0123456789abcdef0"
  ipv4_network_definition = "10.0.0.0/8"

  central_vpcs = {
    inspection = {
      type       = "inspection"
      name       = "inspection-vpc"
      cidr_block = "10.10.0.0/24"
      az_count   = 2

      subnets = {
        endpoints    = { netmask = 28 }
        core_network = { netmask = 28 }
      }
    }
  }

  aws_network_firewall = {
    inspection = {
      name        = "inspection-firewall"
      description = "Firewall whose policy ARN is computed in the same plan"
      policy_arn  = aws_networkfirewall_firewall_policy.computed.arn
    }
  }
}
